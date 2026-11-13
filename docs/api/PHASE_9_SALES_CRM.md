# Phase 9 — Sales & CRM API Contracts

**Scope:** Staff-facing sales pipeline, lead capture and assignment, follow-ups, test-ride operations, branch CRM dashboard, and the dynamic on-road quotation engine.

- **Base URL:** `http://localhost:5053/api/v1`
- **Envelope:** standard `ApiResponse<T>` (`success`, `statusCode`, `message`, `data`, `meta`, `errors`, `timestamp`)
- **Content type:** `application/json`
- **Time format:** UTC ISO-8601 (`2026-11-16T10:00:00Z`)
- **Authorization:** every endpoint in this document requires a staff bearer token and the `StaffOnly` policy.

---

## 1. Authentication & Scope

Staff JWTs are issued by `POST /auth/staff/login`:

```json
{
  "usernameOrEmail": "manager.priya",
  "password": "Demo@123",
  "dealerCode": "ALAGENDRA"
}
```

Claim values now use the canonical mapper `UserTypeClaims`:

| User type | `user_type` claim | Policy |
|---|---|---|
| Dealer staff | `DEALER_STAFF` | `StaffOnly` |
| SaaS admin | `SAAS_ADMIN` | `SuperAdminOnly` |
| Customer | `CUSTOMER` | `CustomerOnly` |

Additional claims: `sub`, `tenant_id`, `branch_id`, `role`, `roles`, `name`, `email`, `phone`, `exp` (8 hours).

**Branch scoping rule**

- A staff token that carries `branch_id` is always constrained to that branch. Requested `branchId` filters are ignored when they differ.
- A SaaS super-admin token may query across branches and pass an explicit `branchId`.
- Tenant isolation is enforced by EF Core global query filters combined with the `tenant_id` claim.

Demo staff (password `Demo@123`, dealer code `ALAGENDRA`):

| Username | Name | Roles |
|---|---|---|
| `manager.priya` | Priya Menon | BranchManager, SalesManager |
| `advisor.kiran` | Kiran Shetty | SalesExecutive, ServiceAdvisor |
| `sales.arjun` | Arjun Kumar | SalesExecutive |

Seed with `docs/demo-data/PHASE_9_DEMO_SEED.sql` after the Phase 8 seed.

---

## 2. Endpoint Summary

### 2.1 Branch CRM — `/staff/sales`

| # | Method | Endpoint | Purpose |
|---|---|---|---|
| 1 | GET | `/staff/sales/leads` | Paged pipeline with stage, owner, due and search filters |
| 2 | GET | `/staff/sales/leads/{enquiryId}` | Lead detail with follow-ups, test rides and quotations |
| 3 | POST | `/staff/sales/leads` | Capture a lead; auto-assign branch and sales executive |
| 4 | PUT | `/staff/sales/leads/{enquiryId}/assign` | Assign or reassign the lead owner |
| 5 | PUT | `/staff/sales/leads/{enquiryId}/status` | Transition the pipeline stage |
| 6 | POST | `/staff/sales/leads/{enquiryId}/follow-ups` | Record a follow-up and schedule the next contact |
| 7 | GET | `/staff/sales/dashboard` | Branch CRM counts and pipeline snapshot |
| 8 | GET | `/staff/sales/sales-executives` | Assignable sales staff and open-lead counts |
| 9 | GET | `/staff/sales/test-rides` | Test-ride work queue |
| 10 | POST | `/staff/sales/test-rides/{testRideId}/complete` | Complete after licence verification |
| 11 | POST | `/staff/sales/test-rides/{testRideId}/cancel` | Cancel with a mandatory reason |
| 12 | POST | `/staff/sales/test-rides/{testRideId}/no-show` | Mark the customer as a no-show |

### 2.2 Quotations — `/quotations`

| # | Method | Endpoint | Purpose |
|---|---|---|---|
| 13 | POST | `/quotations/preview` | Non-persisted on-road calculation |
| 14 | POST | `/quotations` | Persist a numbered, time-bound quotation |
| 15 | GET | `/quotations` | Paged quotation register |
| 16 | GET | `/quotations/{quotationId}` | Single quotation with full breakdown |
| 17 | POST | `/quotations/{quotationId}/expire` | Manually expire an active quotation |

