namespace MotoSaaS.Application.Features.Tenancy.Models;

public class TenantDto
{
    public Guid Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public string LegalName { get; set; } = string.Empty;
    public string TradeName { get; set; } = string.Empty;
    public string? TaxId { get; set; }
    public string? LogoUrl { get; set; }
    public string PrimaryColor { get; set; } = string.Empty;
    public string SecondaryColor { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public List<BranchDto> Branches { get; set; } = new();
}

public class BranchDto
{
    public Guid Id { get; set; }
    public Guid TenantId { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string AddressLine1 { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public string State { get; set; } = string.Empty;
    public string PostalCode { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string? Email { get; set; }
    public bool IsHeadquarters { get; set; }
    public bool IsActive { get; set; }
}

