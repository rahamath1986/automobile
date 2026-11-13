-- Phase 8 Customer App E2E demo seed
-- Tenant: Alagendra Automobiles (ALAGENDRA)
-- Idempotent: fixed UUIDs + ON CONFLICT DO NOTHING.
-- Run with:
--   docker exec -i motosaas_postgres psql -U postgres -d motosaas_db < docs/demo-data/PHASE_8_DEMO_SEED.sql

BEGIN;

-- 1. Tenant -----------------------------------------------------------------
INSERT INTO "Tenants" ("Id", "Code", "LegalName", "TradeName", "PrimaryColor", "SecondaryColor",
                       "Status", "CreatedAt", "UpdatedAt", "IsDeleted")
VALUES ('11111111-1111-1111-1111-111111111111', 'ALAGENDRA',
        'Alagendra Automobiles Private Limited', 'Alagendra Automobiles',
        '#002C6C', '#E11D48', 0, now(), now(), false)
ON CONFLICT ("Id") DO NOTHING;

-- 2. Branch -----------------------------------------------------------------
INSERT INTO "Branches" ("Id", "TenantId", "Code", "Name", "AddressLine1", "City", "State",
                        "PostalCode", "Phone", "Email", "IsHeadquarters", "IsActive",
                        "CreatedAt", "UpdatedAt", "IsDeleted")
VALUES ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111',
        'BLR-IND', 'Indiranagar Showroom', '100 Feet Road, Indiranagar', 'Bengaluru', 'Karnataka',
        '560038', '+91 80 4123 4567', 'indiranagar@alagendra.example', true, true,
        now(), now(), false)
ON CONFLICT ("Id") DO NOTHING;

-- 3. Manufacturer and tenant association ------------------------------------
INSERT INTO "Manufacturers" ("Id", "Code", "Name", "CountryOfOrigin", "IsActive",
                             "CreatedAt", "UpdatedAt", "IsDeleted")
VALUES ('33333333-3333-3333-3333-333333333333', 'YAMAHA', 'Yamaha Motor India', 'Japan', true,
        now(), now(), false)
ON CONFLICT ("Id") DO NOTHING;

INSERT INTO "TenantManufacturers" ("TenantId", "ManufacturerId", "DealerCodeWithOem", "IsPrimary", "CreatedAt")
VALUES ('11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333333',
        'ALG-YAM-001', true, now())
ON CONFLICT ("TenantId", "ManufacturerId") DO NOTHING;

-- 4. Model, variant and colours ---------------------------------------------
-- VehicleCategory: Motorcycle = 0 | FuelType: Petrol = 0
INSERT INTO "VehicleModels" ("Id", "ManufacturerId", "Code", "Name", "Category", "FuelType",
                             "DisplacementCc", "BatteryCapacityKwh", "IsActive",
                             "CreatedAt", "UpdatedAt", "IsDeleted")
VALUES ('44444444-4444-4444-4444-444444444444', '33333333-3333-3333-3333-333333333333',
        'R15V4', 'R15 V4', 0, 0, 155, NULL, true, now(), now(), false)
ON CONFLICT ("Id") DO NOTHING;

INSERT INTO "VehicleVariants" ("Id", "ModelId", "Code", "Name", "BasePrice",
                               "SpecificationsJson", "FeaturesJson", "IsActive",
                               "CreatedAt", "UpdatedAt", "IsDeleted")
VALUES ('55555555-5555-5555-5555-555555555555', '44444444-4444-4444-4444-444444444444',
        'R15V4-STD', 'R15 V4 Standard', 182000,
        '{"displacementCc":155,"powerPs":18.4,"torqueNm":14.2,"mileageKmL":45,"topSpeedKph":136,"kerbWeightKg":142,"fuelTankLitres":11,"seatHeightMm":815,"abs":true,"cooling":"Liquid"}',
        '{"features":["Dual-channel ABS","Traction control","Quick shifter","Assist and slipper clutch","LED headlamp","Y-Connect Bluetooth"]}',
        true, now(), now(), false)
ON CONFLICT ("Id") DO NOTHING;

INSERT INTO "VehicleColors" ("Id", "VariantId", "ColorName", "HexCode", "IsPrimary", "ImageUrl",
                             "CreatedAt", "UpdatedAt", "IsDeleted")
VALUES ('66666666-6666-6666-6666-666666666666', '55555555-5555-5555-5555-555555555555',
        'Racing Blue', '#0031AD', true, 'https://picsum.photos/seed/r15-blue/1200/800',
        now(), now(), false),
       ('77777777-7777-7777-7777-777777777777', '55555555-5555-5555-5555-555555555555',
        'Metallic Red', '#B00020', false, 'https://picsum.photos/seed/r15-red/1200/800',
        now(), now(), false)
ON CONFLICT ("Id") DO NOTHING;

