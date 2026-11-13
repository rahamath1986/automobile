# Phase 8 — Customer App UX Specification

**App path:** `mobile/customer_app`  
**Design system:** Material 3, tenant-driven white-label palette, card-first layout, 8-point spacing rhythm  
**Primary user:** Two-wheeler buyer or owner on a mid-range Android/iOS phone, often on mobile data

---

## 1. Experience Principles

1. **Guest-first discovery.** A visitor can browse the catalog, inspect a model in 3D, compare variants, and see a branch on-road estimate without creating an account. Sign-in is requested only when the user needs ownership data or wants to act on a lead.
2. **One decision per screen.** Each step (model → variant/colour → branch price → enquiry/test ride) answers a single question and keeps the primary action visible.
3. **Never dead-end.** Empty, error, and signed-out states always offer a next action (retry, browse, sign in, call the showroom).
4. **Honest pricing.** Every on-road figure is labelled as an estimate with a disclaimer. No UI element implies a binding quote.
5. **Progressive 3D.** The viewer starts at the best available tier and degrades quietly; users are never blocked by a missing asset.
6. **Status clarity.** Enquiries, test rides, bookings, and job cards use a shared status-chip vocabulary with human-readable labels.

---

## 2. Information Architecture

### 2.1 Bottom navigation (5 tabs)

| Tab | Route | Purpose | Auth |
|---|---|---|---|
| **Showroom** | `/home` | Branding header, search, category filters, model cards, featured 3D entry point | Guest |
| **Compare** | `/compare` | Side-by-side table for up to 3 variants; empty state prompts browsing | Guest |
| **Activity** | `/activity` | Enquiry and test-ride history with status chips | Customer |
| **Garage** | `/garage` | Owned vehicles, bookings, service booking and tracking | Customer |
| **Profile** | `/profile` | Account summary, edit profile, sign out | Customer |

Signed-out users can open Activity/Garage/Profile tabs; each renders a consistent `LoginRequired` panel explaining the benefit and linking to `/login`.

### 2.2 Secondary routes

| Route | Screen | Entry points |
|---|---|---|
| `/models/:modelId` | Model detail (hero, specs, variants, colours, branch pricing, CTAs) | Model card, search result |
| `/viewer/:variantId` | 3D / 360 / gallery showroom | "View in 3D" from model detail or card badge |
| `/enquiry` | Enquiry form | "Enquire" CTA on model detail |
| `/test-ride` | Test-ride form | "Book test ride" CTA |
| `/login` → `/otp` | Phone entry → 6-digit OTP | Protected tabs and CTAs |
| `/profile/edit` | Edit profile form | Profile tab |
| `/service/book` | Service booking form | Garage → "Book service" |
| `/service/track/:bookingId` | Service tracking timeline | Booking card / "Track service" |

Deep links carry the selected variant, colour, and branch through query parameters so back navigation preserves context.

---

## 3. Key Flows

### 3.1 Guest discovery → lead

1. Launch → branding loads (tenant trade name, colours, manufacturer list).
2. Showroom lists models with hero image, starting price, variant/colour counts, and a 3D badge when an asset exists.
3. Tap a model → model detail with sticky primary CTA.
4. Switch variant chips and colour swatches; hero image and price update.
5. Select a branch → on-road estimate card expands (ex-showroom, RTO, insurance, handling, total, stock).
6. Tap **Enquire** or **Book test ride** → form pre-filled with variant/colour/branch.
7. Guest form collects first name, phone, optional last name/email/notes. Submit → success confirmation with "A sales executive will contact you" and a link to sign in to track status.

### 3.2 3D showroom

1. Tap the 3D badge or "View in 3D".
2. Viewer opens full-screen with a loading shimmer while the manifest loads.
3. Tier behaviour:
   - **Tier 1:** interactive GLB with orbit, pinch zoom, colour swap, camera presets, hotspot pins.
   - **Tier 2:** auto-playing 360 frame sequence with drag-to-scrub.
   - **Tier 3:** swipeable multi-angle gallery.
4. Bottom sheet lists colour swatches and camera presets (Hero, Profile, Cockpit, Rear, Top); hotspot taps open a spec card.
5. If the GLB cannot be fetched, a procedural motorcycle renders with the same controls; a subtle "Preview model" label avoids implying asset fidelity.
6. Close returns to the model detail with the previously selected variant/colour preserved.

### 3.3 Comparison

1. Add variants from model detail or card long-press; tray shows count (max 3).
2. Fourth add is rejected with a snackbar ("Compare up to 3 variants").
3. Compare tab renders a horizontally scrollable table: price, displacement/battery, power, torque, mileage/range, weight, seat height, ABS, features.
4. Remove a column inline; clearing all shows an empty state with "Browse showroom".

### 3.4 OTP sign-in

1. Enter 10-digit Indian mobile number → **Send OTP**.
2. OTP screen shows the masked number and a 6-digit field; resend is available after a short cooldown.
3. Success stores the token, loads branding/session, and returns to the tab or CTA that triggered login.
4. Invalid/expired OTP shows an inline error and keeps the entered number.
5. Session restore on launch is silent; a `401` clears the session and returns to login with a friendly message.

