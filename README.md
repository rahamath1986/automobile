# MotoSaaS — Multi-Tenant Two-Wheeler Dealership Management SaaS

MotoSaaS is a production-grade, commercially reusable, manufacturer-independent, multi-tenant cloud platform engineered for two-wheeler dealerships. It covers customer vehicle discovery, interactive 3D virtual showrooms, lead management, test rides, quotations, bookings, payments, inventory chassis allocation, delivery, and after-sales service operations.

---

## 1. Product Highlights & Architecture

- **Manufacturer-Independent:** Decoupled data model supporting multiple OEMs (Yamaha, Honda, TVS, Hero, Bajaj, Suzuki, Royal Enfield, EV startups).
- **Multi-Tenant from the Ground Up:** Logical tenant isolation via PostgreSQL Row-Level Security (RLS) and EF Core global query filters.
- **Dual-Experience Mobile App:** A single Flutter mobile application delivering guest vehicle discovery, 3D showroom, and customer ownership, alongside a dedicated staff operational portal with strict authentication and cache isolation.
- **Interactive 3D Showroom:** WebGL / Three.js and mobile GLB/glTF 2.0 rendering with 360-degree rotation, pinch-zoom, dynamic color/variant switching, interactive feature hotspots, and a 3-tier progressive fallback pipeline.
- **Zero Double-Allocation:** Finite state machine for physical chassis tracking (`Expected` -> `Received` -> `Available` -> `Reserved` -> `Allocated` -> `Sold` -> `Delivered`) backed by row-level database concurrency locks.
- **Complete After-Sales Service:** Customer appointments, reception checklist, digital job card, parts/labour estimate approvals, technician tracking, and service billing.

---

## 2. Technology Stack

- **Backend:** ASP.NET Core 8 Web API (Clean Architecture: Domain, Application, Infrastructure, API).
- **Database:** PostgreSQL 16+ with Npgsql, EF Core 8, and Row-Level Security (RLS).
- **Mobile Application:** Flutter 3.x, Riverpod 3.x, Clean Architecture, Dio, GoRouter.
- **Web Portals:** Next.js (React 19, TypeScript, Tailwind CSS, Radix UI).
- **3D Engine:** Three.js / React Three Fiber (Web) and WebGL / Flutter Controller (Mobile).
- **Observability & Logging:** Serilog, OpenTelemetry, Azure Application Insights.

---

## 3. Project Documentation Directory

- `PROJECT_STATUS.md` — Current phase tracking, execution metrics, and Definition of Done.
- `IMPLEMENTATION_PLAN.md` — 18-phase implementation roadmap and dependency graph.
- `ARCHITECTURE.md` — High-level system architecture and module boundaries.
- `DATABASE_DESIGN.md` — Complete PostgreSQL relational schema, ER diagrams, and RLS specifications.
- `API_CONTRACTS.md` — RESTful endpoint inventory, envelopes, and authentication policies.
- `DECISIONS.md` — Architectural Decision Records (ADRs) and unresolved decisions log.
- `KNOWN_ISSUES.md` — Technical risks, limitations, and security watch items.
- `CHANGELOG.md` — Historical record of modifications.
- `docs/api/PHASE_9_SALES_CRM.md` — Sales pipeline, CRM and quotation API contracts with verified E2E evidence.
- `docs/api/PHASE_8_CUSTOMER_APP.md` — Customer app API contracts and verified E2E evidence.
- `docs/ui-ux/CUSTOMER_APP_UX.md` — Customer app information architecture, flows, and interaction rules.
- `docs/demo-data/PHASE_9_DEMO_SEED.sql` — Idempotent seed for sales roles, leads, follow-ups, test rides and quotations.
- `docs/demo-data/PHASE_8_DEMO_SEED.sql` — Idempotent local/demo seed for the customer journey.
- `docs/testing/PHASE_9_E2E.sh` — Runnable 62-assertion API verification for the sales & CRM engine.
- `docs/testing/PHASE_8_E2E.sh` — Runnable 21-step API verification for the customer journey.
- `docs/` — In-depth architectural specifications and workflow models.

---

## 4. Current Phase: Phase 9 (Sales & CRM Engine)

Phase 9 is complete and awaiting review. It adds a branch CRM pipeline (lead capture, automatic branch/executive assignment, guarded stage transitions, follow-ups) and a dynamic quotation engine with state RTO/road tax, insurance, accessories, handling and discounts.

```bash
# Run the API
dotnet run --project src/MotoSaaS.Api/MotoSaaS.Api.csproj --launch-profile http

# Seed the demo tenant, catalog, customer (Phase 8) and sales data (Phase 9)
docker exec -i motosaas_postgres psql -U postgres -d motosaas_db < docs/demo-data/PHASE_8_DEMO_SEED.sql
docker exec -i motosaas_postgres psql -U postgres -d motosaas_db < docs/demo-data/PHASE_9_DEMO_SEED.sql

# Verify the sales & CRM engine end to end
./docs/testing/PHASE_9_E2E.sh
```

Demo staff login: `manager.priya` / `Demo@123` with dealer code `ALAGENDRA`. Customer demo remains phone `9876543210`, OTP `123456`. Phase 9 API details are in `docs/api/PHASE_9_SALES_CRM.md`. Development proceeds strictly through gated phases; Phase 10 (Purchase, Payments & Delivery) starts only after approval.
