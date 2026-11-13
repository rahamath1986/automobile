using MotoSaaS.Domain.Common;

namespace MotoSaaS.Domain.Tenancy;

public enum TenantStatus
{
    Active,
    Suspended,
    Trial
}

public class Tenant : BaseEntity
{
    public string Code { get; set; } = string.Empty;
    public string LegalName { get; set; } = string.Empty;
    public string TradeName { get; set; } = string.Empty;
    public string? TaxId { get; set; }
    public string? LogoUrl { get; set; }
    public string PrimaryColor { get; set; } = "#002C6C";
    public string SecondaryColor { get; set; } = "#E60012";
    public TenantStatus Status { get; set; } = TenantStatus.Active;

    public ICollection<Branch> Branches { get; set; } = new List<Branch>();
}

public class Branch : BaseEntity, ITenantScopedEntity
{
    public Guid TenantId { get; set; }
    public Tenant? Tenant { get; set; }

    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string AddressLine1 { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public string State { get; set; } = string.Empty;
    public string PostalCode { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string? Email { get; set; }
    public bool IsHeadquarters { get; set; } = false;
    public bool IsActive { get; set; } = true;
}

