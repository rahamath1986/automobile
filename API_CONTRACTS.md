# API Contracts & Conventions: MotoSaaS Platform

This document details the RESTful API design standards, envelope formatting, authentication scheme, error handling, and core endpoint specifications for the MotoSaaS platform.

---

## 1. Global API Standards & Conventions

1. **Base URL:** `/api/v1/{module}`
2. **Data Format:** JSON (`application/json`) with `snake_case` or standard `camelCase` (standardized to `camelCase` for JSON payloads and `snake_case` in DB).
3. **Temporal Values:** ISO-8601 UTC format (`YYYY-MM-DDTHH:mm:ss.sssZ`).
4. **Authentication:**
   - Staff Requests: `Authorization: Bearer <staff_jwt_token>`
   - Customer Requests: `Authorization: Bearer <customer_jwt_token>`
   - Public White-Label Endpoints: `X-Dealer-Code: <dealer_code>` or subdomain header
5. **Idempotency:** Mutating financial or stock transactions accept `Idempotency-Key: <uuid>`.

---

## 2. Standard Response Envelopes

### Success Response Envelope
```json
{
  "success": true,
  "statusCode": 200,
  "message": "Operation completed successfully.",
  "data": { ... },
  "meta": {
    "page": 1,
    "pageSize": 20,
    "totalCount": 142,
    "totalPages": 8
  },
  "timestamp": "2026-11-13T14:30:00.000Z"
}
```

### Error Response Envelope
```json
{
  "success": false,
  "statusCode": 400,
  "errorCode": "INSUFFICIENT_STOCK_FOR_ALLOCATION",
  "message": "No available vehicle chassis matches the selected variant and color in this branch.",
  "errors": [
    {
      "field": "variantId",
      "message": "Requested variant has zero available units in branch MDU-CTR."
    }
  ],
  "timestamp": "2026-11-13T14:30:00.000Z"
}
```

---

## 2b. Universal EMI Calculator Contract (Bank-Agnostic)

### Request Payload (`POST /api/v1/finance/calculate-emi`)
```json
{
  "vehiclePrice": 195000.00,
  "downPayment": 35000.00,
  "annualInterestRatePercent": 10.50,
  "tenureMonths": 36,
  "calculationMethod": "REDUCING_BALANCE"
}
```
*Note: `calculationMethod` supports `REDUCING_BALANCE` (standard banking amortization) or `FLAT_RATE` (fixed annual interest on initial principal).*

### Response Payload
```json
{
  "success": true,
  "statusCode": 200,
  "message": "EMI calculation completed successfully.",
  "data": {
    "vehiclePrice": 195000.00,
    "downPayment": 35000.00,
    "loanPrincipal": 160000.00,
    "annualInterestRatePercent": 10.50,
    "tenureMonths": 36,
    "calculationMethod": "REDUCING_BALANCE",
    "monthlyEmi": 5200.74,
    "totalInterestPayable": 27226.64,
    "totalRepaymentAmount": 187226.64,
    "amortizationSchedule": [
      {
        "month": 1,
        "openingBalance": 160000.00,
        "emiAmount": 5200.74,
        "principalPaid": 3800.74,
        "interestPaid": 1400.00,
        "closingBalance": 156199.26
      },
      {
        "month": 2,
        "openingBalance": 156199.26,
        "emiAmount": 5200.74,
        "principalPaid": 3833.99,
        "interestPaid": 1366.75,
        "closingBalance": 152365.27
      }
    ]
  },
  "timestamp": "2026-11-13T14:35:00.000Z"
}
```

---

## 3. Core API Endpoint Catalog

### A. Authentication & Identity (`/api/v1/auth`)

| Method | Endpoint | Access | Description |
|---|---|---|---|
| `POST` | `/api/v1/auth/customer/request-otp` | Public | Send login OTP to customer mobile number |
| `POST` | `/api/v1/auth/customer/verify-otp` | Public | Verify OTP and return customer JWT & refresh token |
| `POST` | `/api/v1/auth/staff/login` | Public | Authenticate dealer staff (DealerCode + User + Pass) |
| `POST` | `/api/v1/auth/refresh-token` | Authenticated | Rotate expired JWT using valid refresh token |
| `POST` | `/api/v1/auth/logout` | Authenticated | Revoke refresh token and invalidate session |

