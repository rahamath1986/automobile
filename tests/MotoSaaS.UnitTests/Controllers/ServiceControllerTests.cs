using FluentValidation;
using Microsoft.AspNetCore.Mvc;
using MotoSaaS.Api.Controllers;
using MotoSaaS.Application.Common.Models;
using MotoSaaS.Application.Features.Service;
using MotoSaaS.Application.Features.Service.Interfaces;
using MotoSaaS.Application.Features.Service.Models;
using Xunit;

namespace MotoSaaS.UnitTests.Controllers;

public class ServiceControllerTests
{
    private class FakeCustomerServiceBookingService : ICustomerServiceBookingService
    {
        public Task<List<CustomerVehicleDto>> GetMyVehiclesAsync(CancellationToken cancellationToken = default) =>
            Task.FromResult(new List<CustomerVehicleDto>
            {
                new()
                {
                    Id = Guid.NewGuid(),
                    RegistrationNumber = "KA19AB1234",
                    ChassisNumberMasked = "•••• 9988",
                    ModelName = "Yamaha YZF R15 V4",
                    VariantName = "R15M"
                }
            });

        public Task<List<ServiceBookingDto>> GetMyBookingsAsync(CancellationToken cancellationToken = default) =>
            Task.FromResult(new List<ServiceBookingDto>
            {
                new()
                {
                    Id = Guid.NewGuid(),
                    RegistrationNumber = "KA19AB1234",
                    Status = "BOOKED",
                    ServiceType = "PERIODIC"
                }
            });

        public Task<ServiceBookingDto> CreateBookingAsync(CreateServiceBookingRequest request, CancellationToken cancellationToken = default) =>
            Task.FromResult(new ServiceBookingDto
            {
                Id = Guid.NewGuid(),
                CustomerVehicleId = request.CustomerVehicleId,
                BranchId = request.BranchId,
                ServiceType = request.ServiceType,
                ScheduledDate = request.ScheduledDate,
                TimeSlot = request.TimeSlot,
                Status = "BOOKED",
                CreatedAt = DateTime.UtcNow
            });

        public Task<ServiceTrackingDto> GetTrackingAsync(Guid bookingId, CancellationToken cancellationToken = default) =>
            Task.FromResult(new ServiceTrackingDto
            {
                Booking = new ServiceBookingDto { Id = bookingId, Status = "BOOKED" },
                CurrentStage = "Appointment booked",
                ProgressPercent = 10,
                Timeline = new List<ServiceTimelineStepDto>
                {
                    new() { Label = "Appointment booked", Completed = true }
                }
            });

        public Task<ServiceTrackingDto> ApproveEstimateAsync(Guid jobCardId, CancellationToken cancellationToken = default) =>
            Task.FromResult(new ServiceTrackingDto
            {
                JobCard = new JobCardProgressDto { Id = jobCardId, CustomerApproved = true, Status = "APPROVED" },
                CurrentStage = "Estimate approved",
                ProgressPercent = 45
            });
    }

    private static ServiceController CreateController() =>
        new(new FakeCustomerServiceBookingService(), new CreateServiceBookingRequestValidator());

    [Fact]
    public async Task GetMyVehicles_ReturnsGarage()
    {
        var controller = CreateController();

        var result = await controller.GetMyVehicles(CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var envelope = Assert.IsType<ApiResponse<List<CustomerVehicleDto>>>(ok.Value);
        Assert.True(envelope.Success);
        Assert.Single(envelope.Data!);
        Assert.Equal("KA19AB1234", envelope.Data![0].RegistrationNumber);
    }

    [Fact]
    public async Task GetMyBookings_ReturnsAppointments()
    {
        var controller = CreateController();

        var result = await controller.GetMyBookings(CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var envelope = Assert.IsType<ApiResponse<List<ServiceBookingDto>>>(ok.Value);
        Assert.Single(envelope.Data!);
    }

    [Fact]
    public async Task CreateBooking_ValidRequest_ReturnsCreated()
    {
        var controller = CreateController();
        var request = new CreateServiceBookingRequest
        {
            CustomerVehicleId = Guid.NewGuid(),
            BranchId = Guid.NewGuid(),
            ServiceType = "PERIODIC",
            ScheduledDate = DateTime.UtcNow.Date.AddDays(3),
            TimeSlot = "10:00 - 11:00",
            CustomerComplaints = "Chain noise"
        };

        var result = await controller.CreateBooking(request, CancellationToken.None);

        var created = Assert.IsType<ObjectResult>(result);
        Assert.Equal(201, created.StatusCode);
        var envelope = Assert.IsType<ApiResponse<ServiceBookingDto>>(created.Value);
        Assert.Equal("BOOKED", envelope.Data!.Status);
    }

    [Fact]
    public async Task CreateBooking_PastDate_ReturnsBadRequest()
    {
        var controller = CreateController();
        var request = new CreateServiceBookingRequest
        {
            CustomerVehicleId = Guid.NewGuid(),
            BranchId = Guid.NewGuid(),
            ServiceType = "PERIODIC",
            ScheduledDate = DateTime.UtcNow.Date.AddDays(-2)
        };

        var result = await controller.CreateBooking(request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task CreateBooking_InvalidServiceType_ReturnsBadRequest()
    {
        var controller = CreateController();
        var request = new CreateServiceBookingRequest
        {
            CustomerVehicleId = Guid.NewGuid(),
            BranchId = Guid.NewGuid(),
            ServiceType = "FREE_FUEL",
            ScheduledDate = DateTime.UtcNow.Date.AddDays(3)
        };

        var result = await controller.CreateBooking(request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task GetTracking_ReturnsTimeline()
    {
        var controller = CreateController();

        var result = await controller.GetTracking(Guid.NewGuid(), CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var envelope = Assert.IsType<ApiResponse<ServiceTrackingDto>>(ok.Value);
        Assert.Single(envelope.Data!.Timeline);
        Assert.Equal(10, envelope.Data.ProgressPercent);
    }

    [Fact]
    public async Task ApproveEstimate_ReturnsUpdatedTracking()
    {
        var controller = CreateController();

        var result = await controller.ApproveEstimate(Guid.NewGuid(), CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var envelope = Assert.IsType<ApiResponse<ServiceTrackingDto>>(ok.Value);
        Assert.True(envelope.Data!.JobCard!.CustomerApproved);
    }
}
