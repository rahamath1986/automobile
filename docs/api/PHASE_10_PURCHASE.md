# Phase 10 purchase, payments and delivery

Apply the `Phase10Purchase` EF Core migration before calling these endpoints.
Use a staff token for the booking branch. Customers can retrieve invoices issued
to their own customer ID.

| Method and route | Request body | Staff access |
|---|---|---|
| `POST /api/v1/bookings` | `{"quotationId":"<guid>"}` | Sales |
| `GET /api/v1/bookings/{id}` | | Branch staff |
| `POST /api/v1/billing/payments` | `{"bookingId":"<guid>","requestId":"<guid>","amount":5000,"mode":0}` | Cashier or branch manager |
| `POST /api/v1/inventory/allocate` | `{"bookingId":"<guid>","inventoryItemId":"<guid>"}` | Sales |
| `POST /api/v1/billing/invoices/generate` | `{"bookingId":"<guid>"}` | Cashier or branch manager |
| `GET /api/v1/billing/invoices/{id}` | | Branch staff or owning customer |
| `PUT /api/v1/bookings/{id}/inspection` | `{"passed":true,"notes":"Inspection completed"}` | Technician, service advisor or branch manager |
| `POST /api/v1/bookings/{id}/handover` | `{"recipient":"Customer name","registrationNumber":"TN58AB1234"}` | Sales |

Sales includes sales executives, sales managers, and branch managers. SaaS admins
with a tenant context can also operate the endpoints.

Confirmation snapshots the on-road total from an active, unexpired quotation.
The first payment is recorded as the booking amount. Each successful payment
reduces the balance. Payment modes are cash `0`, UPI `1`, card `2`, net banking
`3`, financier `4`, and bank transfer `5`. Send `transactionRef` for non-cash
payments. The cashier records funds received outside the API.

Use a new request ID for each payment and reuse it with the same inputs when
retrying. A repeat returns the existing receipt. A concurrent write can return
`409`; refresh the booking and retry the original operation with the same ID.

The invoice endpoint generates one DEMO-labeled invoice after payment in full
and chassis allocation. The invoice carries the quoted on-road total. The
quotation has no separate GST breakdown, so the demo invoice has no separate tax
charge.

Record notes for a failed pre-delivery inspection. Handover requires a passed
inspection, a paid invoice and the allocated chassis. Handover marks the booking
and chassis delivered, logs the inventory movement, and creates the customer's
owned vehicle for future service bookings.