---

## 3. Pipeline Model

### 3.1 Lead stages

| Stage | Integer | Meaning |
|---|---|---|
| `NEW` | 0 | Captured, not yet contacted |
| `CONTACTED` | 1 | Two-way contact established |
| `TESTRIDE` | 2 | Test ride scheduled or completed |
| `QUOTED` | 3 | A quotation has been shared |
| `BOOKED` | 4 | Converted; terminal until lost |
| `LOST` | 5 | Closed as lost; reopenable |

### 3.2 Allowed transitions

| From | Allowed to |
|---|---|
| `NEW` | `CONTACTED`, `TESTRIDE`, `QUOTED`, `BOOKED`, `LOST` |
| `CONTACTED` | `TESTRIDE`, `QUOTED`, `BOOKED`, `LOST` |
| `TESTRIDE` | `CONTACTED`, `QUOTED`, `BOOKED`, `LOST` |
| `QUOTED` | `TESTRIDE`, `BOOKED`, `LOST` |
| `BOOKED` | `LOST` |
| `LOST` | `NEW`, `CONTACTED` |

Any other transition returns `400` with the message `A lead cannot move from X to Y.` Marking a lead `LOST` requires a non-empty `lostReason`.

### 3.3 Follow-up outcomes

Recording a follow-up can advance the stage automatically:

| Outcome | Implied stage |
|---|---|
| `CONTACTED` | none |
| `NOTREACHABLE` | none |
| `INTERESTED` | `CONTACTED` |
| `NOTINTERESTED` | `LOST` |
| `TESTRIDEBOOKED` | `TESTRIDE` |
| `QUOTATIONSHARED` | `QUOTED` |
| `CONVERTED` | `BOOKED` |
| `LOST` | `LOST` |

Implicit moves are only applied when the transition is legal. `CONVERTED`, `LOST` and `NOTINTERESTED` clear the next follow-up. `CONVERTED` also converts active quotations; `LOST` expires them.

---

## 4. Lead Endpoints

### 4.1 List the pipeline — `GET /staff/sales/leads`

Query parameters:

| Parameter | Type | Notes |
|---|---|---|
| `branchId` | guid | Ignored for branch-scoped staff |
| `status` | string | Comma-separated stages, e.g. `NEW,CONTACTED` |
| `assignedToUserId` | guid | Filter by lead owner |
| `search` | string | Customer name/phone, variant or model |
| `followUpDue` | bool | `true` = due now; `false` = not due |
| `page` | int | Default `1` |
| `pageSize` | int | Default `25`, capped at `100` |

Response `data`:

```json
{
  "items": [
    {
      "id": "a9000001-0000-0000-0000-000000000001",
      "customerId": "88888888-8888-8888-8888-888888888888",
      "customerName": "Asha Rao",
      "phone": "9876543210",
      "email": "asha.rao@example.com",
      "branchId": "22222222-2222-2222-2222-222222222222",
      "branchName": "Indiranagar Showroom",
      "variantId": "55555555-5555-5555-5555-555555555555",
      "variantName": "R15 V4 Standard",
      "modelName": "R15 V4",
      "colorId": "66666666-6666-6666-6666-666666666666",
      "colorName": "Racing Blue",
      "status": "NEW",
      "source": "WALKIN",
      "lostReason": null,
      "expectedPurchaseDate": "2026-12-03T00:00:00Z",
      "createdAt": "2026-11-09T12:00:00Z",
      "assignedSalesExecutiveId": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
      "assignedSalesExecutiveName": "Kiran Shetty",
      "lastContactedAt": "2026-11-10T12:00:00Z",
      "nextFollowUpAt": "2026-11-12T12:00:00Z",
      "followUpDue": true,
      "followUpCount": 1,
      "upcomingTestRideAt": null,
      "latestQuotationNumber": null,
      "latestQuotationOnRoadPrice": null
    }
  ],
  "page": 1,
  "pageSize": 25,
  "totalCount": 1
}
```

