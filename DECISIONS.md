# Architectural Decision Records (ADR) & Decision Log

This document records the architectural, technical, and operational decisions for the Multi-Tenant Two-Wheeler Dealership Management SaaS platform, following ADR conventions.

---

## ADR 001: Tenancy Model — Shared Database with Tenant Scoping and Row-Level Security (RLS)
- **Status:** Accepted (Phase 0)
- **Context:** The platform must support multiple independent dealership organizations (e.g., Alagendra Automobiles, Demo Honda Motors, Demo Multi Motors) while allowing cost-effective operational scalability and strict data isolation.
- **Decision:** 
  1. We adopt a **Shared Database, Shared Schema with Logical Tenant Isolation** via a required `tenant_id` (UUID) column on all tenant-scoped tables.
  2. Entity Framework Core global query filters (`HasQueryFilter(e => e.TenantId == _currentTenantService.TenantId)`) will enforce tenant isolation automatically in the application layer.
  3. PostgreSQL Row-Level Security (RLS) with session variable `app.current_tenant_id` will be configured as defense-in-depth, preventing cross-tenant leakage even in raw SQL queries or administrative errors.
  4. The design keeps connection strings abstracted via an `ITenantConnectionResolver` to allow seamless migration to dedicated databases for enterprise tenants in future releases without application code rewrites.
- **Consequences:** Low infrastructure overhead, fast provisioning of new tenants, strong isolation guarantees, straightforward centralized migrations.

---

