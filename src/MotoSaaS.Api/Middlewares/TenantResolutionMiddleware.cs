using Microsoft.EntityFrameworkCore;
using MotoSaaS.Application.Common.Interfaces;
using MotoSaaS.Infrastructure.Services;

namespace MotoSaaS.Api.Middlewares;

public class TenantResolutionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<TenantResolutionMiddleware> _logger;

    public TenantResolutionMiddleware(RequestDelegate next, ILogger<TenantResolutionMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(
        HttpContext context,
        ICurrentTenantContext tenantContext,
        IApplicationDbContext dbContext)
    {
        // 1. Resolve from Authenticated JWT claims if present
        if (context.User.Identity?.IsAuthenticated == true)
        {
            var tenantClaim = context.User.FindFirst("tenant_id")?.Value;
            var branchClaim = context.User.FindFirst("branch_id")?.Value;
            var userTypeClaim = context.User.FindFirst("user_type")?.Value;
            var userIdClaim = context.User.FindFirst("sub")?.Value 
                ?? context.User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;

            if (Guid.TryParse(tenantClaim, out var tenantId))
            {
                tenantContext.SetTenant(tenantId);
            }

            if (Guid.TryParse(branchClaim, out var branchId))
            {
                tenantContext.SetBranch(branchId);
            }

            if (tenantContext is TenantContext concreteContext && Guid.TryParse(userIdClaim, out var userId))
            {
                concreteContext.SetUser(userId, userTypeClaim ?? "DEALER_STAFF");
            }
        }
        else
        {
            // 2. Resolve for public endpoints from headers (e.g. X-Tenant-Id or X-Dealer-Code)
            if (context.Request.Headers.TryGetValue("X-Tenant-Id", out var tenantHeader) 
                && Guid.TryParse(tenantHeader.ToString(), out var headerTenantId))
            {
                tenantContext.SetTenant(headerTenantId);
            }
            else if (context.Request.Headers.TryGetValue("X-Dealer-Code", out var dealerCodeHeader))
            {
                var dealerCode = dealerCodeHeader.ToString().Trim().ToUpperInvariant();
                if (!string.IsNullOrWhiteSpace(dealerCode))
                {
                    var tenant = await dbContext.Tenants
                        .AsNoTracking()
                        .FirstOrDefaultAsync(t => t.Code == dealerCode, context.RequestAborted);

                    if (tenant != null)
                    {
                        tenantContext.SetTenant(tenant.Id);
                    }
                    else
                    {
                        _logger.LogWarning("Public request supplied unknown dealer code {DealerCode}.", dealerCode);
                    }
                }
            }
        }

        await _next(context);
    }
}
