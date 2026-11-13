using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MotoSaaS.Application.Common.Interfaces;
using MotoSaaS.Application.Common.Models;
using MotoSaaS.Application.Features.Manufacturer.Interfaces;
using MotoSaaS.Application.Features.Manufacturer.Models;

namespace MotoSaaS.Api.Controllers;

[Route("api/v1/tenant-manufacturers")]
public class TenantManufacturersController : BaseApiController
{
    private readonly ITenantManufacturerService _tenantManufacturerService;
    private readonly ICurrentTenantContext _tenantContext;

    public TenantManufacturersController(
        ITenantManufacturerService tenantManufacturerService,
        ICurrentTenantContext tenantContext)
    {
        _tenantManufacturerService = tenantManufacturerService;
        _tenantContext = tenantContext;
    }

    /// <summary>
    /// Retrieves all manufacturer brand authorizations (e.g. Yamaha, Honda, TVS) mapped to the current dealership.
    /// </summary>
    [HttpGet]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<List<TenantManufacturerDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetTenantManufacturers(CancellationToken cancellationToken)
    {
        if (!_tenantContext.TenantId.HasValue)
        {
            return BadRequest(ApiResponse<object>.Failure("Tenant context not found."));
        }

        var list = await _tenantManufacturerService.GetTenantManufacturersAsync(_tenantContext.TenantId.Value, cancellationToken);
        return Ok(ApiResponse<List<TenantManufacturerDto>>.Ok(list));
    }

    /// <summary>
    /// Associates a manufacturer brand with the dealership organization (Restricted to Dealership Org Admin or Super Admin).
    /// </summary>
    [HttpPost]
    [Authorize(Policy = "StaffOnly")]
    [ProducesResponseType(typeof(ApiResponse<TenantManufacturerDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> AssociateManufacturer([FromBody] AssociateManufacturerRequest request, CancellationToken cancellationToken)
    {
        if (!_tenantContext.TenantId.HasValue)
        {
            return BadRequest(ApiResponse<object>.Failure("Tenant context not found."));
        }

        try
        {
            var mapped = await _tenantManufacturerService.AssociateManufacturerAsync(_tenantContext.TenantId.Value, request, cancellationToken);
            return Ok(ApiResponse<TenantManufacturerDto>.Ok(mapped, "Manufacturer associated successfully."));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<object>.Failure(ex.Message, 404));
        }
    }

    /// <summary>
    /// Removes a manufacturer brand mapping from the dealership.
    /// </summary>
    [HttpDelete("{manufacturerId:guid}")]
    [Authorize(Policy = "StaffOnly")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> RemoveAssociation(Guid manufacturerId, CancellationToken cancellationToken)
    {
        if (!_tenantContext.TenantId.HasValue)
        {
            return BadRequest(ApiResponse<object>.Failure("Tenant context not found."));
        }

        var removed = await _tenantManufacturerService.RemoveAssociationAsync(_tenantContext.TenantId.Value, manufacturerId, cancellationToken);
        if (!removed)
        {
            return NotFound(ApiResponse<object>.Failure("Association not found.", 404));
        }

        return Ok(ApiResponse<object>.Ok(new { manufacturerId }, "Manufacturer association removed."));
    }
}