## ADR 002: Technology Stack Selection for Core Platform
- **Status:** Accepted (Phase 0)
- **Context:** The system requires high performance, strict typing, cross-platform mobile support for customers/dealers, and robust enterprise backend persistence.
- **Decision:**
  - **Backend:** ASP.NET Core 8 Web API (C#), Entity Framework Core 8, Npgsql PostgreSQL provider, FluentValidation, Serilog structured logging.
  - **Database:** PostgreSQL 16+ with UUID v7/v4 primary keys and temporal tracking columns.
  - **Mobile:** Flutter (targeting iOS and Android), Riverpod 3.x for reactive state management, Clean Architecture (Domain/Data/Presentation layers), Dio with interceptors, GoRouter for declarative routing.
  - **Web Portals:** Next.js (React 19 / TypeScript) with Tailwind CSS and Radix UI / Shadcn primitives for responsive administrative portals.
  - **3D Visualization:** Three.js / React Three Fiber for Web portals; WebGL WebView or native `flutter_3d_controller` / Filament engine for Flutter, backed by GLB/glTF 2.0 optimized models.
- **Consequences:** Uniform language ecosystems on frontend/mobile/backend, proven scalability, enterprise-grade validation and concurrency control.

---

## ADR 003: Decoupling of Manufacturer, Dealership Organization, and Branch
- **Status:** Accepted (Phase 0)
- **Context:** Pilot customer Alagendra Automobiles sells Yamaha two-wheelers. Future tenants may sell Honda, TVS, Hero, Bajaj, Suzuki, Royal Enfield, or multiple brands. The platform must never hardcode brand-specific entities.
- **Decision:**
  - `Manufacturer` is a top-level platform entity managed by the SaaS Super Admin.
  - `Dealership Organization` (`Tenant`) is an independent legal business entity.
  - `TenantManufacturerMapping` establishes an M:N relationship, enabling single-brand or multi-brand dealerships.
  - `VehicleMaster` and `VehicleModel` belong to the platform catalog (linked to `Manufacturer`), whereas `InventoryItem` (chassis/engine units) belongs strictly to a `Tenant` and is stationed at a specific `Branch`.
- **Consequences:** Zero code changes required to onboard a new dealership or new manufacturer; complete commercial reusability.

---

## ADR 004: Dual-Experience Single Mobile Application with Strict Auth Separation
- **Status:** Accepted (Phase 0)
- **Context:** Customer vehicle discovery/ownership and dealer staff operational workflows must run on mobile devices. Creating two distinct mobile apps multiplies app store distribution overhead.
- **Decision:**
  - A single Flutter mobile codebase provides two decoupled experiences:
    - **Customer Flow:** Default landing experience. Guest browsing without login. Customer registration/login via Mobile Phone + OTP.
    - **Staff Flow:** Explicit staff portal entry. Requires Organization/Dealer Code, Username/Email, and Password with optional 2FA.
  - Token storage, secure storage keys, local Riverpod state containers, and HTTP request headers are strictly partitioned (`/customer/*` vs `/staff/*`).
  - Switching between customer and staff modes triggers complete cache and credential purging. Customer tokens are blocked from invoking staff APIs by backend policy attributes (`[Authorize(Policy = "StaffOnly")]`).
- **Consequences:** Single app distribution on Google Play Store and Apple App Store, zero cross-privilege elevation risk, optimal customer onboarding friction.

---

## ADR 005: Deterministic Demo Data Seeding Architecture
- **Status:** Accepted (Phase 0)
- **Context:** The platform must support repeatable demonstrations with realistic multi-tenant data (3+ tenants, 6+ branches, 30+ vehicle models, 40+ inventory units, real status lifecycles).
- **Decision:**
  - Implement an idempotent CLI/API seeder (`MotoSaaS.Seeder`) executed during startup in `Development` or `Demo` environments.
  - Seed records use deterministic UUIDs generated from seed hashes, preventing duplicate key collisions on re-runs.
  - Hardcoded business prices and live manufacturer images are strictly avoided; demo prices are clearly labeled "DEMO ESTIMATE", and local 3D/image assets are utilized.
- **Consequences:** Immediate demonstration readiness across all 22 required user scenarios; clean automated testing baseline.

---

## ADR 006: Inventory Allocation & Transactional State Machine
- **Status:** Accepted (Phase 0)
- **Context:** Vehicle units represent high-value physical goods identified by chassis (VIN) and engine numbers. Double allocation or premature stock depletion causes severe business failure.
- **Decision:**
  - Inventory state transitions follow a strict finite state machine:
    `Expected` -> `Received` -> `Available` -> `Reserved` -> `Allocated` -> `Sold` -> `Delivered`.
  - Vehicle allocation requires database row-level locking (`SELECT ... FOR UPDATE` via EF Core execution strategies) within an explicit database transaction.
  - Enquiries and Quotations do NOT hold reservations or modify stock status.
  - Only a verified Booking with minimum deposit can transition stock to `Reserved` (time-limited) or `Allocated`.
- **Consequences:** Zero risk of double allocation; guaranteed audit trail of stock transitions.

---

## ADR 007: Dual-Mode EMI Calculator & Financier Scheme Engine
- **Status:** Accepted (Phase 1)
- **Context:** Two-wheeler purchases heavily rely on credit financing. Customers and sales staff need immediate EMI estimation during showroom browsing and quotation creation. Some dealerships operate independently without pre-configured bank APIs, while others have tied-up financier partner schemes with special interest rates.
- **Decision:**
  1. Implement a **Bank-Agnostic Mathematical EMI Engine** in both the frontend (Flutter/Web client-side for zero-latency interactive sliders) and backend (for quotation generation and official records).
     - Standard reducing-balance formula: $E = P \cdot r \cdot \frac{(1 + r)^n}{(1 + r)^n - 1}$.
     - Flat-rate formula: $E_{\text{flat}} = \frac{P + (P \cdot R_{\text{annual}} \cdot \frac{n}{12})}{n}$.
     - Zero dependency on external bank APIs or banking credentials. Works completely stand-alone.
  2. Implement an optional **Tenant Financier & Scheme Registry** where dealerships can register their partner banks/NBFCs (e.g., TVS Credit, HDFC, L&T Finance) with pre-configured APR, LTV limits, processing fees, and documentation charges.
  3. When generating a formal quotation, the sales executive can attach either a general mathematical EMI estimate or an authorized partner financier scheme.
- **Consequences:** Instant customer engagement on showroom screens without bank dependencies, complete commercial flexibility for multi-brand and multi-financier dealerships.

---

## ADR 008: Zero-Cost ($0) Azure Cloud Hosting Architecture
- **Status:** Accepted (Phase 3)
- **Context:** For development, staging, client demos, and initial pilot evaluations, cloud infrastructure costs should be eliminated ($0.00 / month) while maintaining a seamless production-ready upgrade path.
- **Decision:**
  1. **Compute:** Leverage **Azure App Service F1 Free Tier** (1 GB RAM, 60 CPU min/day, $0 forever) or **Azure Container Apps Serverless Scale-to-Zero** with 180k vCPU-seconds and 2 million requests free per month.
  2. **Database:** Utilize the Azure Database for PostgreSQL Flexible Server Burstable `B1ms` free tier (750 hours/month free for 12 months) or a permanent zero-cost serverless PostgreSQL tier (e.g. Neon.tech / Supabase) via standard Npgsql connection string with zero application code changes.
  3. **Storage & Web:** Azure Blob Storage 5 GB free tier / App Service local wwwroot for 3D assets, and Azure Static Web Apps Free Tier for web portals ($0 forever).
- **Consequences:** $0 monthly cloud hosting spend for pilot and demo workloads; 100% production-ready architecture with seamless horizontal scaling when commercial scale requires paid tiers.

---

## ADR 009: Dual-Identity Authentication with Refresh Token Rotation
- **Status:** Accepted (Phase 3)
- **Context:** The platform serves two distinct user classes: Customers (casual discovery and ownership) and Staff (privileged dealership operations across branches).
- **Decision:**
  1. **Customer Auth:** Mobile phone number + OTP token verification. Issues JWT with claim `user_type = "CUSTOMER"`. Customer authentication creates or binds to a `Customer` domain record under the resolved `TenantId`.
  2. **Staff Auth:** Requires `DealerCode`, `UsernameOrEmail`, and salted PBKDF2/SHA-256 password hash verification. Issues JWT with claims `user_type = "DEALER_STAFF"`, `tenant_id`, `branch_id`, and role claims.
  3. **Authorization Policies:** ASP.NET Core policies (`StaffOnly`, `CustomerOnly`, `BranchManagerOnly`, `SuperAdminOnly`) reject cross-privilege elevation.
- **Consequences:** Complete security isolation between customer and operational staff domains with zero risk of privilege escalation.

---

## ADR 010: Subscription Tier Entitlements & Declarative Feature Guard Filters
- **Status:** Accepted (Phase 4)
- **Context:** SaaS commercial viability requires enforcing quota limits (maximum physical branches, active staff seats, inventory units) and feature access (3D virtual showroom, partner financier schemes, accounting sync) based on the dealership's subscription plan.
- **Decision:**
  1. **Subscription Plans:** Structured tiers (`STARTER`, `PROFESSIONAL`, `ENTERPRISE`) with explicit numeric limits (`MaxBranches`, `MaxEmployees`, `MaxInventoryUnits`) and a list of enabled feature keys (`EnabledFeatures`).
  2. **Declarative Feature Guards:** Implemented `[RequiresFeature(SubscriptionFeatures.Showroom3D)]` as an ASP.NET Core action filter. Evaluates tenant entitlements dynamically; returns `403 Forbidden` if the tenant's active plan does not include the feature.
  3. **Quota Enforcement:** `IEntitlementService` validates live database counts before allowing branch addition, staff creation, or stock intake.
  4. **Super Admin Bypass:** Platform Super Admins bypass feature restrictions to provide support and platform maintenance.
- **Consequences:** Clear monetization boundaries; prevents resource over-allocation; zero hardcoded prices or limits.

---

## ADR 011: Decoupled Global OEM Catalog & Dealership Multi-Brand Mappings
- **Status:** Accepted (Phase 5)
- **Context:** Dealerships may be exclusive single-brand franchised dealers (e.g. Alagendra Automobiles with Yamaha) or multi-brand operators (e.g. Demo Multi Motors with TVS, Honda, Hero). Hardcoding OEM brand IDs to tenants creates architectural rigidity and prevents multi-brand dealership onboarding.
- **Decision:**
  1. **Global OEM Catalog:** Original Equipment Manufacturers (`Manufacturer`) exist as platform-level masters managed globally by SaaS Super Admin.
  2. **M:N Association Table (`tenant_manufacturers`):** Dealerships map to one or more OEMs with attributes:
     - `DealerCodeWithOem`: The authorized dealer code assigned by that specific manufacturer to this dealership group.
     - `IsPrimary`: Flags the primary brand for single-brand showroom defaults.
  3. **White-Label Branding Payload:** Dealerships configure unique brand logos, primary/secondary theme colors, and trade names independently of OEM corporate identities.
- **Consequences:** 100% manufacturer-independent architecture; enables onboarding any two-wheeler brand or multi-brand dealership network without code changes.

---

## ADR 012: Physical Chassis Identification & Strict Finite State Allocation Mutex
- **Status:** Accepted (Phase 6)
- **Context:** Two-wheelers are high-value physical assets registered with unique Vehicle Identification Numbers (Chassis Numbers / VIN) and Engine Numbers. Double-allocation or transferring stock that has already been booked or invoiced represents a severe operational failure.
- **Decision:**
  1. **Chassis & Engine Unique Constraints:** Database level uniqueness constraint `uq_chassis_per_tenant (tenant_id, chassis_number)` prevents duplicate stock entry.
  2. **Finite State Machine Invariants:**
     - Allowed transitions: `Expected` $\rightarrow$ `Received` $\rightarrow$ `Available` $\rightarrow$ `Reserved` $\rightarrow$ `Allocated` $\rightarrow$ `Sold` $\rightarrow$ `Delivered`.
     - Reverse transitions: Only `Reserved` $\rightarrow$ `Available` (timeout/release) and `Allocated` $\rightarrow$ `Available` (formal booking cancellation).
     - Forbidden transitions: `Sold` $\rightarrow$ `Available`, `Delivered` $\rightarrow$ `Allocated`, `Expected` $\rightarrow$ `Sold`.
  3. **Stock Allocation Mutex:** Only vehicles in `Available` or `Reserved` status can be allocated to a booking. The allocation increments `concurrency_version` and atomically updates status to `Allocated`.
  4. **Inter-Branch Transfer Guard:** Only unbooked, `Available` stock can be transferred between physical branch locations.
  5. **Audit Trail:** Every status change, allocation, or branch transfer is immutably recorded in `inventory_movements` with the acting user's ID, branch coordinates, and timestamp.
- **Consequences:** Zero risk of double-selling a physical two-wheeler; complete chain-of-custody auditability.

---

## ADR 013: 3D Interactive Showroom Progressive Fallback Pipeline & Camera Constraints
- **Status:** Accepted (Phase 7)
- **Context:** Delivering 3D vehicle visualizers across heterogeneous mobile and web devices requires balancing high visual fidelity against mobile hardware constraints (low GPU memory, bandwidth limits, WebGL context crashes).
- **Decision:**
  1. **3-Tier Progressive Fallback Pipeline:**
     - **Tier 1 (Interactive 3D):** glTF 2.0 Binary (`.glb`) with Google Draco geometry and KTX2 texture compression ($\le 15\text{ MB}$). Full orbit, zoom, pan, and real-time PBR material color swapping without mesh reloads.
     - **Tier 2 (360° Turntable):** 36-frame or 72-frame high-resolution WebP turntable image sequence. Rendered on devices lacking WebGL 2.0 or when 3D asset download fails.
     - **Tier 3 (Static Multi-Angle Gallery):** 8-angle static high-resolution photograph carousel. Rendered on low-bandwidth connections or older hardware.
  2. **Camera Orbital Constraints:** Enforced camera polar angles ($\min 5^\circ$, $\max 75^\circ$) to prevent camera clipping below floor plane or disorienting inverted views. Configured distance clamp ($1.5\text{ m}$ to $6.0\text{ m}$) preventing geometry penetration.
  3. **Camera Presets Manifest:** Standardized 5 viewpoint anchors: Hero ($45^\circ$ isometric front), Profile ($90^\circ$ side), Cockpit (rider point of view towards TFT display and handlebars), Rear, and Top-down.
  4. **Dynamic Technical Hotspots:** 3D coordinate vector positions ($X, Y, Z$) with spec annotations (ABS, Engine VVA, TFT console) that orbit synchronously with the model.
  5. **Feature Gating:** Asset management (`POST /api/v1/showroom/assets`) requires `StaffOnly` authorization and entitlement to `SubscriptionFeatures.Showroom3D`.
- **Consequences:** Graceful degradation on all devices; fast load times; seamless customer visual engagement without mobile app crashes.

---

## ADR 014: Customer Mobile App Architecture — Feature-First Clean Architecture with Riverpod 3
- **Status:** Accepted (Phase 8)
- **Context:** Phase 8 requires a customer-facing Flutter app that supports guest discovery, authenticated ownership, and service workflows while remaining easy to extend for staff roles in Phase 12.
- **Decision:**
  1. **Feature-first layout:** each feature owns `domain` (entities + repository contracts), `data` (Dio data sources + repository implementations), `application` (Riverpod controllers/providers), and `presentation` (pages/widgets). Shared concerns live in `core/` (config, network, storage, theme, formatters, validators, widgets).
  2. **Entities parse their own JSON** to keep the data layer thin; repository interfaces isolate presentation from HTTP concerns.
  3. **Riverpod 3 `AsyncNotifier` controllers** own async state; pages consume `AsyncValue` and render shared loading/error/empty states.
  4. **go_router** defines a single route table, including query-parameter driven flows (model → variant → colour → branch → enquiry/test ride; booking → tracking).
  5. **Session storage** uses `flutter_secure_storage` for the bearer token and `shared_preferences` for non-sensitive preferences. No refresh-token flow: expired tokens route back to login.
- **Consequences:** Clear boundaries for future staff app reuse; predictable state handling; adding a feature means adding one folder rather than touching shared layers.

---

## ADR 015: Guest Tenant Resolution via `X-Dealer-Code` and Indicative Branch Pricing
- **Status:** Accepted (Phase 8)
- **Context:** Guests must browse a specific dealership's catalog, submit enquiries/test rides, and see branch-relevant pricing before any authentication exists. Formal quotations belong to Phase 9.
- **Decision:**
  1. **Anonymous tenant resolution:** `TenantResolutionMiddleware` resolves the tenant from the `X-Dealer-Code` header when no authenticated claims are present, falling back to `ALAGENDRA` for local/demo use. The Flutter app sends the dealer code on every request.
  2. **Guest lead capture:** enquiry/test-ride endpoints are `AllowAnonymous`; when no customer token is present, they require `firstName` + `phone`, deduplicate customers by `(tenantId, normalizedPhone)`, and attach the created lead to that customer.
  3. **Pricing is an estimate, not a quote:** `GET /catalog/variants/{variantId}/pricing` returns ex-showroom, state RTO percentage, insurance percentage, handling charges, an estimated on-road total, branch stock count, `priceBasis = INDICATIVE_ON_ROAD_ESTIMATE`, and a disclaimer. The app displays the disclaimer; the binding quotation remains a Phase 9 dealership document.
- **Consequences:** Guests get a complete pre-auth journey with correct tenant data; no pricing promise is made that the dealership cannot honour.

---

## ADR 016: Tenant Session Context Applied on Connection Open
- **Status:** Accepted (Phase 8)
- **Context:** The original tenant interceptor prefixed every SQL command with `SET LOCAL app.current_tenant_id = '...';`. With EF Core 8 + Npgsql, multi-statement commands caused INSERT/UPDATE batches to report the wrong rows-affected count, producing `DbUpdateConcurrencyException: expected to affect 1 row(s), but actually affected 0 row(s)`.
- **Decision:**
  1. Replace `TenantRlsDbCommandInterceptor` with `TenantRlsConnectionInterceptor`, a `DbConnectionInterceptor` that runs `SELECT set_config('app.current_tenant_id', @tenant_id, false), set_config('app.is_saas_super_admin', @is_super_admin, false)` when a connection opens.
  2. Keep parameters bound (no string interpolation) and rely on Npgsql pool reset (`DISCARD ALL`) so session values never leak across requests.
  3. Resolve the tenant before the first query by keeping `TenantResolutionMiddleware` after authentication and before authorization.
- **Consequences:** EF Core sees clean single-statement commands, concurrency checks pass, RLS/tenant context remains enforced for every pooled connection.

---

## ADR 017: Sales Pipeline as an Explicit, Guarded State Machine
- **Status:** Accepted (Phase 9)
- **Context:** Phase 9 needs follow-ups, test rides and quotations to move a lead through the sales pipeline consistently, without each endpoint inventing its own status logic or regressing a booked deal.
- **Decision:**
  1. **Single rule source:** `SalesPipelineRules` owns the allowed transition matrix (`New`, `Contacted`, `TestRide`, `Quoted`, `Booked`, `Lost`) and the outcome-to-stage mapping used by follow-ups.
  2. **Guarded transitions:** explicit `PUT /leads/{id}/status` calls reject illegal moves (`400`); implicit moves from a follow-up outcome are applied only when legal, otherwise the recorded follow-up still succeeds but the stage is unchanged.
  3. **Final-outcome side effects:** `Converted` converts active quotations and clears the next follow-up; `Lost`/`NotInterested` expire active quotations, require a lost reason, and clear the follow-up.
  4. **Terminal stages are closed:** `Booked` and `Lost` count as closed for dashboards and follow-up-due queries; `Lost` may be reopened to `New`/`Contacted`.
- **Consequences:** Pipeline reporting is consistent across API, CRM dashboard and future staff app; no endpoint can silently regress a deal or resurrect an expired quotation.

---

## ADR 018: Deterministic Quotation Math and Executive-First Lead Assignment
- **Status:** Accepted (Phase 9)
- **Context:** Customers saw indicative pricing in Phase 8, but the dealership still lacked an authoritative, reproducible quotation. New leads also needed fair routing without a manager manually triaging every capture.
- **Decision:**
  1. **Server-side calculation:** `QuotationCalculator` recomputes every quotation from the variant base price and branch state. Client-supplied totals are ignored; only accessories, handling and discount are accepted as inputs.
  2. **Shared state pricing:** RTO/road-tax rates and the 3.5% insurance floor (₹1,500) come from `BranchPricingCalculator`, so the Phase 8 estimate and the Phase 9 quotation cannot drift.
  3. **Guards:** discount cannot exceed ex-showroom + accessories; validity is clamped to 1–30 days; discounts above 5% add an advisory manager-approval warning rather than blocking the deal.
  4. **Numbering:** `QTN-{BRANCHCODE}-{yyyyMMdd}-{seq:D4}` provides a human-readable, tenant-unique quotation reference.
  5. **Executive-first assignment:** `SalesAssignmentRules` ranks `SalesExecutive` → `SalesManager` → `BranchManager`, then least open leads, with branch preference as the final tiebreak. The same ranking is used by staff capture and the Phase 8 customer enquiry path.
- **Consequences:** Quotations are auditable and reproducible; managers are not overloaded with leads that an executive could own; branch scoping and tenant isolation remain enforced by claims plus global query filters.

---

## Unresolved Business & Technical Decisions Log

| Decision ID | Area | Description | Impact | Current Working Assumption |
|---|---|---|---|---|
| **UND-01** | Payments | Specific Payment Gateway provider for India pilot (Razorpay, Cashfree, Pine Labs) | Phase 10 | Provider-agnostic `IPaymentGatewayService` adapter pattern; mock gateway for Dev/Demo. |
| **UND-02** | SMS/WhatsApp | Specific WhatsApp Business API provider (Gupshup, Meta Cloud API, Twilio) | Phase 18 | `INotificationService` interface with template-driven routing and sandbox mock provider. |
| **UND-03** | Existing DMS | Does Alagendra Automobiles use an existing Yamaha DMS with direct API access? | Phase 13/16 | Treat external DMS as an asynchronous synchronization peer via CSV/REST adapters; SaaS serves as primary system of engagement. |
| **UND-04** | Flutter 3D Engine | Native Filament engine vs WebGL Three.js bridge | Phase 7 | Resolved in ADR 013: 3-tier progressive pipeline (GLB WebGL/Three.js bridge + 360 Turntable + Static Gallery). |
| **UND-05** | Storage Provider | MinIO for local Docker development vs Azure Blob Storage for Cloud production | Phase 2 | Abstracted `IBlobStorageService` supporting MinIO/Local FileSystem and Azure Blob Storage. |

