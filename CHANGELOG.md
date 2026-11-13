# Changelog

All notable changes to the Multi-Tenant Two-Wheeler Dealership Management SaaS platform are documented here following Keep a Changelog standards.

---

## [Unreleased] - Phase 9: Sales & CRM Engine (2026-11-13)

### Added
- **Branch CRM pipeline (`/api/v1/staff/sales`):**
  - `GET /staff/sales/leads` paged pipeline with stage, owner, due-follow-up, search and branch filters.
  - `GET /staff/sales/leads/{id}` lead detail with notes, follow-up history, test rides and quotations.
  - `POST /staff/sales/leads` lead capture for walk-in, phone, web and app leads, with branch resolution (token → city → HQ) and automatic sales-executive assignment.
  - `PUT /staff/sales/leads/{id}/assign`, `PUT /staff/sales/leads/{id}/status` and `POST /staff/sales/leads/{id}/follow-ups`.
  - `GET /staff/sales/dashboard` counters, conversion rate, per-stage pipeline and per-branch snapshot.
  - `GET /staff/sales/sales-executives` assignable staff with roles and open-lead counts.
- **Test-ride operations:** `GET /staff/sales/test-rides` queue plus `complete` (driving-licence verification required), `cancel` (mandatory reason) and `no-show` actions.
- **Dynamic quotation engine (`/api/v1/quotations`):**
  - `POST /quotations/preview` and `POST /quotations` with ex-showroom, state RTO/road tax, insurance (3.5%, ₹1,500 floor), accessories, handling (default ₹2,500) and discount.
  - Sequential numbering `QTN-{BRANCH}-{yyyyMMdd}-{seq:D4}`, 1–30 day validity, `ACTIVE` → `CONVERTED`/`EXPIRED` lifecycle, and advisory warnings for discounts above 5%.
  - `GET /quotations`, `GET /quotations/{id}` and `POST /quotations/{id}/expire`; listing auto-expires lapsed quotations.
- **Domain & rules:** `EnquiryFollowUp` entity, enquiry CRM fields (`LastContactedAt`, `NextFollowUpAt`, `LostReason`), quotation `HandlingCharges`/`Notes`, `SalesPipelineRules`, `SalesAssignmentRules`, `QuotationCalculator`, `UserTypeClaims`.
- **Database:** migration `20261113175619_Phase9SalesCrm` (follow-up table, CRM columns, branch/status and follow-up indexes).
- **Demo & test assets:** `docs/demo-data/PHASE_9_DEMO_SEED.sql` (roles, `manager.priya`, `sales.arjun`, leads, follow-ups, test rides, quotations) and `docs/testing/PHASE_9_E2E.sh` (62 assertions).
- **Documentation:** `docs/api/PHASE_9_SALES_CRM.md`, ADR 017–018.

### Fixed
- **Staff authorization:** staff JWTs emitted `user_type = DEALERSTAFF` while the `StaffOnly` policy expected `DEALER_STAFF`, which would reject every staff endpoint with `403`. Added the canonical `UserTypeClaims` mapper used by `StaffAuthService`.
- **Assignment fairness:** lead routing preferred managers over executives; `SalesAssignmentRules` now ranks `SalesExecutive` → `SalesManager` → `BranchManager`, then least open leads, and the Phase 8 customer enquiry path uses the same ranking.
- **Demo passwords:** Phase 8 seed staff hashes were placeholders that could never match; replaced with a valid PBKDF2-SHA256 `Demo@123` hash.

### Testing
- Backend: 171 unit tests passing, 0 warnings, 0 errors (`dotnet build` + `dotnet test`).
- E2E: 62 assertions across authentication, pipeline, capture/assignment, follow-ups, quotations, test rides and illegal transitions — all passing.
- Live smoke run also verified the auto-assignment result (`sales.arjun`, a SalesExecutive, rather than a manager).

---

