using MotoSaaS.Domain.Identity;

namespace MotoSaaS.Application.Features.Sales;

/// <summary>
/// Shared rules for routing new leads to the right sales owner. Executives are
/// preferred over managers, and the least-loaded owner within a role wins.
/// </summary>
public static class SalesAssignmentRules
{
    public static readonly HashSet<string> RoleNames = new(StringComparer.OrdinalIgnoreCase)
    {
        "SalesExecutive",
        "SalesManager",
        "BranchManager"
    };

    public static bool IsSalesRole(string? roleName) =>
        roleName != null && RoleNames.Contains(roleName);

    public static int GetRoleRank(User user)
    {
        if (user.UserRoles.Any(userRole => IsSalesRole(userRole.Role?.Name)
                                           && string.Equals(userRole.Role!.Name, "SalesExecutive", StringComparison.OrdinalIgnoreCase)))
        {
            return 0;
        }

        if (user.UserRoles.Any(userRole => string.Equals(userRole.Role?.Name, "SalesManager", StringComparison.OrdinalIgnoreCase)))
        {
            return 1;
        }

        return 2;
    }
}
