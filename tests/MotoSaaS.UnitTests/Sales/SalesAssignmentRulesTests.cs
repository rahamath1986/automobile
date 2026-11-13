using MotoSaaS.Application.Features.Sales;
using MotoSaaS.Domain.Identity;
using Xunit;

namespace MotoSaaS.UnitTests.Sales;

public class SalesAssignmentRulesTests
{
    [Theory]
    [InlineData("SalesExecutive", true)]
    [InlineData("salesexecutive", true)]
    [InlineData("SalesManager", true)]
    [InlineData("BranchManager", true)]
    [InlineData("Technician", false)]
    [InlineData(null, false)]
    public void IsSalesRole_RecognisesSalesRoles(string? roleName, bool expected)
    {
        Assert.Equal(expected, SalesAssignmentRules.IsSalesRole(roleName));
    }

    [Fact]
    public void GetRoleRank_PrefersExecutiveThenManager()
    {
        var executive = BuildUser("SalesExecutive");
        var manager = BuildUser("SalesManager");
        var branchManager = BuildUser("BranchManager");

        Assert.Equal(0, SalesAssignmentRules.GetRoleRank(executive));
        Assert.Equal(1, SalesAssignmentRules.GetRoleRank(manager));
        Assert.Equal(2, SalesAssignmentRules.GetRoleRank(branchManager));
    }

    [Fact]
    public void GetRoleRank_UserWithMultipleRoles_UsesHighestPriority()
    {
        var user = BuildUser("BranchManager", "SalesExecutive");

        Assert.Equal(0, SalesAssignmentRules.GetRoleRank(user));
    }

    private static User BuildUser(params string[] roleNames)
    {
        var user = new User { FullName = "Test User" };
        foreach (var roleName in roleNames)
        {
            user.UserRoles.Add(new UserRole
            {
                UserId = user.Id,
                RoleId = Guid.NewGuid(),
                Role = new Role { Name = roleName }
            });
        }

        return user;
    }
}
