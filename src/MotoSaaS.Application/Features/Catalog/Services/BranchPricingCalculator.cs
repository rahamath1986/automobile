namespace MotoSaaS.Application.Features.Catalog.Services;

/// <summary>
/// Deterministic, bank-agnostic on-road price estimation used for customer discovery.
/// The dealership remains the authority for the final quotation.
/// </summary>
public static class BranchPricingCalculator
{
    public const decimal DefaultRtoPercent = 10.0m;
    public const decimal DefaultInsurancePercent = 3.5m;
    public const decimal MinimumInsuranceCharge = 1500.0m;
    public const decimal DefaultHandlingCharge = 2500.0m;

    private static readonly Dictionary<string, decimal> StateRtoRates = new(StringComparer.OrdinalIgnoreCase)
    {
        ["KARNATAKA"] = 12.0m,
        ["TAMIL NADU"] = 10.0m,
        ["TAMILNADU"] = 10.0m,
        ["KERALA"] = 11.0m,
        ["MAHARASHTRA"] = 12.0m,
        ["DELHI"] = 8.0m,
        ["TELANGANA"] = 12.0m,
        ["ANDHRA PRADESH"] = 12.0m,
        ["GUJARAT"] = 9.0m,
        ["RAJASTHAN"] = 10.0m,
        ["UTTAR PRADESH"] = 10.0m
    };

    public static decimal GetRtoPercent(string? state)
    {
        if (string.IsNullOrWhiteSpace(state))
        {
            return DefaultRtoPercent;
        }

        return StateRtoRates.TryGetValue(state.Trim(), out var rate)
            ? rate
            : DefaultRtoPercent;
    }

    public static PricingBreakdown Calculate(
        decimal exShowroomPrice,
        string? state,
        decimal accessoriesCharges = 0m,
        decimal handlingCharges = DefaultHandlingCharge)
    {
        var price = Math.Max(exShowroomPrice, 0m);
        var rtoPercent = GetRtoPercent(state);

        var rto = Round(price * rtoPercent / 100m);
        var insurance = Round(Math.Max(price * DefaultInsurancePercent / 100m, MinimumInsuranceCharge));
        var accessories = Round(Math.Max(accessoriesCharges, 0m));
        var handling = Round(Math.Max(handlingCharges, 0m));
        var onRoad = Round(price + rto + insurance + accessories + handling);

        return new PricingBreakdown(
            price,
            rtoPercent,
            rto,
            DefaultInsurancePercent,
            insurance,
            accessories,
            handling,
            onRoad);
    }

    private static decimal Round(decimal value) =>
        Math.Round(value, 2, MidpointRounding.AwayFromZero);
}

public record PricingBreakdown(
    decimal ExShowroomPrice,
    decimal RtoPercent,
    decimal RtoCharges,
    decimal InsurancePercent,
    decimal InsuranceCharges,
    decimal AccessoriesCharges,
    decimal HandlingCharges,
    decimal EstimatedOnRoadPrice);
