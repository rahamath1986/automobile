using FluentValidation;

namespace MotoSaaS.Application.Features.Sales;

public class CreateTestRideRequestValidator : AbstractValidator<Models.CreateTestRideRequest>
{
    public CreateTestRideRequestValidator()
    {
        RuleFor(x => x.BranchId).NotEmpty().WithMessage("A dealership branch is required.");
        RuleFor(x => x.VariantId).NotEmpty().WithMessage("A vehicle variant is required.");
        RuleFor(x => x.ScheduledAt)
            .NotEmpty()
            .Must(date => date > DateTime.UtcNow)
            .WithMessage("Test ride time must be in the future.")
            .Must(date => date <= DateTime.UtcNow.AddDays(60))
            .WithMessage("Test rides can be scheduled at most 60 days in advance.");
        RuleFor(x => x.DrivingLicenseNumber).MaximumLength(30);
        RuleFor(x => x.FirstName).MaximumLength(100);
        RuleFor(x => x.LastName).MaximumLength(100);
        RuleFor(x => x.Phone)
            .MaximumLength(20)
            .Matches(@"^[0-9+\-\s()]{6,20}$")
            .When(x => !string.IsNullOrWhiteSpace(x.Phone))
            .WithMessage("Enter a valid mobile number.");
        RuleFor(x => x.Email)
            .EmailAddress()
            .When(x => !string.IsNullOrWhiteSpace(x.Email))
            .WithMessage("Enter a valid email address.");
    }
}
