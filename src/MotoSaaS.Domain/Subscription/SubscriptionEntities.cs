using MotoSaaS.Domain.Common;
using MotoSaaS.Domain.Tenancy;

namespace MotoSaaS.Domain.Subscription;

public enum SubscriptionStatus
{
    Trial,
    Active,
    PastDue,
    Suspended,
    Cancelled
}

public static class SubscriptionFeatures
{
    public const string Showroom3D = "Showroom3D";
    public const string AfterSalesService = "AfterSalesService";
    public const string EmiCalculator = "EmiCalculator";
    public const string FinancierSchemes = "FinancierSchemes";
    public const string MultiBranchTransfer = "MultiBranchTransfer";
    public const string AccountingExport = "AccountingExport";
    public const string AdvancedAnalytics = "AdvancedAnalytics";
    public const string CustomBranding = "CustomBranding";
}

public class SubscriptionPlan : BaseEntity
{
    public string Code { get; set; } = string.Empty; // 'STARTER', 'PROFESSIONAL', 'ENTERPRISE'
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    
    // Limits
    public int MaxBranches { get; set; } = 1;
    public int MaxEmployees { get; set; } = 5;
    public int MaxInventoryUnits { get; set; } = 50;
    
    // Enabled Features
    public List<string> EnabledFeatures { get; set; } = new();
    
    public int TrialPeriodDays { get; set; } = 14;
    public bool IsActive { get; set; } = true;

    public ICollection<TenantSubscription> TenantSubscriptions { get; set; } = new List<TenantSubscription>();
}

public class TenantSubscription : BaseEntity, ITenantScopedEntity
{
    public Guid TenantId { get; set; }
    public Tenant? Tenant { get; set; }

    public Guid PlanId { get; set; }
    public SubscriptionPlan? Plan { get; set; }

    public SubscriptionStatus Status { get; set; } = SubscriptionStatus.Trial;
    public DateTime StartDate { get; set; } = DateTime.UtcNow;
    public DateTime? EndDate { get; set; }
    public DateTime? TrialEndsAt { get; set; }
    public bool AutoRenew { get; set; } = true;
}

