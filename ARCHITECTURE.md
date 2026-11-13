# System Architecture: MotoSaaS Multi-Tenant Platform

This document describes the high-level architecture of the Multi-Tenant Two-Wheeler Dealership Management SaaS platform.

---

## 1. Architectural Philosophy & Principles

1. **Modular Monolith First:** Built as a single deployable ASP.NET Core 8 Web API with strictly isolated internal modules (bounded contexts) using Clean Architecture. Microservices are rejected at this stage to prevent premature network latency, distributed transaction complexity, and excessive operational cost.
2. **Strict Multi-Tenancy by Design:** The system is tenant-aware from the database layer to the presentation layer. No data is stored without explicit tenant ownership.
3. **Decoupled Business Entities:** 
   - `Manufacturer` (e.g., Yamaha, Honda, TVS, EV startups) is independent of any dealership.
   - `Dealership Organization` (`Tenant`, e.g., Alagendra Automobiles) is an independent business entity.
   - `Branch` is a physical operational location under a dealership organization.
4. **Dual-Experience Mobile Application:** A single Flutter application delivers a guest/customer experience and a staff operational portal with strict runtime, token, and cache isolation.
5. **Real 3D Interactive Showroom:** Realistic GLB/glTF 3D vehicle visualization with dynamic variant/color switches and graceful multi-tier fallbacks.

---

## 2. High-Level System Architecture Diagram

```mermaid
graph TB
    subgraph Clients["Client Presentation Tier"]
        C_MOB["Customer & Staff Flutter Mobile App<br/>(iOS / Android)"]
        W_BRANCH["Dealer Branch Portal<br/>(Next.js / React)"]
        W_ORG["Dealer Org Admin Portal<br/>(Next.js / React)"]
        W_SAAS["SaaS Super Admin Portal<br/>(Next.js / React)"]
    end

    subgraph Gateway["API & Security Boundary"]
        INGRESS["Reverse Proxy / Cloud Ingress (HTTPS)"]
        AUTH_MW["Tenant Resolution & Auth Middleware<br/>(JWT + Session Validator)"]
    end

    subgraph Backend["Core Backend (ASP.NET Core 8 Web API)"]
        subgraph CoreModules["Clean Architecture Bounded Contexts"]
            MOD_TENANT["Tenant & Subscription Engine"]
            MOD_CATALOG["Manufacturer & Vehicle Catalog"]
            MOD_INV["Inventory & Chassis Management"]
            MOD_SALES["Sales, Enquiries & Quotations"]
            MOD_SERVICE["Service, Job Cards & Technicians"]
            MOD_BILLING["Invoicing & Payments Engine"]
            MOD_3D["3D Asset Management & Streaming"]
            MOD_NOTIF["Notification & Communications Hub"]
            MOD_INT["Integration & Sync Framework"]
        end
    end

    subgraph Storage["Data & Asset Tier"]
        PG["PostgreSQL 16+<br/>(RLS + Tenant-Scoped Schemas)"]
        BLOB["Object Storage (Azure Blob / S3 / MinIO)<br/>(3D GLB Models, Textures, Invoices, Media)"]
        REDIS["Distributed Cache / Message Bus<br/>(Session State, Rate Limiting, OTP)"]
    end

    Clients --> INGRESS
    INGRESS --> AUTH_MW
    AUTH_MW --> CoreModules
    CoreModules --> PG
    CoreModules --> BLOB
    CoreModules --> REDIS
```

---

## 3. Tenancy Hierarchy & Isolation Model

```mermaid
graph TD
    SAAS["SaaS Platform Provider"]
    
    subgraph PlatformScope["Global Platform Scope"]
        MANUF_Y["Manufacturer: Yamaha"]
        MANUF_H["Manufacturer: Honda"]
        MANUF_T["Manufacturer: TVS"]
    end
    
    SAAS --> PlatformScope
    
    subgraph Tenant1["Tenant: Alagendra Automobiles"]
        T1_MAPPING["Brand Mapping: Yamaha"]
        T1_B1["Branch: Madurai Central"]
        T1_B2["Branch: Dindigul Town"]
        T1_EMP["Employees (Sales, Service, Cashier)"]
        T1_INV["Inventory (Chassis Stock at Branches)"]
        T1_TX["Sales, Bookings & Job Cards"]
    end

    subgraph Tenant2["Tenant: Demo Multi Motors"]
        T2_MAPPING["Brand Mappings: Honda, TVS"]
        T2_B1["Branch: Coimbatore North"]
        T2_EMP["Employees"]
        T2_INV["Inventory"]
        T2_TX["Sales & Service"]
    end

    SAAS --> Tenant1
    SAAS --> Tenant2
```

