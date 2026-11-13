namespace MotoSaaS.Application.Features.Manufacturer.Models;

public class ManufacturerDto
{
    public Guid Id { get; set; }
    public string Code { get; set; } = string.Empty; // 'YAMAHA', 'HONDA', 'TVS'
    public string Name { get; set; } = string.Empty;
    public string? LogoUrl { get; set; }
    public string? CountryOfOrigin { get; set; }
    public bool IsActive { get; set; }
}

public class CreateManufacturerRequest
{
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? LogoUrl { get; set; }
    public string? CountryOfOrigin { get; set; }
}

public class TenantManufacturerDto
{
    public Guid TenantId { get; set; }
    public Guid ManufacturerId { get; set; }
    public string ManufacturerCode { get; set; } = string.Empty;
    public string ManufacturerName { get; set; } = string.Empty;
    public string? LogoUrl { get; set; }
    public string? DealerCodeWithOem { get; set; }
    public bool IsPrimary { get; set; }
}

public class AssociateManufacturerRequest
{
    public Guid ManufacturerId { get; set; }
    public string? DealerCodeWithOem { get; set; }
    public bool IsPrimary { get; set; }
}

