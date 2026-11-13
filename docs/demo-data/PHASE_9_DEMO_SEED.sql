-- Phase 9 Sales & CRM demo seed
-- Tenant: Alagendra Automobiles (ALAGENDRA), branch: Indiranagar Showroom.
-- Run AFTER docs/demo-data/PHASE_8_DEMO_SEED.sql.
-- Idempotent: fixed UUIDs + ON CONFLICT DO NOTHING / targeted updates.
-- Run with:
--   docker exec -i motosaas_postgres psql -U postgres -d motosaas_db < docs/demo-data/PHASE_9_DEMO_SEED.sql
--
-- Demo staff logins (all use password Demo@123):
--   manager.priya / ALAGENDRA  -> BranchManager + SalesManager
--   advisor.kiran / ALAGENDRA  -> SalesExecutive
--   sales.arjun   / ALAGENDRA  -> SalesExecutive

BEGIN;

-- 1. Roles ------------------------------------------------------------------
INSERT INTO "Roles" ("Id", "TenantId", "Name", "Description", "IsSystemRole",
                     "CreatedAt", "UpdatedAt", "IsDeleted")
VALUES
  ('c0000001-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111',
   'SalesExecutive', 'Works assigned leads, follow-ups and test rides.', true, now(), now(), false),
  ('c0000002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111',
   'SalesManager', 'Owns branch pipeline, assignment and discount approvals.', true, now(), now(), false),
  ('c0000003-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111',
   'BranchManager', 'Full branch operations visibility.', true, now(), now(), false),
  ('c0000004-0000-0000-0000-000000000004', '11111111-1111-1111-1111-111111111111',
   'ServiceAdvisor', 'Service reception and job card ownership.', true, now(), now(), false),
  ('c0000005-0000-0000-0000-000000000005', '11111111-1111-1111-1111-111111111111',
   'Technician', 'Workshop technician.', true, now(), now(), false)
ON CONFLICT ("Id") DO NOTHING;

-- 2. Demo staff users -------------------------------------------------------
-- PBKDF2-SHA256, 100000 iterations, password: Demo@123
INSERT INTO "Users" ("Id", "TenantId", "DefaultBranchId", "Username", "Email", "Phone",
                     "PasswordHash", "FullName", "UserType", "IsActive",
                     "CreatedAt", "UpdatedAt", "IsDeleted")
VALUES
  ('e1e1e1e1-e1e1-e1e1-e1e1-e1e1e1e1e1e1', '11111111-1111-1111-1111-111111111111',
   '22222222-2222-2222-2222-222222222222', 'sales.arjun', 'arjun.sales@alagendra.example',
   '9800000003', 'TW90b1NhYXNQaGFzZTlTYWx0.YqFwIFrvwotiOrqQ50YtjPsriIMejSdNCLZLvLX73qs=',
   'Arjun Kumar', 1, true, now(), now(), false),
  ('f1f1f1f1-f1f1-f1f1-f1f1-f1f1f1f1f1f1', '11111111-1111-1111-1111-111111111111',
   '22222222-2222-2222-2222-222222222222', 'manager.priya', 'priya.manager@alagendra.example',
   '9800000004', 'TW90b1NhYXNQaGFzZTlTYWx0.YqFwIFrvwotiOrqQ50YtjPsriIMejSdNCLZLvLX73qs=',
   'Priya Menon', 1, true, now(), now(), false)
ON CONFLICT ("Id") DO NOTHING;

-- Repair Phase 8 demo users that were seeded with placeholder password hashes.
UPDATE "Users"
SET "PasswordHash" = 'TW90b1NhYXNQaGFzZTlTYWx0.YqFwIFrvwotiOrqQ50YtjPsriIMejSdNCLZLvLX73qs=',
    "UpdatedAt" = now()
WHERE "Id" IN ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
               'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb')
  AND "PasswordHash" NOT LIKE '%.%';

-- 3. Role assignments -------------------------------------------------------
INSERT INTO "UserRoles" ("UserId", "RoleId", "BranchId")
VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'c0000001-0000-0000-0000-000000000001',
   '22222222-2222-2222-2222-222222222222'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'c0000004-0000-0000-0000-000000000004',
   '22222222-2222-2222-2222-222222222222'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'c0000005-0000-0000-0000-000000000005',
   '22222222-2222-2222-2222-222222222222'),
  ('e1e1e1e1-e1e1-e1e1-e1e1-e1e1e1e1e1e1', 'c0000001-0000-0000-0000-000000000001',
   '22222222-2222-2222-2222-222222222222'),
  ('f1f1f1f1-f1f1-f1f1-f1f1-f1f1f1f1f1f1', 'c0000002-0000-0000-0000-000000000002',
   '22222222-2222-2222-2222-222222222222'),
  ('f1f1f1f1-f1f1-f1f1-f1f1-f1f1f1f1f1f1', 'c0000003-0000-0000-0000-000000000003',
   '22222222-2222-2222-2222-222222222222')
