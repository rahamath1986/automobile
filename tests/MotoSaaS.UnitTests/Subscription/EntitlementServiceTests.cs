using MotoSaaS.Application.Features.Subscription.Models;
using MotoSaaS.Domain.Subscription;
using Xunit;

namespace MotoSaaS.UnitTests.Subscription;

public class EntitlementServiceTests
{
    [Fact]
    public void SubscriptionFeatures_ContainsStandardKeys()
    {
        Assert.Equal("Showroom3D", SubscriptionFeatures.Showroom3D);
        Assert.Equal("EmiCalculator", SubscriptionFeatures.EmiCalculator);
        Assert.Equal("FinancierSchemes", SubscriptionFeatures.FinancierSchemes);
        Assert.Equal("AfterSalesService", SubscriptionFeatures.AfterSalesService);
    }

    [Fact]
    public void SubscriptionPlanDto_CapturesLimitsAccurately()
    {
        var plan = new SubscriptionPlanDto
        {
            Code = "STARTER",
            Name = "Starter Dealership",
            MaxBranches = 1,
            MaxEmployees = 5,
            MaxInventoryUnits = 50,
            EnabledFeatures = new List<string> { SubscriptionFeatures.EmiCalculator }
        };

        Assert.Equal(1, plan.MaxBranches);
        Assert.Equal(5, plan.MaxEmployees);
        Assert.Equal(50, plan.MaxInventoryUnits);
        Assert.Contains(SubscriptionFeatures.EmiCalculator, plan.EnabledFeatures);
        Assert.DoesNotContain(SubscriptionFeatures.Showroom3D, plan.EnabledFeatures);
    }

    [Fact]
    public void TenantSubscriptionDto_IdentifiesTrialCorrectly()
    {
        var sub = new TenantSubscriptionDto
        {
            TenantId = Guid.NewGuid(),
            PlanCode = "STARTER",
            Status = "TRIAL",
            IsInTrial = true,
            CurrentBranchesCount = 1,
            MaxBranchesAllowed = 1
        };

        Assert.True(sub.IsInTrial);
        Assert.Equal("TRIAL", sub.Status);
        Assert.Equal(sub.CurrentBranchesCount, sub.MaxBranchesAllowed);
    }
}

