namespace MotoSaaS.Application.Features.Subscription.Models;

public class SubscriptionPlanDto
{
    public Guid Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int MaxBranches { get; set; }
    public int MaxEmployees { get; set; }
    public int MaxInventoryUnits { get; set; }
    public List<string> EnabledFeatures { get; set; } = new();
    public int TrialPeriodDays { get; set; }
    public bool IsActive { get; set; }
}

public class TenantSubscriptionDto
{
    public Guid TenantId { get; set; }
    public string PlanCode { get; set; } = string.Empty;
    public string PlanName { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty; // TRIAL, ACTIVE, SUSPENDED, CANCELLED
    public DateTime StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public DateTime? TrialEndsAt { get; set; }
    public bool IsInTrial { get; set; }

    // Current Quotas & Usage
    public int CurrentBranchesCount { get; set; }
    public int MaxBranchesAllowed { get; set; }

    public int CurrentEmployeesCount { get; set; }
    public int MaxEmployeesAllowed { get; set; }

    public int CurrentInventoryCount { get; set; }
    public int MaxInventoryAllowed { get; set; }

    public List<string> EnabledFeatures { get; set; } = new();
}

public class UpgradeSubscriptionRequest
{
    public string PlanCode { get; set; } = string.Empty;
}

