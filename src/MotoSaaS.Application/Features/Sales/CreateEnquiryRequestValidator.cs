using FluentValidation;

namespace MotoSaaS.Application.Features.Sales;

public class CreateEnquiryRequestValidator : AbstractValidator<Models.CreateEnquiryRequest>
{
    public CreateEnquiryRequestValidator()
    {
        RuleFor(x => x.BranchId).NotEmpty().WithMessage("A dealership branch is required.");
        RuleFor(x => x.VariantId).NotEmpty().WithMessage("A vehicle variant is required.");
        RuleFor(x => x.Notes).MaximumLength(1000);
        RuleFor(x => x.ExpectedPurchaseDate)
            .Must(date => !date.HasValue || date.Value.Date >= DateTime.UtcNow.Date.AddDays(-1))
            .WithMessage("Expected purchase date cannot be in the past.");
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
