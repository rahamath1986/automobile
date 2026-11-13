using MotoSaaS.Application.Features.Identity.Models;

namespace MotoSaaS.Application.Features.Identity.Interfaces;

public interface IJwtTokenService
{
    string GenerateAccessToken(UserProfileDto user);
    string GenerateRefreshToken();
    bool ValidateRefreshToken(string refreshToken);
}

