using System.Data;
using System.Data.Common;
using Microsoft.EntityFrameworkCore.Diagnostics;
using MotoSaaS.Application.Common.Interfaces;

namespace MotoSaaS.Infrastructure.Persistence.Interceptors;

/// <summary>
/// Applies the current tenant to the PostgreSQL session whenever EF Core opens a
/// connection. Using the connection-open hook (instead of prefixing every command
/// with a multi-statement SET LOCAL) keeps the reported rows-affected count intact
/// for INSERT/UPDATE/DELETE batches.
///
/// Npgsql resets the session with DISCARD ALL when a pooled connection is returned,
/// so the value never leaks between requests.
/// </summary>
public class TenantRlsConnectionInterceptor : DbConnectionInterceptor
{
    private readonly ICurrentTenantContext _tenantContext;

    public TenantRlsConnectionInterceptor(ICurrentTenantContext tenantContext)
    {
        _tenantContext = tenantContext;
    }

    public override void ConnectionOpened(DbConnection connection, ConnectionEndEventData eventData)
    {
        ApplySessionContext(connection);
        base.ConnectionOpened(connection, eventData);
    }

    public override async Task ConnectionOpenedAsync(
        DbConnection connection,
        ConnectionEndEventData eventData,
        CancellationToken cancellationToken = default)
    {
        await ApplySessionContextAsync(connection, cancellationToken);
        await base.ConnectionOpenedAsync(connection, eventData, cancellationToken);
    }

    private void ApplySessionContext(DbConnection connection)
    {
        using var command = BuildSessionCommand(connection);
        command.ExecuteNonQuery();
    }

    private async Task ApplySessionContextAsync(DbConnection connection, CancellationToken cancellationToken)
    {
        await using var command = BuildSessionCommand(connection);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private DbCommand BuildSessionCommand(DbConnection connection)
    {
        var command = connection.CreateCommand();
        command.CommandType = CommandType.Text;
        command.CommandText =
            "SELECT set_config('app.current_tenant_id', @tenant_id, false), " +
            "set_config('app.is_saas_super_admin', @is_super_admin, false);";

        var tenantParameter = command.CreateParameter();
        tenantParameter.ParameterName = "tenant_id";
        tenantParameter.Value = _tenantContext.TenantId?.ToString() ?? string.Empty;
        command.Parameters.Add(tenantParameter);

        var superAdminParameter = command.CreateParameter();
        superAdminParameter.ParameterName = "is_super_admin";
        superAdminParameter.Value = _tenantContext.IsSuperAdmin ? "true" : "false";
        command.Parameters.Add(superAdminParameter);

        return command;
    }
}
