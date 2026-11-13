using MotoSaaS.Application.Features.Finance;
using Xunit;

namespace MotoSaaS.UnitTests.Finance;

public class EmiCalculatorServiceTests
{
    private readonly EmiCalculatorService _sut = new();

    [Fact]
    public void Calculate_ReducingBalance_ReturnsAccurateEmiAndZeroFinalBalance()
    {
        // Arrange: Yamaha R15 V4 example
        // On-road: 195,000, Down payment: 35,000 => Principal: 160,000
        // APR: 10.5%, Tenure: 36 months
        var request = new CalculateEmiRequest
        {
            VehiclePrice = 195000m,
            DownPayment = 35000m,
            AnnualInterestRatePercent = 10.5m,
            TenureMonths = 36,
            CalculationMethod = EmiCalculationMethod.ReducingBalance
        };

        // Act
        var result = _sut.Calculate(request);

        // Assert
        Assert.Equal(160000m, result.LoanPrincipal);
        Assert.Equal(36, result.TenureMonths);
        Assert.Equal(36, result.AmortizationSchedule.Count);

        // Standard reducing balance formula for 160,000 at 10.5% over 36 months is ~5,200.74
        Assert.InRange(result.MonthlyEmi, 5190m, 5210m);
        Assert.True(result.TotalInterestPayable > 25000m && result.TotalInterestPayable < 29000m);
        Assert.Equal(result.LoanPrincipal + result.TotalInterestPayable, result.TotalRepaymentAmount);

        // Verify amortization schedule invariants
        var totalPrincipalPaidInSchedule = result.AmortizationSchedule.Sum(x => x.PrincipalPaid);
        Assert.Equal(result.LoanPrincipal, totalPrincipalPaidInSchedule);

        var lastMonth = result.AmortizationSchedule.Last();
        Assert.Equal(0m, lastMonth.ClosingBalance);
    }

    [Fact]
    public void Calculate_FlatRate_ReturnsCorrectTotalInterestAndMonthlyEmi()
    {
        // Arrange
        // Principal: 100,000, APR: 10% flat, Tenure: 24 months (2 years)
        // Total interest = 100,000 * 0.10 * 2 = 20,000
        // Total repayment = 120,000
        // Monthly EMI = 120,000 / 24 = 5,000
        var request = new CalculateEmiRequest
        {
            VehiclePrice = 120000m,
            DownPayment = 20000m,
            AnnualInterestRatePercent = 10.0m,
            TenureMonths = 24,
            CalculationMethod = EmiCalculationMethod.FlatRate
        };

        // Act
        var result = _sut.Calculate(request);

        // Assert
        Assert.Equal(100000m, result.LoanPrincipal);
        Assert.Equal(20000m, result.TotalInterestPayable);
        Assert.Equal(120000m, result.TotalRepaymentAmount);
        Assert.Equal(5000m, result.MonthlyEmi);
        Assert.Equal(24, result.AmortizationSchedule.Count);
        Assert.Equal(0m, result.AmortizationSchedule.Last().ClosingBalance);
    }

    [Fact]
    public void Calculate_ZeroInterest_DividesPrincipalEquallyWithoutInterest()
    {
        // Arrange
        var request = new CalculateEmiRequest
        {
            VehiclePrice = 60000m,
            DownPayment = 0m,
            AnnualInterestRatePercent = 0m,
            TenureMonths = 12,
            CalculationMethod = EmiCalculationMethod.ReducingBalance
        };

        // Act
        var result = _sut.Calculate(request);

        // Assert
        Assert.Equal(60000m, result.LoanPrincipal);
        Assert.Equal(5000m, result.MonthlyEmi);
        Assert.Equal(0m, result.TotalInterestPayable);
        Assert.Equal(60000m, result.TotalRepaymentAmount);
        Assert.Equal(0m, result.AmortizationSchedule.Last().ClosingBalance);
    }

    [Fact]
    public void Calculate_FullDownPayment_ReturnsZeroEmiAndEmptySchedule()
    {
        // Arrange
        var request = new CalculateEmiRequest
        {
            VehiclePrice = 100000m,
            DownPayment = 100000m,
            AnnualInterestRatePercent = 10.5m,
            TenureMonths = 24
        };

        // Act
        var result = _sut.Calculate(request);

        // Assert
        Assert.Equal(0m, result.LoanPrincipal);
        Assert.Equal(0m, result.MonthlyEmi);
        Assert.Equal(0m, result.TotalRepaymentAmount);
        Assert.Empty(result.AmortizationSchedule);
    }
}

