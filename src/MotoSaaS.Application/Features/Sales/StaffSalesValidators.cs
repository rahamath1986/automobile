using FluentValidation;
using MotoSaaS.Application.Features.Sales.Models;
using MotoSaaS.Domain.Sales;

namespace MotoSaaS.Application.Features.Sales;

public class LeadCaptureRequestValidator : AbstractValidator<LeadCaptureRequest>
{
    public LeadCaptureRequestValidator()
    {
        RuleFor(x => x.FirstName)
            .NotEmpty().WithMessage("Customer first name is required.")
            .MaximumLength(100);

        RuleFor(x => x.LastName).MaximumLength(100);

        RuleFor(x => x.Phone)
            .NotEmpty().WithMessage("Customer mobile number is required.")
            .MaximumLength(20)
            .Matches(@"^[0-9+\-\s()]{6,20}$").WithMessage("Enter a valid mobile number.");

        RuleFor(x => x.Email)
            .EmailAddress().When(x => !string.IsNullOrWhiteSpace(x.Email))
            .WithMessage("Enter a valid email address.");

        RuleFor(x => x.City).MaximumLength(100);
        RuleFor(x => x.VariantId).NotEmpty().WithMessage("A vehicle variant is required.");
        RuleFor(x => x.Notes).MaximumLength(1000);

        RuleFor(x => x.Source)
            .Must(source => Enum.TryParse<EnquirySource>(source, true, out _))
            .WithMessage("Source must be WalkIn, MobileApp, Web or Phone.");

        RuleFor(x => x.ExpectedPurchaseDate)
            .Must(date => !date.HasValue || date.Value.Date >= DateTime.UtcNow.Date.AddDays(-1))
            .WithMessage("Expected purchase date cannot be in the past.");
    }
}

public class AssignLeadRequestValidator : AbstractValidator<AssignLeadRequest>
{
    public AssignLeadRequestValidator()
    {
        RuleFor(x => x.SalesExecutiveId)
            .NotEmpty().WithMessage("Select a sales executive to own this lead.");
    }
}

public class UpdateLeadStatusRequestValidator : AbstractValidator<UpdateLeadStatusRequest>
{
    public UpdateLeadStatusRequestValidator()
    {
        RuleFor(x => x.Status)
            .NotEmpty()
            .Must(status => Enum.TryParse<EnquiryStatus>(status, true, out _))
            .WithMessage("Status must be New, Contacted, TestRide, Quoted, Booked or Lost.");

        RuleFor(x => x.LostReason).MaximumLength(500);

        RuleFor(x => x)
            .Must(request =>
                !Enum.TryParse<EnquiryStatus>(request.Status, true, out var status)
                || status != EnquiryStatus.Lost
                || !string.IsNullOrWhiteSpace(request.LostReason))
            .WithName("LostReason")
            .WithMessage("A reason is required when marking a lead as lost.");
    }
}

public class CreateFollowUpRequestValidator : AbstractValidator<CreateFollowUpRequest>
{
    public CreateFollowUpRequestValidator()
    {
        RuleFor(x => x.Channel)
            .NotEmpty()
            .Must(channel => Enum.TryParse<FollowUpChannel>(channel, true, out _))
            .WithMessage("Channel must be Phone, WhatsApp, Sms, Email or InPerson.");

        RuleFor(x => x.Outcome)
            .NotEmpty()
            .Must(outcome => Enum.TryParse<FollowUpOutcome>(outcome, true, out _))
            .WithMessage("Outcome is not a recognised follow-up result.");

        RuleFor(x => x.Notes).MaximumLength(1500).WithMessage("Follow-up notes must be 1500 characters or fewer.");

        RuleFor(x => x.ContactedAt)
            .Must(date => !date.HasValue || date.Value.ToUniversalTime() <= DateTime.UtcNow.AddMinutes(5))
            .WithMessage("Contact time cannot be in the future.");

        RuleFor(x => x.NextFollowUpAt)
            .Must(date => !date.HasValue || date.Value.ToUniversalTime() > DateTime.UtcNow.AddMinutes(-1))
            .WithMessage("Next follow-up must be scheduled in the future.")
            .Must(date => !date.HasValue || date.Value.ToUniversalTime() <= DateTime.UtcNow.AddDays(90))
            .WithMessage("Follow-ups can be scheduled at most 90 days ahead.");
    }
}

public class CompleteTestRideRequestValidator : AbstractValidator<CompleteTestRideRequest>
{
    public CompleteTestRideRequestValidator()
    {
        RuleFor(x => x.DrivingLicenseVerified)
            .Equal(true)
            .WithMessage("Verify the customer's driving licence before completing the test ride.");

        RuleFor(x => x.DrivingLicenseNumber).MaximumLength(30);
        RuleFor(x => x.FeedbackNotes).MaximumLength(2000);
    }
}

public class CancelTestRideRequestValidator : AbstractValidator<CancelTestRideRequest>
{
    public CancelTestRideRequestValidator()
    {
        RuleFor(x => x.Reason)
            .NotEmpty().WithMessage("A cancellation reason is required.")
            .MaximumLength(500);
    }
}
