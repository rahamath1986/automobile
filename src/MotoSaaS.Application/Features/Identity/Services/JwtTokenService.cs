using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using MotoSaaS.Application.Features.Identity.Interfaces;
using MotoSaaS.Application.Features.Identity.Models;

namespace MotoSaaS.Application.Features.Identity.Services;

public class JwtTokenService : IJwtTokenService
{
    private readonly IConfiguration _configuration;

    public JwtTokenService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public string GenerateAccessToken(UserProfileDto user)
    {
        var secretKey = _configuration["JwtSettings:SecretKey"] 
            ?? "MotoSaaS_Super_Secure_Secret_Key_For_Development_Only_Change_In_Production_2026!";
        var issuer = _configuration["JwtSettings:Issuer"] ?? "MotoSaaS.Platform";
        var audience = _configuration["JwtSettings:Audience"] ?? "MotoSaaS.Clients";
        var expirationMinutes = int.TryParse(_configuration["JwtSettings:AccessTokenExpirationMinutes"], out var exp) ? exp : 15;

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new(JwtRegisteredClaimNames.Name, user.FullName),
            new("user_type", user.UserType),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        if (!string.IsNullOrEmpty(user.Email))
        {
            claims.Add(new Claim(JwtRegisteredClaimNames.Email, user.Email));
        }

        if (!string.IsNullOrEmpty(user.Phone))
        {
            claims.Add(new Claim("phone", user.Phone));
        }

        if (user.TenantId.HasValue)
        {
            claims.Add(new Claim("tenant_id", user.TenantId.Value.ToString()));
        }

        if (user.DefaultBranchId.HasValue)
        {
            claims.Add(new Claim("branch_id", user.DefaultBranchId.Value.ToString()));
        }

        foreach (var role in user.Roles)
        {
            claims.Add(new Claim(ClaimTypes.Role, role));
        }

        var tokenDescriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(claims),
            Expires = DateTime.UtcNow.AddMinutes(expirationMinutes),
            Issuer = issuer,
            Audience = audience,
            SigningCredentials = credentials
        };

        var tokenHandler = new JwtSecurityTokenHandler();
        var token = tokenHandler.CreateToken(tokenDescriptor);
        return tokenHandler.WriteToken(token);
    }

    public string GenerateRefreshToken()
    {
        var randomBytes = RandomNumberGenerator.GetBytes(64);
        return Convert.ToBase64String(randomBytes);
    }

    public bool ValidateRefreshToken(string refreshToken)
    {
        return !string.IsNullOrWhiteSpace(refreshToken) && refreshToken.Length >= 32;
    }
}

