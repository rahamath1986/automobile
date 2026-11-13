namespace MotoSaaS.Application.Common.Interfaces;

public interface ICurrentTenantContext
{
    Guid? TenantId { get; }
    Guid? BranchId { get; }
    Guid? UserId { get; }
    string? UserType { get; }
    bool IsSuperAdmin { get; }
    bool IsAuthenticated { get; }
    void SetTenant(Guid tenantId);
    void SetBranch(Guid branchId);
}

