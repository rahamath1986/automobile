using FluentValidation;
using MotoSaaS.Application.Features.Sales.Models;

namespace MotoSaaS.Application.Features.Sales;

public class QuotationDraftRequestValidator : AbstractValidator<QuotationDraftRequest>
{
    public QuotationDraftRequestValidator()
    {
        RuleFor(x => x.AccessoriesCharges)
            .GreaterThanOrEqualTo(0).WithMessage("Accessories charges cannot be negative.");

        RuleFor(x => x.HandlingCharges)
            .GreaterThanOrEqualTo(0).When(x => x.HandlingCharges.HasValue)
            .WithMessage("Handling charges cannot be negative.");

        RuleFor(x => x.DiscountAmount)
            .GreaterThanOrEqualTo(0).WithMessage("Discount cannot be negative.");

        RuleFor(x => x.ValidDays)
            .InclusiveBetween(1, 30)
            .WithMessage("A quotation must be valid for between 1 and 30 days.");

        RuleFor(x => x)
            .Must(x => x.EnquiryId.HasValue || (x.CustomerId.HasValue && x.VariantId.HasValue))
            .WithName("EnquiryId")
            .WithMessage("Provide an enquiry, or a customer and vehicle variant for a direct quotation.");

        RuleFor(x => x.VariantId)
            .NotEmpty()
            .When(x => !x.EnquiryId.HasValue)
            .WithMessage("A vehicle variant is required for a direct quotation.");

        RuleFor(x => x.CustomerId)
            .NotEmpty()
            .When(x => !x.EnquiryId.HasValue)
            .WithMessage("A customer is required for a direct quotation.");
    }
}
