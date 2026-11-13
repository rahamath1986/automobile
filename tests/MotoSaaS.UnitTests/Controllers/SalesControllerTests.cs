using Microsoft.AspNetCore.Mvc;
using MotoSaaS.Api.Controllers;
using MotoSaaS.Application.Common.Models;
using MotoSaaS.Application.Features.Sales;
using MotoSaaS.Application.Features.Sales.Interfaces;
using MotoSaaS.Application.Features.Sales.Models;
using Xunit;

namespace MotoSaaS.UnitTests.Controllers;

public class SalesControllerTests
{
    private class FakeCustomerSalesService : ICustomerSalesService
    {
        public Task<EnquiryDto> CreateEnquiryAsync(CreateEnquiryRequest request, CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new EnquiryDto
            {
                Id = Guid.NewGuid(),
                BranchId = request.BranchId,
                BranchName = "Mangalore Central",
                VariantId = request.VariantId,
                VariantName = "R15M",
                ModelName = "Yamaha YZF R15 V4",
                Status = "NEW",
                Source = "MOBILEAPP",
                CreatedAt = DateTime.UtcNow
            });
        }

        public Task<List<EnquiryDto>> GetMyEnquiriesAsync(CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new List<EnquiryDto>
            {
                new() { Id = Guid.NewGuid(), Status = "NEW", VariantName = "R15M" }
            });
        }

        public Task<TestRideDto> CreateTestRideAsync(CreateTestRideRequest request, CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new TestRideDto
            {
                Id = Guid.NewGuid(),
                BranchId = request.BranchId,
                BranchName = "Mangalore Central",
                VariantId = request.VariantId,
                VariantName = "R15M",
                ScheduledAt = request.ScheduledAt,
                Status = "SCHEDULED",
                CreatedAt = DateTime.UtcNow
            });
        }

        public Task<List<TestRideDto>> GetMyTestRidesAsync(CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new List<TestRideDto>
            {
                new() { Id = Guid.NewGuid(), Status = "SCHEDULED" }
            });
        }
    }

    private static SalesController CreateController() =>
        new(
            new FakeCustomerSalesService(),
            new CreateEnquiryRequestValidator(),
            new CreateTestRideRequestValidator());

    [Fact]
    public async Task CreateEnquiry_ValidRequest_ReturnsCreated()
    {
        var controller = CreateController();
        var request = new CreateEnquiryRequest
        {
            BranchId = Guid.NewGuid(),
            VariantId = Guid.NewGuid(),
            FirstName = "Aarav",
            Phone = "9876543210"
        };

        var result = await controller.CreateEnquiry(request, CancellationToken.None);

        var created = Assert.IsType<ObjectResult>(result);
        Assert.Equal(201, created.StatusCode);
        var envelope = Assert.IsType<ApiResponse<EnquiryDto>>(created.Value);
        Assert.True(envelope.Success);
        Assert.Equal("NEW", envelope.Data!.Status);
    }

    [Fact]
    public async Task CreateEnquiry_InvalidRequest_ReturnsBadRequest()
    {
        var controller = CreateController();

        var result = await controller.CreateEnquiry(new CreateEnquiryRequest(), CancellationToken.None);

        var badRequest = Assert.IsType<BadRequestObjectResult>(result);
        var envelope = Assert.IsType<ApiResponse<object>>(badRequest.Value);
        Assert.False(envelope.Success);
        Assert.NotNull(envelope.Errors);
        Assert.NotEmpty(envelope.Errors!);
    }

    [Fact]
    public async Task GetMyEnquiries_ReturnsCustomerEnquiries()
    {
        var controller = CreateController();

        var result = await controller.GetMyEnquiries(CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var envelope = Assert.IsType<ApiResponse<List<EnquiryDto>>>(ok.Value);
        Assert.True(envelope.Success);
        Assert.Single(envelope.Data!);
    }

    [Fact]
    public async Task CreateTestRide_FutureRequest_ReturnsCreated()
    {
        var controller = CreateController();
        var request = new CreateTestRideRequest
        {
            BranchId = Guid.NewGuid(),
            VariantId = Guid.NewGuid(),
            ScheduledAt = DateTime.UtcNow.AddDays(2),
            FirstName = "Aarav",
            Phone = "9876543210"
        };

        var result = await controller.CreateTestRide(request, CancellationToken.None);

        var created = Assert.IsType<ObjectResult>(result);
        Assert.Equal(201, created.StatusCode);
    }

    [Fact]
    public async Task CreateTestRide_PastRequest_ReturnsBadRequest()
    {
        var controller = CreateController();
        var request = new CreateTestRideRequest
        {
            BranchId = Guid.NewGuid(),
            VariantId = Guid.NewGuid(),
            ScheduledAt = DateTime.UtcNow.AddHours(-2)
        };

        var result = await controller.CreateTestRide(request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task GetMyTestRides_ReturnsTestRides()
    {
        var controller = CreateController();

        var result = await controller.GetMyTestRides(CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var envelope = Assert.IsType<ApiResponse<List<TestRideDto>>>(ok.Value);
        Assert.Single(envelope.Data!);
    }
}
