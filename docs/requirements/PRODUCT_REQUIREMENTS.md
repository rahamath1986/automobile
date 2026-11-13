# Product Requirements Document (PRD)

**Project:** MotoSaaS (Multi-Tenant Two-Wheeler Dealership Management SaaS)  
**Target Category:** New Two-Wheelers Only (Motorcycles, Scooters, Electric Two-Wheelers)  
**Excluded:** Used vehicles, second-hand trade-in inventory holding.

---

## 1. Product Scope & Vision

MotoSaaS delivers an end-to-end cloud ecosystem connecting vehicle buyers, dealership staff, dealership organization leadership, and SaaS administrators. It powers customer discovery via an interactive 3D showroom, manages high-touch showroom sales, controls high-value physical inventory, and streamlines after-sales service operations.

### Key Personas & Portals
1. **End Customer:** Discovers two-wheelers as a guest, explores 3D models and colors, requests test rides, gets quotations, tracks sales delivery, and manages vehicle servicing.
2. **Sales Executive:** Mobile & web CRM to capture walk-in/digital leads, schedule test rides, issue on-road quotations, and convert bookings.
3. **Service Advisor:** Mobile & web vehicle reception, check-in, digital job card creation, parts/labour estimate generation, and customer handover.
4. **Service Technician:** Mobile task execution, checklist inspection, parts requirement logging, and repair status updates.
5. **Cashier / Billing Clerk:** Payment collection (cash, card, UPI, bank transfer, financier disbursements), receipt generation, and invoice sealing.
6. **Branch Manager:** Operational oversight of branch sales targets, stock aging, technician bay utilization, cash reconciliation, and staff activity.
7. **Dealership Organization Admin:** Multi-branch oversight, staff roster, manufacturer catalog association, pricing policies, and inventory transfers.
8. **SaaS Super Admin:** Tenant onboarding, subscription plan management, feature entitlement toggling, and global platform observability.

---

## 2. Functional Requirements Matrix

### Module 1: Vehicle Discovery & Showroom
- **FR-1.1:** Browsable catalog of Motorcycles, Scooters, and Electric Vehicles without mandatory login.
- **FR-1.2:** Side-by-side comparison of up to 3 vehicle variants across technical specifications, battery/engine parameters, dimensions, and indicative pricing.
- **FR-1.3:** Filter by manufacturer, body type, fuel type (petrol vs EV), displacement, price bracket, and branch availability.
- **FR-1.4:** Interactive 3D vehicle viewer loading genuine GLB assets with 360-degree rotation, pinch-zoom, and color/variant switching.

### Module 2: Lead & Sales Management
- **FR-2.1:** Lead capture across walk-in, mobile app, website, and phone enquiry channels.
- **FR-2.2:** Automated round-robin or manual sales executive assignment.
- **FR-2.3:** Test ride booking with driving license capture and feedback recording.
- **FR-2.4:** Configurable quotation calculator including Ex-Showroom, Road Tax (RTO), Insurance (1+4 / 1+5 year terms), Mandatory Accessories, Extended Warranty, and Discounts.
- **FR-2.5:** Universal & Bank-Agnostic EMI Calculator:
  - Interactive mathematical loan calculator for customers and sales executives without requiring bank tie-ups.
  - Configurable parameters: Vehicle On-Road Price, Down Payment ($), Down Payment (%), Annual Interest Rate (APR %), Loan Tenure (12, 18, 24, 36, 48, 60 months), Calculation Mode (Reducing Balance vs Flat Rate).
  - Outputs: Monthly EMI amount, Total Interest Payable, Total Amount Payable, and complete Amortization Schedule.
- **FR-2.6:** Dealership Partner Financier & Bank Schemes:
  - Optional integration with dealership-associated financial institutions (e.g., TVS Credit, HDFC Bank, L&T Finance, IDFC First, Hero FinCorp).
  - Configurable financier schemes: Minimum Down Payment %, Maximum Loan-to-Value (LTV %), Pre-set APR %, Processing Fees, Documentation Charges.
  - Ability to attach selected finance/EMI scheme directly to customer Quotations and Bookings.
  - Finance application tracking: `Applied` -> `Documents Submitted` -> `Under Review` -> `Approved` -> `Disbursed` -> `Rejected`.

### Module 3: Inventory & Chassis Tracking
- **FR-3.1:** Physical inventory tracked by unique Vehicle Identification Number (VIN/Chassis Number) and Engine Number.
- **FR-3.2:** Seven-stage state machine: `Expected` -> `Received` -> `Available` -> `Reserved` -> `Allocated` -> `Sold` -> `Delivered`.
- **FR-3.3:** Strict concurrency control preventing double allocation of any chassis number.
- **FR-3.4:** Stock transfer requests and approvals between branches under the same tenant.

### Module 4: Invoicing & Financial Workflows
- **FR-4.1:** Multi-mode payment receipts supporting partial deposits and remaining balance tracking.
- **FR-4.2:** Official tax invoice generation upon delivery readiness with DEMO watermark in test environments.
- **FR-4.3:** Separate tracking of customer direct payments and bank finance disbursements.

### Module 5: After-Sales Service Management
- **FR-5.1:** Service appointment scheduling by customer with time-slot selection and complaint logging.
- **FR-5.2:** Digital job card generation at vehicle reception with odometer reading, fuel percentage, exterior scratch diagram, and inventory checklist (mirrors, toolkit).
- **FR-5.3:** Itemized estimates for spare parts and labour with customer digital approval before work commencement.
- **FR-5.4:** Technician assignment and status tracking (`Open` -> `Estimated` -> `Approved` -> `Work In Progress` -> `Quality Check` -> `Ready for Delivery` -> `Closed`).

