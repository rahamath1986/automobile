using MotoSaaS.Application.Features.Subscription.Models;

namespace MotoSaaS.Application.Features.Subscription.Interfaces;

public interface ISubscriptionPlanService
{
    Task<List<SubscriptionPlanDto>> GetActivePlansAsync(CancellationToken cancellationToken = default);
    Task<SubscriptionPlanDto?> GetPlanByCodeAsync(string planCode, CancellationToken cancellationToken = default);
    Task<TenantSubscriptionDto> AssignPlanAsync(Guid tenantId, string planCode, CancellationToken cancellationToken = default);
}

