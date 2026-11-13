using Microsoft.EntityFrameworkCore;
using MotoSaaS.Application.Common.Interfaces;
using MotoSaaS.Application.Features.Identity.Interfaces;
using MotoSaaS.Application.Features.Identity.Models;
using MotoSaaS.Domain.Identity;

namespace MotoSaaS.Application.Features.Identity.Services;

public class StaffAuthService : IStaffAuthService
{
    private readonly IApplicationDbContext _context;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IJwtTokenService _jwtTokenService;

    public StaffAuthService(
        IApplicationDbContext context,
        IPasswordHasher passwordHasher,
        IJwtTokenService jwtTokenService)
    {
        _context = context;
        _passwordHasher = passwordHasher;
        _jwtTokenService = jwtTokenService;
    }

    public async Task<AuthResponse> LoginAsync(StaffLoginRequest request, CancellationToken cancellationToken = default)
    {
        var normalizedUser = request.UsernameOrEmail.Trim().ToLowerInvariant();
        var normalizedCode = request.DealerCode.Trim().ToUpperInvariant();

        // 1. Resolve Tenant
        var tenant = await _context.Tenants
            .AsNoTracking()
            .FirstOrDefaultAsync(t => t.Code == normalizedCode, cancellationToken);

        if (tenant == null && normalizedCode != "SUPERADMIN")
        {
            throw new UnauthorizedAccessException("Invalid dealer code or organization not found.");
        }

        // 2. Query User
        var query = _context.Users
            .Include(u => u.Tenant)
            .Include(u => u.DefaultBranch)
            .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
            .AsNoTracking();

        User? user;
        if (tenant != null)
        {
            user = await query.FirstOrDefaultAsync(u => 
                u.TenantId == tenant.Id && 
                (u.Username.ToLower() == normalizedUser || u.Email.ToLower() == normalizedUser), 
                cancellationToken);
        }
        else
        {
            // Super Admin
            user = await query.FirstOrDefaultAsync(u => 
                u.TenantId == null && 
                (u.Username.ToLower() == normalizedUser || u.Email.ToLower() == normalizedUser), 
                cancellationToken);
        }

        if (user == null || !user.IsActive)
        {
            throw new UnauthorizedAccessException("Invalid credentials or account is deactivated.");
        }

        // 3. Verify Password
        if (!_passwordHasher.VerifyPassword(request.Password, user.PasswordHash))
        {
            throw new UnauthorizedAccessException("Invalid credentials.");
        }

        // 4. Build Profile and Tokens
        var roles = user.UserRoles
            .Where(ur => ur.Role != null)
            .Select(ur => ur.Role!.Name)
            .Distinct()
            .ToList();

        if (roles.Count == 0 && user.UserType == UserType.SaasAdmin)
        {
            roles.Add("SaaSAdmin");
        }

        var profile = new UserProfileDto
        {
            Id = user.Id,
            FullName = user.FullName,
            Email = user.Email,
            Phone = user.Phone,
            UserType = UserTypeClaims.From(user.UserType),
            TenantId = user.TenantId,
            TenantCode = user.Tenant?.Code,
            TenantName = user.Tenant?.TradeName,
            DefaultBranchId = user.DefaultBranchId,
            BranchCode = user.DefaultBranch?.Code,
            BranchName = user.DefaultBranch?.Name,
            Roles = roles
        };

        var accessToken = _jwtTokenService.GenerateAccessToken(profile);
        var refreshToken = _jwtTokenService.GenerateRefreshToken();

        return new AuthResponse
        {
            AccessToken = accessToken,
            RefreshToken = refreshToken,
            ExpiresInSeconds = 900,
            TokenType = "Bearer",
            User = profile
        };
    }

    public Task<AuthResponse> RefreshTokenAsync(RefreshTokenRequest request, CancellationToken cancellationToken = default)
    {
        if (!_jwtTokenService.ValidateRefreshToken(request.RefreshToken))
        {
            throw new UnauthorizedAccessException("Invalid or expired refresh token.");
        }

        // Return renewed session envelope
        return Task.FromResult(new AuthResponse
        {
            AccessToken = "MOCK_ROTATED_TOKEN",
            RefreshToken = _jwtTokenService.GenerateRefreshToken(),
            ExpiresInSeconds = 900
        });
    }
}

