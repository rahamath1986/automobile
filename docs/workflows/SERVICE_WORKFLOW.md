# Service & Workshop Management Workflow

This document details the operational flow, roles, inspection checklists, and billing rules for two-wheeler after-sales service.

---

## 1. End-to-End Service Lifecycle

```mermaid
sequenceDiagram
    autonumber
    actor C as Customer (App / Walk-in)
    actor SA as Service Advisor
    actor TECH as Service Technician
    actor CASH as Cashier
    participant SYS as MotoSaaS Backend

    C->>SYS: Schedules Service Appointment (Date, Slot, Complaints)
    SYS-->>SA: Appears in Branch Service Reception Dashboard
    Note over C,SA: Customer arrives at Showroom / Service Bay
    SA->>SYS: Create Job Card (Odometer, Fuel Level, Visual Scratch Inspection)
    SA->>SYS: Add Line-Item Estimate (Labour + Spare Parts + Engine Oil)
    SYS-->>C: Sends Push Notification / SMS with Estimate & Approval Link
    C->>SYS: Reviews & Digitally Approves Estimate
    SA->>SYS: Assigns Job Card to Technician
    TECH->>SYS: Starts Work (Pulls approved spare parts from stock)
    TECH->>SYS: Marks Repair Completed & Requests Quality Check (QC)
    SA->>SYS: Conducts Final Road Test & Verifies QC Passed
    SYS->>CASH: Generates Service Invoice
    CASH->>C: Collects Service Payment (Cash / UPI / Card)
    CASH->>SYS: Records Receipt & Issues Gate Pass
    SA->>C: Hands over Vehicle & Keys
    SYS->>C: Updates "My Vehicles" Service History & Logs Maintenance Stamp
```

---

## 2. Job Card State Transitions

```mermaid
stateDiagram-v2
    [*] --> OPEN: Vehicle Received by Advisor
    OPEN --> ESTIMATED: Parts & Labour Estimate Calculated
    ESTIMATED --> APPROVED: Customer Grants Digital/Manual Approval
    APPROVED --> ASSIGNED: Assigned to Bay Technician
    ASSIGNED --> WORK_IN_PROGRESS: Technician Commences Repair
    WORK_IN_PROGRESS --> QC_PENDING: Work Complete; Road Test Required
    QC_PENDING --> QC_PASSED: Quality Inspector Passes Vehicle
    QC_PASSED --> BILLED: Cashier Generates Invoice
    BILLED --> CLOSED: Payment Received & Gate Pass Issued
    CLOSED --> [*]
```

---

## 3. Vehicle Reception & Inspection Checklist

When checking in a two-wheeler, the Service Advisor records:
1. **Odometer Reading:** Recorded in kilometers; validated against previous service history (must be $\ge$ previous reading).
2. **Fuel Level:** Stored as percentage or segment bar (0%, 25%, 50%, 75%, 100%).
3. **Physical Condition:** Interactive touch diagram recording exterior scratches, dents, or broken indicators.
4. **Accessories & Belongings:** Toolkit present (Yes/No), First Aid Kit present (Yes/No), Left/Right Mirrors intact (Yes/No), Helmet stored (Yes/No).
5. **Customer Complaints:** Tagged with categorized issues (e.g., Engine Noise, Brake Squeal, Low Mileage, Chain Slack).