## [Unreleased] - Phase 8: Customer Flutter Application (2026-11-13)

### Added
- **Customer Flutter App (`mobile/customer_app`):**
  - Riverpod 3.3.2 + go_router 17.2.3 + Dio Clean Architecture app with Domain / Data / Application / Presentation layers per feature.
  - Five-tab shell: Showroom, Compare, Activity, Garage, Profile. Guests can browse; authenticated-only tabs show a contextual sign-in prompt.
  - Guest vehicle discovery: white-label branding, catalog list/search/category filters, model detail with variant and colour switching.
  - Branch on-road pricing panel (ex-showroom, RTO by state, insurance, handling) with an explicit indicative-estimate disclaimer.
  - Comparison tray supporting up to three variants with a side-by-side specification table.
  - 3D showroom viewer: bundled Three.js WebView (`assets/viewer`) with orbit controls, camera presets, colour switching and hotspots; procedural motorcycle fallback when the GLB is unavailable; tier-aware 3D / 360 / gallery presentation.
  - Enquiry and test-ride forms for guests and signed-in customers, with first-name/phone validation and UTC ISO-8601 scheduling.
  - Customer OTP login, secure session restore, profile view/edit, and sign-out.
  - Garage: My Vehicles ownership cards, service booking form, and service tracking timeline with live job card progress and estimate approval.
  - Activity: combined enquiry and test-ride history with status chips.
- **Backend customer APIs:**
  - `GET /api/v1/catalog/variants/{variantId}/pricing?branchId=` — indicative on-road price breakdown with stock availability.
  - `POST /api/v1/sales/enquiries`, `GET /api/v1/sales/enquiries/mine` — guest or authenticated enquiry capture and history.
  - `POST /api/v1/sales/test-rides`, `GET /api/v1/sales/test-rides/mine` — guest or authenticated test-ride requests and history.
  - `GET /api/v1/customers/me`, `PUT /api/v1/customers/me` — customer profile read/update.
  - `GET /api/v1/service/my-vehicles`, `GET /api/v1/service/bookings/mine`, `POST /api/v1/service/bookings`, `GET /api/v1/service/bookings/{id}/tracking`, `PUT /api/v1/service/job-cards/{id}/approve`.
  - `X-Dealer-Code` header tenant resolution for anonymous guest requests (fallback `ALAGENDRA`).
- **Database:**
  - Migration `20261113165631_AddEnquiryColorPreference` adds nullable `Enquiries.ColorId`.
  - Idempotent demo seed `docs/demo-data/PHASE_8_DEMO_SEED.sql` with fixed UUIDs (tenant, branch, Yamaha R15 V4, colours, 3D asset, customer `9876543210`, owned vehicle, staff users, estimated job card).
- **Documentation:**
  - `docs/api/PHASE_8_CUSTOMER_APP.md`, `docs/ui-ux/CUSTOMER_APP_UX.md`, `docs/testing/PHASE_8_E2E.sh`, ADR 014–016, updated API/README/status docs.

### Fixed
- Replaced the per-command `SET LOCAL` tenant prefix with `TenantRlsConnectionInterceptor`, resolving spurious `DbUpdateConcurrencyException` (expected 1 row, affected 0) on inserts.
- Moved `TenantResolutionMiddleware` after `UseAuthentication()` so JWT tenant/user claims are populated before authorization, fixing 401 responses on authenticated customer endpoints.
- Customer OTP verification now uses `IgnoreQueryFilters()` for the anonymous lookup, preventing duplicate-key inserts against `IX_Customers_TenantId_Phone`.

### Testing
- Backend: 107 unit tests passing, 0 warnings.
- Flutter: `flutter analyze` clean; 34 tests passing.
- E2E: 20 API calls covering guest and authenticated Phase 8 journeys all returned 200/201.

---

## [Unreleased] - Phase 7: Interactive 3D Showroom (2026-11-13)