### Data Isolation Guarantees
1. **Server-Side Identity:** The tenant context (`TenantId`) is extracted exclusively from the authenticated JWT claims on protected routes or resolved via domain/header on public white-labeled endpoints. Client-supplied `tenant_id` in request bodies is never trusted for authorization.
2. **EF Core Global Query Filters:**
   ```csharp
   modelBuilder.Entity<InventoryItem>()
       .HasQueryFilter(e => e.TenantId == _currentTenantService.TenantId);
   ```
3. **PostgreSQL Row-Level Security (RLS):**
   ```sql
   ALTER TABLE inventory_items ENABLE ROW LEVEL SECURITY;
   CREATE POLICY tenant_isolation_policy ON inventory_items
       FOR ALL
       USING (tenant_id = current_setting('app.current_tenant_id')::uuid);
   ```
4. **Branch Authorization:** For branch-scoped entities (e.g., job cards, inventory allocation), the backend verifies that the acting user has role assignment to that specific `BranchId` within the authenticated `TenantId`.

---

## 4. Dual-Experience Mobile Client Architecture (Flutter)

The single Flutter application cleanly isolates Customer and Staff domains:

```mermaid
graph LR
    subgraph AppEntry["Flutter Main Application (GoRouter)"]
        SPLASH["App Initializer / Brand Loader"]
        MODE_SELECT["Context Switcher & Session Guard"]
    end

    subgraph CustomerDomain["Customer Domain (/customer)"]
        GUEST["Guest Showroom & 3D Viewer"]
        C_AUTH["Customer OTP Login / Registration"]
        C_HOME["Customer Portal (My Vehicles, Service)"]
        C_STATE["Customer Riverpod Container & Storage"]
    end

    subgraph StaffDomain["Staff Domain (/staff)"]
        S_AUTH["Staff Login (Dealer Code + User + Pass)"]
        S_DASH["Role-Based Operations Dashboard"]
        S_WORK["Sales / Service / Cashier / Manager Modules"]
        S_STATE["Staff Riverpod Container & Secure Vault"]
    end

    SPLASH --> MODE_SELECT
    MODE_SELECT --> CustomerDomain
    MODE_SELECT --> StaffDomain
```

- **Zero Cache Leakage:** On switching modes or logging out, an explicit `PurgeSessionUseCase` purges JWT tokens, user profiles, secure storage keys, and Dio client headers for that domain.

---

## 5. Backend Clean Architecture Layout

The ASP.NET Core solution is partitioned into four clear layers per bounded context:

```
src/
├── MotoSaaS.Domain/             # Pure enterprise business entities, value objects, domain events, enums
├── MotoSaaS.Application/        # Use cases, CQRS commands/queries, FluentValidation, DTOs, interfaces
├── MotoSaaS.Infrastructure/     # EF Core DbContext, PostgreSQL configs, RLS interceptors, Blob storage, Email/SMS
├── MotoSaaS.Api/                # Controllers, Middlewares, Filters, OpenAPI Swagger, Dependency Injection
└── MotoSaaS.Seeder/             # Centralized deterministic demo data seeding CLI
```

---

## 6. Integration Architecture

Dealerships frequently utilize upstream manufacturer systems or local accounting software. The integration engine provides an adapter-based framework:
- **`IDmsAdapter`:** Synchronization of vehicle catalog, dispatched chassis, and warranty registrations.
- **`IAccountingAdapter`:** Export of daily invoice journals, ledger postings, and tax summaries (Tally / Zoho Books / QuickBooks compatible).
- **`IPaymentGatewayAdapter`:** Idempotent processing of customer booking deposits and service payments.
- **`ICommunicationAdapter`:** SMS and WhatsApp delivery with delivery receipt logging.

