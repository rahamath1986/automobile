using MotoSaaS.Application.Features.Catalog.Services;

namespace MotoSaaS.Application.Features.Sales.Services;

/// <summary>
/// Deterministic on-road quotation math shared by preview and persisted quotations.
/// RTO/road-tax and insurance are derived from the branch state; the dealership can
/// override accessories, handling and discount per deal.
/// </summary>
public static class QuotationCalculator
{
    public const int DefaultValidDays = 7;
    public const int MaximumValidDays = 30;

    public static QuotationCalculation Calculate(
        decimal exShowroomPrice,
        string? state,
        decimal accessoriesCharges,
        decimal? handlingCharges,
        decimal discountAmount,
        int validDays,
        DateTime? quotedAt = null)
    {
        if (accessoriesCharges < 0)
        {
            throw new ArgumentException("Accessories charges cannot be negative.");
        }

        if (handlingCharges is < 0)
        {
            throw new ArgumentException("Handling charges cannot be negative.");
        }

        if (discountAmount < 0)
        {
            throw new ArgumentException("Discount cannot be negative.");
        }

        var price = Math.Max(exShowroomPrice, 0m);
        var pricing = BranchPricingCalculator.Calculate(
            price,
            state,
            accessoriesCharges,
            handlingCharges ?? BranchPricingCalculator.DefaultHandlingCharge);

        var discountableBase = pricing.ExShowroomPrice + pricing.AccessoriesCharges;
        if (discountAmount > discountableBase)
        {
            throw new ArgumentException(
                $"Discount cannot exceed the ex-showroom plus accessories amount of {discountableBase:N2}.");
        }

        var days = validDays == 0
            ? DefaultValidDays
            : Math.Clamp(validDays, 1, MaximumValidDays);
        var start = (quotedAt ?? DateTime.UtcNow).ToUniversalTime();

        var warnings = new List<string>();
        if (discountAmount > 0 && discountAmount > pricing.ExShowroomPrice * 0.05m)
        {
            warnings.Add("Discount exceeds 5% of the ex-showroom price and may require manager approval.");
        }

        return new QuotationCalculation(
            pricing.ExShowroomPrice,
            pricing.RtoPercent,
            pricing.RtoCharges,
            pricing.InsurancePercent,
            pricing.InsuranceCharges,
            pricing.AccessoriesCharges,
            pricing.HandlingCharges,
            pricing.EstimatedOnRoadPrice,
            Round(discountAmount),
            Round(pricing.EstimatedOnRoadPrice - discountAmount),
            start.AddDays(days),
            warnings);
    }

    private static decimal Round(decimal value) =>
        Math.Round(value, 2, MidpointRounding.AwayFromZero);
}

public record QuotationCalculation(
    decimal ExShowroomPrice,
    decimal RtoPercent,
    decimal RtoCharges,
    decimal InsurancePercent,
    decimal InsuranceCharges,
    decimal AccessoriesCharges,
    decimal HandlingCharges,
    decimal Subtotal,
    decimal DiscountAmount,
    decimal TotalOnRoadPrice,
    DateTime ValidUntil,
    IReadOnlyList<string> Warnings);
