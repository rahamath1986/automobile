using MotoSaaS.Domain.Catalog;

namespace MotoSaaS.Application.Features.Catalog.Models;

public class VehicleModelSummaryDto
{
    public Guid Id { get; set; }
    public Guid ManufacturerId { get; set; }
    public string ManufacturerName { get; set; } = string.Empty;
    public string ManufacturerCode { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty; // MOTORCYCLE, SCOOTER, EV
    public string FuelType { get; set; } = string.Empty; // PETROL, ELECTRIC, HYBRID
    public int? DisplacementCc { get; set; }
    public decimal? BatteryCapacityKwh { get; set; }
    public decimal StartingPrice { get; set; }
    public int VariantCount { get; set; }
    public int ColorCount { get; set; }
    public string? HeroImageUrl { get; set; }
    public bool Has3DAsset { get; set; }
}

public class VehicleModelDetailDto : VehicleModelSummaryDto
{
    public List<VehicleVariantDto> Variants { get; set; } = new();
}

public class VehicleVariantDto
{
    public Guid Id { get; set; }
    public Guid ModelId { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public decimal BasePrice { get; set; }
    public string SpecificationsJson { get; set; } = "{}";
    public string FeaturesJson { get; set; } = "{}";
    public List<VehicleColorDto> Colors { get; set; } = new();
    public List<Asset3DDto> Assets3D { get; set; } = new();
}

public class VehicleColorDto
{
    public Guid Id { get; set; }
    public Guid VariantId { get; set; }
    public string ColorName { get; set; } = string.Empty;
    public string HexCode { get; set; } = "#000000";
    public bool IsPrimary { get; set; }
    public string? ImageUrl { get; set; }
}

public class Asset3DDto
{
    public Guid Id { get; set; }
    public Guid VariantId { get; set; }
    public Guid? ColorId { get; set; }
    public string GlbFileUrl { get; set; } = string.Empty;
    public string? UsdzFileUrl { get; set; }
    public long ModelFileSizeBytes { get; set; }
    public string HotspotsJson { get; set; } = "[]";
    public string CameraPresetsJson { get; set; } = "{}";
}

public class CreateModelRequest
{
    public Guid ManufacturerId { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public VehicleCategory Category { get; set; } = VehicleCategory.Motorcycle;
    public FuelType FuelType { get; set; } = FuelType.Petrol;
    public int? DisplacementCc { get; set; }
    public decimal? BatteryCapacityKwh { get; set; }
}

public class CreateVariantRequest
{
    public Guid ModelId { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public decimal BasePrice { get; set; }
    public string? SpecificationsJson { get; set; }
    public string? FeaturesJson { get; set; }
}

public class CreateColorRequest
{
    public Guid VariantId { get; set; }
    public string ColorName { get; set; } = string.Empty;
    public string HexCode { get; set; } = "#000000";
    public bool IsPrimary { get; set; }
    public string? ImageUrl { get; set; }
}

/// <summary>
/// Indicative on-road price estimate for a variant at a specific branch.
/// This is a discovery aid for the customer mobile app; the binding price is always
/// the quotation issued by dealership staff (Phase 9 quotation engine).
/// </summary>
public class VariantBranchPricingDto
{
    public Guid VariantId { get; set; }
    public string VariantCode { get; set; } = string.Empty;
    public string VariantName { get; set; } = string.Empty;
    public string ModelName { get; set; } = string.Empty;

    public Guid? BranchId { get; set; }
    public string BranchCode { get; set; } = "ALL";
    public string BranchName { get; set; } = "All Branches";
    public string State { get; set; } = string.Empty;

    public decimal ExShowroomPrice { get; set; }
    public decimal RtoPercent { get; set; }
    public decimal RtoCharges { get; set; }
    public decimal InsurancePercent { get; set; }
    public decimal InsuranceCharges { get; set; }
    public decimal AccessoriesCharges { get; set; }
    public decimal HandlingCharges { get; set; }
    public decimal EstimatedOnRoadPrice { get; set; }

    public int AvailableUnits { get; set; }
    public bool InStock { get; set; }
    public string PriceBasis { get; set; } = "INDICATIVE_ON_ROAD_ESTIMATE";
    public string Disclaimer { get; set; } = string.Empty;
}