### Added
- **3-Tier Progressive Showroom Pipeline Engine:**
  - `IShowroom3DService` / `Showroom3DService`: Implements progressive fallback mechanism:
    - **Tier 1 (Interactive 3D):** glTF 2.0 Binary (`.glb`) with Draco compression and full 3D orbital controls.
    - **Tier 2 (360° Turntable):** 36-frame high-resolution WebP turntable image sequence fallback.
    - **Tier 3 (Static Multi-Angle Gallery):** Multi-angle photo gallery fallback for low-spec devices or low-bandwidth connections.
  - **Camera Orbital Presets & Constraints:**
    - Standardized viewpoints: Hero (isometric $45^\circ$), Profile ($90^\circ$ side), Cockpit (rider POV towards TFT console), Rear, Top-down.
    - Strict polar angle clamping ($5^\circ$ to $75^\circ$) to eliminate ground clipping and disorienting inverted top-down views.
    - Distance clamping ($1.5\text{ m}$ to $6.0\text{ m}$) preventing geometry clipping and extreme zoom-out.
  - **Interactive 3D Hotspots Engine:**
    - 3D coordinate vector positions ($X, Y, Z$) with spec annotations (Dual-channel ABS, Liquid-cooled engine with VVA, TFT smartphone connectivity).
  - **Showroom API Endpoints:**
    - `GET /api/v1/showroom/variants/{variantId}`: Resolves 3-tier showroom manifest with color options (AllowAnonymous).
    - `GET /api/v1/showroom/variants/{variantId}/hotspots`: Resolves technical feature hotspots in 3D coordinate space (AllowAnonymous).
    - `GET /api/v1/showroom/variants/{variantId}/camera-presets`: Returns orbital presets and angle/distance constraints (AllowAnonymous).
    - `POST /api/v1/showroom/assets`: Registers/updates 3D asset metadata with size/format validation (`[Authorize(Policy = "StaffOnly")]`, `[RequiresFeature(SubscriptionFeatures.Showroom3D)]`).
- **Decisions & Documentation:**
  - Added ADR 013 (Interactive 3D Showroom Progressive Fallback Pipeline & Camera Constraints) in `DECISIONS.md`.
- **Testing:**
  - 11 new unit tests added covering asset validation (empty URL, non-glb formats, size $\le 15\text{ MB}$ limit), camera preset constraints, demo asset fallback, and ShowroomController endpoints (total: 69 tests passing, 0 warnings, 0 failures).

## [0.7.0] - Phase 6: Vehicle Catalogue & Inventory (2026-11-13)

### Added
- **Two-Wheeler Vehicle Catalogue Engine:**
  - `IVehicleCatalogService` / `VehicleCatalogService`: Model discovery with category filtering (Motorcycles, Scooters, EVs) and fuel type filtering (Petrol, Electric, Hybrid).
  - Supports automatic filtering to tenant's authorized OEM brands via `tenant_manufacturers`.
  - Rich model details including variants, colors (Hex code, primary flag), technical specifications (JSONB), and 3D asset links.
  - Endpoints: `GET /api/v1/catalog/models`, `GET /api/v1/catalog/models/{id}`, `POST /api/v1/catalog/models`, `POST /api/v1/catalog/variants`.
- **Physical Inventory & Chassis Tracking State Machine:**
  - `IInventoryService` / `InventoryService`: Physical two-wheeler unit tracking by Chassis Number (VIN) and Engine Number.
  - Strict Finite State Machine: `Expected` $\rightarrow$ `Received` $\rightarrow$ `Available` $\rightarrow$ `Reserved` $\rightarrow$ `Allocated` $\rightarrow$ `Sold` $\rightarrow$ `Delivered`.
  - Allocation Mutex: Strictly allows allocating only `Available` or `Reserved` stock to bookings; rejects double-allocation and increments concurrency versions.
  - Inter-branch stock transfers restricted strictly to unbooked, available stock.
  - Immutable movement audit logging (`InventoryMovement`) capturing all transitions with timestamps and responsible users.
  - Endpoints: `GET /api/v1/inventory`, `POST /api/v1/inventory/receive`, `POST /api/v1/inventory/allocate`, `POST /api/v1/inventory/transfer`, `GET /api/v1/inventory/chassis/{chassisNumber}/history`.
