using MotoSaaS.Infrastructure.Services;
using Xunit;

namespace MotoSaaS.UnitTests.Infrastructure;

public class TenantContextTests
{
    [Fact]
    public void SetTenant_UpdatesTenantId()
    {
        var context = new TenantContext();
        var tenantId = Guid.NewGuid();

        context.SetTenant(tenantId);

        Assert.Equal(tenantId, context.TenantId);
        Assert.False(context.IsAuthenticated);
        Assert.False(context.IsSuperAdmin);
    }

    [Fact]
    public void SetUser_SuperAdmin_SetsIsSuperAdminTrue()
    {
        var context = new TenantContext();
        var userId = Guid.NewGuid();

        context.SetUser(userId, "SAAS_ADMIN");

        Assert.Equal(userId, context.UserId);
        Assert.Equal("SAAS_ADMIN", context.UserType);
        Assert.True(context.IsSuperAdmin);
        Assert.True(context.IsAuthenticated);
    }

    [Fact]
    public void SetUser_DealerStaff_SetsIsSuperAdminFalse()
    {
        var context = new TenantContext();
        var userId = Guid.NewGuid();

        context.SetUser(userId, "DEALER_STAFF");

        Assert.Equal(userId, context.UserId);
        Assert.False(context.IsSuperAdmin);
        Assert.True(context.IsAuthenticated);
    }
}

