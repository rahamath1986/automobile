# Phase 8 — Customer App API Contracts

**Scope:** Customer-facing endpoints consumed by `mobile/customer_app`, including guest discovery, branch pricing, leads, OTP authentication, profile, garage, service booking, and service tracking.

- **Base URL:** `http://localhost:5053/api/v1`
- **Envelope:** standard `ApiResponse<T>` (`success`, `statusCode`, `message`, `data`, `meta`, `errors`, `timestamp`)
- **Content type:** `application/json`
- **Time format:** UTC ISO-8601 (`2026-11-16T10:00:00Z`)

---

## 1. Authentication & Tenant Resolution

| Caller | Tenant source | Authorization |
|---|---|---|
| Guest | `X-Dealer-Code: ALAGENDRA` header; fallback `ALAGENDRA` | none |
| Customer | `tenant_id` JWT claim | `Authorization: Bearer <token>` with policy `CustomerOnly` |
| Staff | `tenant_id` / `branch_id` JWT claims | staff policies (not used by this app) |

Customer JWTs are issued by `POST /auth/customer/verify-otp` and carry: `sub` (customer id), `tenant_id`, `user_type = CUSTOMER`, `role = Customer`, `phone`, `email`, `name`, `exp` (15 minutes).

Demo login: phone `9876543210`, OTP `123456`. Phones ending `43210` and `9999999999` also receive the fixed demo OTP.

---

## 2. Endpoint Summary

| # | Method | Endpoint | Access | Purpose |
|---|---|---|---|---|
| 1 | GET | `/branding/current` | Guest | White-label trade name, colours, associated manufacturers |
| 2 | GET | `/catalog/models` | Guest | Catalog list (`category`, `manufacturerId`, `fuelType` filters) |
| 3 | GET | `/catalog/models/{id}` | Guest | Model detail with variants, colours, specs, 3D assets |
| 4 | GET | `/catalog/variants/{variantId}/pricing?branchId=` | Guest | Indicative on-road price and branch stock |
| 5 | GET | `/showroom/variants/{variantId}?colorId=` | Guest | 3-tier showroom manifest, camera presets, hotspots |
| 6 | POST | `/sales/enquiries` | Guest / Customer | Create enquiry |
| 7 | GET | `/sales/enquiries/mine` | Customer | Enquiry history |
| 8 | POST | `/sales/test-rides` | Guest / Customer | Request test ride |
| 9 | GET | `/sales/test-rides/mine` | Customer | Test-ride history |
| 10 | POST | `/auth/customer/request-otp` | Guest | Send OTP (`dealerCode` in body) |
| 11 | POST | `/auth/customer/verify-otp` | Guest | Verify OTP, receive JWT |
| 12 | GET | `/customers/me` | Customer | Profile summary |
| 13 | PUT | `/customers/me` | Customer | Update profile |
| 14 | GET | `/service/my-vehicles` | Customer | Garage / owned vehicles |
| 15 | GET | `/service/bookings/mine` | Customer | Service appointments |
| 16 | POST | `/service/bookings` | Customer | Book service |
| 17 | GET | `/service/bookings/{bookingId}/tracking` | Customer | Timeline, job card, estimate |
| 18 | PUT | `/service/job-cards/{jobCardId}/approve` | Customer | Approve estimate (idempotent) |

Full example payloads and validation rules are below; the authoritative endpoint catalog is also in `API_CONTRACTS.md` §3–§4.

---

## 3. Discovery & Pricing

### 3.1 Catalog list — `GET /catalog/models`

Query parameters: `category` (`MOTORCYCLE`, `SCOOTER`, `ELECTRIC_SCOOTER`, `ELECTRIC_MOTORCYCLE`), `manufacturerId`, `fuelType` (`PETROL`, `ELECTRIC`, `HYBRID`).

Response `data[]` fields: `id`, `manufacturerId`, `manufacturerName`, `manufacturerCode`, `code`, `name`, `category`, `fuelType`, `displacementCc`, `batteryCapacityKwh`, `startingPrice`, `variantCount`, `colorCount`, `heroImageUrl`, `has3DAsset`.

If the tenant has no associated OEM or no models, a demo Yamaha fallback catalog is returned so the app remains browsable before Phase 16 seeding.

### 3.2 Model detail — `GET /catalog/models/{id}`

Response `data`:

```json
{
  "id": "44444444-4444-4444-4444-444444444444",
  "manufacturerName": "Yamaha Motor India",
  "name": "R15 V4",
  "category": "MOTORCYCLE",
  "fuelType": "PETROL",
  "displacementCc": 155,
  "variants": [
    {
      "id": "55555555-5555-5555-5555-555555555555",
      "code": "R15V4-STD",
      "name": "R15 V4 Standard",
      "basePrice": 182000,
      "specificationsJson": "{\"displacementCc\":155,\"powerPs\":18.4,...}",
      "featuresJson": "{\"features\":[\"Dual-channel ABS\", ...]}",
      "colors": [
        { "id": "66666666-6666-6666-6666-666666666666", "colorName": "Racing Blue", "hexCode": "#0031AD", "isPrimary": true, "imageUrl": "https://..." }
      ],
      "has3DAsset": true
    }
  ]
}
```

