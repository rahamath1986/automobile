using MotoSaaS.Application.Features.Tenancy.Models;

namespace MotoSaaS.Application.Features.Tenancy.Interfaces;

public interface ITenantService
{
    Task<TenantDto?> GetTenantByCodeAsync(string code, CancellationToken cancellationToken = default);
    Task<TenantDto?> GetTenantByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<List<BranchDto>> GetBranchesByTenantIdAsync(Guid tenantId, CancellationToken cancellationToken = default);
}

