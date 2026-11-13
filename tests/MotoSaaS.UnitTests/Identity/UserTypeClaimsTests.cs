using MotoSaaS.Application.Features.Identity;
using MotoSaaS.Domain.Identity;
using Xunit;

namespace MotoSaaS.UnitTests.Identity;

public class UserTypeClaimsTests
{
    [Theory]
    [InlineData(UserType.DealerStaff, "DEALER_STAFF")]
    [InlineData(UserType.SaasAdmin, "SAAS_ADMIN")]
    [InlineData(UserType.Customer, "CUSTOMER")]
    public void From_ReturnsPolicyClaimValue(UserType userType, string expected)
    {
        Assert.Equal(expected, UserTypeClaims.From(userType));
    }
}
