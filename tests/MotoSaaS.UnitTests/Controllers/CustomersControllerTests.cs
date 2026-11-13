using Microsoft.AspNetCore.Mvc;
using MotoSaaS.Api.Controllers;
using MotoSaaS.Application.Common.Models;
using MotoSaaS.Application.Features.Customers;
using MotoSaaS.Application.Features.Customers.Interfaces;
using MotoSaaS.Application.Features.Customers.Models;
using Xunit;

namespace MotoSaaS.UnitTests.Controllers;

public class CustomersControllerTests
{
    private class FakeCustomerProfileService : ICustomerProfileService
    {
        public Task<CustomerProfileDto> GetProfileAsync(CancellationToken cancellationToken = default) =>
            Task.FromResult(new CustomerProfileDto
            {
                Id = Guid.NewGuid(),
                FirstName = "Aarav",
                LastName = "Shetty",
                FullName = "Aarav Shetty",
                Phone = "+919876543210",
                Email = "aarav@example.com",
                VehicleCount = 1,
                EnquiryCount = 2,
                ActiveServiceBookingCount = 1
            });

        public Task<CustomerProfileDto> UpdateProfileAsync(UpdateCustomerProfileRequest request, CancellationToken cancellationToken = default)
        {
            var profile = GetProfileAsync(cancellationToken).Result;
            profile.FirstName = request.FirstName ?? profile.FirstName;
            profile.Email = request.Email ?? profile.Email;
            return Task.FromResult(profile);
        }
    }

    private static CustomersController CreateController() =>
        new(new FakeCustomerProfileService(), new UpdateCustomerProfileRequestValidator());

    [Fact]
    public async Task GetProfile_ReturnsOwnershipSummary()
    {
        var controller = CreateController();

        var result = await controller.GetProfile(CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var envelope = Assert.IsType<ApiResponse<CustomerProfileDto>>(ok.Value);
        Assert.True(envelope.Success);
        Assert.Equal(1, envelope.Data!.VehicleCount);
        Assert.Equal("Aarav Shetty", envelope.Data.FullName);
    }

    [Fact]
    public async Task UpdateProfile_ValidRequest_ReturnsUpdatedProfile()
    {
        var controller = CreateController();
        var request = new UpdateCustomerProfileRequest
        {
            FirstName = "Rohan",
            City = "Mangalore",
            PostalCode = "575001"
        };

        var result = await controller.UpdateProfile(request, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var envelope = Assert.IsType<ApiResponse<CustomerProfileDto>>(ok.Value);
        Assert.Equal("Rohan", envelope.Data!.FirstName);
    }

    [Fact]
    public async Task UpdateProfile_InvalidEmail_ReturnsBadRequest()
    {
        var controller = CreateController();
        var request = new UpdateCustomerProfileRequest { Email = "invalid-email" };

        var result = await controller.UpdateProfile(request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task UpdateProfile_InvalidPostalCode_ReturnsBadRequest()
    {
        var controller = CreateController();
        var request = new UpdateCustomerProfileRequest { PostalCode = "ABC" };

        var result = await controller.UpdateProfile(request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
    }
}
