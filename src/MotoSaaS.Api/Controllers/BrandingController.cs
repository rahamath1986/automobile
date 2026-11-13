using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MotoSaaS.Application.Common.Interfaces;
using MotoSaaS.Application.Common.Models;
using MotoSaaS.Application.Features.Branding.Interfaces;
using MotoSaaS.Application.Features.Branding.Models;

namespace MotoSaaS.Api.Controllers;

public class BrandingController : BaseApiController
{
    private readonly IBrandingService _brandingService;
    private readonly ICurrentTenantContext _tenantContext;

    public BrandingController(
        IBrandingService brandingService,
        ICurrentTenantContext tenantContext)
    {
        _brandingService = brandingService;
        _tenantContext = tenantContext;
    }

    /// <summary>
    /// Retrieves active white-label branding, logos, primary/secondary colors, and contact info for the current dealership.
    /// </summary>
    [HttpGet("current")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<WhiteLabelBrandingDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetCurrentBranding(CancellationToken cancellationToken)
    {
        if (!_tenantContext.TenantId.HasValue)
        {
            // Fallback to Alagendra Automobiles pilot
            var fallback = await _brandingService.GetBrandingByCodeAsync("ALAGENDRA", cancellationToken);
            if (fallback != null)
            {
                return Ok(ApiResponse<WhiteLabelBrandingDto>.Ok(fallback));
            }

            return NotFound(ApiResponse<object>.Failure("Tenant branding not found.", 404));
        }

        var branding = await _brandingService.GetBrandingAsync(_tenantContext.TenantId.Value, cancellationToken);
        if (branding == null)
        {
            return NotFound(ApiResponse<object>.Failure("Branding profile not found.", 404));
        }

        return Ok(ApiResponse<WhiteLabelBrandingDto>.Ok(branding));
    }

    /// <summary>
    /// Retrieves branding parameters by unique dealer code (used by mobile apps during white-label initialization).
    /// </summary>
    [HttpGet("{dealerCode}")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<WhiteLabelBrandingDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetBrandingByCode(string dealerCode, CancellationToken cancellationToken)
    {
        var branding = await _brandingService.GetBrandingByCodeAsync(dealerCode, cancellationToken);
        if (branding == null)
        {
            return NotFound(ApiResponse<object>.Failure($"Dealership with code '{dealerCode}' not found.", 404));
        }

        return Ok(ApiResponse<WhiteLabelBrandingDto>.Ok(branding));
    }

    /// <summary>
    /// Updates white-label branding parameters, colors, or logo (Restricted to Dealership Org Admin or Super Admin).
    /// </summary>
    [HttpPut("current")]
    [Authorize(Policy = "StaffOnly")]
    [ProducesResponseType(typeof(ApiResponse<WhiteLabelBrandingDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> UpdateCurrentBranding([FromBody] UpdateBrandingRequest request, CancellationToken cancellationToken)
    {
        if (!_tenantContext.TenantId.HasValue)
        {
            return BadRequest(ApiResponse<object>.Failure("Tenant context not found."));
        }

        var updated = await _brandingService.UpdateBrandingAsync(_tenantContext.TenantId.Value, request, cancellationToken);
        return Ok(ApiResponse<WhiteLabelBrandingDto>.Ok(updated, "Branding updated successfully."));
    }
}