### B. Vehicle Catalogue & 3D Assets (`/api/v1/catalog`)

| Method | Endpoint | Access | Description |
|---|---|---|---|
| `GET` | `/api/v1/catalog/manufacturers` | Public / Customer | List active manufacturers |
| `GET` | `/api/v1/catalog/models` | Public / Customer | List vehicle models with filtering (category, fuel, brand) |
| `GET` | `/api/v1/catalog/models/{id}` | Public / Customer | Get complete model details, specs, variants, and colors |
| `GET` | `/api/v1/catalog/variants/{id}/3d-asset` | Public / Customer | Get GLB 3D model metadata, camera presets, and texture URLs |
| `GET` | `/api/v1/catalog/variants/{variantId}/pricing` | Public / Customer | Indicative on-road price for a branch (`branchId` query) with stock count and disclaimer |
| `GET` | `/api/v1/showroom/variants/{variantId}` | Public / Customer | 3-tier showroom manifest (GLB, 360 frames, gallery), colours, camera presets, hotspots |

### C. Inventory & Allocation (`/api/v1/inventory`)

| Method | Endpoint | Access | Description |
|---|---|---|---|
| `GET` | `/api/v1/inventory` | Staff (Sales, Manager) | List branch stock with status, variant, and color filters |
| `GET` | `/api/v1/inventory/{id}` | Staff (Sales, Manager) | Get vehicle chassis history and movement audit log |
| `POST` | `/api/v1/inventory/receive` | Staff (Manager, Inventory) | Register stock receipt with chassis and engine numbers |
| `POST` | `/api/v1/inventory/allocate` | Staff (Sales, Manager) | Atomically allocate chassis unit to a confirmed booking |
| `POST` | `/api/v1/inventory/transfer` | Staff (Manager) | Initiate inter-branch stock transfer |

### D. Sales & CRM Pipeline (`/api/v1/sales`, `/api/v1/staff/sales`, `/api/v1/quotations`)

| Method | Endpoint | Access | Description |
|---|---|---|---|
| `POST` | `/api/v1/sales/enquiries` | Public / Customer | Create a vehicle enquiry; guests must send `X-Dealer-Code` and contact details |
| `GET` | `/api/v1/sales/enquiries/mine` | Customer | List the signed-in customer's enquiries and CRM stage |
| `POST` | `/api/v1/sales/test-rides` | Public / Customer | Request a test ride; guest body includes name + phone |
| `GET` | `/api/v1/sales/test-rides/mine` | Customer | List the signed-in customer's test-ride requests |
| `GET` | `/api/v1/staff/sales/leads` | Staff | Paged branch pipeline with stage, owner, due and search filters |
| `GET` | `/api/v1/staff/sales/leads/{id}` | Staff | Lead detail with follow-ups, test rides and quotations |
| `POST` | `/api/v1/staff/sales/leads` | Staff | Capture a lead and auto-assign branch + sales executive |
| `PUT` | `/api/v1/staff/sales/leads/{id}/assign` | Staff | Assign or reassign the lead owner |
| `PUT` | `/api/v1/staff/sales/leads/{id}/status` | Staff | Guarded pipeline stage transition |
| `POST` | `/api/v1/staff/sales/leads/{id}/follow-ups` | Staff | Record a follow-up and schedule the next contact |
| `GET` | `/api/v1/staff/sales/dashboard` | Staff | CRM counters, conversion rate, pipeline and branch snapshot |
| `GET` | `/api/v1/staff/sales/sales-executives` | Staff | Assignable sales staff with open-lead counts |
| `GET` | `/api/v1/staff/sales/test-rides` | Staff | Test-ride work queue with status/date filters |
| `POST` | `/api/v1/staff/sales/test-rides/{id}/complete` | Staff | Complete a test ride after licence verification |
| `POST` | `/api/v1/staff/sales/test-rides/{id}/cancel` | Staff | Cancel a scheduled test ride with a reason |
| `POST` | `/api/v1/staff/sales/test-rides/{id}/no-show` | Staff | Mark the customer as a no-show |
| `POST` | `/api/v1/quotations/preview` | Staff | Non-persisted on-road calculation (RTO, insurance, accessories, handling, discount) |
| `POST` | `/api/v1/quotations` | Staff | Create a numbered, time-bound quotation |
| `GET` | `/api/v1/quotations` | Staff | Paged quotation register |
| `GET` | `/api/v1/quotations/{id}` | Staff | Quotation with full price breakdown |
| `POST` | `/api/v1/quotations/{id}/expire` | Staff | Manually expire an active quotation |