`specificationsJson` / `featuresJson` are JSON strings; the Flutter entity decodes them into typed maps/lists and tolerates malformed payloads.

### 3.3 Branch pricing — `GET /catalog/variants/{variantId}/pricing?branchId={guid}`

```json
{
  "variantId": "55555555-5555-5555-5555-555555555555",
  "variantCode": "R15V4-STD",
  "variantName": "R15 V4 Standard",
  "modelName": "R15 V4",
  "branchId": "22222222-2222-2222-2222-222222222222",
  "branchCode": "BLR-IND",
  "branchName": "Indiranagar Showroom",
  "state": "Karnataka",
  "exShowroomPrice": 182000,
  "rtoPercent": 12.0,
  "rtoCharges": 21840,
  "insurancePercent": 3.5,
  "insuranceCharges": 6370,
  "accessoriesCharges": 0,
  "handlingCharges": 2500,
  "estimatedOnRoadPrice": 212710,
  "availableUnits": 2,
  "inStock": true,
  "priceBasis": "INDICATIVE_ON_ROAD_ESTIMATE",
  "disclaimer": "Indicative on-road estimate for Indiranagar Showroom. RTO and insurance are estimates; the final quotation is issued by the dealership."
}
```

Rules:

- RTO percentage is derived from the branch **state** (Karnataka 12%, Maharashtra 11%, Tamil Nadu 10%, Delhi 8%, default 10%); `rtoCharges = exShowroom × rtoPercent / 100`.
- Insurance defaults to 3.5%; handling defaults to ₹2,500 (branch override supported by the calculator).
- `availableUnits` counts `InventoryItems` with `Status = Available` for the variant **and** branch.
- Branch must belong to the current tenant and be active; otherwise `404`/`400`.
- This endpoint is an estimate only. Binding quotations are Phase 9 documents.

### 3.4 Showroom manifest — `GET /showroom/variants/{variantId}?colorId=`

Response `data` includes `activeTier` (`0` = interactive 3D, `1` = 360 turntable, `2` = static gallery), `glbFileUrl`, `usdzFileUrl`, `modelFileSizeBytes`, `hasDracoCompression`, `turntable360FrameUrls`, `staticGalleryImageUrls`, `cameraPresets`, `hotspots`, `colors`, `activeColor`.

- The Flutter viewer loads a bundled Three.js scene from `assets/viewer/showroom.html` inside a WebView.
- When `glbFileUrl` cannot be fetched (demo `cdn.motosaas.local` placeholder), the scene renders a procedural motorcycle so orbit, colour, preset, and hotspot interactions remain demonstrable.
- If no `Assets3D` row exists, the service returns a demo manifest instead of failing.

---

## 4. Enquiries & Test Rides

### 4.1 Create enquiry — `POST /sales/enquiries`

Guest request:

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

Authenticated request: same body without contact fields; the customer is taken from the JWT.

Validation:

| Field | Rule |
|---|---|
| `branchId`, `variantId` | required |
| `notes` | ≤ 1000 chars |
| `expectedPurchaseDate` | optional; not before yesterday |
| `firstName`, `lastName` | ≤ 100 chars |
| `phone` | 6–20 chars matching `^[0-9+\-\s()]{6,20}$`; required for guests |
| `email` | valid email when present |

Behaviour:

- Guest customer is deduplicated by `(tenantId, normalizedPhone)`; a new `Customers` row is created only when needed.
- Enquiry `Source = MOBILEAPP`; `Status = NEW`.
- Response: `201` with `EnquiryDto`.

### 4.2 Enquiry history — `GET /sales/enquiries/mine`

Returns the signed-in customer's enquiries, newest first, with `branchName`, `variantName`, `modelName`, `colorName`, `status`, `source`, `notes`, `assignedSalesExecutiveName`, `createdAt`.

### 4.3 Create test ride — `POST /sales/test-rides`

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

Validation:

| Field | Rule |
|---|---|
| `branchId`, `variantId` | required |
| `scheduledAt` | required, in the future, ≤ 60 days ahead |
| `drivingLicenseNumber` | ≤ 30 chars |
| guest contact | `firstName` + `phone` required; same phone/email rules as enquiry |

Behaviour: a linked enquiry is created (`Status = TESTRIDE`, notes "Test ride requested from the customer mobile app.") and `TestRides.Status = SCHEDULED`. Response `201` with `TestRideDto`.

