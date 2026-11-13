using Microsoft.AspNetCore.Mvc;
using MotoSaaS.Api.Controllers;
using MotoSaaS.Application.Common.Models;
using MotoSaaS.Application.Features.Subscription.Interfaces;
using MotoSaaS.Application.Features.Subscription.Models;
using MotoSaaS.Domain.Subscription;
using MotoSaaS.Infrastructure.Services;
using Xunit;

namespace MotoSaaS.UnitTests.Controllers;

public class SubscriptionsControllerTests
{
    private class FakeSubscriptionPlanService : ISubscriptionPlanService
    {
        public Task<List<SubscriptionPlanDto>> GetActivePlansAsync(CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new List<SubscriptionPlanDto>
            {
                new() { Code = "STARTER", Name = "Starter", MaxBranches = 1 },
                new() { Code = "PROFESSIONAL", Name = "Professional", MaxBranches = 5 },
                new() { Code = "ENTERPRISE", Name = "Enterprise", MaxBranches = 100 }
            });
        }

        public Task<SubscriptionPlanDto?> GetPlanByCodeAsync(string planCode, CancellationToken cancellationToken = default)
        {
            return Task.FromResult<SubscriptionPlanDto?>(new SubscriptionPlanDto { Code = planCode });
        }

        public Task<TenantSubscriptionDto> AssignPlanAsync(Guid tenantId, string planCode, CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new TenantSubscriptionDto
            {
                TenantId = tenantId,
                PlanCode = planCode,
                Status = "ACTIVE"
            });
        }
    }

    private class FakeEntitlementService : IEntitlementService
    {
        public Task<bool> IsFeatureEnabledAsync(Guid tenantId, string featureKey, CancellationToken cancellationToken = default)
        {
            return Task.FromResult(featureKey == SubscriptionFeatures.EmiCalculator);
        }

        public Task<bool> CanAddBranchAsync(Guid tenantId, CancellationToken cancellationToken = default)
        {
            return Task.FromResult(true);
        }

        public Task<bool> CanAddEmployeeAsync(Guid tenantId, CancellationToken cancellationToken = default)
        {
            return Task.FromResult(true);
        }

        public Task<bool> CanAddInventoryUnitAsync(Guid tenantId, CancellationToken cancellationToken = default)
        {
            return Task.FromResult(true);
        }

        public Task<TenantSubscriptionDto> GetSubscriptionDetailsAsync(Guid tenantId, CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new TenantSubscriptionDto
            {
                TenantId = tenantId,
                PlanCode = "PROFESSIONAL",
                Status = "ACTIVE",
                CurrentBranchesCount = 2,
                MaxBranchesAllowed = 5
            });
        }
    }

    [Fact]
    public async Task GetPlans_ReturnsOkWithThreePlans()
    {
        var tenantContext = new TenantContext();
        var controller = new SubscriptionsController(new FakeSubscriptionPlanService(), new FakeEntitlementService(), tenantContext);

        var result = await controller.GetPlans(CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var envelope = Assert.IsType<ApiResponse<List<SubscriptionPlanDto>>>(okResult.Value);

        Assert.True(envelope.Success);
        Assert.Equal(3, envelope.Data!.Count);
    }

    [Fact]
    public async Task GetCurrentSubscription_WithTenantContext_ReturnsSubscriptionDetails()
    {
        var tenantContext = new TenantContext();
        var tenantId = Guid.NewGuid();
        tenantContext.SetTenant(tenantId);

        var controller = new SubscriptionsController(new FakeSubscriptionPlanService(), new FakeEntitlementService(), tenantContext);

        var result = await controller.GetCurrentSubscription(CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var envelope = Assert.IsType<ApiResponse<TenantSubscriptionDto>>(okResult.Value);

        Assert.True(envelope.Success);
        Assert.Equal(tenantId, envelope.Data!.TenantId);
        Assert.Equal("PROFESSIONAL", envelope.Data.PlanCode);
        Assert.Equal(2, envelope.Data.CurrentBranchesCount);
    }

    [Fact]
    public async Task UpgradeSubscription_ValidPlan_ReturnsUpdatedSubscription()
    {
        var tenantContext = new TenantContext();
        var tenantId = Guid.NewGuid();
        tenantContext.SetTenant(tenantId);

        var controller = new SubscriptionsController(new FakeSubscriptionPlanService(), new FakeEntitlementService(), tenantContext);
        var request = new UpgradeSubscriptionRequest { PlanCode = "ENTERPRISE" };

        var result = await controller.UpgradeSubscription(request, CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var envelope = Assert.IsType<ApiResponse<TenantSubscriptionDto>>(okResult.Value);

        Assert.True(envelope.Success);
        Assert.Equal("ENTERPRISE", envelope.Data!.PlanCode);
    }
}