- **Decisions & Documentation:**
  - Added ADR 012 (Physical Chassis Identification & Allocation Mutex) in `DECISIONS.md`.
- **Testing:**
  - 18 new unit tests added covering model DTOs, variant/color mappings, finite state transitions (valid vs forbidden), and Catalog/Inventory controllers (total: 58 tests passing).

## [0.6.0] - Phase 5: Manufacturer & White-Label Configuration (2026-11-13)

### Added
- **Global Manufacturer (OEM) Management:**
  - `IManufacturerService` / `ManufacturerService`: Catalog support for Yamaha, Honda, TVS, Hero, Bajaj, Suzuki, Royal Enfield.
  - Endpoints: `GET /api/v1/manufacturers`, `GET /api/v1/manufacturers/{id}`, `POST /api/v1/manufacturers` (SaaS Admin).
- **Dealership Multi-Brand Associations (`tenant_manufacturers`):**
  - `ITenantManufacturerService` / `TenantManufacturerService`: Enables single-brand (Alagendra Yamaha) or multi-brand (TVS + Honda + Hero) dealership configurations with OEM dealer codes (`DealerCodeWithOem`) and primary brand flags.
  - Endpoints: `GET /api/v1/tenant-manufacturers`, `POST /api/v1/tenant-manufacturers`, `DELETE /api/v1/tenant-manufacturers/{id}`.
- **White-Label Dealership Branding Engine:**
  - `IBrandingService` / `BrandingService`: Configurable branding profile (TradeName, LegalName, GSTIN TaxId, LogoUrl, FaviconUrl, PrimaryColor, SecondaryColor, Support contact info, and associated OEM names).
  - Endpoints: `GET /api/v1/branding/current`, `GET /api/v1/branding/{dealerCode}`, `PUT /api/v1/branding/current`.
- **Decisions & Documentation:**
  - Added ADR 011 (Decoupled Global OEM Catalog & Multi-Brand Mappings) in `DECISIONS.md`.
- **Testing:**
  - 5 new unit tests added covering Manufacturer DTOs, TenantManufacturer mappings, WhiteLabel branding, and controllers (total: 40 tests passing).

## [0.5.0] - Phase 4: Subscription & Entitlements (2026-11-13)

### Added
- **Subscription Plans & Tier Quotas:**
  - `SubscriptionPlan`: Structured plans (`STARTER`, `PROFESSIONAL`, `ENTERPRISE`) with defined numerical limits (`MaxBranches`, `MaxEmployees`, `MaxInventoryUnits`) and active feature lists.
  - `TenantSubscription`: Tracks subscription status (`Trial`, `Active`, `PastDue`, `Suspended`), start/end dates, and trial expiration dates.
  - EF Core migration `AddSubscriptions` capturing subscription entities and foreign key associations.
- **Entitlement & Feature Guard Engine:**
  - `IEntitlementService` / `EntitlementService`: Live validation for feature enablement and branch/employee/inventory quota limits.
  - `ISubscriptionPlanService` / `SubscriptionPlanService`: Plan catalog lookup and tenant plan upgrade management.
  - `[RequiresFeature]` Action Filter: Declarative API gate rejecting requests with `403 Forbidden` if the tenant's tier lacks the required capability (e.g. `Showroom3D`, `FinancierSchemes`).
- **Subscription API Endpoints:**
  - `GET /api/v1/subscriptions/plans`: Public listing of available subscription plans.
  - `GET /api/v1/subscriptions/current`: Dealership tenant active plan, quota limits, and current resource usage counts.
  - `POST /api/v1/subscriptions/upgrade`: Dealership subscription plan change/upgrade.