### 4.4 Test-ride history — `GET /sales/test-rides/mine`

Returns scheduled time, status, branch, variant/model, driving licence, feedback notes, and creation time.

---

## 5. OTP Authentication

### 5.1 Request OTP — `POST /auth/customer/request-otp`

```json
{ "phone": "9876543210", "dealerCode": "ALAGENDRA" }
```

- Normalizes phone (strips spaces/`+91` variants) and resolves the tenant by dealer code (fallback `ALAGENDRA`).
- Demo OTP `123456` is assigned for the seeded customer and calls from the app; production wiring is Phase 18.

### 5.2 Verify OTP — `POST /auth/customer/verify-otp`

```json
{ "phone": "9876543210", "otp": "123456", "dealerCode": "ALAGENDRA" }
```

Response `data`:

```json
{
  "accessToken": "<jwt>",
  "expiresIn": 900,
  "user": {
    "id": "88888888-8888-8888-8888-888888888888",
    "fullName": "Asha Rao",
    "email": "asha.rao@example.com",
    "phone": "9876543210",
    "userType": "CUSTOMER",
    "tenantId": "11111111-1111-1111-1111-111111111111",
    "tenantCode": "ALAGENDRA",
    "tenantName": "Alagendra Automobiles",
    "roles": ["Customer"]
  }
}
```

- Lookup uses `IgnoreQueryFilters()` because anonymous verification has no tenant context yet.
- The app stores the token in secure storage and restores the session on launch.
- No customer refresh token: `401` clears the session and routes to login.

---

## 6. Profile

### 6.1 Read — `GET /customers/me`

```json
{
  "id": "88888888-8888-8888-8888-888888888888",
  "firstName": "Asha",
  "lastName": "Rao",
  "fullName": "Asha Rao",
  "phone": "9876543210",
  "email": "asha.rao@example.com",
  "addressLine1": "42, 12th Main, Indiranagar",
  "city": "Bengaluru",
  "state": "Karnataka",
  "postalCode": "560038",
  "vehicleCount": 1,
  "bookingCount": 1,
  "memberSince": "2026-11-13T17:39:59Z"
}
```

### 6.2 Update — `PUT /customers/me`

Accept any subset of `firstName`, `lastName`, `email`, `addressLine1`, `city`, `state`, `postalCode`.

| Field | Rule |
|---|---|
| `firstName` | ≤ 100 chars; when provided must be ≥ 2 chars after trim |
| `lastName` | ≤ 100 chars |
| `email` | valid email when present |
| address fields | ≤ 250 / 100 / 100 chars |
| `postalCode` | 4–10 digits when present |

Phone number is read-only in this phase (changing it requires OTP re-verification).

---

## 7. Garage & Service

### 7.1 My Vehicles — `GET /service/my-vehicles`

```json
[
  {
    "id": "99999999-9999-9999-9999-999999999999",
    "variantId": "55555555-5555-5555-5555-555555555555",
    "modelName": "R15 V4",
    "variantName": "R15 V4 Standard",
    "registrationNumber": "KA01AB1234",
    "chassisNumberMasked": "•••• 9012",
    "engineNumberMasked": "•••• 4567",
    "deliveryDate": "2026-07-16T17:39:59Z",
    "heroImageUrl": "https://...",
    "lastServiceDate": "2026-11-12T17:39:59Z",
    "lastServiceStatus": "BOOKED"
  }
]
```

Chassis/engine numbers are masked in API responses. Ownership is scoped through `CustomerVehicles.CustomerId = sub`.

### 7.2 My bookings — `GET /service/bookings/mine`

Returns booking details plus `jobCardId` and `jobCardStatus` when a job card exists.

### 7.3 Create booking — `POST /service/bookings`

```json
{
  "customerVehicleId": "99999999-9999-9999-9999-999999999999",
  "branchId": "22222222-2222-2222-2222-222222222222",
  "serviceType": "PERIODIC",
  "scheduledDate": "2026-11-15T00:00:00Z",
  "timeSlot": "09:00 - 10:00",
  "customerComplaints": "Chain noise and front brake feel"
}
```

| Field | Rule |
|---|---|
| `customerVehicleId`, `branchId` | required; vehicle must belong to the caller |
| `serviceType` | one of `FREE_SERVICE`, `PAID_GENERAL`, `PERIODIC`, `REPAIR`, `ACCIDENT`, `BATTERY` |
| `scheduledDate` | today or later, ≤ 90 days ahead |
| `timeSlot` | required, ≤ 40 chars |
| `customerComplaints` | ≤ 1000 chars |

Response `201` with `ServiceBookingDto` (`Status = BOOKED`).

### 7.4 Tracking — `GET /service/bookings/{bookingId}/tracking`

