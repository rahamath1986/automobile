using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MotoSaaS.Application.Common.Models;
using MotoSaaS.Application.Features.Identity.Interfaces;
using MotoSaaS.Application.Features.Identity.Models;

namespace MotoSaaS.Api.Controllers;

[AllowAnonymous]
public class AuthController : BaseApiController
{
    private readonly IStaffAuthService _staffAuthService;
    private readonly ICustomerAuthService _customerAuthService;

    public AuthController(
        IStaffAuthService staffAuthService,
        ICustomerAuthService customerAuthService)
    {
        _staffAuthService = staffAuthService;
        _customerAuthService = customerAuthService;
    }

    /// <summary>
    /// Authenticates dealership staff (Sales, Service Advisor, Technician, Cashier, Manager, Admin) using Dealer Code and credentials.
    /// </summary>
    [HttpPost("staff/login")]
    [ProducesResponseType(typeof(ApiResponse<AuthResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> StaffLogin([FromBody] StaffLoginRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var response = await _staffAuthService.LoginAsync(request, cancellationToken);
            return Ok(ApiResponse<AuthResponse>.Ok(response, "Staff authenticated successfully."));
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(ApiResponse<object>.Failure(ex.Message, StatusCodes.Status401Unauthorized));
        }
        catch (Exception ex)
        {
            return BadRequest(ApiResponse<object>.Failure(ex.Message, StatusCodes.Status400BadRequest));
        }
    }

    /// <summary>
    /// Dispatches a 6-digit numeric OTP to the customer's mobile number.
    /// </summary>
    [HttpPost("customer/request-otp")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    public async Task<IActionResult> CustomerRequestOtp([FromBody] CustomerRequestOtpRequest request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Phone))
        {
            return BadRequest(ApiResponse<object>.Failure("Mobile phone number is required."));
        }

        await _customerAuthService.RequestOtpAsync(request, cancellationToken);
        return Ok(ApiResponse<object>.Ok(new { request.Phone }, "OTP dispatched successfully."));
    }

    /// <summary>
    /// Verifies the customer's mobile OTP and issues a Customer JWT token.
    /// </summary>
    [HttpPost("customer/verify-otp")]
    [ProducesResponseType(typeof(ApiResponse<AuthResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> CustomerVerifyOtp([FromBody] CustomerVerifyOtpRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var response = await _customerAuthService.VerifyOtpAsync(request, cancellationToken);
            return Ok(ApiResponse<AuthResponse>.Ok(response, "Customer authenticated successfully."));
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(ApiResponse<object>.Failure(ex.Message, StatusCodes.Status401Unauthorized));
        }
        catch (Exception ex)
        {
            return BadRequest(ApiResponse<object>.Failure(ex.Message, StatusCodes.Status400BadRequest));
        }
    }

    /// <summary>
    /// Renews an expired access token using a valid refresh token.
    /// </summary>
    [HttpPost("refresh-token")]
    [ProducesResponseType(typeof(ApiResponse<AuthResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var response = await _staffAuthService.RefreshTokenAsync(request, cancellationToken);
            return Ok(ApiResponse<AuthResponse>.Ok(response, "Token refreshed successfully."));
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(ApiResponse<object>.Failure(ex.Message, StatusCodes.Status401Unauthorized));
        }
        catch (Exception ex)
        {
            return BadRequest(ApiResponse<object>.Failure(ex.Message, StatusCodes.Status400BadRequest));
        }
    }
}

