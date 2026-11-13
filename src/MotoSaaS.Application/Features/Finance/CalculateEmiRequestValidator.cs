using FluentValidation;

namespace MotoSaaS.Application.Features.Finance;

public class CalculateEmiRequestValidator : AbstractValidator<CalculateEmiRequest>
{
    public CalculateEmiRequestValidator()
    {
        RuleFor(x => x.VehiclePrice)
            .GreaterThan(0)
            .WithMessage("Vehicle price must be greater than zero.");

        RuleFor(x => x.DownPayment)
            .GreaterThanOrEqualTo(0)
            .WithMessage("Down payment cannot be negative.")
            .LessThan(x => x.VehiclePrice)
            .WithMessage("Down payment must be less than the total vehicle price.");

        RuleFor(x => x.AnnualInterestRatePercent)
            .GreaterThanOrEqualTo(0)
            .WithMessage("Annual interest rate cannot be negative.")
            .LessThanOrEqualTo(50)
            .WithMessage("Annual interest rate cannot exceed 50%.");

        RuleFor(x => x.TenureMonths)
            .InclusiveBetween(3, 84)
            .WithMessage("Tenure must be between 3 and 84 months.");
    }
}