ON CONFLICT ("UserId", "RoleId", "BranchId") DO NOTHING;

-- 4. Demo customer ----------------------------------------------------------
INSERT INTO "Customers" ("Id", "TenantId", "FirstName", "LastName", "Phone", "Email",
                         "AddressLine1", "City", "State", "PostalCode",
                         "CreatedAt", "UpdatedAt", "IsDeleted")
VALUES ('a8000001-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111',
        'Rahul', 'Nair', '+919812345678', 'rahul.nair@example.com',
        '18, 5th Block, Koramangala', 'Bengaluru', 'Karnataka', '560095',
        now(), now(), false)
ON CONFLICT ("Id") DO NOTHING;

-- 5. Sample pipeline leads --------------------------------------------------
-- EnquiryStatus: New=0, Contacted=1, TestRide=2, Quoted=3, Booked=4, Lost=5
-- EnquirySource: WalkIn=0, MobileApp=1, Web=2, Phone=3
INSERT INTO "Enquiries" ("Id", "TenantId", "BranchId", "CustomerId", "VariantId", "ColorId",
                         "AssignedSalesExecId", "Status", "Source", "ExpectedPurchaseDate",
                         "Notes", "LostReason", "LastContactedAt", "NextFollowUpAt",
                         "CreatedAt", "UpdatedAt", "IsDeleted")
VALUES
  ('a9000001-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111',
   '22222222-2222-2222-2222-222222222222', '88888888-8888-8888-8888-888888888888',
   '55555555-5555-5555-5555-555555555555', '66666666-6666-6666-6666-666666666666',
   'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 0, 0, now() + interval '20 days',
   'Walk-in lead interested in the blue R15; wants an exchange quote for a 2019 FZ.',
   NULL, now() - interval '3 days', now() - interval '1 day',
   now() - interval '4 days', now() - interval '3 days', false),

  ('a9000002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111',
   '22222222-2222-2222-2222-222222222222', 'a8000001-0000-0000-0000-000000000001',
   '55555555-5555-5555-5555-555555555555', '66666666-6666-6666-6666-666666666666',
   'e1e1e1e1-e1e1-e1e1-e1e1-e1e1e1e1e1e1', 3, 3, now() + interval '10 days',
   'Phone enquiry; quotation shared on WhatsApp after test ride.',
   NULL, now() - interval '1 day', now() + interval '2 days',
   now() - interval '8 days', now() - interval '1 day', false),

  ('a9000003-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111',
   '22222222-2222-2222-2222-222222222222', '88888888-8888-8888-8888-888888888888',
   '55555555-5555-5555-5555-555555555555', '77777777-7777-7777-7777-777777777777',
   'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 2, 1, now() + interval '15 days',
   'Booked a test ride for the red R15 through the customer app.',
   NULL, now() - interval '2 days', now() + interval '1 day',
   now() - interval '5 days', now() - interval '2 days', false),

  ('a9000004-0000-0000-0000-000000000004', '11111111-1111-1111-1111-111111111111',
   '22222222-2222-2222-2222-222222222222', 'a8000001-0000-0000-0000-000000000001',
   '55555555-5555-5555-5555-555555555555', '66666666-6666-6666-6666-666666666666',
   'e1e1e1e1-e1e1-e1e1-e1e1-e1e1e1e1e1e1', 4, 0, now() + interval '2 days',
   'Booking amount received; vehicle allocation pending Phase 10 delivery workflow.',
   NULL, now() - interval '6 days', NULL,
   now() - interval '14 days', now() - interval '6 days', false),

  ('a9000005-0000-0000-0000-000000000005', '11111111-1111-1111-1111-111111111111',
   '22222222-2222-2222-2222-222222222222', '88888888-8888-8888-8888-888888888888',
   '55555555-5555-5555-5555-555555555555', '66666666-6666-6666-6666-666666666666',
   'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 5, 2, NULL,
   'Web lead that went cold after two follow-ups.',
   'Purchased a competitor motorcycle in a different city.',
   now() - interval '12 days', NULL,
   now() - interval '20 days', now() - interval '12 days', false)
ON CONFLICT ("Id") DO NOTHING;

-- 6. Follow-up history ------------------------------------------------------
-- Channel: Phone=0, WhatsApp=1, Sms=2, Email=3, InPerson=4
-- Outcome: Contacted=0, NotReachable=1, Interested=2, NotInterested=3,
--          TestRideBooked=4, QuotationShared=5, Converted=6, Lost=7
INSERT INTO "EnquiryFollowUps" ("Id", "TenantId", "BranchId", "EnquiryId", "PerformedByUserId",
                                "Channel", "Outcome", "Notes", "ContactedAt", "NextFollowUpAt",
                                "CreatedAt", "UpdatedAt", "IsDeleted")
