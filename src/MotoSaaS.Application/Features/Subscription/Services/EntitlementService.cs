using Microsoft.EntityFrameworkCore;
using MotoSaaS.Application.Common.Interfaces;
using MotoSaaS.Application.Features.Subscription.Interfaces;
using MotoSaaS.Application.Features.Subscription.Models;
using MotoSaaS.Domain.Inventory;
using MotoSaaS.Domain.Subscription;

namespace MotoSaaS.Application.Features.Subscription.Services;

public class EntitlementService : IEntitlementService
{
    private readonly IApplicationDbContext _context;

    public EntitlementService(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<bool> IsFeatureEnabledAsync(Guid tenantId, string featureKey, CancellationToken cancellationToken = default)
    {
        var subscription = await GetActiveTenantSubscriptionAsync(tenantId, cancellationToken);
        if (subscription?.Plan == null)
        {
            // Default built-in starter features if no plan assigned yet
            return featureKey is SubscriptionFeatures.EmiCalculator 
                or SubscriptionFeatures.AfterSalesService;
        }

        if (subscription.Status == SubscriptionStatus.Suspended || subscription.Status == SubscriptionStatus.Cancelled)
        {
            return false;
        }

        if (subscription.Status == SubscriptionStatus.Trial && subscription.TrialEndsAt.HasValue && subscription.TrialEndsAt.Value < DateTime.UtcNow)
        {
            return false;
        }

        return subscription.Plan.EnabledFeatures.Contains(featureKey);
    }

    public async Task<bool> CanAddBranchAsync(Guid tenantId, CancellationToken cancellationToken = default)
    {
        var subscription = await GetActiveTenantSubscriptionAsync(tenantId, cancellationToken);
        var maxAllowed = subscription?.Plan?.MaxBranches ?? 1; // Default 1 branch for Starter

        var currentCount = await _context.Branches
            .CountAsync(b => b.TenantId == tenantId && b.IsActive, cancellationToken);

        return currentCount < maxAllowed;
    }

    public async Task<bool> CanAddEmployeeAsync(Guid tenantId, CancellationToken cancellationToken = default)
    {
        var subscription = await GetActiveTenantSubscriptionAsync(tenantId, cancellationToken);
        var maxAllowed = subscription?.Plan?.MaxEmployees ?? 5; // Default 5 for Starter

        var currentCount = await _context.Users
            .CountAsync(u => u.TenantId == tenantId && u.IsActive, cancellationToken);

        return currentCount < maxAllowed;
    }

    public async Task<bool> CanAddInventoryUnitAsync(Guid tenantId, CancellationToken cancellationToken = default)
    {
        var subscription = await GetActiveTenantSubscriptionAsync(tenantId, cancellationToken);
        var maxAllowed = subscription?.Plan?.MaxInventoryUnits ?? 50; // Default 50 for Starter

        var currentCount = await _context.InventoryItems
            .CountAsync(i => i.TenantId == tenantId 
                && i.Status != InventoryStatus.Sold 
                && i.Status != InventoryStatus.Delivered, cancellationToken);

        return currentCount < maxAllowed;
    }

    public async Task<TenantSubscriptionDto> GetSubscriptionDetailsAsync(Guid tenantId, CancellationToken cancellationToken = default)
    {
        var subscription = await GetActiveTenantSubscriptionAsync(tenantId, cancellationToken);

        var branchesCount = await _context.Branches
            .CountAsync(b => b.TenantId == tenantId && b.IsActive, cancellationToken);

        var employeesCount = await _context.Users
            .CountAsync(u => u.TenantId == tenantId && u.IsActive, cancellationToken);

        var inventoryCount = await _context.InventoryItems
            .CountAsync(i => i.TenantId == tenantId 
                && i.Status != InventoryStatus.Sold 
                && i.Status != InventoryStatus.Delivered, cancellationToken);

        var plan = subscription?.Plan;
        var isTrial = subscription?.Status == SubscriptionStatus.Trial;

        return new TenantSubscriptionDto
        {
            TenantId = tenantId,
            PlanCode = plan?.Code ?? "STARTER",
            PlanName = plan?.Name ?? "Starter Plan",
            Status = (subscription?.Status ?? SubscriptionStatus.Trial).ToString().ToUpperInvariant(),
            StartDate = subscription?.StartDate ?? DateTime.UtcNow,
            EndDate = subscription?.EndDate,
            TrialEndsAt = subscription?.TrialEndsAt,
            IsInTrial = isTrial,
            CurrentBranchesCount = branchesCount,
            MaxBranchesAllowed = plan?.MaxBranches ?? 1,
            CurrentEmployeesCount = employeesCount,
            MaxEmployeesAllowed = plan?.MaxEmployees ?? 5,
            CurrentInventoryCount = inventoryCount,
            MaxInventoryAllowed = plan?.MaxInventoryUnits ?? 50,
            EnabledFeatures = plan?.EnabledFeatures ?? new List<string>
            {
                SubscriptionFeatures.EmiCalculator,
                SubscriptionFeatures.AfterSalesService
            }
        };
    }

    private async Task<TenantSubscription?> GetActiveTenantSubscriptionAsync(Guid tenantId, CancellationToken cancellationToken)
    {
        return await _context.TenantSubscriptions
            .Include(ts => ts.Plan)
            .AsNoTracking()
            .FirstOrDefaultAsync(ts => ts.TenantId == tenantId, cancellationToken);
    }
}

