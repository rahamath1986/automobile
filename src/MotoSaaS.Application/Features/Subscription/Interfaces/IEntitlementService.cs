using MotoSaaS.Application.Features.Subscription.Models;

namespace MotoSaaS.Application.Features.Subscription.Interfaces;

public interface IEntitlementService
{
    Task<bool> IsFeatureEnabledAsync(Guid tenantId, string featureKey, CancellationToken cancellationToken = default);
    Task<bool> CanAddBranchAsync(Guid tenantId, CancellationToken cancellationToken = default);
    Task<bool> CanAddEmployeeAsync(Guid tenantId, CancellationToken cancellationToken = default);
    Task<bool> CanAddInventoryUnitAsync(Guid tenantId, CancellationToken cancellationToken = default);
    Task<TenantSubscriptionDto> GetSubscriptionDetailsAsync(Guid tenantId, CancellationToken cancellationToken = default);
}

