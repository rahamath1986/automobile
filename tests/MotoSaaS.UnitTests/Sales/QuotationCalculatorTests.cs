using MotoSaaS.Application.Features.Sales.Services;
using Xunit;

namespace MotoSaaS.UnitTests.Sales;

public class QuotationCalculatorTests
{
    [Fact]
    public void Calculate_KarnatakaMotorcycle_AppliesStateRtoAndInsurance()
    {
        var quotedAt = new DateTime(2026, 11, 13, 10, 0, 0, DateTimeKind.Utc);

        var result = QuotationCalculator.Calculate(
            exShowroomPrice: 182000m,
            state: "Karnataka",
            accessoriesCharges: 5000m,
            handlingCharges: null,
            discountAmount: 3000m,
            validDays: 7,
            quotedAt: quotedAt);

        Assert.Equal(182000m, result.ExShowroomPrice);
        Assert.Equal(12m, result.RtoPercent);
        Assert.Equal(21840m, result.RtoCharges);
        Assert.Equal(3.5m, result.InsurancePercent);
        Assert.Equal(6370m, result.InsuranceCharges);
        Assert.Equal(5000m, result.AccessoriesCharges);
        Assert.Equal(2500m, result.HandlingCharges);
        Assert.Equal(217710m, result.Subtotal);
        Assert.Equal(3000m, result.DiscountAmount);
        Assert.Equal(214710m, result.TotalOnRoadPrice);
        Assert.Equal(quotedAt.AddDays(7), result.ValidUntil);
    }

    [Fact]
    public void Calculate_MinimumInsurance_IsApplied()
    {
        var result = QuotationCalculator.Calculate(
            exShowroomPrice: 30000m,
            state: "Delhi",
            accessoriesCharges: 0m,
            handlingCharges: 0m,
            discountAmount: 0m,
            validDays: 7);

        Assert.Equal(1500m, result.InsuranceCharges);
    }

    [Fact]
    public void Calculate_HandlingOverride_IsUsed()
    {
        var result = QuotationCalculator.Calculate(
            exShowroomPrice: 100000m,
            state: "Karnataka",
            accessoriesCharges: 0m,
            handlingCharges: 1000m,
            discountAmount: 0m,
            validDays: 7);

        Assert.Equal(1000m, result.HandlingCharges);
    }

    [Fact]
    public void Calculate_DiscountAboveExShowroomAndAccessories_Throws()
    {
        var ex = Assert.Throws<ArgumentException>(() => QuotationCalculator.Calculate(
            exShowroomPrice: 100000m,
            state: "Karnataka",
            accessoriesCharges: 1000m,
            handlingCharges: null,
            discountAmount: 102000m,
            validDays: 7));

        Assert.Contains("Discount cannot exceed", ex.Message);
    }

    [Fact]
    public void Calculate_LargeDiscount_AddsApprovalWarning()
    {
        var result = QuotationCalculator.Calculate(
            exShowroomPrice: 100000m,
            state: "Karnataka",
            accessoriesCharges: 0m,
            handlingCharges: null,
            discountAmount: 6000m,
            validDays: 7);

        Assert.Contains(result.Warnings, warning => warning.Contains("5%"));
    }

    [Fact]
    public void Calculate_ValidDaysOutOfRange_ClampsToOneToThirty()
    {
        var quotedAt = new DateTime(2026, 11, 13, 10, 0, 0, DateTimeKind.Utc);

        var tooShort = QuotationCalculator.Calculate(100000m, "Karnataka", 0m, null, 0m, -5, quotedAt);
        var tooLong = QuotationCalculator.Calculate(100000m, "Karnataka", 0m, null, 0m, 90, quotedAt);

        Assert.Equal(quotedAt.AddDays(1), tooShort.ValidUntil);
        Assert.Equal(quotedAt.AddDays(30), tooLong.ValidUntil);
    }

    [Fact]
    public void Calculate_NegativeDiscount_Throws()
    {
        Assert.Throws<ArgumentException>(() => QuotationCalculator.Calculate(
            100000m, "Karnataka", 0m, null, -1m, 7));
    }
}