VALUES
  ('b1000001-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111',
   '22222222-2222-2222-2222-222222222222', 'a9000001-0000-0000-0000-000000000001',
   'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 0, 0,
   'Discussed exchange value and RTO breakup. Customer will visit on Saturday.',
   now() - interval '3 days', now() - interval '1 day',
   now() - interval '3 days', now() - interval '3 days', false),

  ('b1000002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111',
   '22222222-2222-2222-2222-222222222222', 'a9000002-0000-0000-0000-000000000002',
   'e1e1e1e1-e1e1-e1e1-e1e1-e1e1e1e1e1e1', 1, 5,
   'Shared the on-road quotation PDF. Customer is checking finance eligibility.',
   now() - interval '1 day', now() + interval '2 days',
   now() - interval '1 day', now() - interval '1 day', false),

  ('b1000003-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111',
   '22222222-2222-2222-2222-222222222222', 'a9000003-0000-0000-0000-000000000003',
   'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 0, 4,
   'Test ride confirmed for tomorrow at the Indiranagar showroom.',
   now() - interval '2 days', now() + interval '1 day',
   now() - interval '2 days', now() - interval '2 days', false)
ON CONFLICT ("Id") DO NOTHING;

-- 7. Test rides -------------------------------------------------------------
-- TestRideStatus: Scheduled=0, Completed=1, Cancelled=2, NoShow=3
INSERT INTO "TestRides" ("Id", "TenantId", "BranchId", "EnquiryId", "CustomerId", "VariantId",
                         "ScheduledAt", "CompletedAt", "Status", "DrivingLicenseNumber",
                         "FeedbackNotes", "CreatedAt", "UpdatedAt", "IsDeleted")
VALUES
  ('b2000001-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111',
   '22222222-2222-2222-2222-222222222222', 'a9000003-0000-0000-0000-000000000003',
   '88888888-8888-8888-8888-888888888888', '55555555-5555-5555-5555-555555555555',
   now() + interval '1 day', NULL, 0, 'KA0120230001234',
   NULL, now() - interval '2 days', now() - interval '2 days', false),

  ('b2000002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111',
   '22222222-2222-2222-2222-222222222222', 'a9000002-0000-0000-0000-000000000002',
   'a8000001-0000-0000-0000-000000000001', '55555555-5555-5555-5555-555555555555',
   now() - interval '3 days', now() - interval '3 days' + interval '25 minutes', 1,
   'KA0320220005678',
   'Licence verified. Customer liked the mid-range pull and quick shifter.',
   now() - interval '5 days', now() - interval '3 days', false)
ON CONFLICT ("Id") DO NOTHING;

-- 8. Quotations -------------------------------------------------------------
-- QuotationStatus: Active=0, Converted=1, Expired=2
-- Karnataka RTO 12% = 21,840; insurance 3.5% = 6,370; accessories 5,000;
-- handling 2,500; discount 3,000; total on-road = 2,14,710.
INSERT INTO "Quotations" ("Id", "TenantId", "BranchId", "QuotationNumber", "EnquiryId",
                          "CustomerId", "VariantId", "ColorId", "ExShowroomPrice",
                          "RtoCharges", "InsuranceCharges", "AccessoriesCharges",
                          "HandlingCharges", "DiscountAmount", "TotalOnRoadPrice",
                          "ValidUntil", "Status", "Notes",
                          "CreatedAt", "UpdatedAt", "IsDeleted")
VALUES
  ('c9000001-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111',
   '22222222-2222-2222-2222-222222222222', 'QTN-BLRIND-20261113-0001',
   'a9000002-0000-0000-0000-000000000002', 'a8000001-0000-0000-0000-000000000001',
   '55555555-5555-5555-5555-555555555555', '66666666-6666-6666-6666-666666666666',
   182000, 21840, 6370, 5000, 2500, 3000, 214710,
   now() + interval '6 days', 0,
   'Includes touring accessory pack. Discount approved by branch manager.',
   now() - interval '1 day', now() - interval '1 day', false),

  ('c9000002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111',
   '22222222-2222-2222-2222-222222222222', 'QTN-BLRIND-20261113-0002',
   'a9000004-0000-0000-0000-000000000004', 'a8000001-0000-0000-0000-000000000001',
   '55555555-5555-5555-5555-555555555555', '66666666-6666-6666-6666-666666666666',
   182000, 21840, 6370, 5000, 2500, 3000, 214710,
   now() + interval '2 days', 1,
   'Converted after booking amount receipt.',
   now() - interval '7 days', now() - interval '6 days', false)
ON CONFLICT ("Id") DO NOTHING;

COMMIT;