-- 5. Interactive 3D asset (Tier 1 manifest; viewer falls back to procedural GLB
--    rendering when the placeholder CDN URL cannot be fetched) -----------------
INSERT INTO "Assets3D" ("Id", "VariantId", "ColorId", "GlbFileUrl", "UsdzFileUrl",
                        "ModelFileSizeBytes", "HotspotsJson", "CameraPresetsJson", "IsActive",
                        "CreatedAt", "UpdatedAt", "IsDeleted")
VALUES ('abababab-abab-abab-abab-abababababab', '55555555-5555-5555-5555-555555555555', NULL,
        'https://cdn.motosaas.local/assets/yamaha_r15_v4.glb',
        'https://cdn.motosaas.local/assets/yamaha_r15_v4.usdz',
        5400000,
        '[{"id":"engine","title":"155cc VVA engine","description":"Liquid-cooled single with Variable Valve Actuation for strong mid-range pull.","category":"Mechanical","position":{"x":0,"y":0.45,"z":0.05},"specMetric":"18.4 PS @ 10,000 rpm"},{"id":"abs","title":"Dual-channel ABS","description":"Prevents wheel lock-up under hard braking on low-grip surfaces.","category":"Safety","position":{"x":0.12,"y":0.32,"z":0.85},"specMetric":"282 mm front / 220 mm rear discs"},{"id":"cockpit","title":"Y-Connect TFT cockpit","description":"Colour display with call alerts, turn-by-turn navigation and ride stats.","category":"Electrical","position":{"x":0,"y":1.15,"z":-0.25},"specMetric":"Bluetooth telematics"}]',
        '{"heroView":{"position":{"x":2.4,"y":1.2,"z":2.4},"target":{"x":0,"y":0.6,"z":0},"fov":45,"minPolarAngleDeg":5,"maxPolarAngleDeg":75,"minDistanceMeters":1.5,"maxDistanceMeters":6},"profileView":{"position":{"x":3.2,"y":0.8,"z":0},"target":{"x":0,"y":0.6,"z":0},"fov":40,"minPolarAngleDeg":5,"maxPolarAngleDeg":75,"minDistanceMeters":1.5,"maxDistanceMeters":6},"cockpitView":{"position":{"x":0,"y":1.3,"z":-0.4},"target":{"x":0,"y":1,"z":0.2},"fov":50,"minPolarAngleDeg":5,"maxPolarAngleDeg":75,"minDistanceMeters":1.5,"maxDistanceMeters":6},"rearView":{"position":{"x":-2.2,"y":1,"z":-2},"target":{"x":0,"y":0.6,"z":0},"fov":45,"minPolarAngleDeg":5,"maxPolarAngleDeg":75,"minDistanceMeters":1.5,"maxDistanceMeters":6},"topView":{"position":{"x":0,"y":3.5,"z":0.1},"target":{"x":0,"y":0.6,"z":0},"fov":45,"minPolarAngleDeg":5,"maxPolarAngleDeg":75,"minDistanceMeters":1.5,"maxDistanceMeters":6}}',
        true, now(), now(), false)
ON CONFLICT ("Id") DO NOTHING;

-- 6. Staff users (job card FK targets) --------------------------------------
-- UserType: DealerStaff = 1
INSERT INTO "Users" ("Id", "TenantId", "DefaultBranchId", "Username", "Email", "Phone",
                     "PasswordHash", "FullName", "UserType", "IsActive",
                     "CreatedAt", "UpdatedAt", "IsDeleted")
VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111',
        '22222222-2222-2222-2222-222222222222', 'advisor.kiran', 'kiran.advisor@alagendra.example',
        '9800000001', 'TW90b1NhYXNQaGFzZTlTYWx0.YqFwIFrvwotiOrqQ50YtjPsriIMejSdNCLZLvLX73qs=', 'Kiran Shetty', 1, true,
        now(), now(), false),
       ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111',
        '22222222-2222-2222-2222-222222222222', 'tech.suresh', 'suresh.tech@alagendra.example',
        '9800000002', 'TW90b1NhYXNQaGFzZTlTYWx0.YqFwIFrvwotiOrqQ50YtjPsriIMejSdNCLZLvLX73qs=', 'Suresh Rao', 1, true,
        now(), now(), false)
ON CONFLICT ("Id") DO NOTHING;

-- 7. Customer, owned vehicle and showroom stock ------------------------------
INSERT INTO "Customers" ("Id", "TenantId", "FirstName", "LastName", "Phone", "Email",
                         "AddressLine1", "City", "State", "PostalCode",
                         "CreatedAt", "UpdatedAt", "IsDeleted")
VALUES ('88888888-8888-8888-8888-888888888888', '11111111-1111-1111-1111-111111111111',
        'Asha', 'Rao', '9876543210', 'asha.rao@example.com',
        '42, 12th Main, Indiranagar', 'Bengaluru', 'Karnataka', '560038',
        now(), now(), false)
ON CONFLICT ("Id") DO NOTHING;