`meta` mirrors `page`, `pageSize` and `totalCount`. `followUpDue` is `true` only for open leads whose `nextFollowUpAt` is at or before now.

### 4.2 Lead detail — `GET /staff/sales/leads/{enquiryId}`

Returns the summary fields above plus `notes`, `followUps[]`, `testRides[]` and `quotations[]`, newest first.

### 4.3 Capture a lead — `POST /staff/sales/leads`

```json
{
  "branchId": null,
  "variantId": "55555555-5555-5555-5555-555555555555",
  "colorId": "66666666-6666-6666-6666-666666666666",
  "firstName": "Rahul",
  "lastName": "Nair",
  "phone": "9700000002",
  "email": "rahul.nair@example.com",
  "city": "Bengaluru",
  "source": "WalkIn",
  "notes": "Wants an exchange quote for a 2019 FZ.",
  "expectedPurchaseDate": "2026-11-28T00:00:00Z",
  "assignedSalesExecutiveId": null
}
```

Validation:

- `firstName`, `phone` and `variantId` are required; `phone` must match `^[0-9+\-\s()]{6,20}$`.
- `source` must be `WalkIn`, `MobileApp`, `Web` or `Phone`.
- `expectedPurchaseDate` cannot be in the past.

Assignment behaviour:

1. An explicit `assignedSalesExecutiveId` must be an active `DEALER_STAFF` user holding a sales role in the same branch, otherwise `400`.
2. Otherwise the lead is auto-assigned by `SalesAssignmentRules`: `SalesExecutive` first, then `SalesManager`, then `BranchManager`, and least open leads within the winning role.
3. If `branchId` is omitted, the branch is resolved from the staff token, then the customer's city, then the headquarters branch.

Response: `201` with the lead detail (`status = NEW`).

### 4.4 Assign — `PUT /staff/sales/leads/{enquiryId}/assign`

```json
{ "salesExecutiveId": "e1e1e1e1-e1e1-e1e1-e1e1-e1e1e1e1e1e1" }
```

The target must be a sales-role staff member in the lead's branch. Assigning to an open lead with no scheduled follow-up sets the next follow-up to `now + 1 day`.

### 4.5 Update stage — `PUT /staff/sales/leads/{enquiryId}/status`

```json
{ "status": "Contacted" }
```

or, to lose a lead:

```json
{ "status": "Lost", "lostReason": "Purchased a competitor motorcycle." }
```

`status` accepts any stage name case-insensitively. Illegal transitions and a missing lost reason return `400`. Moving to `BOOKED` converts active quotations and stamps `lastContactedAt`; `LOST` expires active quotations and clears the next follow-up.

### 4.6 Follow-up — `POST /staff/sales/leads/{enquiryId}/follow-ups`

```json
{
  "channel": "WhatsApp",
  "outcome": "Interested",
  "notes": "Wants an R15 in blue; comparing with the MT-15.",
  "contactedAt": "2026-11-13T10:15:00Z",
  "nextFollowUpAt": "2026-11-16T10:00:00Z"
}
```

- `channel`: `Phone`, `WhatsApp`, `Sms`, `Email`, `InPerson`.
- `outcome`: one of the eight outcomes in §3.3.
- `contactedAt` defaults to now and cannot be more than 5 minutes in the future.
- `nextFollowUpAt` must be in the future and at most 90 days ahead; it is ignored for final outcomes.

Response: `201` with the follow-up, including `performedByName`.

### 4.7 Dashboard — `GET /staff/sales/dashboard?branchId=`

