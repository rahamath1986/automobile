using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MotoSaaS.Application.Common.Interfaces;
using MotoSaaS.Application.Common.Models;
using MotoSaaS.Application.Features.Catalog.Interfaces;
using MotoSaaS.Application.Features.Catalog.Models;
using MotoSaaS.Domain.Catalog;

namespace MotoSaaS.Api.Controllers;

public class CatalogController : BaseApiController
{
    private readonly IVehicleCatalogService _catalogService;
    private readonly ICurrentTenantContext _tenantContext;

    public CatalogController(
        IVehicleCatalogService catalogService,
        ICurrentTenantContext tenantContext)
    {
        _catalogService = catalogService;
        _tenantContext = tenantContext;
    }

    /// <summary>
    /// Retrieves vehicle models filtered by category (Motorcycle, Scooter, EV), brand, or fuel type.
    /// When called in tenant context, automatically filters to OEM brands authorized for the dealership.
    /// </summary>
    [HttpGet("models")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<List<VehicleModelSummaryDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetModels(
        [FromQuery] VehicleCategory? category,
        [FromQuery] Guid? manufacturerId,
        [FromQuery] FuelType? fuelType,
        CancellationToken cancellationToken)
    {
        List<VehicleModelSummaryDto> models;

        if (_tenantContext.TenantId.HasValue)
        {
            models = await _catalogService.GetCatalogForTenantAsync(_tenantContext.TenantId.Value, category, cancellationToken);
        }
        else
        {
            models = await _catalogService.GetModelsAsync(category, manufacturerId, fuelType, cancellationToken);
        }

        return Ok(ApiResponse<List<VehicleModelSummaryDto>>.Ok(models));
    }

    /// <summary>
    /// Retrieves comprehensive vehicle model details including variants, colors, technical specs, and 3D asset links.
    /// </summary>
    [HttpGet("models/{id:guid}")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<VehicleModelDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetModelDetails(Guid id, CancellationToken cancellationToken)
    {
        var model = await _catalogService.GetModelDetailsByIdAsync(id, cancellationToken);
        if (model == null)
        {
            return NotFound(ApiResponse<object>.Failure($"Vehicle model with ID '{id}' not found.", 404));
        }

        return Ok(ApiResponse<VehicleModelDetailDto>.Ok(model));
    }

    /// <summary>
    /// Returns an indicative branch-level on-road price estimate and live availability for a variant.
    /// Used by the customer mobile app for branch price comparison before a formal quotation is issued.
    /// </summary>
    [HttpGet("variants/{variantId:guid}/pricing")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<VariantBranchPricingDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetVariantPricing(
        Guid variantId,
        [FromQuery] Guid? branchId,
        CancellationToken cancellationToken)
    {
        try
        {
            var pricing = await _catalogService.GetVariantBranchPricingAsync(variantId, branchId, cancellationToken);
            if (pricing == null)
            {
                return NotFound(ApiResponse<object>.Failure($"Vehicle variant with ID '{variantId}' not found.", 404));
            }

            return Ok(ApiResponse<VariantBranchPricingDto>.Ok(pricing));
        }
        catch (ArgumentException ex)
        {
            return BadRequest(ApiResponse<object>.Failure(ex.Message, 400));
        }
    }

    /// <summary>
    /// Creates a new vehicle model (Restricted to SaaS Admin or Dealership Org Admin).
    /// </summary>
    [HttpPost("models")]
    [Authorize(Policy = "StaffOnly")]
    [ProducesResponseType(typeof(ApiResponse<VehicleModelSummaryDto>), StatusCodes.Status201Created)]
    public async Task<IActionResult> CreateModel([FromBody] CreateModelRequest request, CancellationToken cancellationToken)
    {
        var created = await _catalogService.CreateModelAsync(request, cancellationToken);
        return StatusCode(StatusCodes.Status201Created, ApiResponse<VehicleModelSummaryDto>.Ok(created, "Vehicle model created successfully."));
    }

    /// <summary>
    /// Creates a new variant for a vehicle model.
    /// </summary>
    [HttpPost("variants")]
    [Authorize(Policy = "StaffOnly")]
    [ProducesResponseType(typeof(ApiResponse<VehicleVariantDto>), StatusCodes.Status201Created)]
    public async Task<IActionResult> CreateVariant([FromBody] CreateVariantRequest request, CancellationToken cancellationToken)
    {
        var created = await _catalogService.CreateVariantAsync(request, cancellationToken);
        return StatusCode(StatusCodes.Status201Created, ApiResponse<VehicleVariantDto>.Ok(created, "Variant created successfully."));
    }
}

