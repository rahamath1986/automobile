# Known Issues & Risk Register

This document tracks known issues, technical limitations, security watch-items, and risks across all development phases.

---

## 1. Technical Debt & Known Limitations

| Issue ID | Module | Description | Severity | Target Phase | Status |
|---|---|---|---|---|---|
| **ISSUE-001** | Environment | Flutter runtime was not on the global PATH at Phase 0 | Low | Phase 8 | Resolved; Flutter SDK available and `mobile/customer_app` builds/analyzes/tests cleanly. |
| **ISSUE-002** | 3D Graphics | WebGL rendering on low-end budget Android devices may experience high memory consumption with >50MB GLB assets | Medium | Phase 7 | Mitigated by Draco compression, LOD (Level of Detail), and 360-degree image fallback. |
| **ISSUE-003** | RLS Performance | EF Core query compilation with PostgreSQL RLS session variables requires connection pooling reset handling (`DISCARD ALL` or scoped session configuration) | Medium | Phase 2 | Resolved in Phase 8: `TenantRlsConnectionInterceptor` applies `set_config` on connection open and relies on Npgsql pool reset. |
| **ISSUE-004** | Customer Auth | No refresh-token flow for customers; an expired JWT requires phone + OTP re-login | Low | Phase 12 | Accepted; secure-storage restore redirects to login on `401`. Deferred again in Phase 9; revisit when the staff/customer session policy is unified for the staff app. |
| **ISSUE-005** | 3D Showroom | Demo GLB URL (`cdn.motosaas.local`) is not reachable, so the viewer uses the procedural motorcycle fallback | Low | Phase 16 | Accepted for demo; real Draco-compressed GLB/USDZ assets land with Phase 16 seeding. |
| **ISSUE-006** | Pricing | Branch pricing remains an indicative on-road estimate; the binding document is now the Phase 9 quotation | Low | Phase 9 | Resolved in Phase 9: `POST /api/v1/quotations` produces a numbered, server-calculated quotation with an expiry. The catalog pricing endpoint stays an estimate by design. |
| **ISSUE-007** | Notifications | OTP delivery is not integrated with SMS/WhatsApp; the demo returns a fixed OTP for known numbers | Low | Phase 18 | Accepted for local/demo. Wire `INotificationService` before production release. |
| **ISSUE-008** | Demo Data | `PHASE_8_DEMO_SEED.sql` leaves the sample job card awaiting approval; repeatedly approving it changes demo state | Low | Phase 16 | Mitigated: approval is idempotent, and the E2E runner resets the seeded estimate before each run. |
| **ISSUE-009** | Quotations | Quotations are API/JSON only; there is no PDF renderer or WhatsApp/email delivery yet | Medium | Phase 10 | Accepted; staff currently share the breakdown manually. Quotation PDF generation belongs with booking/invoicing. |
| **ISSUE-010** | Quotations | `QTN-…-{seq}` numbering reads the latest daily sequence without a unique retry loop; two simultaneous creates could collide on the unique index | Low | Phase 10 | Accepted for pilot volumes. Add a retry/sequence table when creation becomes concurrent. |
| **ISSUE-011** | CRM | Follow-ups are a manual record; there is no background scheduler that pushes due follow-ups or escalates overdue leads | Low | Phase 12/16 | Accepted; `followUpDue`/`overdueFollowUps` expose the queue, and notifications arrive with the staff app and integrations phase. |
| **ISSUE-012** | Test Rides | Completion records a verified licence number but does not validate its format or check expiry | Low | Phase 17 | Accepted; staff attestation is the current control. Add format/expiry validation with compliance work. |

---

## 2. Security Watchlist

1. **Cross-Tenant Data Exposure:**
   - *Risk:* Accidental omission of tenant filter in direct queries or joins.
   - *Mitigation:* Global query filters in EF Core + PostgreSQL Row-Level Security (RLS) policies + Automated integration tests checking cross-tenant query rejections.
2. **Branch Privilege Escalation:**
   - *Risk:* A staff member assigned to Branch X queries or updates inventory belonging to Branch Y.
   - *Mitigation:* Explicit server-side validation of `BranchId` against employee's assigned branch claims in all mutating endpoints.
3. **Session Replay & Token Leakage:**
   - *Risk:* Switching between Customer and Staff modes on the shared mobile device leaking bearer tokens.
   - *Mitigation:* Hard partition of secure storage keys, forced session destruction and in-memory cache eviction upon mode switch.
4. **Chassis Allocation Race Conditions:**
   - *Risk:* Two concurrent bookings attempting to allocate the same physical two-wheeler chassis number.
   - *Mitigation:* Database-level unique constraint on `ChassisNumber` + serializable transaction isolation during allocation.

