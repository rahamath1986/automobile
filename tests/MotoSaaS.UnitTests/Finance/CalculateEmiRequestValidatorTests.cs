using MotoSaaS.Application.Features.Finance;
using Xunit;

namespace MotoSaaS.UnitTests.Finance;

public class CalculateEmiRequestValidatorTests
{
    private readonly CalculateEmiRequestValidator _validator = new();

    [Fact]
    public void Validate_ValidParameters_ReturnsTrue()
    {
        var request = new CalculateEmiRequest
        {
            VehiclePrice = 150000m,
            DownPayment = 30000m,
            AnnualInterestRatePercent = 9.5m,
            TenureMonths = 36
        };

        var result = _validator.Validate(request);

        Assert.True(result.IsValid);
        Assert.Empty(result.Errors);
    }

    [Fact]
    public void Validate_ZeroOrNegativeVehiclePrice_FailsValidation()
    {
        var request = new CalculateEmiRequest
        {
            VehiclePrice = 0m,
            DownPayment = 0m,
            AnnualInterestRatePercent = 10m,
            TenureMonths = 24
        };

        var result = _validator.Validate(request);

        Assert.False(result.IsValid);
        Assert.Contains(result.Errors, e => e.PropertyName == nameof(request.VehiclePrice));
    }

    [Fact]
    public void Validate_DownPaymentExceedingVehiclePrice_FailsValidation()
    {
        var request = new CalculateEmiRequest
        {
            VehiclePrice = 100000m,
            DownPayment = 120000m,
            AnnualInterestRatePercent = 10m,
            TenureMonths = 24
        };

        var result = _validator.Validate(request);

        Assert.False(result.IsValid);
        Assert.Contains(result.Errors, e => e.PropertyName == nameof(request.DownPayment));
    }

    [Fact]
    public void Validate_ExcessiveInterestRate_FailsValidation()
    {
        var request = new CalculateEmiRequest
        {
            VehiclePrice = 100000m,
            DownPayment = 20000m,
            AnnualInterestRatePercent = 55m, // Exceeds 50% limit
            TenureMonths = 24
        };

        var result = _validator.Validate(request);

        Assert.False(result.IsValid);
        Assert.Contains(result.Errors, e => e.PropertyName == nameof(request.AnnualInterestRatePercent));
    }

    [Fact]
    public void Validate_InvalidTenureMonths_FailsValidation()
    {
        var request = new CalculateEmiRequest
        {
            VehiclePrice = 100000m,
            DownPayment = 20000m,
            AnnualInterestRatePercent = 10m,
            TenureMonths = 1 // Below minimum 3 months
        };

        var result = _validator.Validate(request);

        Assert.False(result.IsValid);
        Assert.Contains(result.Errors, e => e.PropertyName == nameof(request.TenureMonths));
    }
}

