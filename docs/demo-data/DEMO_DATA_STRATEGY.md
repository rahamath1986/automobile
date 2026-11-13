# Centralized Deterministic Demo-Data Strategy

This document specifies the seeding architecture, target record volumes, demo personas, deterministic generation algorithms, and demonstration test scripts for MotoSaaS.

---

## 1. Seeding Principles & Architecture

1. **Deterministic & Idempotent:** Re-running the seeder does not create duplicates or fail with primary key violations. UUIDs are deterministically derived from stable namespace seeds (UUID v5 / deterministic seed hashes).
2. **Environment Restriced:** Seeding logic is executable ONLY in `Development`, `Staging`, and `Demo` environments. It is strictly disabled in `Production` builds.
3. **Clearly Labeled Demo Data:** All generated quotes, invoices, and financial records carry explicit `DEMO ESTIMATE` and `DEMO INVOICE` watermarks to prevent any real-world commercial confusion.
4. **Calculated Live Metrics:** Dashboards and charts never display hardcoded mock numbers; they compute aggregations directly from the seeded database records via SQL.

---

## 2. Seed Target Matrix

| Entity | Quantity Target | Distribution & Scope |
|---|---|---|
| **Manufacturers** | 7 OEMs | Yamaha, Honda, TVS, Hero, Bajaj, Suzuki, Royal Enfield |
| **Tenants** | 3 Organizations | 1. Alagendra Automobiles (Yamaha)<br/>2. Demo Honda Motors (Honda)<br/>3. Demo Multi Motors (TVS & Hero) |
| **Branches** | 6 Branches | Madurai Central, Dindigul Bypass, Coimbatore North, Salem Central, Chennai West, Trichy Main |
| **Vehicle Models** | 30+ Models | Balanced across Motorcycles (15), Scooters (10), EVs (5) |
| **Vehicle Variants** | 60+ Variants | Standard, Deluxe, Disc, ABS, Connected Bluetooth trims |
| **Staff Accounts** | 25+ Employees | Branch Managers, Sales Executives, Service Advisors, Technicians, Cashiers, Org Admins |
| **Customers** | 90+ Customers | 30+ per tenant with realistic phone numbers and addresses |
| **Enquiries (Leads)**| 150+ Leads | 50+ per tenant across stages: New, Contacted, Test Ride, Quoted, Booked, Lost |
| **Test Rides** | 45+ Rides | 15+ per tenant with completed feedback and upcoming slots |
| **Quotations** | 60+ Quotes | 20+ per tenant with full tax, RTO, and accessory breakdowns |
| **Bookings** | 30+ Bookings | 10+ per tenant with recorded deposits |
| **Inventory Stock** | 40+ Units | Real VIN/Chassis and Engine numbers across all 7 statuses |
| **Service Bookings**| 90+ Bookings | 30+ per tenant with maintenance intervals |
| **Job Cards** | 75+ Job Cards | 25+ per tenant across Open, In-Progress, QC, and Billed stages |

---

## 3. Demo Persona Accounts & Development Credentials

*Note: These credentials are for local development and demonstration environments only.*

| Role | Username / Email | Password | Tenant Scope | Assigned Branch |
|---|---|---|---|---|
| **SaaS Super Admin** | `superadmin@motosaas.local` | `SaaSAdmin@2026!` | Global Platform | Global |
| **Org Admin (Alagendra)** | `admin@alagendra.local` | `DealerAdmin@2026!` | Alagendra Automobiles | Madurai HQ |
| **Branch Manager** | `manager.mdu@alagendra.local` | `BranchMgr@2026!` | Alagendra Automobiles | Madurai Central |
| **Sales Executive** | `sales1.mdu@alagendra.local` | `SalesExec@2026!` | Alagendra Automobiles | Madurai Central |
| **Service Advisor** | `advisor1.mdu@alagendra.local` | `ServiceAdv@2026!` | Alagendra Automobiles | Madurai Central |
| **Service Technician** | `tech1.mdu@alagendra.local` | `Technician@2026!` | Alagendra Automobiles | Madurai Central |
| **Cashier / Billing** | `cashier.mdu@alagendra.local` | `Cashier@2026!` | Alagendra Automobiles | Madurai Central |
| **Customer** | `+91 98765 43210` | OTP: `123456` (Mocked in Dev) | Alagendra Automobiles | Madurai Central |

---

## 4. End-to-End Demonstration Verification Scripts

The seeded dataset verifies all 22 required end-to-end demonstration scenarios:
1. Customer launches mobile app as guest -> explores catalog.
2. Customer selects Yamaha R15 V4 -> opens 3D showroom -> orbits 360 degrees.
3. Customer switches color to "Racing Blue" -> zooms into engine hotspot.
4. Customer submits an enquiry for test ride at Madurai Central branch.
5. Sales Executive logs into staff portal -> views new enquiry on CRM dashboard.
6. Sales Executive schedules and conducts test ride -> records license & feedback.
7. Sales Executive generates on-road quotation with road tax, insurance, and accessories.
8. Customer confirms booking and pays initial deposit.
9. Sales Executive allocates available physical chassis number from Madurai Central stock.
10. Cashier records remaining payment disbursement from financier.
11. Cashier seals vehicle tax invoice.
12. Pre-Delivery Inspection completed -> vehicle handover checklist signed.
13. Customer logs into mobile app via OTP -> views newly delivered vehicle under "My Vehicles".
14. Customer schedules first periodic free maintenance service.
15. Service Advisor checks in vehicle -> inputs odometer reading & scratches -> opens Job Card.
16. Advisor adds engine oil and labour estimate -> customer approves on mobile app.
17. Technician picks up assigned job card -> records work completion.
18. Quality inspector passes road test -> cashier records service payment.
19. Branch Manager reviews daily sales revenue and bay utilization reports.
20. Organization Admin reviews consolidated multi-branch performance.
21. SaaS Super Admin logs into platform portal -> inspects tenant subscriptions and usage.
22. Cross-tenant isolation verified: Alagendra staff cannot access Demo Honda inventory.