### 3.5 Garage → service → tracking

1. Garage lists owned vehicles: hero image, model/variant, registration, masked chassis, last service status.
2. **Book service** → choose vehicle, branch, service type, date (today…+90 days), slot, complaints.
3. Submit → success sheet with booking id and "Track service" action.
4. Tracking screen shows a vertical timeline (Booked → Estimate → Approved → In progress → Quality check → Ready → Completed), a progress bar, job card summary, technician name, and itemised estimate.
5. When `awaitingCustomerApproval = true`, a prominent estimate card lists labour/parts/consumables with an **Approve estimate** button. Approval is optimistic-idempotent: the timeline and badge update to Approved.
6. If no job card exists yet, the timeline shows Booked as current and explains that the advisor will create the job card at check-in.

---

## 4. Visual & Interaction Rules

### 4.1 Colour and branding

- Primary/secondary colours come from `GET /branding/current`; fallbacks are deep blue `#002C6C` and red `#E60012`.
- Scaffold background `#F4F6FB`; cards white with `#E8EDF5` border and 20 px radius.
- Status chips use semantic tints (info, success, warning, danger) independent of tenant branding so meaning stays stable.
- Colour swatches show a check mark and border when selected; the name is always shown as text for accessibility.

### 4.2 Typography and spacing

- Page title 20 px / 700; section title 16 px / 700; body 14 px; caption 12 px.
- Spacing scale: 4, 8, 12, 16, 24, 32 px. Cards use 16–20 px padding.
- Prices use tabular figures and the Indian grouping formatter (`₹2,12,710`).

### 4.3 Touch targets and feedback

- Minimum 48×48 dp touch targets; primary buttons are 52 px tall and full-width inside forms.
- Every async action shows a button-level spinner and disables repeat submission.
- Destructive/irreversible actions (sign out, clear comparison) confirm inline or via dialog.
- Haptics are not required; visual state changes must be sufficient.

### 4.4 Loading, empty, and error states

| State | Pattern |
|---|---|
| Initial load | Skeleton cards or centred spinner with brand mark |
| Empty list | Icon + one-line explanation + primary action |
| Recoverable error | Message, "Try again" button, and secondary "Browse showroom" |
| Signed out | `LoginRequired` panel with benefit copy and "Sign in" |
| Offline/Dio failure | "Couldn't reach the showroom. Check your connection." + retry |
| 3D asset failure | Procedural preview + non-blocking notice |

### 4.5 Forms

- Labels above fields; placeholders are examples, not labels.
- Validation fires on submit and re-validates on change after the first error.
- Phone accepts `98765 43210`, `+91 98765 43210`, and `09876543210`; normalized before submit.
- Date pickers constrain to valid ranges (test ride +60 days, service +90 days) and default to the next sensible day.
- Errors are inline under the field; a summary snackbar appears only for server-side failures.

---

## 5. Content & Tone

- Plain, helpful English; no internal jargon. Backend enums are humanised (`WORK_IN_PROGRESS` → "In progress").
- Pricing copy: "Indicative on-road estimate" and "Final quotation is issued by the dealership."
- Lead confirmation: "Enquiry submitted. A sales executive will contact you shortly."
- Test ride: "Request received. The dealership will confirm your slot."
- Service approval: "Approve estimate" (not "Accept quote") to match the pre-invoice stage.
- Avoid promising availability: show "2 units in stock at this branch" only from live inventory counts.

---

## 6. Accessibility

- All images have semantic labels (`R15 V4 in Racing Blue`), and 3D controls expose text alternatives.
- Colour is never the sole carrier of meaning: status chips include text, selected swatches include a check.
- Text contrast targets WCAG AA against card and scaffold backgrounds.
- Dynamic type: layouts use wrapping/flexible text; prices and chips can grow without clipping.
- Screen-reader order follows visual order; the comparison table exposes row headers.

---

## 7. Responsive Behaviour

- Phones (≤ 600 dp): single-column lists, horizontal chip rows, full-width CTAs.
- Large phones/tablets (≥ 600 dp): catalog grid of 2–3 cards; model detail keeps a max content width of ~720 dp.
- Landscape 3D viewer hides the bottom sheet behind a "Colours & views" button.
- Safe areas respected for notched devices; bottom navigation uses `NavigationBar` with labels always visible.

---

## 8. QA Checklist

- [ ] Guest can complete discovery → pricing → enquiry without signing in.
- [ ] Guest test ride rejects past dates and dates beyond 60 days with a readable message.
- [ ] Sign-in returns the user to the originating tab or CTA.
- [ ] Expired token routes to login without a crash loop.
- [ ] Profile edits persist after app restart.
- [ ] Garage shows masked chassis/engine identifiers only.
- [ ] Booking rejects past dates and unknown service types.
- [ ] Tracking shows the correct current stage and progress for each job card status.
- [ ] Estimate approval updates the timeline and is safe to repeat.
- [ ] Comparison caps at 3 variants and survives tab switches.
- [ ] 3D viewer falls back to procedural preview when the GLB is unavailable.
- [ ] Empty/error states always offer a next action.
- [ ] All primary actions remain reachable at large text sizes.
