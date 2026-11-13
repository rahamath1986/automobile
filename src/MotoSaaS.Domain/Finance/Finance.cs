using MotoSaaS.Domain.Common;
using MotoSaaS.Domain.Sales;
using MotoSaaS.Domain.Tenancy;

namespace MotoSaaS.Domain.Finance;

public enum InterestType
{
    Reducing,
    Flat
}

public enum FinanceStatus
{
    Applied,
    DocsSubmitted,
    UnderReview,
    Approved,
    Rejected,
    Disbursed
}

public class Financier : BaseEntity, ITenantScopedEntity
{
    public Guid TenantId { get; set; }
    public Tenant? Tenant { get; set; }

    public string Code { get; set; } = string.Empty; // 'HDFC', 'TVS_CREDIT'
    public string Name { get; set; } = string.Empty;
    public string? ContactPerson { get; set; }
    public string? Phone { get; set; }
    public string? Email { get; set; }
    public bool IsActive { get; set; } = true;

    public ICollection<FinancierScheme> Schemes { get; set; } = new List<FinancierScheme>();
}

public class FinancierScheme : BaseEntity, ITenantScopedEntity
{
    public Guid TenantId { get; set; }
    public Tenant? Tenant { get; set; }

    public Guid FinancierId { get; set; }
    public Financier? Financier { get; set; }

    public string SchemeName { get; set; } = string.Empty;
    public decimal InterestRateApr { get; set; }
    public InterestType InterestType { get; set; } = InterestType.Reducing;
    public decimal MinDownPaymentPercent { get; set; } = 15.00m;
    public decimal MaxLtvPercent { get; set; } = 85.00m;
    public int[] AllowedTenuresMonths { get; set; } = [12, 18, 24, 36, 48, 60];
    public decimal? ProcessingFeePercent { get; set; } = 1.50m;
    public decimal? ProcessingFeeFlat { get; set; } = 0.00m;
    public decimal DocumentationCharges { get; set; } = 500.00m;
    public bool IsActive { get; set; } = true;
    public DateTime ValidFrom { get; set; }
    public DateTime? ValidUntil { get; set; }
}

public class FinanceApplication : BaseEntity, ITenantScopedEntity, IBranchScopedEntity
{
    public Guid TenantId { get; set; }
    public Tenant? Tenant { get; set; }

    public Guid BranchId { get; set; }
    public Branch? Branch { get; set; }

    public Guid BookingId { get; set; }
    public Booking? Booking { get; set; }

    public Guid FinancierId { get; set; }
    public Financier? Financier { get; set; }

    public Guid? SchemeId { get; set; }
    public FinancierScheme? Scheme { get; set; }

    public decimal LoanAmount { get; set; }
    public decimal DownPaymentAmount { get; set; }
    public int TenureMonths { get; set; }
    public decimal InterestRateApr { get; set; }
    public decimal CalculatedMonthlyEmi { get; set; }
    public decimal ProcessingFee { get; set; }
    public FinanceStatus Status { get; set; } = FinanceStatus.Applied;
    public string? LoanAccountNumber { get; set; }
    public string? ApprovalReference { get; set; }
    public DateTime? DisbursedAt { get; set; }
    public string? Notes { get; set; }
}

