using FluentValidation;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MotoSaaS.Application.Common.Models;
using MotoSaaS.Application.Features.Service;
using MotoSaaS.Application.Features.Service.Interfaces;
using MotoSaaS.Application.Features.Service.Models;

namespace MotoSaaS.Api.Controllers;

public class ServiceController : BaseApiController
{
    private readonly ICustomerServiceBookingService _serviceBookingService;
    private readonly IValidator<CreateServiceBookingRequest> _validator;

    public ServiceController(
        ICustomerServiceBookingService serviceBookingService,
        IValidator<CreateServiceBookingRequest> validator)
    {
        _serviceBookingService = serviceBookingService;
        _validator = validator;
    }

    /// <summary>
    /// Returns the signed-in customer's owned vehicles ("My Vehicles" garage).
    /// </summary>
    [HttpGet("my-vehicles")]
    [Authorize(Policy = "CustomerOnly")]
    [ProducesResponseType(typeof(ApiResponse<List<CustomerVehicleDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMyVehicles(CancellationToken cancellationToken)
    {
        try
        {
            var vehicles = await _serviceBookingService.GetMyVehiclesAsync(cancellationToken);
            return Ok(ApiResponse<List<CustomerVehicleDto>>.Ok(vehicles));
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(ApiResponse<object>.Failure(ex.Message, StatusCodes.Status401Unauthorized));
        }
    }

    /// <summary>
    /// Lists the signed-in customer's service appointments and live job card status.
    /// </summary>
    [HttpGet("bookings/mine")]
    [Authorize(Policy = "CustomerOnly")]
    [ProducesResponseType(typeof(ApiResponse<List<ServiceBookingDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMyBookings(CancellationToken cancellationToken)
    {
        try
        {
            var bookings = await _serviceBookingService.GetMyBookingsAsync(cancellationToken);
            return Ok(ApiResponse<List<ServiceBookingDto>>.Ok(bookings));
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(ApiResponse<object>.Failure(ex.Message, StatusCodes.Status401Unauthorized));
        }
    }

    /// <summary>
    /// Books a service appointment for an owned vehicle.
    /// </summary>
    [HttpPost("bookings")]
    [Authorize(Policy = "CustomerOnly")]
    [ProducesResponseType(typeof(ApiResponse<ServiceBookingDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CreateBooking(
        [FromBody] CreateServiceBookingRequest request,
        CancellationToken cancellationToken)
    {
        var validation = await _validator.ValidateAsync(request, cancellationToken);
        if (!validation.IsValid)
        {
            return BadRequest(ApiResponse<object>.Failure(
                "Invalid service booking details.",
                StatusCodes.Status400BadRequest,
                validation.Errors.Select(e => new ValidationErrorItem
                {
                    Field = e.PropertyName,
                    Message = e.ErrorMessage
                }).ToList()));
        }

        try
        {
            var booking = await _serviceBookingService.CreateBookingAsync(request, cancellationToken);
            return StatusCode(
                StatusCodes.Status201Created,
                ApiResponse<ServiceBookingDto>.Ok(booking, "Service appointment booked successfully."));
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
    }

    /// <summary>
    /// Returns live service progress for one appointment, including job card, estimate items and stage timeline.
    /// </summary>
    [HttpGet("bookings/{bookingId:guid}/tracking")]
    [Authorize(Policy = "CustomerOnly")]
    [ProducesResponseType(typeof(ApiResponse<ServiceTrackingDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetTracking(Guid bookingId, CancellationToken cancellationToken)
    {
        try
        {
            var tracking = await _serviceBookingService.GetTrackingAsync(bookingId, cancellationToken);
            return Ok(ApiResponse<ServiceTrackingDto>.Ok(tracking));
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
    /// Allows the customer to digitally approve the service estimate.
    /// </summary>
    [HttpPut("job-cards/{jobCardId:guid}/approve")]
    [Authorize(Policy = "CustomerOnly")]
    [ProducesResponseType(typeof(ApiResponse<ServiceTrackingDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> ApproveEstimate(Guid jobCardId, CancellationToken cancellationToken)
    {
        try
        {
            var tracking = await _serviceBookingService.ApproveEstimateAsync(jobCardId, cancellationToken);
            return Ok(ApiResponse<ServiceTrackingDto>.Ok(tracking, "Service estimate approved successfully."));
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
    }
}
