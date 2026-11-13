using FluentValidation;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MotoSaaS.Application.Common.Models;
using MotoSaaS.Application.Features.Sales;
using MotoSaaS.Application.Features.Sales.Interfaces;
using MotoSaaS.Application.Features.Sales.Models;

namespace MotoSaaS.Api.Controllers;

/// <summary>
/// Branch CRM endpoints used by sales executives and branch managers.
/// All routes are scoped to the tenant and branch carried by the staff JWT.
/// </summary>
[Authorize(Policy = "StaffOnly")]
[Route("api/v1/staff/sales")]
public class StaffSalesController : BaseApiController
{
    private readonly IStaffSalesService _staffSalesService;
    private readonly IValidator<LeadCaptureRequest> _captureValidator;
    private readonly IValidator<AssignLeadRequest> _assignValidator;
    private readonly IValidator<UpdateLeadStatusRequest> _statusValidator;
    private readonly IValidator<CreateFollowUpRequest> _followUpValidator;
    private readonly IValidator<CompleteTestRideRequest> _completeTestRideValidator;
    private readonly IValidator<CancelTestRideRequest> _cancelTestRideValidator;

    public StaffSalesController(
        IStaffSalesService staffSalesService,
        IValidator<LeadCaptureRequest> captureValidator,
        IValidator<AssignLeadRequest> assignValidator,
        IValidator<UpdateLeadStatusRequest> statusValidator,
        IValidator<CreateFollowUpRequest> followUpValidator,
        IValidator<CompleteTestRideRequest> completeTestRideValidator,
        IValidator<CancelTestRideRequest> cancelTestRideValidator)
    {
        _staffSalesService = staffSalesService;
        _captureValidator = captureValidator;
        _assignValidator = assignValidator;
        _statusValidator = statusValidator;
        _followUpValidator = followUpValidator;
        _completeTestRideValidator = completeTestRideValidator;
        _cancelTestRideValidator = cancelTestRideValidator;
    }

