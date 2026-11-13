using MotoSaaS.Application.Features.Catalog.Services;
using Xunit;

namespace MotoSaaS.UnitTests.Catalog;

public class BranchPricingCalculatorTests
{
    [Theory]
    [InlineData("Karnataka", 12.0)]
    [InlineData("Tamil Nadu", 10.0)]
    [InlineData("Kerala", 11.0)]
    [InlineData("Delhi", 8.0)]
    [InlineData("Unknown State", 10.0)]
    [InlineData(null, 10.0)]
    public void GetRtoPercent_ReturnsStateRateWithDefault(string? state, decimal expected)
    {
        Assert.Equal(expected, BranchPricingCalculator.GetRtoPercent(state));
    }

    [Fact]
    public void Calculate_BuildsTransparentOnRoadBreakdown()
    {
        var result = BranchPricingCalculator.Calculate(200_000m, "Karnataka");

        Assert.Equal(200_000m, result.ExShowroomPrice);
        Assert.Equal(12.0m, result.RtoPercent);
        Assert.Equal(24_000m, result.RtoCharges);
        Assert.Equal(3.5m, result.InsurancePercent);
        Assert.Equal(7_000m, result.InsuranceCharges);
        Assert.Equal(2_500m, result.HandlingCharges);
        Assert.Equal(233_500m, result.EstimatedOnRoadPrice);
    }

    [Fact]
    public void Calculate_NeverProducesNegativeOrSubMinimumInsurance()
    {
        var result = BranchPricingCalculator.Calculate(-100m, "Karnataka");

        Assert.Equal(0m, result.ExShowroomPrice);
        Assert.Equal(1_500m, result.InsuranceCharges);
        Assert.Equal(1_500m + BranchPricingCalculator.DefaultHandlingCharge, result.EstimatedOnRoadPrice);
    }
}
