using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using MotoSaaS.Application.Common.Interfaces;
using MotoSaaS.Infrastructure.Persistence;
using MotoSaaS.Infrastructure.Persistence.Interceptors;
using MotoSaaS.Infrastructure.Services;

namespace MotoSaaS.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructureServices(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        services.AddScoped<TenantContext>();
        services.AddScoped<ICurrentTenantContext>(sp => sp.GetRequiredService<TenantContext>());
        services.AddScoped<TenantRlsConnectionInterceptor>();

        var connectionString = configuration.GetConnectionString("DefaultConnection") 
            ?? "Host=localhost;Port=5432;Database=motosaas_db;Username=postgres;Password=postgres;";

        services.AddDbContext<ApplicationDbContext>((sp, options) =>
        {
            var interceptor = sp.GetRequiredService<TenantRlsConnectionInterceptor>();
            options.UseNpgsql(connectionString, npgsqlOptions =>
            {
                npgsqlOptions.MigrationsAssembly(typeof(ApplicationDbContext).Assembly.FullName);
                npgsqlOptions.EnableRetryOnFailure(3);
            });
            options.AddInterceptors(interceptor);
        });

        services.AddScoped<IApplicationDbContext>(sp => sp.GetRequiredService<ApplicationDbContext>());

        return services;
    }
}

