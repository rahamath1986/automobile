using FluentValidation;

namespace MotoSaaS.Application.Features.Service;

public class CreateServiceBookingRequestValidator : AbstractValidator<Models.CreateServiceBookingRequest>
{
    private static readonly HashSet<string> AllowedServiceTypes = new(StringComparer.OrdinalIgnoreCase)
    {
        "FREE_SERVICE",
        "PAID_GENERAL",
        "PERIODIC",
        "REPAIR",
        "ACCIDENT",
        "BATTERY"
    };

    public CreateServiceBookingRequestValidator()
    {
        RuleFor(x => x.CustomerVehicleId).NotEmpty().WithMessage("Select the vehicle to be serviced.");
        RuleFor(x => x.BranchId).NotEmpty().WithMessage("Select a service branch.");
        RuleFor(x => x.ServiceType)
            .NotEmpty()
            .Must(type => AllowedServiceTypes.Contains(type))
            .WithMessage("Select a valid service type.");
        RuleFor(x => x.ScheduledDate)
            .Must(date => date.Date >= DateTime.UtcNow.Date)
            .WithMessage("Service date cannot be in the past.")
            .Must(date => date <= DateTime.UtcNow.AddDays(90))
            .WithMessage("Service appointments can be booked at most 90 days in advance.");
        RuleFor(x => x.TimeSlot).NotEmpty().MaximumLength(40);
        RuleFor(x => x.CustomerComplaints).MaximumLength(1000);
    }
}
