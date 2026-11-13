using FluentValidation;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MotoSaaS.Application.Common.Models;
using MotoSaaS.Application.Features.Customers;
using MotoSaaS.Application.Features.Customers.Interfaces;
using MotoSaaS.Application.Features.Customers.Models;

namespace MotoSaaS.Api.Controllers;

[Authorize(Policy = "CustomerOnly")]
public class CustomersController : BaseApiController
{
    private readonly ICustomerProfileService _profileService;
    private readonly IValidator<UpdateCustomerProfileRequest> _validator;

    public CustomersController(
        ICustomerProfileService profileService,
        IValidator<UpdateCustomerProfileRequest> validator)
    {
        _profileService = profileService;
        _validator = validator;
    }

    /// <summary>
    /// Returns the signed-in customer's profile, contact details and ownership summary.
    /// </summary>
    [HttpGet("me")]
    [ProducesResponseType(typeof(ApiResponse<CustomerProfileDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetProfile(CancellationToken cancellationToken)
    {
        try
        {
            var profile = await _profileService.GetProfileAsync(cancellationToken);
            return Ok(ApiResponse<CustomerProfileDto>.Ok(profile));
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(ApiResponse<object>.Failure(ex.Message, StatusCodes.Status401Unauthorized));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<object>.Failure(ex.Message, StatusCodes.Status404NotFound));
        }
    }

    /// <summary>
    /// Updates the signed-in customer's profile and delivery contact details.
    /// </summary>
    [HttpPut("me")]
    [ProducesResponseType(typeof(ApiResponse<CustomerProfileDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> UpdateProfile(
        [FromBody] UpdateCustomerProfileRequest request,
        CancellationToken cancellationToken)
    {
        var validation = await _validator.ValidateAsync(request, cancellationToken);
        if (!validation.IsValid)
        {
            return BadRequest(ApiResponse<object>.Failure(
                "Invalid profile details.",
                StatusCodes.Status400BadRequest,
                validation.Errors.Select(e => new ValidationErrorItem
                {
                    Field = e.PropertyName,
                    Message = e.ErrorMessage
                }).ToList()));
        }

        try
        {
            var profile = await _profileService.UpdateProfileAsync(request, cancellationToken);
            return Ok(ApiResponse<CustomerProfileDto>.Ok(profile, "Profile updated successfully."));
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(ApiResponse<object>.Failure(ex.Message, StatusCodes.Status401Unauthorized));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<object>.Failure(ex.Message, StatusCodes.Status404NotFound));
        }
    }
}