- **Decisions & Documentation:**
  - Added ADR 010 (Subscription Tier Entitlements & Feature Guard Filters) in `DECISIONS.md`.
- **Testing:**
  - 6 new unit tests added covering feature key constants, plan quota models, trial flags, and SubscriptionsController (total: 35 tests passing).

## [0.4.0] - Phase 3: Tenant & Authentication Foundation (2026-11-13)

### Added
- **Dual-Identity Authentication Architecture:**
  - `StaffAuthService`: Staff login requiring Dealer Code + Username/Email + Password. Resolves tenant, verifies salted PBKDF2/SHA-256 hash, and embeds roles and branch claims.
  - `CustomerAuthService`: Mobile phone OTP authentication. Auto-creates/binds `Customer` record under dealership tenant and issues Customer JWT with strict `user_type = "CUSTOMER"` claim.
  - `PasswordHasher`: Salted PBKDF2 password hasher with 100,000 iterations and 128-bit CSPRNG salt.
  - `JwtTokenService`: Signs JWT access tokens (15-min expiry) and generates secure 64-byte CSPRNG refresh tokens.
  - `TenantService`: Multi-branch and tenant organization profile resolution by code and ID.
- **ASP.NET Core Authorization Policies:**
  - `StaffOnly`: Restricts endpoints to `DEALER_STAFF` and `SAAS_ADMIN`.
  - `CustomerOnly`: Restricts endpoints to `CUSTOMER`.
  - `SuperAdminOnly`: Restricts platform endpoints to `SAAS_ADMIN`.
  - `BranchManagerOnly`: Restricts branch management actions to `BranchManager` role.
- **API Endpoints:**
  - `POST /api/v1/auth/staff/login`
  - `POST /api/v1/auth/customer/request-otp`
  - `POST /api/v1/auth/customer/verify-otp`
  - `POST /api/v1/auth/refresh-token`
  - `GET /api/v1/tenants/current`
  - `GET /api/v1/tenants/{code}`
  - `GET /api/v1/tenants/{id}/branches`
- **Zero-Cost ($0) Azure Cloud Hosting Architecture Guide:**
  - Added section in `docs/deployment/DEVOPS_AND_DEPLOYMENT.md` detailing Azure App Service F1 Free Tier ($0/month), Azure Container Apps serverless free consumption grant (180k vCPU-s + 2M requests/month), and PostgreSQL free tier options.
  - Added ADR 008 in `DECISIONS.md`.
  - Added ADR 009 for Dual Authentication Lifecycle in `DECISIONS.md`.
- **Testing:**
  - 13 new unit tests added covering PasswordHasher, JwtTokenService, AuthController, and TenantsController (total: 29 tests passing).

## [0.3.0] - Phase 2: Backend Foundation (2026-11-13)

### Added
- **ASP.NET Core 8 Web API Clean Architecture Solution:**
  - `MotoSaaS.Domain`: Pure enterprise entities across 8 bounded contexts (31 domain entities).
  - `MotoSaaS.Application`: CQRS interfaces, FluentValidation pipelines, `ApiResponse<T>` envelopes, and universal bank-agnostic `IEmiCalculatorService`.
  - `MotoSaaS.Infrastructure`: EF Core 8 `ApplicationDbContext` with PostgreSQL Npgsql provider, global query filters for `ITenantScopedEntity`, and `TenantRlsDbCommandInterceptor`.
  - `MotoSaaS.Api`: Controllers, Serilog structured console logging, `GlobalExceptionHandlingMiddleware`, `TenantResolutionMiddleware`, and Swagger/OpenAPI documentation.
  - `MotoSaaS.UnitTests`: 16 comprehensive unit tests verifying EMI calculations (reducing balance, flat rate, zero interest), FluentValidation rules, and health endpoints.
