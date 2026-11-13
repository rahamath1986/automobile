using MotoSaaS.Domain.Common;
using MotoSaaS.Domain.Tenancy;

namespace MotoSaaS.Domain.Catalog;

public enum VehicleCategory
{
    Motorcycle,
    Scooter,
    ElectricVehicle
}

public enum FuelType
{
    Petrol,
    Electric,
    Hybrid
}

public class Manufacturer : BaseEntity
{
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? LogoUrl { get; set; }
    public string? CountryOfOrigin { get; set; }
    public bool IsActive { get; set; } = true;

    public ICollection<VehicleModel> Models { get; set; } = new List<VehicleModel>();
}

public class TenantManufacturer
{
    public Guid TenantId { get; set; }
    public Tenant? Tenant { get; set; }

    public Guid ManufacturerId { get; set; }
    public Manufacturer? Manufacturer { get; set; }

    public string? DealerCodeWithOem { get; set; }
    public bool IsPrimary { get; set; } = false;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class VehicleModel : BaseEntity
{
    public Guid ManufacturerId { get; set; }
    public Manufacturer? Manufacturer { get; set; }

    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public VehicleCategory Category { get; set; } = VehicleCategory.Motorcycle;
    public FuelType FuelType { get; set; } = FuelType.Petrol;
    public int? DisplacementCc { get; set; }
    public decimal? BatteryCapacityKwh { get; set; }
    public bool IsActive { get; set; } = true;

    public ICollection<VehicleVariant> Variants { get; set; } = new List<VehicleVariant>();
}

public class VehicleVariant : BaseEntity
{
    public Guid ModelId { get; set; }
    public VehicleModel? Model { get; set; }

    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public decimal BasePrice { get; set; } // Indicative Ex-Showroom
    public string SpecificationsJson { get; set; } = "{}";
    public string FeaturesJson { get; set; } = "{}";
    public bool IsActive { get; set; } = true;

    public ICollection<VehicleColor> Colors { get; set; } = new List<VehicleColor>();
    public ICollection<Asset3D> Assets3D { get; set; } = new List<Asset3D>();
}

public class VehicleColor : BaseEntity
{
    public Guid VariantId { get; set; }
    public VehicleVariant? Variant { get; set; }

    public string ColorName { get; set; } = string.Empty;
    public string HexCode { get; set; } = "#000000";
    public bool IsPrimary { get; set; } = false;
    public string? ImageUrl { get; set; }
}

public class Asset3D : BaseEntity
{
    public Guid VariantId { get; set; }
    public VehicleVariant? Variant { get; set; }

    public Guid? ColorId { get; set; }
    public VehicleColor? Color { get; set; }

    public string GlbFileUrl { get; set; } = string.Empty;
    public string? UsdzFileUrl { get; set; }
    public long ModelFileSizeBytes { get; set; }
    public string HotspotsJson { get; set; } = "[]";
    public string CameraPresetsJson { get; set; } = "{}";
    public bool IsActive { get; set; } = true;
}

