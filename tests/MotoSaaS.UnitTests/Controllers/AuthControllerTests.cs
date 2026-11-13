using Microsoft.AspNetCore.Mvc;
using MotoSaaS.Api.Controllers;
using MotoSaaS.Application.Common.Models;
using MotoSaaS.Application.Features.Identity.Interfaces;
using MotoSaaS.Application.Features.Identity.Models;
using Xunit;

namespace MotoSaaS.UnitTests.Controllers;

public class AuthControllerTests
{
    private class FakeStaffAuthService : IStaffAuthService
    {
        public Task<AuthResponse> LoginAsync(StaffLoginRequest request, CancellationToken cancellationToken = default)
        {
            if (request.DealerCode == "ALAGENDRA" && request.Password == "ValidPass")
            {
                return Task.FromResult(new AuthResponse
                {
                    AccessToken = "MOCK_STAFF_TOKEN",
                    RefreshToken = "MOCK_REFRESH_TOKEN",
                    User = new UserProfileDto
                    {
                        FullName = "Staff Member",
                        UserType = "DEALER_STAFF",
                        Roles = new List<string> { "SalesExecutive" }
                    }
                });
            }

            throw new UnauthorizedAccessException("Invalid credentials.");
        }

        public Task<AuthResponse> RefreshTokenAsync(RefreshTokenRequest request, CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new AuthResponse { AccessToken = "NEW_TOKEN" });
        }
    }

    private class FakeCustomerAuthService : ICustomerAuthService
    {
        public Task<bool> RequestOtpAsync(CustomerRequestOtpRequest request, CancellationToken cancellationToken = default)
        {
            return Task.FromResult(true);
        }

        public Task<AuthResponse> VerifyOtpAsync(CustomerVerifyOtpRequest request, CancellationToken cancellationToken = default)
        {
            if (request.Otp == "123456")
            {
                return Task.FromResult(new AuthResponse
                {
                    AccessToken = "MOCK_CUSTOMER_TOKEN",
                    RefreshToken = "MOCK_CUSTOMER_REFRESH",
                    User = new UserProfileDto
                    {
                        FullName = "Test Customer",
                        UserType = "CUSTOMER"
                    }
                });
            }

            throw new UnauthorizedAccessException("Invalid OTP.");
        }
    }

    [Fact]
    public async Task StaffLogin_ValidCredentials_ReturnsOkWithAuthResponse()
    {
        var controller = new AuthController(new FakeStaffAuthService(), new FakeCustomerAuthService());
        var request = new StaffLoginRequest
        {
            DealerCode = "ALAGENDRA",
            UsernameOrEmail = "sales@alagendra.local",
            Password = "ValidPass"
        };

        var result = await controller.StaffLogin(request, CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var envelope = Assert.IsType<ApiResponse<AuthResponse>>(okResult.Value);
        Assert.True(envelope.Success);
        Assert.Equal("MOCK_STAFF_TOKEN", envelope.Data!.AccessToken);
        Assert.Equal("DEALER_STAFF", envelope.Data.User.UserType);
    }

    [Fact]
    public async Task StaffLogin_InvalidCredentials_ReturnsUnauthorized()
    {
        var controller = new AuthController(new FakeStaffAuthService(), new FakeCustomerAuthService());
        var request = new StaffLoginRequest
        {
            DealerCode = "ALAGENDRA",
            UsernameOrEmail = "sales@alagendra.local",
            Password = "WrongPassword"
        };

        var result = await controller.StaffLogin(request, CancellationToken.None);

        var unauthorizedResult = Assert.IsType<UnauthorizedObjectResult>(result);
        var envelope = Assert.IsType<ApiResponse<object>>(unauthorizedResult.Value);
        Assert.False(envelope.Success);
        Assert.Equal(401, envelope.StatusCode);
    }

    [Fact]
    public async Task CustomerRequestOtp_ValidPhone_ReturnsOk()
    {
        var controller = new AuthController(new FakeStaffAuthService(), new FakeCustomerAuthService());
        var request = new CustomerRequestOtpRequest { Phone = "+919876543210" };

        var result = await controller.CustomerRequestOtp(request, CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var envelope = Assert.IsType<ApiResponse<object>>(okResult.Value);
        Assert.True(envelope.Success);
    }

    [Fact]
    public async Task CustomerVerifyOtp_ValidOtp_ReturnsOkWithCustomerToken()
    {
        var controller = new AuthController(new FakeStaffAuthService(), new FakeCustomerAuthService());
        var request = new CustomerVerifyOtpRequest
        {
            Phone = "+919876543210",
            Otp = "123456"
        };

        var result = await controller.CustomerVerifyOtp(request, CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var envelope = Assert.IsType<ApiResponse<AuthResponse>>(okResult.Value);
        Assert.True(envelope.Success);
        Assert.Equal("MOCK_CUSTOMER_TOKEN", envelope.Data!.AccessToken);
        Assert.Equal("CUSTOMER", envelope.Data.User.UserType);
    }
}

