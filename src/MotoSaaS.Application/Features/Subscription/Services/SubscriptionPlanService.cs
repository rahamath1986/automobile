using Microsoft.EntityFrameworkCore;
using MotoSaaS.Application.Common.Interfaces;
using MotoSaaS.Application.Features.Subscription.Interfaces;
using MotoSaaS.Application.Features.Subscription.Models;
using MotoSaaS.Domain.Subscription;

namespace MotoSaaS.Application.Features.Subscription.Services;

public class SubscriptionPlanService : ISubscriptionPlanService
{
    private readonly IApplicationDbContext _context;
    private readonly IEntitlementService _entitlementService;

    public SubscriptionPlanService(
        IApplicationDbContext context,
        IEntitlementService entitlementService)
    {
        _context = context;
        _entitlementService = entitlementService;
    }

    public async Task<List<SubscriptionPlanDto>> GetActivePlansAsync(CancellationToken cancellationToken = default)
    {
        var plans = await _context.SubscriptionPlans
            .Where(p => p.IsActive)
            .AsNoTracking()
            .ToListAsync(cancellationToken);

        if (plans.Count == 0)
        {
            // Return built-in plans if database is not yet seeded
            return GetBuiltInPlans();
        }

        return plans.Select(p => new SubscriptionPlanDto
        {
            Id = p.Id,
            Code = p.Code,
            Name = p.Name,
            Description = p.Description,
            MaxBranches = p.MaxBranches,
            MaxEmployees = p.MaxEmployees,
            MaxInventoryUnits = p.MaxInventoryUnits,
            EnabledFeatures = p.EnabledFeatures,
            TrialPeriodDays = p.TrialPeriodDays,
            IsActive = p.IsActive
        }).ToList();
    }

    public async Task<SubscriptionPlanDto?> GetPlanByCodeAsync(string planCode, CancellationToken cancellationToken = default)
    {
        var normalized = planCode.Trim().ToUpperInvariant();
        var plan = await _context.SubscriptionPlans
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.Code == normalized, cancellationToken);

        if (plan != null)
        {
            return new SubscriptionPlanDto
            {
                Id = plan.Id,
                Code = plan.Code,
                Name = plan.Name,
                Description = plan.Description,
                MaxBranches = plan.MaxBranches,
                MaxEmployees = plan.MaxEmployees,
                MaxInventoryUnits = plan.MaxInventoryUnits,
                EnabledFeatures = plan.EnabledFeatures,
                TrialPeriodDays = plan.TrialPeriodDays,
                IsActive = plan.IsActive
            };
        }

        return GetBuiltInPlans().FirstOrDefault(p => p.Code == normalized);
    }

    public async Task<TenantSubscriptionDto> AssignPlanAsync(Guid tenantId, string planCode, CancellationToken cancellationToken = default)
    {
        var normalized = planCode.Trim().ToUpperInvariant();
        var plan = await _context.SubscriptionPlans
            .FirstOrDefaultAsync(p => p.Code == normalized, cancellationToken);

        if (plan == null)
        {
            // Seed plan if missing
            var builtIn = GetBuiltInPlans().FirstOrDefault(p => p.Code == normalized)
                ?? throw new KeyNotFoundException($"Subscription plan with code '{planCode}' not found.");

            plan = new SubscriptionPlan
            {
                Code = builtIn.Code,
                Name = builtIn.Name,
                Description = builtIn.Description,
                MaxBranches = builtIn.MaxBranches,
                MaxEmployees = builtIn.MaxEmployees,
                MaxInventoryUnits = builtIn.MaxInventoryUnits,
                EnabledFeatures = builtIn.EnabledFeatures,
                TrialPeriodDays = builtIn.TrialPeriodDays,
                IsActive = true
            };

            _context.SubscriptionPlans.Add(plan);
            await _context.SaveChangesAsync(cancellationToken);
        }

        var existingSubscription = await _context.TenantSubscriptions
            .FirstOrDefaultAsync(ts => ts.TenantId == tenantId, cancellationToken);

        if (existingSubscription == null)
        {
            existingSubscription = new TenantSubscription
            {
                TenantId = tenantId,
                PlanId = plan.Id,
                Status = SubscriptionStatus.Active,
                StartDate = DateTime.UtcNow,
                EndDate = DateTime.UtcNow.AddYears(1)
            };
            _context.TenantSubscriptions.Add(existingSubscription);
        }
        else
        {
            existingSubscription.PlanId = plan.Id;
            existingSubscription.Status = SubscriptionStatus.Active;
            existingSubscription.EndDate = DateTime.UtcNow.AddYears(1);
        }

        await _context.SaveChangesAsync(cancellationToken);

        return await _entitlementService.GetSubscriptionDetailsAsync(tenantId, cancellationToken);
    }

    private static List<SubscriptionPlanDto> GetBuiltInPlans()
    {
        return new List<SubscriptionPlanDto>
        {
            new()
            {
                Code = "STARTER",
                Name = "Starter Dealership",
                Description = "Ideal for single-branch two-wheeler dealerships starting digital operations.",
                MaxBranches = 1,
                MaxEmployees = 5,
                MaxInventoryUnits = 50,
                TrialPeriodDays = 14,
                IsActive = true,
                EnabledFeatures = new List<string>
                {
                    SubscriptionFeatures.EmiCalculator,
                    SubscriptionFeatures.AfterSalesService
                }
            },
            new()
            {
                Code = "PROFESSIONAL",
                Name = "Growth Dealership",
                Description = "For growing dealerships requiring 3D virtual showrooms and financier tie-ups.",
                MaxBranches = 5,
                MaxEmployees = 25,
                MaxInventoryUnits = 500,
                TrialPeriodDays = 14,
                IsActive = true,
                EnabledFeatures = new List<string>
                {
                    SubscriptionFeatures.Showroom3D,
                    SubscriptionFeatures.EmiCalculator,
                    SubscriptionFeatures.FinancierSchemes,
                    SubscriptionFeatures.AfterSalesService,
                    SubscriptionFeatures.MultiBranchTransfer,
                    SubscriptionFeatures.CustomBranding
                }
            },
            new()
            {
                Code = "ENTERPRISE",
                Name = "Enterprise Multi-Branch",
                Description = "Full capability suite with unlimited branches, multi-OEM mappings, and advanced analytics.",
                MaxBranches = 100,
                MaxEmployees = 500,
                MaxInventoryUnits = 10000,
                TrialPeriodDays = 30,
                IsActive = true,
                EnabledFeatures = new List<string>
                {
                    SubscriptionFeatures.Showroom3D,
                    SubscriptionFeatures.EmiCalculator,
                    SubscriptionFeatures.FinancierSchemes,
                    SubscriptionFeatures.AfterSalesService,
                    SubscriptionFeatures.MultiBranchTransfer,
                    SubscriptionFeatures.AccountingExport,
                    SubscriptionFeatures.AdvancedAnalytics,
                    SubscriptionFeatures.CustomBranding
                }
            }
        };
    }
}