Returns `booking`, `jobCard` (number, status, odometer, fuel, estimated cost, approval flag, technician, items), `currentStage`, `progressPercent`, `awaitingCustomerApproval`, and `timeline[]`.

Resolution order: job card linked by `ServiceBookingId`; otherwise the latest non-closed job card for the vehicle. A booking with no job card returns the booking with an empty timeline stage `BOOKED`.

Stage/progress mapping:

| Job card status | currentStage | Progress |
|---|---|---|
| `OPEN` / `ESTIMATED` | `ESTIMATE_AWAITING_APPROVAL` (when estimated and unapproved) | 25% |
| `APPROVED` | `APPROVED` | 40% |
| `WORK_IN_PROGRESS` | `IN_PROGRESS` | 60% |
| `QUALITY_CHECK_PENDING` | `QUALITY_CHECK` | 80% |
| `QUALITY_CHECK_PASSED` | `READY_FOR_DELIVERY` | 90% |
| `BILLED` / `CLOSED` | `COMPLETED` | 100% |

### 7.5 Approve estimate — `PUT /service/job-cards/{jobCardId}/approve`

- Verifies the job card's vehicle belongs to the caller.
- First call: sets `CustomerApproved = true`, `Status = APPROVED`, and marks every item approved.
- Subsequent calls return the current tracking payload without error (idempotent).
- If the job card is already beyond `OPEN`/`ESTIMATED` without approval, returns `400`.

---

## 8. Error Matrix

| Status | When |
|---|---|
| `400` | validation failure, unknown service type, past/too-far date, estimate no longer awaiting approval, invalid guest contact |
| `401` | missing/expired token, non-customer token on `CustomerOnly` endpoints, unresolved customer |
| `404` | unknown model/variant/branch/booking, job card not owned by caller |
| `500` | unexpected server failure (generic envelope; details in Serilog) |

Validation failures use `errors: [{ field, message }]` and message `"Invalid ... details."`.

---

## 9. Verified E2E Evidence (2026-11-13)

Environment: local PostgreSQL (`motosaas_postgres`), API on `http://localhost:5053`, seed `docs/demo-data/PHASE_8_DEMO_SEED.sql`.

| Step | Status | Key assertion |
|---|---|---|
| Branding | 200 | `dealerCode = ALAGENDRA`, trade name and colours returned |
| Catalog | 200 | 1 model, Yamaha R15 V4, `has3DAsset = true` |
| Model detail | 200 | 1 variant, 2 colours, specs/features JSON present |
| Branch pricing | 200 | `estimatedOnRoadPrice = 212710`, `availableUnits = 2`, `inStock = true` |
| Showroom | 200 | `activeTier = 0`, camera presets + hotspots present |
| Guest enquiry | 201 | `status = NEW`, `source = MOBILEAPP` |
| Guest test ride | 201 | `status = SCHEDULED`, linked enquiry id |
| OTP request | 200 | OTP issued |
| OTP verify | 200 | customer JWT with `tenant_id`, `user_type = CUSTOMER` |
| Profile read | 200 | Asha Rao, Bengaluru address |
| Profile update | 200 | persisted contact fields |
| Customer enquiry | 201 | enquiry linked to signed-in customer |
| Customer test ride | 201 | test ride linked to signed-in customer |
| My enquiries | 200 | both customer enquiries present |
| My test rides | 200 | test ride present |
| My vehicles | 200 | `KA01AB1234`, masked chassis/engine |
| My bookings | 200 | seeded booking with `jobCardStatus = ESTIMATED` |
| New booking | 201 | `status = BOOKED` |
| Tracking (before) | 200 | `awaitingCustomerApproval = true`, 3 items |
| Approve estimate | 200 | `jobCardStatus = APPROVED`, `customerApproved = true` |
| Tracking (after) | 200 | approval reflected, stage progressed |

Latest automated totals: **107 backend unit tests**, **34 Flutter tests**, `flutter analyze` clean.

### Reproducing

```bash
docker exec -i motosaas_postgres psql -U postgres -d motosaas_db < docs/demo-data/PHASE_8_DEMO_SEED.sql
dotnet run --project src/MotoSaaS.Api/MotoSaaS.Api.csproj --launch-profile http

# In another terminal:
./docs/testing/PHASE_8_E2E.sh
```

The runner asserts every status code, prints `PASS`/`FAIL` per step, and leaves JSON responses in a temporary directory. It requires `curl`, `jq`, `python3`, and the `motosaas_postgres` container.

The seed is idempotent (fixed UUIDs + `ON CONFLICT DO NOTHING`). It leaves the sample job card `dddddddd-dddd-dddd-dddd-dddddddddddd` in `ESTIMATED` state awaiting customer approval; approval is idempotent, so re-running the approval step is safe, and the runner resets the estimate before and after each run.
