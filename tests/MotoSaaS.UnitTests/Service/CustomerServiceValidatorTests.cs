using MotoSaaS.Application.Features.Service;
using MotoSaaS.Application.Features.Service.Models;
using Xunit;

namespace MotoSaaS.UnitTests.Service;

public class CustomerServiceValidatorTests
{
    private readonly CreateServiceBookingRequestValidator _validator = new();

    [Fact]
    public void Booking_ValidRequest_Passes()
    {
        var request = new CreateServiceBookingRequest
        {
            CustomerVehicleId = Guid.NewGuid(),
            BranchId = Guid.NewGuid(),
            ServiceType = "PERIODIC",
            ScheduledDate = DateTime.UtcNow.Date.AddDays(5),
            TimeSlot = "09:00 - 10:00",
            CustomerComplaints = "Brake squeal"
        };

        Assert.True(_validator.Validate(request).IsValid);
    }

    [Fact]
    public void Booking_TooFarInFuture_Fails()
    {
        var request = new CreateServiceBookingRequest
        {
            CustomerVehicleId = Guid.NewGuid(),
            BranchId = Guid.NewGuid(),
            ServiceType = "PERIODIC",
            ScheduledDate = DateTime.UtcNow.Date.AddDays(120)
        };

        var result = _validator.Validate(request);

        Assert.False(result.IsValid);
        Assert.Contains(result.Errors, e => e.PropertyName == "ScheduledDate");
    }

    [Fact]
    public void Booking_MissingVehicle_Fails()
    {
        var result = _validator.Validate(new CreateServiceBookingRequest
        {
            BranchId = Guid.NewGuid(),
            ServiceType = "PAID_GENERAL",
            ScheduledDate = DateTime.UtcNow.Date.AddDays(1)
        });

        Assert.False(result.IsValid);
        Assert.Contains(result.Errors, e => e.PropertyName == "CustomerVehicleId");
    }
}
