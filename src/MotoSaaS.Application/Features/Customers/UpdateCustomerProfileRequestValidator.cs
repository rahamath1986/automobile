using FluentValidation;

namespace MotoSaaS.Application.Features.Customers;

public class UpdateCustomerProfileRequestValidator : AbstractValidator<Models.UpdateCustomerProfileRequest>
{
    public UpdateCustomerProfileRequestValidator()
    {
        RuleFor(x => x.FirstName)
            .MaximumLength(100)
            .Must(name => string.IsNullOrWhiteSpace(name) || name.Trim().Length >= 2)
            .WithMessage("First name must be at least 2 characters.");
        RuleFor(x => x.LastName).MaximumLength(100);
        RuleFor(x => x.Email)
            .EmailAddress()
            .When(x => !string.IsNullOrWhiteSpace(x.Email))
            .WithMessage("Enter a valid email address.");
        RuleFor(x => x.AddressLine1).MaximumLength(250);
        RuleFor(x => x.City).MaximumLength(100);
        RuleFor(x => x.State).MaximumLength(100);
        RuleFor(x => x.PostalCode)
            .Matches(@"^[0-9]{4,10}$")
            .When(x => !string.IsNullOrWhiteSpace(x.PostalCode))
            .WithMessage("Enter a valid postal code.");
    }
}