```json
{
  "totalLeads": 15,
  "openLeads": 13,
  "newLeads": 6,
  "bookedLeads": 1,
  "lostLeads": 1,
  "dueFollowUps": 1,
  "overdueFollowUps": 1,
  "testRidesToday": 0,
  "scheduledTestRides": 2,
  "completedTestRides": 2,
  "activeQuotations": 1,
  "quotationsExpiringInSevenDays": 1,
  "conversionRate": 6.7,
  "generatedAt": "2026-11-13T18:30:00Z",
  "pipeline": [
    { "status": "NEW", "count": 6 },
    { "status": "CONTACTED", "count": 1 },
    { "status": "TESTRIDE", "count": 1 },
    { "status": "QUOTED", "count": 1 },
    { "status": "BOOKED", "count": 1 },
    { "status": "LOST", "count": 1 }
  ],
  "branches": [
    {
      "branchId": "22222222-2222-2222-2222-222222222222",
      "branchName": "Indiranagar Showroom",
      "openLeads": 13,
      "dueFollowUps": 1,
      "scheduledTestRides": 2,
      "activeQuotations": 1
    }
  ]
}
```

`conversionRate` = booked ÷ total × 100, rounded to one decimal.

### 4.8 Sales executives — `GET /staff/sales/sales-executives?branchId=`

Returns active `DEALER_STAFF` users holding `SalesExecutive`, `SalesManager` or `BranchManager`, with `roles[]` and `openLeads`.

---

## 5. Test-Ride Operations

### 5.1 Queue — `GET /staff/sales/test-rides`

Filters: `branchId`, `status` (`SCHEDULED`, `COMPLETED`, `CANCELLED`, `NOSHOW`), `from`, `to` (UTC ISO-8601). Ordered by `scheduledAt` ascending.

Each item: `id`, `enquiryId`, `customerId`, `customerName`, `phone`, `branchId`, `branchName`, `variantId`, `variantName`, `modelName`, `scheduledAt`, `completedAt`, `status`, `drivingLicenseNumber`, `feedbackNotes`, `assignedSalesExecutiveName`, `createdAt`.

### 5.2 Complete — `POST /staff/sales/test-rides/{testRideId}/complete`

```json
{
  "drivingLicenseVerified": true,
  "drivingLicenseNumber": "KA0120200000009",
  "feedbackNotes": "Licence verified. Customer liked the mid-range pull."
}
```

`drivingLicenseVerified` must be `true`. A licence number must be present from either the original booking or this request. Only a `SCHEDULED` ride can be completed. If the lead was in `TESTRIDE`, it returns to `CONTACTED` with a follow-up scheduled for `now + 1 day`.

### 5.3 Cancel — `POST /staff/sales/test-rides/{testRideId}/cancel`

```json
{ "reason": "Customer requested a different weekend." }
```

`reason` is required (max 500). Only a `SCHEDULED` ride can be cancelled.

### 5.4 No-show — `POST /staff/sales/test-rides/{testRideId}/no-show`

No body. Marks the ride `NOSHOW` and records a default note when none exists.

---

## 6. Dynamic Quotation Engine

### 6.1 Pricing formulas

Quotations reuse the deterministic state pricing in `BranchPricingCalculator` and apply branch overrides:

| Component | Formula |
|---|---|
| Ex-showroom | `variant.BasePrice` |
| RTO / road tax | `exShowroom × stateRtoPercent ÷ 100` |
| Insurance | `max(exShowroom × 3.5 ÷ 100, ₹1,500)` |
| Accessories | dealership input, ≥ 0 |
| Handling | input, default ₹2,500 |
| Subtotal | ex-showroom + RTO + insurance + accessories + handling |
| Discount | input, ≥ 0 and ≤ ex-showroom + accessories |
| **On-road total** | **subtotal − discount** |

State RTO rates: Karnataka 12%, Tamil Nadu 10%, Kerala 11%, Maharashtra 12%, Delhi 8%, Telangana 12%, Andhra Pradesh 12%, Gujarat 9%, Rajasthan 10%, Uttar Pradesh 10%; default 10%.

Warnings are advisory and do not block creation:

- Discount above 5% of ex-showroom → manager approval warning.
- Expired quotation → reissue warning on read.

Validity is clamped to 1–30 days; `0` means the default 7 days.

### 6.2 Preview — `POST /quotations/preview`

```json
{
  "enquiryId": "a9000002-0000-0000-0000-000000000002",
  "accessoriesCharges": 5000,
  "handlingCharges": 2500,
  "discountAmount": 3000,
  "validDays": 7
}
```

