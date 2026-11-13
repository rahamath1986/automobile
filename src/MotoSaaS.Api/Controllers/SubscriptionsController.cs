using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MotoSaaS.Application.Common.Interfaces;
using MotoSaaS.Application.Common.Models;
using MotoSaaS.Application.Features.Subscription.Interfaces;
using MotoSaaS.Application.Features.Subscription.Models;

namespace MotoSaaS.Api.Controllers;

public class SubscriptionsController : BaseApiController
{
    private readonly ISubscriptionPlanService _planService;
    private readonly IEntitlementService _entitlementService;
    private readonly ICurrentTenantContext _tenantContext;

    public SubscriptionsController(
        ISubscriptionPlanService planService,
        IEntitlementService entitlementService,
        ICurrentTenantContext tenantContext)
    {
        _planService = planService;
        _entitlementService = entitlementService;
        _tenantContext = tenantContext;
    }

    /// <summary>
    /// Lists all active subscription tiers (Starter, Growth, Enterprise) and feature matrices.
    /// </summary>
    [HttpGet("plans")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<List<SubscriptionPlanDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetPlans(CancellationToken cancellationToken)
    {
        var plans = await _planService.GetActivePlansAsync(cancellationToken);
        return Ok(ApiResponse<List<SubscriptionPlanDto>>.Ok(plans));
    }

    /// <summary>
    /// Retrieves the current tenant's active subscription tier, quota limits, and live resource usage.
    /// </summary>
    [HttpGet("current")]
    [Authorize(Policy = "StaffOnly")]
    [ProducesResponseType(typeof(ApiResponse<TenantSubscriptionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> GetCurrentSubscription(CancellationToken cancellationToken)
    {
        if (!_tenantContext.TenantId.HasValue)
        {
            return BadRequest(ApiResponse<object>.Failure("Tenant context not found."));
        }

        var details = await _entitlementService.GetSubscriptionDetailsAsync(_tenantContext.TenantId.Value, cancellationToken);
        return Ok(ApiResponse<TenantSubscriptionDto>.Ok(details));
    }

    /// <summary>
    /// Upgrades or changes the dealership organization's subscription tier.
    /// </summary>
    [HttpPost("upgrade")]
    [Authorize(Policy = "StaffOnly")]
    [ProducesResponseType(typeof(ApiResponse<TenantSubscriptionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> UpgradeSubscription([FromBody] UpgradeSubscriptionRequest request, CancellationToken cancellationToken)
    {
        if (!_tenantContext.TenantId.HasValue)
        {
            return BadRequest(ApiResponse<object>.Failure("Tenant context not found."));
        }

        var updated = await _planService.AssignPlanAsync(_tenantContext.TenantId.Value, request.PlanCode, cancellationToken);
        return Ok(ApiResponse<TenantSubscriptionDto>.Ok(updated, $"Subscription upgraded successfully to '{request.PlanCode}'."));
    }
}

