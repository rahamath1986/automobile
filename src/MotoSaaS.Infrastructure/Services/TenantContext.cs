using MotoSaaS.Application.Common.Interfaces;

namespace MotoSaaS.Infrastructure.Services;

public class TenantContext : ICurrentTenantContext
{
    public Guid? TenantId { get; private set; }
    public Guid? BranchId { get; private set; }
    public Guid? UserId { get; private set; }
    public string? UserType { get; private set; }
    public bool IsSuperAdmin => string.Equals(UserType, "SAAS_ADMIN", StringComparison.OrdinalIgnoreCase);
    public bool IsAuthenticated => UserId.HasValue;

    public void SetTenant(Guid tenantId)
    {
        TenantId = tenantId;
    }

    public void SetBranch(Guid branchId)
    {
        BranchId = branchId;
    }

    public void SetUser(Guid userId, string userType)
    {
        UserId = userId;
        UserType = userType;
    }
}

