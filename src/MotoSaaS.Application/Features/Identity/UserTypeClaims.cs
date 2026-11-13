using MotoSaaS.Domain.Identity;

namespace MotoSaaS.Application.Features.Identity;

/// <summary>
/// Canonical claim values for <see cref="UserType"/>. JWT policies and the tenant
/// context compare against these strings, so they must not rely on enum casing.
/// </summary>
public static class UserTypeClaims
{
    public const string SaasAdmin = "SAAS_ADMIN";
    public const string DealerStaff = "DEALER_STAFF";
    public const string Customer = "CUSTOMER";

    public static string From(UserType userType) => userType switch
    {
        UserType.SaasAdmin => SaasAdmin,
        UserType.DealerStaff => DealerStaff,
        UserType.Customer => Customer,
        _ => userType.ToString().ToUpperInvariant()
    };
}
