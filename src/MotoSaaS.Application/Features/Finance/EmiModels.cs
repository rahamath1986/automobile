namespace MotoSaaS.Application.Features.Finance;

public enum EmiCalculationMethod
{
    ReducingBalance,
    FlatRate
}

public class CalculateEmiRequest
{
    public decimal VehiclePrice { get; set; }
    public decimal DownPayment { get; set; }
    public decimal AnnualInterestRatePercent { get; set; }
    public int TenureMonths { get; set; }
    public EmiCalculationMethod CalculationMethod { get; set; } = EmiCalculationMethod.ReducingBalance;
}

public class AmortizationScheduleItem
{
    public int Month { get; set; }
    public decimal OpeningBalance { get; set; }
    public decimal EmiAmount { get; set; }
    public decimal PrincipalPaid { get; set; }
    public decimal InterestPaid { get; set; }
    public decimal ClosingBalance { get; set; }
}

public class CalculateEmiResponse
{
    public decimal VehiclePrice { get; set; }
    public decimal DownPayment { get; set; }
    public decimal LoanPrincipal { get; set; }
    public decimal AnnualInterestRatePercent { get; set; }
    public int TenureMonths { get; set; }
    public string CalculationMethod { get; set; } = string.Empty;
    public decimal MonthlyEmi { get; set; }
    public decimal TotalInterestPayable { get; set; }
    public decimal TotalRepaymentAmount { get; set; }
    public List<AmortizationScheduleItem> AmortizationSchedule { get; set; } = new();
}

public interface IEmiCalculatorService
{
    CalculateEmiResponse Calculate(CalculateEmiRequest request);
}

