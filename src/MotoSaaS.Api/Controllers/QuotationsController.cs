using FluentValidation;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MotoSaaS.Application.Common.Models;
using MotoSaaS.Application.Features.Sales.Interfaces;
using MotoSaaS.Application.Features.Sales.Models;

namespace MotoSaaS.Api.Controllers;

/// <summary>
/// Dynamic on-road quotation endpoints for dealership staff.
/// </summary>
[Authorize(Policy = "StaffOnly")]
public class QuotationsController : BaseApiController
{
    private readonly IQuotationService _quotationService;
    private readonly IValidator<QuotationDraftRequest> _draftValidator;

    public QuotationsController(
        IQuotationService quotationService,
        IValidator<QuotationDraftRequest> draftValidator)
    {
        _quotationService = quotationService;
        _draftValidator = draftValidator;
    }

    /// <summary>
    /// Calculates a non-persisted on-road quotation, including accessories, RTO/road tax,
    /// insurance, handling and discount for the branch state.
    /// </summary>
    [HttpPost("preview")]
    [ProducesResponseType(typeof(ApiResponse<QuotationCalculationDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Preview(
        [FromBody] QuotationDraftRequest request,
        CancellationToken cancellationToken)
    {
        var validation = await _draftValidator.ValidateAsync(request, cancellationToken);
        if (!validation.IsValid)
        {
            return BadRequest(ApiResponse<object>.Failure(
                "Invalid quotation inputs.",
                StatusCodes.Status400BadRequest,
                ToValidationErrors(validation)));
        }

        try
        {
            var preview = await _quotationService.PreviewAsync(request, cancellationToken);
            return Ok(ApiResponse<QuotationCalculationDto>.Ok(preview));
        }
        catch (Exception ex) when (IsHandled(ex))
        {
            return Handle(ex);
        }
    }

    /// <summary>Creates a numbered, time-bound quotation and advances the lead to QUOTED.</summary>
    [HttpPost]
    [ProducesResponseType(typeof(ApiResponse<QuotationDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Create(
        [FromBody] CreateQuotationRequest request,
        CancellationToken cancellationToken)
    {
        var validation = await _draftValidator.ValidateAsync(request, cancellationToken);
        if (!validation.IsValid)
        {
            return BadRequest(ApiResponse<object>.Failure(
                "Invalid quotation inputs.",
                StatusCodes.Status400BadRequest,
                ToValidationErrors(validation)));
        }

        try
        {
            var quotation = await _quotationService.CreateAsync(request, cancellationToken);
            return StatusCode(
                StatusCodes.Status201Created,
                ApiResponse<QuotationDto>.Ok(quotation, "Quotation created successfully."));
        }
        catch (Exception ex) when (IsHandled(ex))
        {
            return Handle(ex);
        }
    }

    /// <summary>Lists branch quotations with status, lead, customer and search filters.</summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<PagedResult<QuotationDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetQuotations(
        [FromQuery] QuotationQuery query,
        CancellationToken cancellationToken)
    {
        try
        {
            var result = await _quotationService.GetQuotationsAsync(query, cancellationToken);
            return Ok(ApiResponse<PagedResult<QuotationDto>>.Ok(result, meta: ToMeta(result)));
        }
        catch (Exception ex) when (IsHandled(ex))
        {
            return Handle(ex);
        }
    }

    /// <summary>Returns a single quotation with its full price breakdown.</summary>
    [HttpGet("{quotationId:guid}")]
    [ProducesResponseType(typeof(ApiResponse<QuotationDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetQuotation(Guid quotationId, CancellationToken cancellationToken)
    {
        try
        {
            var quotation = await _quotationService.GetQuotationAsync(quotationId, cancellationToken);
            return Ok(ApiResponse<QuotationDto>.Ok(quotation));
        }
        catch (Exception ex) when (IsHandled(ex))
        {
            return Handle(ex);
        }
    }

    /// <summary>Manually expires an active quotation.</summary>
    [HttpPost("{quotationId:guid}/expire")]
    [ProducesResponseType(typeof(ApiResponse<QuotationDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Expire(Guid quotationId, CancellationToken cancellationToken)
    {
        try
        {
            var quotation = await _quotationService.ExpireAsync(quotationId, cancellationToken);
            return Ok(ApiResponse<QuotationDto>.Ok(quotation, "Quotation expired."));
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
