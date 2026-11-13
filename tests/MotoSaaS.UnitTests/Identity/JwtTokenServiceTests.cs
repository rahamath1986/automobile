using System.IdentityModel.Tokens.Jwt;
using Microsoft.Extensions.Configuration;
using MotoSaaS.Application.Features.Identity.Models;
using MotoSaaS.Application.Features.Identity.Services;
using Xunit;

namespace MotoSaaS.UnitTests.Identity;

public class JwtTokenServiceTests
{
    private readonly JwtTokenService _tokenService;

    public JwtTokenServiceTests()
    {
        var inMemorySettings = new Dictionary<string, string?>
        {
            {"JwtSettings:SecretKey", "Very_Secret_Key_For_Unit_Testing_Purposes_32_Bytes_Long!"},
            {"JwtSettings:Issuer", "Test.MotoSaaS"},
            {"JwtSettings:Audience", "Test.Clients"},
            {"JwtSettings:AccessTokenExpirationMinutes", "30"}
        };

        var configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(inMemorySettings)
            .Build();

        _tokenService = new JwtTokenService(configuration);
    }

    [Fact]
    public void GenerateAccessToken_StaffUser_EmbedsTenantAndBranchClaims()
    {
        var tenantId = Guid.NewGuid();
        var branchId = Guid.NewGuid();
        var userId = Guid.NewGuid();

        var profile = new UserProfileDto
        {
            Id = userId,
            FullName = "Ramesh Kumar",
            Email = "ramesh@alagendra.local",
            Phone = "+919876543210",
            UserType = "DEALER_STAFF",
            TenantId = tenantId,
            DefaultBranchId = branchId,
            Roles = new List<string> { "SalesExecutive", "BranchManager" }
        };

        var token = _tokenService.GenerateAccessToken(profile);

        Assert.NotNull(token);
        Assert.NotEmpty(token);

        var handler = new JwtSecurityTokenHandler();
        var jwt = handler.ReadJwtToken(token);

        Assert.Equal("Test.MotoSaaS", jwt.Issuer);
        Assert.Equal(userId.ToString(), jwt.Subject);
        Assert.Equal("DEALER_STAFF", jwt.Claims.First(c => c.Type == "user_type").Value);
        Assert.Equal(tenantId.ToString(), jwt.Claims.First(c => c.Type == "tenant_id").Value);
        Assert.Equal(branchId.ToString(), jwt.Claims.First(c => c.Type == "branch_id").Value);
        Assert.Contains(jwt.Claims, c => c.Type == "role" && c.Value == "SalesExecutive");
    }

    [Fact]
    public void GenerateAccessToken_CustomerUser_EmbedsCustomerTypeWithoutStaffClaims()
    {
        var customerId = Guid.NewGuid();
        var profile = new UserProfileDto
        {
            Id = customerId,
            FullName = "Priya Sharma",
            Phone = "+919876500000",
            UserType = "CUSTOMER",
            Roles = new List<string> { "Customer" }
        };

        var token = _tokenService.GenerateAccessToken(profile);
        var handler = new JwtSecurityTokenHandler();
        var jwt = handler.ReadJwtToken(token);

        Assert.Equal("CUSTOMER", jwt.Claims.First(c => c.Type == "user_type").Value);
        Assert.DoesNotContain(jwt.Claims, c => c.Type == "role" && c.Value == "SalesExecutive");
    }

    [Fact]
    public void GenerateRefreshToken_ReturnsCryptographicallySecureString()
    {
        var token1 = _tokenService.GenerateRefreshToken();
        var token2 = _tokenService.GenerateRefreshToken();

        Assert.NotNull(token1);
        Assert.NotEmpty(token1);
        Assert.NotEqual(token1, token2);
        Assert.True(_tokenService.ValidateRefreshToken(token1));
    }
}

