using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using MotoSaaS.Application.Common.Interfaces;
using MotoSaaS.Application.Common.Models;
using MotoSaaS.Application.Features.Subscription.Interfaces;

namespace MotoSaaS.Api.Filters;

[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, AllowMultiple = false, Inherited = true)]
public class RequiresFeatureAttribute : TypeFilterAttribute
{
    public RequiresFeatureAttribute(string featureKey) : base(typeof(RequiresFeatureFilter))
    {
        Arguments = new object[] { featureKey };
    }

    private class RequiresFeatureFilter : IAsyncActionFilter
    {
        private readonly string _featureKey;
        private readonly IEntitlementService _entitlementService;
        private readonly ICurrentTenantContext _tenantContext;

        public RequiresFeatureFilter(
            string featureKey,
            IEntitlementService entitlementService,
            ICurrentTenantContext tenantContext)
        {
            _featureKey = featureKey;
            _entitlementService = entitlementService;
            _tenantContext = tenantContext;
        }

        public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
        {
            // SaaS Super Admin bypasses feature restrictions for support/management
            if (_tenantContext.IsSuperAdmin)
            {
                await next();
                return;
            }

            if (!_tenantContext.TenantId.HasValue)
            {
                context.Result = new ObjectResult(ApiResponse<object>.Failure(
                    "Tenant context is required to evaluate feature entitlement.", 400))
                {
                    StatusCode = StatusCodes.Status400BadRequest
                };
                return;
            }

            var isEnabled = await _entitlementService.IsFeatureEnabledAsync(_tenantContext.TenantId.Value, _featureKey);
            if (!isEnabled)
            {
                context.Result = new ObjectResult(ApiResponse<object>.Failure(
                    $"Feature '{_featureKey}' is not enabled for your dealership subscription tier. Please upgrade your subscription plan.", 
                    StatusCodes.Status403Forbidden))
                {
                    StatusCode = StatusCodes.Status403Forbidden
                };
                return;
            }

            await next();
        }
    }
}

