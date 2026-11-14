using Microsoft.EntityFrameworkCore;
using MotoSaaS.Application.Common.Interfaces;
using MotoSaaS.Application.Features.Catalog.Interfaces;
using MotoSaaS.Application.Features.Catalog.Models;
using MotoSaaS.Domain.Catalog;
using MotoSaaS.Domain.Inventory;
using MotoSaaS.Domain.Tenancy;

namespace MotoSaaS.Application.Features.Catalog.Services;

public class VehicleCatalogService : IVehicleCatalogService
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentTenantContext _tenantContext;

    public VehicleCatalogService(
        IApplicationDbContext context,
        ICurrentTenantContext tenantContext)
    {
        _context = context;
        _tenantContext = tenantContext;
    }

    public async Task<List<VehicleModelSummaryDto>> GetModelsAsync(
        VehicleCategory? category = null,
        Guid? manufacturerId = null,
        FuelType? fuelType = null,
        CancellationToken cancellationToken = default)
    {
        var query = _context.VehicleModels
            .Include(m => m.Manufacturer)
            .Include(m => m.Variants)
                .ThenInclude(v => v.Colors)
            .Include(m => m.Variants)
                .ThenInclude(v => v.Assets3D)
            .Where(m => m.IsActive)
            .AsNoTracking();

        if (category.HasValue)
        {
            query = query.Where(m => m.Category == category.Value);
        }

        if (manufacturerId.HasValue)
        {
            query = query.Where(m => m.ManufacturerId == manufacturerId.Value);
        }

        if (fuelType.HasValue)
        {
            query = query.Where(m => m.FuelType == fuelType.Value);
        }

        var list = await query.ToListAsync(cancellationToken);
        if (list.Count == 0)
        {
            return GetDefaultCatalog(category, manufacturerId, fuelType);
        }

        return list.Select(m => MapToSummary(m)).ToList();
    }

    public async Task<List<VehicleModelSummaryDto>> GetCatalogForTenantAsync(
        Guid tenantId,
        VehicleCategory? category = null,
        CancellationToken cancellationToken = default)
    {
        // 1. Get associated manufacturers for this tenant
        var associatedOemIds = await _context.TenantManufacturers
            .Where(tm => tm.TenantId == tenantId)
            .Select(tm => tm.ManufacturerId)
            .ToListAsync(cancellationToken);

        if (associatedOemIds.Count == 0)
        {
            // Default pilot fallback (Yamaha)
            var defaultYamaha = await _context.Manufacturers
                .FirstOrDefaultAsync(m => m.Code == "YAMAHA", cancellationToken);
            if (defaultYamaha != null)
            {
                associatedOemIds.Add(defaultYamaha.Id);
            }
        }

        var query = _context.VehicleModels
            .Include(m => m.Manufacturer)
            .Include(m => m.Variants)
                .ThenInclude(v => v.Colors)
            .Include(m => m.Variants)
                .ThenInclude(v => v.Assets3D)
            .Where(m => m.IsActive && associatedOemIds.Contains(m.ManufacturerId))
            .AsNoTracking();

        if (category.HasValue)
        {
            query = query.Where(m => m.Category == category.Value);
        }

        var list = await query.ToListAsync(cancellationToken);
        if (list.Count == 0)
        {
            return GetDefaultCatalog(category, null, null);
        }

        return list.Select(m => MapToSummary(m)).ToList();
    }

    public async Task<VehicleModelDetailDto?> GetModelDetailsByIdAsync(Guid modelId, CancellationToken cancellationToken = default)
    {
        var model = await _context.VehicleModels
            .Include(m => m.Manufacturer)
            .Include(m => m.Variants.Where(v => v.IsActive))
                .ThenInclude(v => v.Colors)
            .Include(m => m.Variants.Where(v => v.IsActive))
                .ThenInclude(v => v.Assets3D.Where(a => a.IsActive))
            .AsNoTracking()
            .FirstOrDefaultAsync(m => m.Id == modelId, cancellationToken);

        if (model == null)
        {
            // Demo-mode fallback so the customer app remains browsable before Phase 16 seeding.
            return GetDefaultModelDetail(modelId);
        }

        var summary = MapToSummary(model);
        return new VehicleModelDetailDto
        {
            Id = summary.Id,
            ManufacturerId = summary.ManufacturerId,
            ManufacturerName = summary.ManufacturerName,
            ManufacturerCode = summary.ManufacturerCode,
            Code = summary.Code,
            Name = summary.Name,
            Category = summary.Category,
            FuelType = summary.FuelType,
            DisplacementCc = summary.DisplacementCc,
            BatteryCapacityKwh = summary.BatteryCapacityKwh,
            StartingPrice = summary.StartingPrice,
            VariantCount = summary.VariantCount,
            ColorCount = summary.ColorCount,
            HeroImageUrl = summary.HeroImageUrl,
            Has3DAsset = summary.Has3DAsset,
            Variants = model.Variants.Select(v => new VehicleVariantDto
            {
                Id = v.Id,
                ModelId = v.ModelId,
                Code = v.Code,
                Name = v.Name,
                BasePrice = v.BasePrice,
                SpecificationsJson = v.SpecificationsJson,
                FeaturesJson = v.FeaturesJson,
                Colors = v.Colors.Select(c => new VehicleColorDto
                {
                    Id = c.Id,
                    VariantId = c.VariantId,
                    ColorName = c.ColorName,
                    HexCode = c.HexCode,
                    IsPrimary = c.IsPrimary,
                    ImageUrl = c.ImageUrl
                }).ToList(),
                Assets3D = v.Assets3D.Select(a => new Asset3DDto
                {
                    Id = a.Id,
                    VariantId = a.VariantId,
                    ColorId = a.ColorId,
                    GlbFileUrl = a.GlbFileUrl,
                    UsdzFileUrl = a.UsdzFileUrl,
                    ModelFileSizeBytes = a.ModelFileSizeBytes,
                    HotspotsJson = a.HotspotsJson,
                    CameraPresetsJson = a.CameraPresetsJson
                }).ToList()
            }).ToList()
        };
    }

    public async Task<VariantBranchPricingDto?> GetVariantBranchPricingAsync(
        Guid variantId,
        Guid? branchId = null,
        CancellationToken cancellationToken = default)
    {
        var variant = await _context.VehicleVariants
            .Include(v => v.Model)
            .AsNoTracking()
            .FirstOrDefaultAsync(v => v.Id == variantId && v.IsActive, cancellationToken);

        var variantCode = variant?.Code;
        var variantName = variant?.Name;
        var modelName = variant?.Model?.Name;
        var basePrice = variant?.BasePrice;
        var tenantId = _tenantContext.TenantId;

        if (variant == null)
        {
            var demoVariant = GetDefaultVariantInfo(variantId);
            if (demoVariant == null)
            {
                return null;
            }

            variantCode = demoVariant.Value.Variant.Code;
            variantName = demoVariant.Value.Variant.Name;
            modelName = demoVariant.Value.ModelName;
            basePrice = demoVariant.Value.Variant.BasePrice;
        }

        Branch? branch = null;
        if (tenantId.HasValue)
        {
            if (branchId.HasValue)
            {
                branch = await _context.Branches
                    .AsNoTracking()
                    .FirstOrDefaultAsync(b => b.Id == branchId.Value && b.TenantId == tenantId.Value && b.IsActive, cancellationToken);

                if (branch == null)
                {
                    throw new ArgumentException($"Branch '{branchId}' was not found for the active dealership.");
                }
            }
            else
            {
                branch = await _context.Branches
                    .AsNoTracking()
                    .Where(b => b.TenantId == tenantId.Value && b.IsActive)
                    .OrderByDescending(b => b.IsHeadquarters)
                    .ThenBy(b => b.Name)
                    .FirstOrDefaultAsync(cancellationToken);
            }
        }

        var availableUnits = 0;
        if (tenantId.HasValue)
        {
            var inventoryQuery = _context.InventoryItems
                .AsNoTracking()
                .Where(i => i.TenantId == tenantId.Value
                            && i.VariantId == variantId
                            && i.Status == InventoryStatus.Available);

            if (branch != null)
            {
                inventoryQuery = inventoryQuery.Where(i => i.BranchId == branch.Id);
            }

            availableUnits = await inventoryQuery.CountAsync(cancellationToken);
        }

        var breakdown = BranchPricingCalculator.Calculate(basePrice ?? 0m, branch?.State);

        return new VariantBranchPricingDto
        {
            VariantId = variantId,
            VariantCode = variantCode ?? string.Empty,
            VariantName = variantName ?? string.Empty,
            ModelName = modelName ?? string.Empty,
            BranchId = branch?.Id,
            BranchCode = branch?.Code ?? "ALL",
            BranchName = branch?.Name ?? "All Branches",
            State = branch?.State ?? string.Empty,
            ExShowroomPrice = breakdown.ExShowroomPrice,
            RtoPercent = breakdown.RtoPercent,
            RtoCharges = breakdown.RtoCharges,
            InsurancePercent = breakdown.InsurancePercent,
            InsuranceCharges = breakdown.InsuranceCharges,
            AccessoriesCharges = breakdown.AccessoriesCharges,
            HandlingCharges = breakdown.HandlingCharges,
            EstimatedOnRoadPrice = breakdown.EstimatedOnRoadPrice,
            AvailableUnits = availableUnits,
            InStock = availableUnits > 0,
            Disclaimer = branch == null
                ? "Indicative on-road estimate across dealership branches. Final price is confirmed by the dealership."
                : $"Indicative on-road estimate for {branch.Name}. RTO and insurance are estimates; the final quotation is issued by the dealership."
        };
    }

    public async Task<VehicleModelSummaryDto> CreateModelAsync(CreateModelRequest request, CancellationToken cancellationToken = default)
    {
        var model = new VehicleModel
        {
            ManufacturerId = request.ManufacturerId,
            Code = request.Code.Trim().ToUpperInvariant(),
            Name = request.Name.Trim(),
            Category = request.Category,
            FuelType = request.FuelType,
            DisplacementCc = request.DisplacementCc,
            BatteryCapacityKwh = request.BatteryCapacityKwh,
            IsActive = true
        };

        _context.VehicleModels.Add(model);
        await _context.SaveChangesAsync(cancellationToken);

        return new VehicleModelSummaryDto
        {
            Id = model.Id,
            ManufacturerId = model.ManufacturerId,
            Code = model.Code,
            Name = model.Name,
            Category = model.Category.ToString().ToUpperInvariant(),
            FuelType = model.FuelType.ToString().ToUpperInvariant(),
            DisplacementCc = model.DisplacementCc,
            BatteryCapacityKwh = model.BatteryCapacityKwh
        };
    }

    public async Task<VehicleVariantDto> CreateVariantAsync(CreateVariantRequest request, CancellationToken cancellationToken = default)
    {
        var variant = new VehicleVariant
        {
            ModelId = request.ModelId,
            Code = request.Code.Trim().ToUpperInvariant(),
            Name = request.Name.Trim(),
            BasePrice = request.BasePrice,
            SpecificationsJson = request.SpecificationsJson ?? "{}",
            FeaturesJson = request.FeaturesJson ?? "{}",
            IsActive = true
        };

        _context.VehicleVariants.Add(variant);
        await _context.SaveChangesAsync(cancellationToken);

        return new VehicleVariantDto
        {
            Id = variant.Id,
            ModelId = variant.ModelId,
            Code = variant.Code,
            Name = variant.Name,
            BasePrice = variant.BasePrice,
            SpecificationsJson = variant.SpecificationsJson,
            FeaturesJson = variant.FeaturesJson
        };
    }

    public async Task<VehicleColorDto> CreateColorAsync(CreateColorRequest request, CancellationToken cancellationToken = default)
    {
        var color = new VehicleColor
        {
            VariantId = request.VariantId,
            ColorName = request.ColorName.Trim(),
            HexCode = request.HexCode.Trim(),
            IsPrimary = request.IsPrimary,
            ImageUrl = request.ImageUrl
        };

        _context.VehicleColors.Add(color);
        await _context.SaveChangesAsync(cancellationToken);

        return new VehicleColorDto
        {
            Id = color.Id,
            VariantId = color.VariantId,
            ColorName = color.ColorName,
            HexCode = color.HexCode,
            IsPrimary = color.IsPrimary,
            ImageUrl = color.ImageUrl
        };
    }

    private static VehicleModelSummaryDto MapToSummary(VehicleModel m)
    {
        var variants = m.Variants.Where(v => v.IsActive).ToList();
        var startingPrice = variants.Count > 0 ? variants.Min(v => v.BasePrice) : 0m;
        var allColors = variants.SelectMany(v => v.Colors).ToList();
        var heroColor = allColors.FirstOrDefault(c => c.IsPrimary) ?? allColors.FirstOrDefault();
        var has3D = variants.Any(v => v.Assets3D.Any(a => a.IsActive));

        return new VehicleModelSummaryDto
        {
            Id = m.Id,
            ManufacturerId = m.ManufacturerId,
            ManufacturerName = m.Manufacturer?.Name ?? string.Empty,
            ManufacturerCode = m.Manufacturer?.Code ?? string.Empty,
            Code = m.Code,
            Name = m.Name,
            Category = m.Category.ToString().ToUpperInvariant(),
            FuelType = m.FuelType.ToString().ToUpperInvariant(),
            DisplacementCc = m.DisplacementCc,
            BatteryCapacityKwh = m.BatteryCapacityKwh,
            StartingPrice = startingPrice,
            VariantCount = variants.Count,
            ColorCount = allColors.Count,
            HeroImageUrl = heroColor?.ImageUrl,
            Has3DAsset = has3D
        };
    }

    private static List<VehicleModelSummaryDto> GetDefaultCatalog(
        VehicleCategory? category,
        Guid? manufacturerId,
        FuelType? fuelType)
    {
        var list = new List<VehicleModelSummaryDto>
        {
            new()
            {
                Id = Guid.Parse("22222222-2222-2222-2222-222222222204"),
                ManufacturerId = Guid.Parse("11111111-1111-1111-1111-111111111102"),
                ManufacturerCode = "HONDA",
                ManufacturerName = "Honda Motorcycle and Scooter India",
                Code = "ACTIVA-6G",
                Name = "Honda Activa 6G",
                Category = "SCOOTER",
                FuelType = "PETROL",
                DisplacementCc = 110,
                StartingPrice = 78684m,
                VariantCount = 3,
                ColorCount = 6,
                HeroImageUrl = "assets/images/vehicles/scooter_front.jpg",
                Has3DAsset = true
            },
            new()
            {
                Id = Guid.Parse("22222222-2222-2222-2222-222222222205"),
                ManufacturerId = Guid.Parse("11111111-1111-1111-1111-111111111102"),
                ManufacturerCode = "HONDA",
                ManufacturerName = "Honda Motorcycle and Scooter India",
                Code = "DIO-125",
                Name = "Honda Dio 125",
                Category = "SCOOTER",
                FuelType = "PETROL",
                DisplacementCc = 125,
                StartingPrice = 83400m,
                VariantCount = 2,
                ColorCount = 4,
                HeroImageUrl = "assets/images/vehicles/scooter_blue_front.jpg",
                Has3DAsset = true
            },
            new()
            {
                Id = Guid.Parse("22222222-2222-2222-2222-222222222206"),
                ManufacturerId = Guid.Parse("11111111-1111-1111-1111-111111111102"),
                ManufacturerCode = "HONDA",
                ManufacturerName = "Honda Motorcycle and Scooter India",
                Code = "SHINE-125",
                Name = "Honda Shine 125",
                Category = "MOTORCYCLE",
                FuelType = "PETROL",
                DisplacementCc = 125,
                StartingPrice = 81200m,
                VariantCount = 2,
                ColorCount = 5,
                HeroImageUrl = "assets/images/vehicles/bike_red.jpg",
                Has3DAsset = true
            },
            new()
            {
                Id = Guid.Parse("22222222-2222-2222-2222-222222222201"),
                ManufacturerId = Guid.Parse("11111111-1111-1111-1111-111111111101"),
                ManufacturerCode = "YAMAHA",
                ManufacturerName = "Yamaha Motor Company",
                Code = "YZF-R15-V4",
                Name = "Yamaha YZF R15 V4",
                Category = "MOTORCYCLE",
                FuelType = "PETROL",
                DisplacementCc = 155,
                StartingPrice = 182000m,
                VariantCount = 3,
                ColorCount = 5,
                HeroImageUrl = "assets/images/vehicles/yamaha_r15_v4.jpg",
                Has3DAsset = true
            },
            new()
            {
                Id = Guid.Parse("22222222-2222-2222-2222-222222222202"),
                ManufacturerId = Guid.Parse("11111111-1111-1111-1111-111111111101"),
                ManufacturerCode = "YAMAHA",
                ManufacturerName = "Yamaha Motor Company",
                Code = "AEROX-155",
                Name = "Yamaha Aerox 155",
                Category = "SCOOTER",
                FuelType = "PETROL",
                DisplacementCc = 155,
                StartingPrice = 147000m,
                VariantCount = 2,
                ColorCount = 4,
                HeroImageUrl = "assets/images/vehicles/yamaha_aerox_155.jpg",
                Has3DAsset = true
            },
            new()
            {
                Id = Guid.Parse("22222222-2222-2222-2222-222222222203"),
                ManufacturerId = Guid.Parse("11111111-1111-1111-1111-111111111103"),
                ManufacturerCode = "TVS",
                ManufacturerName = "TVS Motor Company",
                Code = "IQUBE-ELECTRIC",
                Name = "TVS iQube Electric",
                Category = "ELECTRICVEHICLE",
                FuelType = "ELECTRIC",
                BatteryCapacityKwh = 3.4m,
                StartingPrice = 117000m,
                VariantCount = 3,
                ColorCount = 4,
                HeroImageUrl = "assets/images/vehicles/tvs_iqube.jpg",
                Has3DAsset = true
            }
        };

        if (category.HasValue)
        {
            var catStr = category.Value.ToString().ToUpperInvariant();
            list = list.Where(x => x.Category == catStr).ToList();
        }

        if (fuelType.HasValue)
        {
            var fuelStr = fuelType.Value.ToString().ToUpperInvariant();
            list = list.Where(x => x.FuelType == fuelStr).ToList();
        }

        return list;
    }

    private static VehicleModelDetailDto? GetDefaultModelDetail(Guid modelId) =>
        BuildDefaultModelDetails().FirstOrDefault(m => m.Id == modelId);

    private static (VehicleVariantDto Variant, string ModelName)? GetDefaultVariantInfo(Guid variantId)
    {
        foreach (var model in BuildDefaultModelDetails())
        {
            var variant = model.Variants.FirstOrDefault(v => v.Id == variantId);
            if (variant != null)
            {
                return (variant, model.Name);
            }
        }

        return null;
    }

    /// <summary>
    /// Fallback catalogue used before the deterministic Phase 16 demo seed is loaded.
    /// Keeps guest discovery, pricing, comparison and the 3D showroom usable end-to-end.
    /// </summary>
    private static List<VehicleModelDetailDto> BuildDefaultModelDetails()
    {
        return new List<VehicleModelDetailDto>
        {
            new()
            {
                Id = Guid.Parse("22222222-2222-2222-2222-222222222201"),
                ManufacturerId = Guid.Parse("11111111-1111-1111-1111-111111111101"),
                ManufacturerCode = "YAMAHA",
                ManufacturerName = "Yamaha Motor Company",
                Code = "YZF-R15-V4",
                Name = "Yamaha YZF R15 V4",
                Category = "MOTORCYCLE",
                FuelType = "PETROL",
                DisplacementCc = 155,
                StartingPrice = 182000m,
                VariantCount = 3,
                ColorCount = 5,
                HeroImageUrl = "assets/images/vehicles/yamaha_r15_v4.jpg",
                Has3DAsset = true,
                Variants = new List<VehicleVariantDto>
                {
                    new()
                    {
                        Id = Guid.Parse("22222222-2222-2222-2222-222222222301"),
                        ModelId = Guid.Parse("22222222-2222-2222-2222-222222222201"),
                        Code = "R15-V4-BASE",
                        Name = "R15 V4 Base",
                        BasePrice = 182000m,
                        SpecificationsJson = "{\"engine\":\"155cc liquid-cooled VVA\",\"power\":\"18.4 PS @ 10000 rpm\",\"torque\":\"14.2 Nm @ 7500 rpm\",\"transmission\":\"6-speed\",\"brakes\":\"Dual-channel ABS\",\"kerbWeightKg\":142,\"fuelTankLitres\":11}",
                        FeaturesJson = "{\"display\":\"LCD console\",\"lighting\":\"LED\",\"connectivity\":\"Y-Connect\",\"quickShifter\":false,\"tractionControl\":false}",
                        Colors = new List<VehicleColorDto>
                        {
                            new() { Id = Guid.Parse("22222222-2222-2222-2222-222222222401"), VariantId = Guid.Parse("22222222-2222-2222-2222-222222222301"), ColorName = "Metallic Grey", HexCode = "#707070", IsPrimary = true, ImageUrl = "assets/images/vehicles/yamaha_r15m.jpg" },
                            new() { Id = Guid.Parse("22222222-2222-2222-2222-222222222402"), VariantId = Guid.Parse("22222222-2222-2222-2222-222222222301"), ColorName = "Racing Blue", HexCode = "#002C6C", ImageUrl = "assets/images/vehicles/yamaha_r15_v4.jpg" },
                            new() { Id = Guid.Parse("22222222-2222-2222-2222-222222222406"), VariantId = Guid.Parse("22222222-2222-2222-2222-222222222301"), ColorName = "Vivid Red", HexCode = "#D32F2F", ImageUrl = "assets/images/vehicles/yamaha_r15_red.jpg" },
                            new() { Id = Guid.Parse("22222222-2222-2222-2222-222222222407"), VariantId = Guid.Parse("22222222-2222-2222-2222-222222222301"), ColorName = "Dark Knight", HexCode = "#1A1A1A", ImageUrl = "assets/images/vehicles/yamaha_r15_dark_knight.jpg" }
                        },
                        Assets3D = new List<Asset3DDto>
                        {
                            new() { Id = Guid.Parse("22222222-2222-2222-2222-222222222501"), VariantId = Guid.Parse("22222222-2222-2222-2222-222222222301"), GlbFileUrl = "https://cdn.motosaas.local/assets/yamaha_r15_v4.glb", ModelFileSizeBytes = 5_400_000, HotspotsJson = "[]", CameraPresetsJson = "{}" }
                        }
                    },
                    new()
                    {
                        Id = Guid.Parse("22222222-2222-2222-2222-222222222302"),
                        ModelId = Guid.Parse("22222222-2222-2222-2222-222222222201"),
                        Code = "R15M",
                        Name = "R15M",
                        BasePrice = 195000m,
                        SpecificationsJson = "{\"engine\":\"155cc liquid-cooled VVA\",\"power\":\"18.4 PS @ 10000 rpm\",\"torque\":\"14.2 Nm @ 7500 rpm\",\"transmission\":\"6-speed with quickshifter\",\"brakes\":\"Dual-channel ABS\",\"kerbWeightKg\":142,\"fuelTankLitres\":11}",
                        FeaturesJson = "{\"display\":\"TFT with Bluetooth\",\"lighting\":\"LED\",\"connectivity\":\"Y-Connect\",\"quickShifter\":true,\"tractionControl\":true}",
                        Colors = new List<VehicleColorDto>
                        {
                            new() { Id = Guid.Parse("22222222-2222-2222-2222-222222222403"), VariantId = Guid.Parse("22222222-2222-2222-2222-222222222302"), ColorName = "Metallic Grey", HexCode = "#707070", IsPrimary = true, ImageUrl = "assets/images/vehicles/yamaha_r15m.jpg" },
                            new() { Id = Guid.Parse("22222222-2222-2222-2222-222222222404"), VariantId = Guid.Parse("22222222-2222-2222-2222-222222222302"), ColorName = "Intensity White", HexCode = "#F2F2F2", ImageUrl = "assets/images/vehicles/yamaha_r15m.jpg" }
                        },
                        Assets3D = new List<Asset3DDto>
                        {
                            new() { Id = Guid.Parse("22222222-2222-2222-2222-222222222502"), VariantId = Guid.Parse("22222222-2222-2222-2222-222222222302"), GlbFileUrl = "https://cdn.motosaas.local/assets/yamaha_r15m_v4_opt.glb", ModelFileSizeBytes = 5_400_000, HotspotsJson = "[]", CameraPresetsJson = "{}" }
                        }
                    },
                    new()
                    {
                        Id = Guid.Parse("22222222-2222-2222-2222-222222222303"),
                        ModelId = Guid.Parse("22222222-2222-2222-2222-222222222201"),
                        Code = "R15-V4-DARK-KNIGHT",
                        Name = "R15 V4 Dark Knight",
                        BasePrice = 188000m,
                        SpecificationsJson = "{\"engine\":\"155cc liquid-cooled VVA\",\"power\":\"18.4 PS @ 10000 rpm\",\"torque\":\"14.2 Nm @ 7500 rpm\",\"transmission\":\"6-speed\",\"brakes\":\"Dual-channel ABS\",\"kerbWeightKg\":142,\"fuelTankLitres\":11}",
                        FeaturesJson = "{\"display\":\"LCD console\",\"lighting\":\"LED\",\"connectivity\":\"Y-Connect\",\"quickShifter\":false,\"tractionControl\":false}",
                        Colors = new List<VehicleColorDto>
                        {
                            new() { Id = Guid.Parse("22222222-2222-2222-2222-222222222405"), VariantId = Guid.Parse("22222222-2222-2222-2222-222222222303"), ColorName = "Dark Knight", HexCode = "#1A1A1A", IsPrimary = true, ImageUrl = "assets/images/vehicles/yamaha_r15_dark_knight.jpg" }
                        },
                        Assets3D = new List<Asset3DDto>
                        {
                            new() { Id = Guid.Parse("22222222-2222-2222-2222-222222222503"), VariantId = Guid.Parse("22222222-2222-2222-2222-222222222303"), GlbFileUrl = "https://cdn.motosaas.local/assets/yamaha_r15_v4_dark.glb", ModelFileSizeBytes = 5_400_000, HotspotsJson = "[]", CameraPresetsJson = "{}" }
                        }
                    }
                }
            },
            new()
            {
                Id = Guid.Parse("22222222-2222-2222-2222-222222222202"),
                ManufacturerId = Guid.Parse("11111111-1111-1111-1111-111111111101"),
                ManufacturerCode = "YAMAHA",
                ManufacturerName = "Yamaha Motor Company",
                Code = "AEROX-155",
                Name = "Yamaha Aerox 155",
                Category = "SCOOTER",
                FuelType = "PETROL",
                DisplacementCc = 155,
                StartingPrice = 147000m,
                VariantCount = 2,
                ColorCount = 4,
                HeroImageUrl = "assets/images/vehicles/yamaha_aerox_155.jpg",
                Has3DAsset = true,
                Variants = new List<VehicleVariantDto>
                {
                    new()
                    {
                        Id = Guid.Parse("22222222-2222-2222-2222-222222222311"),
                        ModelId = Guid.Parse("22222222-2222-2222-2222-222222222202"),
                        Code = "AEROX-155-STD",
                        Name = "Aerox 155 Standard",
                        BasePrice = 147000m,
                        SpecificationsJson = "{\"engine\":\"155cc liquid-cooled VVA\",\"power\":\"15 PS @ 8000 rpm\",\"torque\":\"13.9 Nm @ 6500 rpm\",\"transmission\":\"CVT\",\"brakes\":\"Single-channel ABS\",\"kerbWeightKg\":126,\"fuelTankLitres\":5.5}",
                        FeaturesJson = "{\"display\":\"LCD console\",\"lighting\":\"LED\",\"connectivity\":\"Y-Connect\",\"smartKey\":false}",
                        Colors = new List<VehicleColorDto>
                        {
                            new() { Id = Guid.Parse("22222222-2222-2222-2222-222222222411"), VariantId = Guid.Parse("22222222-2222-2222-2222-222222222311"), ColorName = "Racing Blue", HexCode = "#002C6C", IsPrimary = true, ImageUrl = "assets/images/vehicles/yamaha_aerox_155.jpg" },
                            new() { Id = Guid.Parse("22222222-2222-2222-2222-222222222412"), VariantId = Guid.Parse("22222222-2222-2222-2222-222222222311"), ColorName = "Matte Black", HexCode = "#1A1A1A", ImageUrl = "assets/images/vehicles/yamaha_aerox_155.jpg" }
                        },
                        Assets3D = new List<Asset3DDto>
                        {
                            new() { Id = Guid.Parse("22222222-2222-2222-2222-222222222511"), VariantId = Guid.Parse("22222222-2222-2222-2222-222222222311"), GlbFileUrl = "https://cdn.motosaas.local/assets/yamaha_aerox_155.glb", ModelFileSizeBytes = 4_800_000, HotspotsJson = "[]", CameraPresetsJson = "{}" }
                        }
                    },
                    new()
                    {
                        Id = Guid.Parse("22222222-2222-2222-2222-222222222312"),
                        ModelId = Guid.Parse("22222222-2222-2222-2222-222222222202"),
                        Code = "AEROX-155-S",
                        Name = "Aerox 155 S",
                        BasePrice = 152000m,
                        SpecificationsJson = "{\"engine\":\"155cc liquid-cooled VVA\",\"power\":\"15 PS @ 8000 rpm\",\"torque\":\"13.9 Nm @ 6500 rpm\",\"transmission\":\"CVT\",\"brakes\":\"Single-channel ABS\",\"kerbWeightKg\":126,\"fuelTankLitres\":5.5}",
                        FeaturesJson = "{\"display\":\"LCD console\",\"lighting\":\"LED\",\"connectivity\":\"Y-Connect\",\"smartKey\":true}",
                        Colors = new List<VehicleColorDto>
                        {
                            new() { Id = Guid.Parse("22222222-2222-2222-2222-222222222413"), VariantId = Guid.Parse("22222222-2222-2222-2222-222222222312"), ColorName = "Metallic Grey", HexCode = "#707070", IsPrimary = true, ImageUrl = "assets/images/vehicles/yamaha_aerox_155.jpg" },
                            new() { Id = Guid.Parse("22222222-2222-2222-2222-222222222414"), VariantId = Guid.Parse("22222222-2222-2222-2222-222222222312"), ColorName = "Racing Blue", HexCode = "#002C6C", ImageUrl = "assets/images/vehicles/yamaha_aerox_155.jpg" }
                        },
                        Assets3D = new List<Asset3DDto>
                        {
                            new() { Id = Guid.Parse("22222222-2222-2222-2222-222222222512"), VariantId = Guid.Parse("22222222-2222-2222-2222-222222222312"), GlbFileUrl = "https://cdn.motosaas.local/assets/yamaha_aerox_155s.glb", ModelFileSizeBytes = 4_800_000, HotspotsJson = "[]", CameraPresetsJson = "{}" }
                        }
                    }
                }
            },
            new()
            {
                Id = Guid.Parse("22222222-2222-2222-2222-222222222203"),
                ManufacturerId = Guid.Parse("11111111-1111-1111-1111-111111111103"),
                ManufacturerCode = "TVS",
                ManufacturerName = "TVS Motor Company",
                Code = "IQUBE-ELECTRIC",
                Name = "TVS iQube Electric",
                Category = "ELECTRICVEHICLE",
                FuelType = "ELECTRIC",
                BatteryCapacityKwh = 3.4m,
                StartingPrice = 117000m,
                VariantCount = 3,
                ColorCount = 4,
                HeroImageUrl = "assets/images/vehicles/tvs_iqube.jpg",
                Has3DAsset = true,
                Variants = new List<VehicleVariantDto>
                {
                    new()
                    {
                        Id = Guid.Parse("22222222-2222-2222-2222-222222222321"),
                        ModelId = Guid.Parse("22222222-2222-2222-2222-222222222203"),
                        Code = "IQUBE-25",
                        Name = "iQube 2.5 kWh",
                        BasePrice = 117000m,
                        SpecificationsJson = "{\"batteryKwh\":2.5,\"rangeKm\":100,\"peakPowerKw\":4.4,\"torqueNm\":33,\"chargingTimeHours\":4.5,\"topSpeedKph\":78}",
                        FeaturesJson = "{\"display\":\"TFT\",\"connectivity\":\"SmartXonnect\",\"ridingModes\":3,\"regenerativeBraking\":true,\"fastCharging\":false}",
                        Colors = new List<VehicleColorDto>
                        {
                            new() { Id = Guid.Parse("22222222-2222-2222-2222-222222222421"), VariantId = Guid.Parse("22222222-2222-2222-2222-222222222321"), ColorName = "Pearl White", HexCode = "#F7F7F7", IsPrimary = true, ImageUrl = "assets/images/vehicles/tvs_iqube.jpg" },
                            new() { Id = Guid.Parse("22222222-2222-2222-2222-222222222422"), VariantId = Guid.Parse("22222222-2222-2222-2222-222222222321"), ColorName = "Titanium Grey", HexCode = "#5A5A5A", ImageUrl = "assets/images/vehicles/tvs_iqube.jpg" }
                        },
                        Assets3D = new List<Asset3DDto>
                        {
                            new() { Id = Guid.Parse("22222222-2222-2222-2222-222222222521"), VariantId = Guid.Parse("22222222-2222-2222-2222-222222222321"), GlbFileUrl = "https://cdn.motosaas.local/assets/tvs_iqube_25.glb", ModelFileSizeBytes = 6_200_000, HotspotsJson = "[]", CameraPresetsJson = "{}" }
                        }
                    },
                    new()
                    {
                        Id = Guid.Parse("22222222-2222-2222-2222-222222222322"),
                        ModelId = Guid.Parse("22222222-2222-2222-2222-222222222203"),
                        Code = "IQUBE-34",
                        Name = "iQube 3.4 kWh",
                        BasePrice = 127000m,
                        SpecificationsJson = "{\"batteryKwh\":3.4,\"rangeKm\":145,\"peakPowerKw\":4.4,\"torqueNm\":33,\"chargingTimeHours\":4.5,\"topSpeedKph\":78}",
                        FeaturesJson = "{\"display\":\"TFT\",\"connectivity\":\"SmartXonnect\",\"ridingModes\":3,\"regenerativeBraking\":true,\"fastCharging\":true}",
                        Colors = new List<VehicleColorDto>
                        {
                            new() { Id = Guid.Parse("22222222-2222-2222-2222-222222222423"), VariantId = Guid.Parse("22222222-2222-2222-2222-222222222322"), ColorName = "Pearl White", HexCode = "#F7F7F7", IsPrimary = true },
                            new() { Id = Guid.Parse("22222222-2222-2222-2222-222222222424"), VariantId = Guid.Parse("22222222-2222-2222-2222-222222222322"), ColorName = "Titanium Grey", HexCode = "#5A5A5A" }
                        },
                        Assets3D = new List<Asset3DDto>
                        {
                            new() { Id = Guid.Parse("22222222-2222-2222-2222-222222222522"), VariantId = Guid.Parse("22222222-2222-2222-2222-222222222322"), GlbFileUrl = "https://cdn.motosaas.local/assets/tvs_iqube_34.glb", ModelFileSizeBytes = 6_200_000, HotspotsJson = "[]", CameraPresetsJson = "{}" }
                        }
                    },
                    new()
                    {
                        Id = Guid.Parse("22222222-2222-2222-2222-222222222323"),
                        ModelId = Guid.Parse("22222222-2222-2222-2222-222222222203"),
                        Code = "IQUBE-ST",
                        Name = "iQube ST",
                        BasePrice = 142000m,
                        SpecificationsJson = "{\"batteryKwh\":5.1,\"rangeKm\":145,\"peakPowerKw\":4.4,\"torqueNm\":33,\"chargingTimeHours\":4.5,\"topSpeedKph\":82}",
                        FeaturesJson = "{\"display\":\"TFT\",\"connectivity\":\"SmartXonnect\",\"ridingModes\":3,\"regenerativeBraking\":true,\"fastCharging\":true}",
                        Colors = new List<VehicleColorDto>
                        {
                            new() { Id = Guid.Parse("22222222-2222-2222-2222-222222222425"), VariantId = Guid.Parse("22222222-2222-2222-2222-222222222323"), ColorName = "Pearl White", HexCode = "#F7F7F7", IsPrimary = true },
                            new() { Id = Guid.Parse("22222222-2222-2222-2222-222222222426"), VariantId = Guid.Parse("22222222-2222-2222-2222-222222222323"), ColorName = "Titanium Grey", HexCode = "#5A5A5A" }
                        },
                        Assets3D = new List<Asset3DDto>
                        {
                            new() { Id = Guid.Parse("22222222-2222-2222-2222-222222222523"), VariantId = Guid.Parse("22222222-2222-2222-2222-222222222323"), GlbFileUrl = "https://cdn.motosaas.local/assets/tvs_iqube_st.glb", ModelFileSizeBytes = 6_200_000, HotspotsJson = "[]", CameraPresetsJson = "{}" }
                        }
                    }
                }
            }
        };
    }
}