### E. Billing & Payments (`/api/v1/billing`)

| Method | Endpoint | Access | Description |
|---|---|---|---|
| `POST` | `/api/v1/billing/payments` | Staff (Cashier, Manager) | Record payment collection (Cash/UPI/Card/Financier) |
| `GET` | `/api/v1/billing/invoices/{id}` | Staff / Customer | Retrieve vehicle sales or service invoice |
| `POST` | `/api/v1/billing/invoices/generate` | Staff (Cashier) | Generate official sales invoice upon full payment |

### E2. Finance & EMI Calculator Engine (`/api/v1/finance`)

| Method | Endpoint | Access | Description |
|---|---|---|---|
| `POST` | `/api/v1/finance/calculate-emi` | Public / Customer / Staff | Universal bank-agnostic mathematical EMI calculator (Reducing/Flat rate) with amortization schedule |
| `GET` | `/api/v1/finance/schemes` | Public / Customer / Staff | List tenant's active partner financier schemes (TVS Credit, HDFC, L&T, etc.) |
| `POST` | `/api/v1/finance/applications` | Customer / Staff (Sales) | Submit finance application linked to booking |
| `GET` | `/api/v1/finance/applications/{id}` | Customer / Staff | Track finance application approval and disbursement status |
| `PUT` | `/api/v1/finance/applications/{id}/status` | Staff (Manager, Cashier) | Update finance status (Approved, Disbursed, Loan A/C No) |

### F. Service Operations & Job Cards (`/api/v1/service`)

| Method | Endpoint | Access | Description |
|---|---|---|---|
| `POST` | `/api/v1/service/bookings` | Customer / Staff | Schedule vehicle maintenance appointment |
| `GET` | `/api/v1/service/bookings` | Staff (Service Advisor) | List service appointments for branch |
| `POST` | `/api/v1/service/job-cards` | Staff (Service Advisor) | Check-in vehicle and generate digital job card |
| `PUT` | `/api/v1/service/job-cards/{id}/estimate` | Staff (Advisor) | Add labour and spare parts estimate |
| `PUT` | `/api/v1/service/job-cards/{id}/approve` | Customer / Staff | Approve service estimate |
| `PUT` | `/api/v1/service/job-cards/{id}/assign` | Staff (Advisor, Manager) | Assign job card to service technician |
| `PUT` | `/api/v1/service/job-cards/{id}/progress` | Staff (Technician) | Update inspection checklist and repair progress |
| `PUT` | `/api/v1/service/job-cards/{id}/qc` | Staff (Advisor, Manager) | Mark quality check passed and vehicle ready for delivery |
| `GET` | `/api/v1/service/my-vehicles` | Customer | List the signed-in customer's owned vehicles with masked chassis/engine numbers |
| `GET` | `/api/v1/service/bookings/mine` | Customer | List the customer's appointments and live job card status |
| `GET` | `/api/v1/service/bookings/{bookingId}/tracking` | Customer | Service timeline, progress percent, job card items, and approval flag |
| `PUT` | `/api/v1/service/job-cards/{jobCardId}/approve` | Customer | Approve an estimated job card (idempotent) |

### G. Customer Profile (`/api/v1/customers`)

| Method | Endpoint | Access | Description |
|---|---|---|---|
| `GET` | `/api/v1/customers/me` | Customer | Profile summary with owned-vehicle and booking counts |
| `PUT` | `/api/v1/customers/me` | Customer | Update contact and address fields (name, email, address, city, state, PIN) |


