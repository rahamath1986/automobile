using MotoSaaS.Application.Features.Identity.Services;
using Xunit;

namespace MotoSaaS.UnitTests.Identity;

public class PasswordHasherTests
{
    private readonly PasswordHasher _hasher = new();

    [Fact]
    public void HashPassword_GeneratesSaltedHash()
    {
        var password = "SecureDealerPassword2026!";
        var hash = _hasher.HashPassword(password);

        Assert.NotNull(hash);
        Assert.Contains(".", hash);
    }

    [Fact]
    public void VerifyPassword_CorrectPassword_ReturnsTrue()
    {
        var password = "MySecretStaffPassword";
        var hash = _hasher.HashPassword(password);

        var result = _hasher.VerifyPassword(password, hash);

        Assert.True(result);
    }

    [Fact]
    public void VerifyPassword_WrongPassword_ReturnsFalse()
    {
        var password = "CorrectPassword123";
        var hash = _hasher.HashPassword(password);

        var result = _hasher.VerifyPassword("WrongPassword456", hash);

        Assert.False(result);
    }

    [Fact]
    public void HashPassword_SamePassword_GeneratesUniqueSalts()
    {
        var password = "SamePasswordRepeated";
        var hash1 = _hasher.HashPassword(password);
        var hash2 = _hasher.HashPassword(password);

        Assert.NotEqual(hash1, hash2);
        Assert.True(_hasher.VerifyPassword(password, hash1));
        Assert.True(_hasher.VerifyPassword(password, hash2));
    }
}

