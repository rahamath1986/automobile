namespace MotoSaaS.Application.Features.Finance;

public class EmiCalculatorService : IEmiCalculatorService
{
    public CalculateEmiResponse Calculate(CalculateEmiRequest request)
    {
        var principal = request.VehiclePrice - request.DownPayment;
        if (principal <= 0)
        {
            return new CalculateEmiResponse
            {
                VehiclePrice = request.VehiclePrice,
                DownPayment = request.DownPayment,
                LoanPrincipal = 0,
                AnnualInterestRatePercent = request.AnnualInterestRatePercent,
                TenureMonths = request.TenureMonths,
                CalculationMethod = request.CalculationMethod.ToString(),
                MonthlyEmi = 0,
                TotalInterestPayable = 0,
                TotalRepaymentAmount = 0,
                AmortizationSchedule = new List<AmortizationScheduleItem>()
            };
        }

        if (request.CalculationMethod == EmiCalculationMethod.FlatRate)
        {
            return CalculateFlatRate(request, principal);
        }

        return CalculateReducingBalance(request, principal);
    }

    private static CalculateEmiResponse CalculateReducingBalance(CalculateEmiRequest request, decimal principal)
    {
        var n = request.TenureMonths;
        decimal monthlyEmi;

        if (request.AnnualInterestRatePercent <= 0)
        {
            monthlyEmi = Math.Round(principal / n, 2, MidpointRounding.AwayFromZero);
            var zeroInterestSchedule = new List<AmortizationScheduleItem>();
            var balance = principal;

            for (var m = 1; m <= n; m++)
            {
                var principalPaid = m == n ? balance : monthlyEmi;
                var closing = Math.Max(0, balance - principalPaid);
                zeroInterestSchedule.Add(new AmortizationScheduleItem
                {
                    Month = m,
                    OpeningBalance = balance,
                    EmiAmount = principalPaid,
                    PrincipalPaid = principalPaid,
                    InterestPaid = 0,
                    ClosingBalance = closing
                });
                balance = closing;
            }

            return new CalculateEmiResponse
            {
                VehiclePrice = request.VehiclePrice,
                DownPayment = request.DownPayment,
                LoanPrincipal = principal,
                AnnualInterestRatePercent = request.AnnualInterestRatePercent,
                TenureMonths = n,
                CalculationMethod = "REDUCING_BALANCE",
                MonthlyEmi = monthlyEmi,
                TotalInterestPayable = 0,
                TotalRepaymentAmount = principal,
                AmortizationSchedule = zeroInterestSchedule
            };
        }

        // Monthly periodic rate r = (APR / 12) / 100
        var r = (double)(request.AnnualInterestRatePercent / (12m * 100m));
        var p = (double)principal;

        // E = P * r * (1 + r)^n / ((1 + r)^n - 1)
        var factor = Math.Pow(1 + r, n);
        var emiDouble = p * r * factor / (factor - 1);
        monthlyEmi = Math.Round((decimal)emiDouble, 2, MidpointRounding.AwayFromZero);

        var schedule = new List<AmortizationScheduleItem>();
        var currentBalance = principal;
        decimal totalInterest = 0;

        for (var month = 1; month <= n; month++)
        {
            var interestForMonth = Math.Round(currentBalance * (request.AnnualInterestRatePercent / (12m * 100m)), 2, MidpointRounding.AwayFromZero);
            decimal principalForMonth;
            decimal closingBalance;

            if (month == n)
            {
                // Final month adjustment to settle exact remaining balance
                principalForMonth = currentBalance;
                monthlyEmi = principalForMonth + interestForMonth;
                closingBalance = 0;
            }
            else
            {
                principalForMonth = monthlyEmi - interestForMonth;
                closingBalance = Math.Max(0, currentBalance - principalForMonth);
            }

            totalInterest += interestForMonth;

            schedule.Add(new AmortizationScheduleItem
            {
                Month = month,
                OpeningBalance = currentBalance,
                EmiAmount = monthlyEmi,
                PrincipalPaid = principalForMonth,
                InterestPaid = interestForMonth,
                ClosingBalance = closingBalance
            });

            currentBalance = closingBalance;
        }

        return new CalculateEmiResponse
        {
            VehiclePrice = request.VehiclePrice,
            DownPayment = request.DownPayment,
            LoanPrincipal = principal,
            AnnualInterestRatePercent = request.AnnualInterestRatePercent,
            TenureMonths = n,
            CalculationMethod = "REDUCING_BALANCE",
            MonthlyEmi = schedule[0].EmiAmount,
            TotalInterestPayable = totalInterest,
            TotalRepaymentAmount = principal + totalInterest,
            AmortizationSchedule = schedule
        };
    }

    private static CalculateEmiResponse CalculateFlatRate(CalculateEmiRequest request, decimal principal)
    {
        var n = request.TenureMonths;
        var years = (decimal)n / 12m;
        var totalInterest = Math.Round(principal * (request.AnnualInterestRatePercent / 100m) * years, 2, MidpointRounding.AwayFromZero);
        var totalRepayment = principal + totalInterest;
        var monthlyEmi = Math.Round(totalRepayment / n, 2, MidpointRounding.AwayFromZero);
        var monthlyPrincipal = Math.Round(principal / n, 2, MidpointRounding.AwayFromZero);
        var monthlyInterest = Math.Round(totalInterest / n, 2, MidpointRounding.AwayFromZero);

        var schedule = new List<AmortizationScheduleItem>();
        var currentBalance = principal;

        for (var month = 1; month <= n; month++)
        {
            var closing = month == n ? 0 : Math.Max(0, currentBalance - monthlyPrincipal);
            schedule.Add(new AmortizationScheduleItem
            {
                Month = month,
                OpeningBalance = currentBalance,
                EmiAmount = monthlyEmi,
                PrincipalPaid = month == n ? currentBalance : monthlyPrincipal,
                InterestPaid = monthlyInterest,
                ClosingBalance = closing
            });
            currentBalance = closing;
        }

        return new CalculateEmiResponse
        {
            VehiclePrice = request.VehiclePrice,
            DownPayment = request.DownPayment,
            LoanPrincipal = principal,
            AnnualInterestRatePercent = request.AnnualInterestRatePercent,
            TenureMonths = n,
            CalculationMethod = "FLAT_RATE",
            MonthlyEmi = monthlyEmi,
            TotalInterestPayable = totalInterest,
            TotalRepaymentAmount = totalRepayment,
            AmortizationSchedule = schedule
        };
    }
}

