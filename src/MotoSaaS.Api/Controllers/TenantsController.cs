using Microsoft.AspNetCore.Mvc;
using MotoSaaS.Application.Common.Interfaces;
using MotoSaaS.Application.Common.Models;
using MotoSaaS.Application.Features.Tenancy.Interfaces;
using MotoSaaS.Application.Features.Tenancy.Models;

namespace MotoSaaS.Api.Controllers;

public class TenantsController : BaseApiController
{
    private readonly ITenantService _tenantService;
    private readonly ICurrentTenantContext _tenantContext;

    public TenantsController(
        ITenantService tenantService,
        ICurrentTenantContext tenantContext)
    {
        _tenantService = tenantService;
        _tenantContext = tenantContext;
    }

    /// <summary>
    /// Resolves dealership branding, primary/secondary colors, and operational branches for the active context.
    /// </summary>
    [HttpGet("current")]
    [ProducesResponseType(typeof(ApiResponse<TenantDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetCurrentTenant(CancellationToken cancellationToken)
    {
        if (!_tenantContext.TenantId.HasValue)
        {
            // Default pilot fallback (Alagendra Automobiles)
            var defaultTenant = await _tenantService.GetTenantByCodeAsync("ALAGENDRA", cancellationToken);
            if (defaultTenant != null)
            {
                return Ok(ApiResponse<TenantDto>.Ok(defaultTenant));
            }
            return NotFound(ApiResponse<object>.Failure("Tenant context not resolved.", 404));
        }

        var tenant = await _tenantService.GetTenantByIdAsync(_tenantContext.TenantId.Value, cancellationToken);
        if (tenant == null)
        {
            return NotFound(ApiResponse<object>.Failure("Tenant not found.", 404));
        }

        return Ok(ApiResponse<TenantDto>.Ok(tenant));
    }

    /// <summary>
    /// Looks up a dealership organization profile and active branches by unique dealer code.
    /// </summary>
    [HttpGet("{code}")]
    [ProducesResponseType(typeof(ApiResponse<TenantDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetTenantByCode(string code, CancellationToken cancellationToken)
    {
        var tenant = await _tenantService.GetTenantByCodeAsync(code, cancellationToken);
        if (tenant == null)
        {
            return NotFound(ApiResponse<object>.Failure($"Dealership with code '{code}' not found.", 404));
        }

        return Ok(ApiResponse<TenantDto>.Ok(tenant));
    }

    /// <summary>
    /// Retrieves physical branch locations under a dealership organization.
    /// </summary>
    [HttpGet("{id:guid}/branches")]
    [ProducesResponseType(typeof(ApiResponse<List<BranchDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetBranches(Guid id, CancellationToken cancellationToken)
    {
        var branches = await _tenantService.GetBranchesByTenantIdAsync(id, cancellationToken);
        return Ok(ApiResponse<List<BranchDto>>.Ok(branches));
    }
}

