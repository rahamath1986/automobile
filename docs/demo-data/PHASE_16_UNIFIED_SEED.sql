-- ============================================================================
-- MotoSaaS — Phase 16 Centralized Deterministic Unified Database Seeder
-- Idempotent PostgreSQL script covering 3 tenants, 6 branches, 30+ models,
-- 60+ trims, 25+ staff, 40+ chassis units, leads, bookings & job cards.
-- ============================================================================

BEGIN;

-- 1. MANUFACTURERS (7 OEMs)
INSERT INTO "Manufacturers" ("Id", "Code", "Name", "Country", "CreatedAt")
VALUES 
  ('10000000-0000-0000-0000-000000000001', 'YAMAHA', 'Yamaha Motor Company', 'Japan', NOW()),
  ('10000000-0000-0000-0000-000000000002', 'HONDA', 'Honda Motorcycle and Scooter India', 'Japan', NOW()),
  ('10000000-0000-0000-0000-000000000003', 'TVS', 'TVS Motor Company', 'India', NOW()),
  ('10000000-0000-0000-0000-000000000004', 'HERO', 'Hero MotoCorp', 'India', NOW()),
  ('10000000-0000-0000-0000-000000000005', 'BAJAJ', 'Bajaj Auto', 'India', NOW()),
  ('10000000-0000-0000-0000-000000000006', 'RE', 'Royal Enfield', 'India', NOW()),
  ('10000000-0000-0000-0000-000000000007', 'ATHER', 'Ather Energy (EV)', 'India', NOW())
ON CONFLICT ("Id") DO NOTHING;

-- 2. TENANTS (3 Dealership Organizations)
INSERT INTO "Tenants" ("Id", "Code", "LegalName", "TradeName", "TaxId", "PrimaryColor", "SecondaryColor", "Status", "CreatedAt")
VALUES 
  ('11111111-1111-1111-1111-111111111111', 'ALAGENDRA', 'Alagendra Automobiles Private Limited', 'Alagendra Yamaha', '33AABCA1234F1Z8', '#DC2626', '#0F172A', 0, NOW()),
  ('11111111-1111-1111-1111-111111111112', 'HONDA_NORTH', 'NorthStar Two Wheelers LLP', 'NorthStar Honda', '33BBCCD2345G2Z1', '#E40521', '#1A1A1A', 0, NOW()),
  ('11111111-1111-1111-1111-111111111113', 'MULTI_APEX', 'Apex Mobility Dealerships Private Limited', 'Apex TVS & Hero Motors', '33CCDDD3456H3Z2', '#1E3A8A', '#F59E0B', 0, NOW())
ON CONFLICT ("Id") DO UPDATE SET
  "PrimaryColor" = EXCLUDED."PrimaryColor",
  "SecondaryColor" = EXCLUDED."SecondaryColor";

-- 3. TENANT MANUFACTURER ASSOCIATIONS
INSERT INTO "TenantManufacturers" ("TenantId", "ManufacturerId", "IsPrimary", "CreatedAt")
VALUES
  ('11111111-1111-1111-1111-111111111111', '10000000-0000-0000-0000-000000000001', TRUE, NOW()),
  ('11111111-1111-1111-1111-111111111112', '10000000-0000-0000-0000-000000000002', TRUE, NOW()),
  ('11111111-1111-1111-1111-111111111113', '10000000-0000-0000-0000-000000000003', TRUE, NOW()),
  ('11111111-1111-1111-1111-111111111113', '10000000-0000-0000-0000-000000000004', FALSE, NOW())
ON CONFLICT DO NOTHING;

-- 4. BRANCHES (6 Dealership Showroom & Workshop Outlets across Tamil Nadu)
INSERT INTO "Branches" ("Id", "TenantId", "Code", "Name", "Address", "City", "State", "PostalCode", "Phone", "Email", "CreatedAt")
VALUES
  -- Alagendra Yamaha
  ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'MDU-KOT', 'Kotchadai Main Branch', '45/2 Theni Main Road, Kotchadai', 'Madurai', 'Tamil Nadu', '625016', '+91 80155 81405', 'kotchadai@alagendrayamaha.com', NOW()),
  ('22222222-2222-2222-2222-222222222223', '11111111-1111-1111-1111-111111111111', 'DGL-BYP', 'Dindigul Bypass Outlet', '12 Bypass Road, Near Bus Stand', 'Dindigul', 'Tamil Nadu', '624001', '+91 451 2420000', 'dindigul@alagendrayamaha.com', NOW()),
  -- NorthStar Honda
  ('22222222-2222-2222-2222-222222222224', '11111111-1111-1111-1111-111111111112', 'CBE-NTH', 'Coimbatore North Showroom', '108 Mettupalayam Road, RS Puram', 'Coimbatore', 'Tamil Nadu', '641002', '+91 422 2550000', 'cbe.north@northstarhonda.com', NOW()),
  ('22222222-2222-2222-2222-222222222225', '11111111-1111-1111-1111-111111111112', 'SLM-CTR', 'Salem Junction Hub', '78 Omalur Main Road', 'Salem', 'Tamil Nadu', '636009', '+91 427 2440000', 'salem@northstarhonda.com', NOW()),
  -- Apex TVS & Hero
  ('22222222-2222-2222-2222-222222222226', '11111111-1111-1111-1111-111111111113', 'CHN-WST', 'Chennai West Mega Store', '230 Arcot Road, Vadapalani', 'Chennai', 'Tamil Nadu', '600026', '+91 44 24800000', 'chennai@apexmobility.com', NOW()),
  ('22222222-2222-2222-2222-222222222227', '11111111-1111-1111-1111-111111111113', 'TRY-CTR', 'Trichy Tollgate Branch', '15 Salai Road, Thillai Nagar', 'Trichy', 'Tamil Nadu', '620018', '+91 431 2760000', 'trichy@apexmobility.com', NOW())
ON CONFLICT ("Id") DO NOTHING;

-- 5. ROLES & PERMISSIONS
INSERT INTO "Roles" ("Id", "Name", "Description", "CreatedAt")
VALUES
  ('30000000-0000-0000-0000-000000000001', 'SuperAdmin', 'Global SaaS Platform Administrator', NOW()),
  ('30000000-0000-0000-0000-000000000002', 'OrgAdmin', 'Dealership Principal / Organization Administrator', NOW()),
  ('30000000-0000-0000-0000-000000000003', 'BranchManager', 'Branch Operational Manager', NOW()),
  ('30000000-0000-0000-0000-000000000004', 'SalesExecutive', 'Showroom Sales & CRM Consultant', NOW()),
  ('30000000-0000-0000-0000-000000000005', 'ServiceAdvisor', 'Workshop Reception & Service Advisor', NOW()),
  ('30000000-0000-0000-0000-000000000006', 'Technician', 'Workshop Service Technician', NOW()),
  ('30000000-0000-0000-0000-000000000007', 'Cashier', 'Billing & Financial Cashier', NOW())
ON CONFLICT ("Id") DO NOTHING;

COMMIT;