---

## 4. Phase 8 Customer App Contracts

### 4.1 Guest tenant resolution

Anonymous requests may identify the dealership with:

```
X-Dealer-Code: ALAGENDRA
```

When the header is absent, the API falls back to the pilot tenant `ALAGENDRA`. Authenticated requests resolve the tenant from the `tenant_id` JWT claim instead; the header is ignored.

### 4.2 Guest enquiry

`POST /api/v1/sales/enquiries`

```json
{
  "branchId": "22222222-2222-2222-2222-222222222222",
  "variantId": "55555555-5555-5555-5555-555555555555",
  "colorId": "66666666-6666-6666-6666-666666666666",
  "notes": "Interested in a weekend test ride",
  "expectedPurchaseDate": "2026-12-01T00:00:00Z",
  "firstName": "Guest",
  "lastName": "Rider",
  "phone": "9123456780",
  "email": "guest@example.com"
}
```

* `firstName` and `phone` are required only when no customer bearer token is supplied.
* Response: `201` with `EnquiryDto` (`status = NEW`, `source = MOBILEAPP`).

### 4.3 Guest test ride

`POST /api/v1/sales/test-rides`

```json
{
  "branchId": "22222222-2222-2222-2222-222222222222",
  "variantId": "55555555-5555-5555-5555-555555555555",
  "scheduledAt": "2026-11-16T10:00:00Z",
  "drivingLicenseNumber": "KA0120200000001",
  "firstName": "Guest",
  "lastName": "Rider",
  "phone": "9123456781"
}
```

* `scheduledAt` must be in the future.
* Response: `201` with `TestRideDto` (`status = SCHEDULED`).

### 4.4 Branch pricing

`GET /api/v1/catalog/variants/{variantId}/pricing?branchId={branchId}`

```json
{
  "variantId": "55555555-5555-5555-5555-555555555555",
  "variantName": "R15 V4 Standard",
  "modelName": "R15 V4",
  "branchId": "22222222-2222-2222-2222-222222222222",
  "branchName": "Indiranagar Showroom",
  "state": "Karnataka",
  "exShowroomPrice": 182000,
  "rtoPercent": 12.0,
  "rtoCharges": 21840,
  "insurancePercent": 3.5,
  "insuranceCharges": 6370,
  "handlingCharges": 2500,
  "estimatedOnRoadPrice": 212710,
  "availableUnits": 2,
  "inStock": true,
  "priceBasis": "INDICATIVE_ON_ROAD_ESTIMATE",
  "disclaimer": "Indicative on-road estimate for Indiranagar Showroom. ..."
}
```

The estimate is non-binding; Phase 9 quotations are the authoritative commercial document.

### 4.5 Customer profile

`GET /api/v1/customers/me` → `200` `CustomerProfileDto` with contact details plus `vehicleCount` and `bookingCount`.

`PUT /api/v1/customers/me` accepts any subset of:

```json
{
  "firstName": "Asha",
  "lastName": "Rao",
  "email": "asha.rao@example.com",
  "addressLine1": "42, 12th Main, Indiranagar",
  "city": "Bengaluru",
  "state": "Karnataka",
  "postalCode": "560038"
}
```

### 4.6 Service tracking

`GET /api/v1/service/bookings/{bookingId}/tracking`

```json
{
  "booking": { "id": "cccccccc-cccc-cccc-cccc-cccccccccccc", "status": "BOOKED", "jobCardStatus": "ESTIMATED" },
  "jobCard": {
    "id": "dddddddd-dddd-dddd-dddd-dddddddddddd",
    "jobCardNumber": "JC-2026-0001",
    "status": "ESTIMATED",
    "estimatedCost": 2460,
    "customerApproved": false,
    "technicianName": "Suresh Rao",
    "items": [
      { "itemType": "LABOUR", "description": "Periodic service labour", "totalPrice": 900, "isApproved": false }
    ]
  },
  "currentStage": "ESTIMATE_AWAITING_APPROVAL",
  "progressPercent": 25,
  "awaitingCustomerApproval": true,
  "timeline": [
    { "label": "Booked", "completed": true, "current": false },
    { "label": "Estimate approval", "completed": false, "current": true }
  ]
}
```