- **Entity Framework Core 8 Initial Migration:**
  - Generated `InitialCreate` migration capturing all 31 tables, foreign keys, unique constraints, and indexes.
  - Installed `dotnet-ef` local tool in `.config/dotnet-tools.json`.
- **API Endpoints Implemented & Verified:**
  - `POST /api/v1/finance/calculate-emi`: Universal bank-agnostic EMI calculator with amortization schedule.
  - `GET /health/live`: Liveness health check.
  - `GET /health/ready`: Readiness health check.
- **Docker Compose Setup (`docker-compose.yml`):**
  - PostgreSQL 16 container with health check.
  - Redis 7 container for distributed caching.
  - MinIO S3 object storage for 3D GLB assets.

## [0.2.0] - Phase 1: Architecture & Detailed Design (2026-11-13)

### Added
- **Universal Bank-Agnostic EMI Calculator Specification:**
  - Standard reducing-balance and flat-rate mathematical formulation independent of banking infrastructure.
  - Interactive parameters: Vehicle Price, Down Payment (value/percentage), APR %, and Tenure options.
  - Complete amortization schedule generation ($P$, $r$, $n$, principal paid, interest paid, closing balance).
- **Dealership Financier & Partner Scheme Management:**
  - Added relational schema and DDL for `financiers`, `financier_schemes`, and `finance_applications`.
  - Added RESTful contracts: `POST /api/v1/finance/calculate-emi`, `GET /api/v1/finance/schemes`, `POST /api/v1/finance/applications`.
  - Added ADR 007 in `DECISIONS.md`.
- **Master PostgreSQL 16+ DDL Migration (`docs/database/POSTGRES_DDL_MIGRATIONS.sql`):**
  - 31 normalized tables with UUID primary keys, temporal auditing, foreign keys, unique constraints, and B-Tree indexes.
  - Active Row-Level Security (RLS) policies and security definition functions for non-negotiable multi-tenant isolation.
- **Detailed System Design Document (`docs/architecture/DETAILED_SYSTEM_DESIGN.md`):**
  - Clean Architecture Onion Model and module dependency graph.
  - Comprehensive Role-Based Access Control (RBAC) and Claim Authorization Policy Matrix.
  - Branch Access and multi-branch governance model.
  - 3D Vehicle Asset validation pipeline, camera preset schemas, and hotspot coordinate contracts.

## [0.1.0] - Phase 0: Repository Analysis & Product Discovery (2026-11-13)

### Added
- Comprehensive Phase 0 Repository Analysis across all 25 assessment criteria.
- Master architectural blueprints and product requirements specifications.
- Repository structure definition:
  - Backend: ASP.NET Core 8 Web API Clean Architecture modular monolith.
  - Mobile: Flutter with Riverpod 3.x and Clean Architecture (Dual Customer/Dealer experience).
  - Web: Next.js / TypeScript Portals for Branch, Org Admin, and SaaS Super Admin.
  - Database: PostgreSQL with Tenant Scoping and Row-Level Security (RLS).
- High-level Entity Relationship Data Model encompassing 28 core domain tables.
- End-to-end sales lifecycle state machine (Browse -> Enquiry -> Test Ride -> Quotation -> Booking -> Allocation -> Payment -> Delivery -> Ownership).
- End-to-end service lifecycle state machine (Vehicle -> Booking -> Reception -> Job Card -> Estimate -> Approval -> Tech Assignment -> Work -> Quality Check -> Billing -> Delivery).
- 3D Interactive Showroom architecture specification with GLB/glTF rendering, camera controls, color variants, and progressive fallback pipeline.
- Integration framework design for manufacturer DMS, accounting, payment gateways, and WhatsApp/SMS.
- Deterministic demo-data seeding strategy targeting 3 tenants (Alagendra Yamaha, Demo Honda, Demo Multi-Brand), 6 branches, 30+ models, 40+ inventory units, and full operational records.
- 18-phase implementation roadmap with strict gated criteria.