INSERT INTO "CustomerVehicles" ("Id", "TenantId", "CustomerId", "VariantId", "RegistrationNumber",
                                "ChassisNumber", "EngineNumber", "DeliveryDate",
                                "CreatedAt", "UpdatedAt", "IsDeleted")
VALUES ('99999999-9999-9999-9999-999999999999', '11111111-1111-1111-1111-111111111111',
        '88888888-8888-8888-8888-888888888888', '55555555-5555-5555-5555-555555555555',
        'KA01AB1234', 'ME1RG123456789012', 'G3E4E1234567', now() - interval '120 days',
        now(), now(), false)
ON CONFLICT ("Id") DO NOTHING;

-- InventoryStatus: Available = 2
INSERT INTO "InventoryItems" ("Id", "TenantId", "BranchId", "VariantId", "ColorId",
                              "ChassisNumber", "EngineNumber", "Status", "ManufacturingDate",
                              "ReceivedDate", "PurchaseCost", "ConcurrencyVersion",
                              "CreatedAt", "UpdatedAt", "IsDeleted")
VALUES ('acacacac-acac-acac-acac-acacacacacac', '11111111-1111-1111-1111-111111111111',
        '22222222-2222-2222-2222-222222222222', '55555555-5555-5555-5555-555555555555',
        '66666666-6666-6666-6666-666666666666', 'ME1RG200000000101', 'G3E4E2000000101',
        2, now() - interval '60 days', now() - interval '45 days', 168000, 1,
        now(), now(), false),
       ('adadadad-adad-adad-adad-adadadadadad', '11111111-1111-1111-1111-111111111111',
        '22222222-2222-2222-2222-222222222222', '55555555-5555-5555-5555-555555555555',
        '77777777-7777-7777-7777-777777777777', 'ME1RG200000000102', 'G3E4E2000000102',
        2, now() - interval '60 days', now() - interval '45 days', 168000, 1,
        now(), now(), false)
ON CONFLICT ("Id") DO NOTHING;

-- 8. Existing service appointment + estimated job card (approval flow) -------
INSERT INTO "ServiceBookings" ("Id", "TenantId", "BranchId", "CustomerVehicleId", "ServiceType",
                               "ScheduledDate", "TimeSlot", "CustomerComplaints", "Status",
                               "CreatedAt", "UpdatedAt", "IsDeleted")
VALUES ('cccccccc-cccc-cccc-cccc-cccccccccccc', '11111111-1111-1111-1111-111111111111',
        '22222222-2222-2222-2222-222222222222', '99999999-9999-9999-9999-999999999999',
        'PERIODIC', now() - interval '1 day', '10:00 - 11:00',
        'Chain noise and front brake feel', 'BOOKED', now() - interval '3 days', now(), false)
ON CONFLICT ("Id") DO NOTHING;

-- JobCardStatus: Estimated = 1
INSERT INTO "JobCards" ("Id", "TenantId", "BranchId", "JobCardNumber", "ServiceBookingId",
                        "CustomerVehicleId", "ServiceAdvisorId", "TechnicianId",
                        "OdometerReading", "FuelLevelPercent", "EstimatedCost", "CustomerApproved",
                        "Status", "CreatedAt", "UpdatedAt", "IsDeleted")
VALUES ('dddddddd-dddd-dddd-dddd-dddddddddddd', '11111111-1111-1111-1111-111111111111',
        '22222222-2222-2222-2222-222222222222', 'JC-2026-0001',
        'cccccccc-cccc-cccc-cccc-cccccccccccc', '99999999-9999-9999-9999-999999999999',
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        4200, 60, 2460, false, 1, now() - interval '2 days', now(), false)
ON CONFLICT ("Id") DO NOTHING;

-- JobCardItemType: Labour = 0, SparePart = 1, Consumable = 2
INSERT INTO "JobCardItems" ("Id", "TenantId", "JobCardId", "ItemType", "Description",
                            "Quantity", "UnitPrice", "TotalPrice", "IsApproved",
                            "CreatedAt", "UpdatedAt", "IsDeleted")
VALUES ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '11111111-1111-1111-1111-111111111111',
        'dddddddd-dddd-dddd-dddd-dddddddddddd', 0, 'Periodic service labour', 1, 900, 900, false,
        now(), now(), false),
       ('ffffffff-ffff-ffff-ffff-ffffffffffff', '11111111-1111-1111-1111-111111111111',
        'dddddddd-dddd-dddd-dddd-dddddddddddd', 1, 'Engine oil 10W-40 (1L)', 1.2, 800, 960, false,
        now(), now(), false),
       ('fafafafa-fafa-fafa-fafa-fafafafafafa', '11111111-1111-1111-1111-111111111111',
        'dddddddd-dddd-dddd-dddd-dddddddddddd', 2, 'Chain lube and cleaner', 1, 600, 600, false,
        now(), now(), false)
ON CONFLICT ("Id") DO NOTHING;

COMMIT;