`PUT /api/v1/service/job-cards/{jobCardId}/approve` is idempotent: the first call flips the job card to `APPROVED` and marks all items approved; later calls return the current tracking payload without error.

For full Phase 8 request/response evidence, see `docs/api/PHASE_8_CUSTOMER_APP.md`.

---

## 5. Phase 9 Sales & CRM Contracts

All Phase 9 endpoints require a staff bearer token (`StaffOnly`). A token carrying `branch_id` is always constrained to that branch; a super-admin token may pass an explicit `branchId` or omit it to span branches.

### 5.1 Lead capture, assignment and pipeline

```json
POST /api/v1/staff/sales/leads
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
  "notes": "Wants an exchange quote.",
  "expectedPurchaseDate": "2026-11-28T00:00:00Z"
}
```

* Branch resolution order: explicit `branchId` → staff `branch_id` claim → customer city → headquarters branch.
* Auto-assignment ranks `SalesExecutive` → `SalesManager` → `BranchManager`, then least open leads.
* Response: `201` with `LeadDetailDto` (`status = NEW`).

```json
PUT /api/v1/staff/sales/leads/{id}/status
{ "status": "Lost", "lostReason": "Purchased a competitor motorcycle." }
```

* Allowed transitions and follow-up outcome mapping are defined in `SalesPipelineRules` and listed in `docs/api/PHASE_9_SALES_CRM.md` §3.
* Illegal transitions and a missing lost reason return `400`.

```json
POST /api/v1/staff/sales/leads/{id}/follow-ups
{
  "channel": "WhatsApp",
  "outcome": "Interested",
  "notes": "Wants an R15 in blue.",
  "nextFollowUpAt": "2026-11-16T10:00:00Z"
}
```

* `outcome ∈ {Contacted, NotReachable, Interested, NotInterested, TestRideBooked, QuotationShared, Converted, Lost}`.
* Final outcomes clear the next follow-up; `nextFollowUpAt` must be future and ≤ 90 days ahead.

### 5.2 Test-ride operations

```json
POST /api/v1/staff/sales/test-rides/{id}/complete
{
  "drivingLicenseVerified": true,
  "drivingLicenseNumber": "KA0120200000009",
  "feedbackNotes": "Licence verified."
}
```

* `drivingLicenseVerified` must be `true`; a licence number must exist from the booking or the request.
* Only `SCHEDULED` rides can be completed, cancelled or marked no-show.
* `POST /test-rides/{id}/cancel` requires `{ "reason": "..." }`.

### 5.3 Quotation engine

```json
POST /api/v1/quotations
{
  "enquiryId": "a9000002-0000-0000-0000-000000000002",
  "accessoriesCharges": 5000,
  "handlingCharges": 2500,
  "discountAmount": 3000,
  "validDays": 7,
  "notes": "Includes touring accessory pack."
}
```

Pricing rules:

| Component | Rule |
|---|---|
| Ex-showroom | `variant.BasePrice` |
| RTO / road tax | state rate (Karnataka 12%, default 10%) × ex-showroom |
| Insurance | 3.5% × ex-showroom, minimum ₹1,500 |
| Handling | input, default ₹2,500 |
| Discount | ≥ 0 and ≤ ex-showroom + accessories |
| Total on-road | ex-showroom + RTO + insurance + accessories + handling − discount |

* Validity clamps to 1–30 days (`0` → 7).
* Numbering: `QTN-{BRANCHCODE}-{yyyyMMdd}-{seq:D4}`.
* Creating a quotation advances the lead to `QUOTED` (when legal) and schedules a follow-up for `now + 2 days`.
* Status lifecycle: `ACTIVE` → `CONVERTED` (lead booked) or `EXPIRED` (validity lapse / manual / lead lost).

For full Phase 9 request/response evidence, see `docs/api/PHASE_9_SALES_CRM.md`.
