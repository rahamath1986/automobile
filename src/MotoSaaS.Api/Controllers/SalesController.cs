using FluentValidation;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MotoSaaS.Application.Common.Models;
using MotoSaaS.Application.Features.Sales;
using MotoSaaS.Application.Features.Sales.Interfaces;
using MotoSaaS.Application.Features.Sales.Models;

namespace MotoSaaS.Api.Controllers;

public class SalesController : BaseApiController
{
    private readonly ICustomerSalesService _customerSalesService;
    private readonly IValidator<CreateEnquiryRequest> _enquiryValidator;
    private readonly IValidator<CreateTestRideRequest> _testRideValidator;

    public SalesController(
        ICustomerSalesService customerSalesService,
        IValidator<CreateEnquiryRequest> enquiryValidator,
        IValidator<CreateTestRideRequest> testRideValidator)
    {
        _customerSalesService = customerSalesService;
        _enquiryValidator = enquiryValidator;
        _testRideValidator = testRideValidator;
    }

    /// <summary>
    /// Captures a vehicle purchase enquiry from the customer mobile app (guest or authenticated).
    /// </summary>
    [HttpPost("enquiries")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<EnquiryDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CreateEnquiry(
        [FromBody] CreateEnquiryRequest request,
        CancellationToken cancellationToken)
    {
        var validation = await _enquiryValidator.ValidateAsync(request, cancellationToken);
        if (!validation.IsValid)
        {
            return BadRequest(ApiResponse<object>.Failure(
                "Invalid enquiry details.",
                StatusCodes.Status400BadRequest,
                validation.Errors.Select(ToValidationError).ToList()));
        }

        try
        {
            var enquiry = await _customerSalesService.CreateEnquiryAsync(request, cancellationToken);
            return StatusCode(
                StatusCodes.Status201Created,
                ApiResponse<EnquiryDto>.Ok(enquiry, "Enquiry submitted successfully. A sales executive will contact you shortly."));
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(ApiResponse<object>.Failure(ex.Message, StatusCodes.Status401Unauthorized));
        }
        catch (ArgumentException ex)
        {
            return BadRequest(ApiResponse<object>.Failure(ex.Message, StatusCodes.Status400BadRequest));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResponse<object>.Failure(ex.Message, StatusCodes.Status400BadRequest));
        }
    }

    /// <summary>
    /// Lists the signed-in customer's enquiries and their current CRM stages.
    /// </summary>
    [HttpGet("enquiries/mine")]
    [Authorize(Policy = "CustomerOnly")]
    [ProducesResponseType(typeof(ApiResponse<List<EnquiryDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMyEnquiries(CancellationToken cancellationToken)
    {
        try
        {
            var enquiries = await _customerSalesService.GetMyEnquiriesAsync(cancellationToken);
            return Ok(ApiResponse<List<EnquiryDto>>.Ok(enquiries));
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(ApiResponse<object>.Failure(ex.Message, StatusCodes.Status401Unauthorized));
        }
    }

    /// <summary>
    /// Requests a customer test ride appointment (guest or authenticated).
    /// </summary>
    [HttpPost("test-rides")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<TestRideDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CreateTestRide(
        [FromBody] CreateTestRideRequest request,
        CancellationToken cancellationToken)
    {
        var validation = await _testRideValidator.ValidateAsync(request, cancellationToken);
        if (!validation.IsValid)
        {
            return BadRequest(ApiResponse<object>.Failure(
                "Invalid test ride details.",
                StatusCodes.Status400BadRequest,
                validation.Errors.Select(ToValidationError).ToList()));
        }

        try
        {
            var testRide = await _customerSalesService.CreateTestRideAsync(request, cancellationToken);
            return StatusCode(
                StatusCodes.Status201Created,
                ApiResponse<TestRideDto>.Ok(testRide, "Test ride request received. The dealership will confirm your slot."));
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(ApiResponse<object>.Failure(ex.Message, StatusCodes.Status401Unauthorized));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<object>.Failure(ex.Message, StatusCodes.Status404NotFound));
        }
        catch (ArgumentException ex)
        {
            return BadRequest(ApiResponse<object>.Failure(ex.Message, StatusCodes.Status400BadRequest));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResponse<object>.Failure(ex.Message, StatusCodes.Status400BadRequest));
        }
    }

    /// <summary>
    /// Lists the signed-in customer's test ride requests.
    /// </summary>
    [HttpGet("test-rides/mine")]
    [Authorize(Policy = "CustomerOnly")]
    [ProducesResponseType(typeof(ApiResponse<List<TestRideDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMyTestRides(CancellationToken cancellationToken)
    {
        try
        {
            var testRides = await _customerSalesService.GetMyTestRidesAsync(cancellationToken);
            return Ok(ApiResponse<List<TestRideDto>>.Ok(testRides));
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(ApiResponse<object>.Failure(ex.Message, StatusCodes.Status401Unauthorized));
        }
    }

    private static ValidationErrorItem ToValidationError(FluentValidation.Results.ValidationFailure failure) =>
        new()
        {
            Field = failure.PropertyName,
            Message = failure.ErrorMessage
        };
}
