using FluentValidation;
using Microsoft.Extensions.DependencyInjection;
using MotoSaaS.Application.Features.Branding.Interfaces;
using MotoSaaS.Application.Features.Branding.Services;
using MotoSaaS.Application.Features.Catalog.Interfaces;
using MotoSaaS.Application.Features.Catalog.Services;
using MotoSaaS.Application.Features.Customers.Interfaces;
using MotoSaaS.Application.Features.Customers.Services;
using MotoSaaS.Application.Features.Finance;
using MotoSaaS.Application.Features.Identity.Interfaces;
using MotoSaaS.Application.Features.Identity.Services;
using MotoSaaS.Application.Features.Inventory.Interfaces;
using MotoSaaS.Application.Features.Inventory.Services;
using MotoSaaS.Application.Features.Manufacturer.Interfaces;
using MotoSaaS.Application.Features.Manufacturer.Services;
using MotoSaaS.Application.Features.Sales.Interfaces;
using MotoSaaS.Application.Features.Sales.Services;
using MotoSaaS.Application.Features.Service.Interfaces;
using MotoSaaS.Application.Features.Service.Services;
using MotoSaaS.Application.Features.Showroom3D.Interfaces;
using MotoSaaS.Application.Features.Showroom3D.Services;
using MotoSaaS.Application.Features.Subscription.Interfaces;
using MotoSaaS.Application.Features.Subscription.Services;
using MotoSaaS.Application.Features.Tenancy.Interfaces;
using MotoSaaS.Application.Features.Tenancy.Services;

namespace MotoSaaS.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplicationServices(this IServiceCollection services)
    {
        services.AddScoped<IEmiCalculatorService, EmiCalculatorService>();
        services.AddSingleton<IPasswordHasher, PasswordHasher>();
        services.AddScoped<IJwtTokenService, JwtTokenService>();
        services.AddScoped<IStaffAuthService, StaffAuthService>();
        services.AddScoped<ICustomerAuthService, CustomerAuthService>();
        services.AddScoped<ITenantService, TenantService>();
        services.AddScoped<IEntitlementService, EntitlementService>();
        services.AddScoped<ISubscriptionPlanService, SubscriptionPlanService>();
        services.AddScoped<IManufacturerService, ManufacturerService>();
        services.AddScoped<ITenantManufacturerService, TenantManufacturerService>();
        services.AddScoped<IBrandingService, BrandingService>();
        services.AddScoped<IVehicleCatalogService, VehicleCatalogService>();
        services.AddScoped<IInventoryService, InventoryService>();
        services.AddScoped<IShowroom3DService, Showroom3DService>();
        services.AddScoped<ICustomerSalesService, CustomerSalesService>();
        services.AddScoped<IStaffSalesService, StaffSalesService>();
        services.AddScoped<IQuotationService, QuotationService>();
        services.AddScoped<ICustomerServiceBookingService, CustomerServiceBookingService>();
        services.AddScoped<ICustomerProfileService, CustomerProfileService>();

        services.AddValidatorsFromAssembly(typeof(DependencyInjection).Assembly);

        return services;
    }
}
