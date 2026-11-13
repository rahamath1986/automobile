namespace MotoSaaS.Application.Features.Branding.Models;

public class WhiteLabelBrandingDto
{
    public Guid TenantId { get; set; }
    public string DealerCode { get; set; } = string.Empty;
    public string TradeName { get; set; } = string.Empty;
    public string LegalName { get; set; } = string.Empty;
    public string? TaxId { get; set; } // GSTIN
    public string? LogoUrl { get; set; }
    public string? FaviconUrl { get; set; }
    public string PrimaryColor { get; set; } = "#002C6C";
    public string SecondaryColor { get; set; } = "#E60012";
    public string? SupportPhone { get; set; }
    public string? SupportEmail { get; set; }
    public string? WebsiteUrl { get; set; }
    public List<string> AssociatedManufacturerNames { get; set; } = new();
}

public class UpdateBrandingRequest
{
    public string? TradeName { get; set; }
    public string? LegalName { get; set; }
    public string? TaxId { get; set; }
    public string? LogoUrl { get; set; }
    public string? FaviconUrl { get; set; }
    public string? PrimaryColor { get; set; }
    public string? SecondaryColor { get; set; }
    public string? SupportPhone { get; set; }
    public string? SupportEmail { get; set; }
    public string? WebsiteUrl { get; set; }
}

public class UpdateBranchConfigRequest
{
    public string Name { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string AddressLine1 { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public string State { get; set; } = string.Empty;
    public string PostalCode { get; set; } = string.Empty;
    public bool IsHeadquarters { get; set; }
    public bool IsActive { get; set; } = true;
}