    /// <summary>Lists the branch sales pipeline with optional stage, owner and search filters.</summary>
    [HttpGet("leads")]
    [ProducesResponseType(typeof(ApiResponse<PagedResult<LeadSummaryDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetPipeline(
        [FromQuery] SalesPipelineQuery query,
        CancellationToken cancellationToken)
    {
        try
        {
            var result = await _staffSalesService.GetPipelineAsync(query, cancellationToken);
            return Ok(ApiResponse<PagedResult<LeadSummaryDto>>.Ok(result, meta: ToMeta(result)));
        }
        catch (Exception ex) when (IsHandled(ex))
        {
            return Handle(ex);
        }
    }

    /// <summary>Returns a lead with follow-up history, test rides and quotations.</summary>
    [HttpGet("leads/{enquiryId:guid}")]
    [ProducesResponseType(typeof(ApiResponse<LeadDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetLead(Guid enquiryId, CancellationToken cancellationToken)
    {
        try
        {
            var lead = await _staffSalesService.GetLeadAsync(enquiryId, cancellationToken);
            return Ok(ApiResponse<LeadDetailDto>.Ok(lead));
        }
        catch (Exception ex) when (IsHandled(ex))
        {
            return Handle(ex);
        }
    }

    /// <summary>Captures a walk-in, phone or web lead and auto-assigns a branch and sales executive.</summary>
    [HttpPost("leads")]
    [ProducesResponseType(typeof(ApiResponse<LeadDetailDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CaptureLead(
        [FromBody] LeadCaptureRequest request,
        CancellationToken cancellationToken)
    {
        var validation = await _captureValidator.ValidateAsync(request, cancellationToken);
        if (!validation.IsValid)
        {
            return BadRequest(ApiResponse<object>.Failure(
                "Invalid lead details.",
                StatusCodes.Status400BadRequest,
                ToValidationErrors(validation)));
        }

        try
        {
            var lead = await _staffSalesService.CaptureLeadAsync(request, cancellationToken);
            return StatusCode(
                StatusCodes.Status201Created,
                ApiResponse<LeadDetailDto>.Ok(lead, "Lead captured and assigned successfully."));
        }
        catch (Exception ex) when (IsHandled(ex))
        {
            return Handle(ex);
        }
    }

    /// <summary>Assigns or reassigns a lead to a sales executive in the same branch.</summary>
    [HttpPut("leads/{enquiryId:guid}/assign")]
    [ProducesResponseType(typeof(ApiResponse<LeadDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> AssignLead(
        Guid enquiryId,
        [FromBody] AssignLeadRequest request,
        CancellationToken cancellationToken)
    {
        var validation = await _assignValidator.ValidateAsync(request, cancellationToken);
        if (!validation.IsValid)
        {
            return BadRequest(ApiResponse<object>.Failure(
                "Invalid assignment.",
                StatusCodes.Status400BadRequest,
                ToValidationErrors(validation)));
        }

        try
        {
            var lead = await _staffSalesService.AssignLeadAsync(enquiryId, request, cancellationToken);
            return Ok(ApiResponse<LeadDetailDto>.Ok(lead, "Lead owner updated."));
        }
        catch (Exception ex) when (IsHandled(ex))
        {
            return Handle(ex);
        }
    }

    /// <summary>Moves a lead through the sales pipeline stage machine.</summary>
    [HttpPut("leads/{enquiryId:guid}/status")]
    [ProducesResponseType(typeof(ApiResponse<LeadDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> UpdateLeadStatus(
        Guid enquiryId,
        [FromBody] UpdateLeadStatusRequest request,
        CancellationToken cancellationToken)
    {
        var validation = await _statusValidator.ValidateAsync(request, cancellationToken);
        if (!validation.IsValid)
        {
            return BadRequest(ApiResponse<object>.Failure(
                "Invalid lead status update.",
                StatusCodes.Status400BadRequest,
                ToValidationErrors(validation)));
        }

        try
        {
            var lead = await _staffSalesService.UpdateLeadStatusAsync(enquiryId, request, cancellationToken);
            return Ok(ApiResponse<LeadDetailDto>.Ok(lead, "Lead status updated."));
        }
        catch (Exception ex) when (IsHandled(ex))
        {
            return Handle(ex);
        }
    }

    /// <summary>Records a sales follow-up and schedules the next contact.</summary>
    [HttpPost("leads/{enquiryId:guid}/follow-ups")]
    [ProducesResponseType(typeof(ApiResponse<FollowUpDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> AddFollowUp(
        Guid enquiryId,
        [FromBody] CreateFollowUpRequest request,
        CancellationToken cancellationToken)
    {
        var validation = await _followUpValidator.ValidateAsync(request, cancellationToken);
        if (!validation.IsValid)
        {
            return BadRequest(ApiResponse<object>.Failure(
                "Invalid follow-up details.",
                StatusCodes.Status400BadRequest,
                ToValidationErrors(validation)));
        }

        try
        {
            var followUp = await _staffSalesService.AddFollowUpAsync(enquiryId, request, cancellationToken);
            return StatusCode(
                StatusCodes.Status201Created,
                ApiResponse<FollowUpDto>.Ok(followUp, "Follow-up recorded."));
        }
        catch (Exception ex) when (IsHandled(ex))
        {
            return Handle(ex);
        }
    }

    /// <summary>Branch CRM dashboard counts for pipeline, follow-ups, test rides and quotations.</summary>
    [HttpGet("dashboard")]
    [ProducesResponseType(typeof(ApiResponse<SalesDashboardDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetDashboard(
        [FromQuery] Guid? branchId,
        CancellationToken cancellationToken)
    {
        try
        {
            var dashboard = await _staffSalesService.GetDashboardAsync(branchId, cancellationToken);
            return Ok(ApiResponse<SalesDashboardDto>.Ok(dashboard));
        }
        catch (Exception ex) when (IsHandled(ex))
        {
            return Handle(ex);
        }
    }

    /// <summary>Lists sales-role staff available for lead assignment.</summary>
    [HttpGet("sales-executives")]
    [ProducesResponseType(typeof(ApiResponse<List<SalesExecutiveDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetSalesExecutives(
        [FromQuery] Guid? branchId,
        CancellationToken cancellationToken)
    {
        try
        {
            var executives = await _staffSalesService.GetSalesExecutivesAsync(branchId, cancellationToken);
            return Ok(ApiResponse<List<SalesExecutiveDto>>.Ok(executives));
        }
        catch (Exception ex) when (IsHandled(ex))
        {
            return Handle(ex);
        }
    }

    /// <summary>Lists test rides for branch operations, optionally filtered by status and date range.</summary>
    [HttpGet("test-rides")]
    [ProducesResponseType(typeof(ApiResponse<List<StaffTestRideDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetTestRideQueue(
        [FromQuery] TestRideQueueQuery query,
        CancellationToken cancellationToken)
    {
        try
        {
            var testRides = await _staffSalesService.GetTestRideQueueAsync(query, cancellationToken);
            return Ok(ApiResponse<List<StaffTestRideDto>>.Ok(testRides));
        }
        catch (Exception ex) when (IsHandled(ex))
        {
            return Handle(ex);
        }
    }

    /// <summary>Completes a test ride after verifying the customer's driving licence.</summary>
    [HttpPost("test-rides/{testRideId:guid}/complete")]
    [ProducesResponseType(typeof(ApiResponse<StaffTestRideDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CompleteTestRide(
        Guid testRideId,
        [FromBody] CompleteTestRideRequest request,
        CancellationToken cancellationToken)
    {
        var validation = await _completeTestRideValidator.ValidateAsync(request, cancellationToken);
        if (!validation.IsValid)
        {
            return BadRequest(ApiResponse<object>.Failure(
                "Invalid test ride completion.",
                StatusCodes.Status400BadRequest,
                ToValidationErrors(validation)));
        }

        try
        {
            var testRide = await _staffSalesService.CompleteTestRideAsync(testRideId, request, cancellationToken);
            return Ok(ApiResponse<StaffTestRideDto>.Ok(testRide, "Test ride completed."));
        }
        catch (Exception ex) when (IsHandled(ex))
        {
            return Handle(ex);
        }
    }

    /// <summary>Cancels a scheduled test ride with a mandatory reason.</summary>
    [HttpPost("test-rides/{testRideId:guid}/cancel")]
    [ProducesResponseType(typeof(ApiResponse<StaffTestRideDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CancelTestRide(
        Guid testRideId,
        [FromBody] CancelTestRideRequest request,
        CancellationToken cancellationToken)
    {
        var validation = await _cancelTestRideValidator.ValidateAsync(request, cancellationToken);
        if (!validation.IsValid)
        {
            return BadRequest(ApiResponse<object>.Failure(
                "Invalid test ride cancellation.",
                StatusCodes.Status400BadRequest,
                ToValidationErrors(validation)));
        }

        try
        {
            var testRide = await _staffSalesService.CancelTestRideAsync(testRideId, request, cancellationToken);
            return Ok(ApiResponse<StaffTestRideDto>.Ok(testRide, "Test ride cancelled."));
        }
        catch (Exception ex) when (IsHandled(ex))
        {
            return Handle(ex);
        }
    }

    /// <summary>Marks a scheduled test ride as a customer no-show.</summary>
    [HttpPost("test-rides/{testRideId:guid}/no-show")]
    [ProducesResponseType(typeof(ApiResponse<StaffTestRideDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> MarkTestRideNoShow(Guid testRideId, CancellationToken cancellationToken)
    {
        try
        {
            var testRide = await _staffSalesService.MarkTestRideNoShowAsync(testRideId, cancellationToken);
            return Ok(ApiResponse<StaffTestRideDto>.Ok(testRide, "Test ride marked as no-show."));
        }
        catch (Exception ex) when (IsHandled(ex))
        {
            return Handle(ex);
        }
    }

    private static PaginationMeta ToMeta<T>(PagedResult<T> result) => new()
    {
        Page = result.Page,
        PageSize = result.PageSize,
        TotalCount = result.TotalCount
    };

    private static bool IsHandled(Exception ex) =>
        ex is ArgumentException or KeyNotFoundException or InvalidOperationException or UnauthorizedAccessException;

    private static IActionResult Handle(Exception ex) => ex switch
    {
        UnauthorizedAccessException => new UnauthorizedObjectResult(
            ApiResponse<object>.Failure(ex.Message, StatusCodes.Status401Unauthorized)),
        KeyNotFoundException => new NotFoundObjectResult(
            ApiResponse<object>.Failure(ex.Message, StatusCodes.Status404NotFound)),
        _ => new BadRequestObjectResult(
            ApiResponse<object>.Failure(ex.Message, StatusCodes.Status400BadRequest))
    };

    private static List<ValidationErrorItem> ToValidationErrors(FluentValidation.Results.ValidationResult validation) =>
        validation.Errors.Select(error => new ValidationErrorItem
        {
            Field = error.PropertyName,
            Message = error.ErrorMessage
        }).ToList();
}