When `enquiryId` is supplied, customer, branch, variant and colour are inherited from the lead; any conflicting explicit value returns `400`. Otherwise a direct quotation requires `customerId` and `variantId`.

Response `data`:

```json
{
  "branchId": "22222222-2222-2222-2222-222222222222",
  "branchName": "Indiranagar Showroom",
  "enquiryId": "a9000002-0000-0000-0000-000000000002",
  "customerId": "a8000001-0000-0000-0000-000000000001",
  "customerName": "Rahul Nair",
  "phone": "+919812345678",
  "variantId": "55555555-5555-5555-5555-555555555555",
  "variantName": "R15 V4 Standard",
  "modelName": "R15 V4",
  "colorId": "66666666-6666-6666-6666-666666666666",
  "colorName": "Racing Blue",
  "exShowroomPrice": 182000,
  "rtoPercent": 12.0,
  "rtoCharges": 21840,
  "insurancePercent": 3.5,
  "insuranceCharges": 6370,
  "accessoriesCharges": 5000,
  "handlingCharges": 2500,
  "subtotal": 217710,
  "discountAmount": 3000,
  "totalOnRoadPrice": 214710,
  "validUntil": "2026-11-20T18:30:00Z",
  "warnings": []
}
```

### 6.3 Create — `POST /quotations`

Same body as preview, plus optional `notes` (max 1000). The service:

1. Recalculates the breakdown server-side (client totals are never trusted).
2. Generates `QTN-{BRANCHCODE}-{yyyyMMdd}-{seq:D4}`, e.g. `QTN-BLRIND-20261113-0001`.
3. Persists `status = ACTIVE` with `validUntil`.
4. Advances an attached lead to `QUOTED` when legal, stamps `lastContactedAt`, and schedules a follow-up for `now + 2 days` while the lead is open.

Response: `201` with the persisted quotation (`QuotationDto`), including `id`, `quotationNumber`, `status`, `isExpired`, `notes`, `createdByUserId`, `createdAt`, `updatedAt`.

### 6.4 Register — `GET /quotations`

Filters: `branchId`, `status` (comma-separated `ACTIVE`, `CONVERTED`, `EXPIRED`), `enquiryId`, `customerId`, `search`, `includeExpired` (default `true`), `page`, `pageSize`.

Listing first expires lapsed active quotations in the tenant so status filters stay truthful.

### 6.5 Detail — `GET /quotations/{quotationId}`

Returns the full `QuotationDto`. Reading an active quotation that has passed `validUntil` marks it `EXPIRED` before responding.

### 6.6 Expire — `POST /quotations/{quotationId}/expire`

Only an `ACTIVE` quotation can be expired; any other status returns `400`. Returns the updated quotation.

---

## 7. Error Model

| Status | Cause |
|---|---|
| `400` | Validation failure, illegal stage transition, invalid pricing input, missing licence or lost reason |
| `401` | Missing/expired token, or a branch-scope violation |
| `404` | Lead, test ride or quotation not found in the caller's tenant |
| `403` | Staff token without a sales role (policy-level) |

Validation failures populate `errors[]` with `{ field, message }`.

---

## 8. Verified Evidence

`docs/testing/PHASE_9_E2E.sh` exercises 62 assertions against a running API and seeded database:

- Staff login for a manager and a sales executive, including the canonical `DEALER_STAFF` claim.
- `401` on the dashboard without a token.
- Dashboard, pipeline filtering and sales-executive listing.
- Lead capture with auto branch + executive assignment, lead detail, reassignment, explicit stage update and follow-up recording (with implicit stage advance).
- Quotation preview and create with the exact seeded breakdown (`182000 + 21840 + 6370 + 5000 + 2500 − 3000 = 214710`), read-back, list filter and manual expiry.
- Test-ride scheduling through the customer API, queue visibility, rejected completion without licence verification, successful completion, and cancellation.
- Rejection of an illegal `CONTACTED → NEW` transition.

Unit coverage: pipeline rules, assignment ranking, quotation math, staff/quotation validators, both controllers, and `UserTypeClaims` — 171 backend tests passing.
