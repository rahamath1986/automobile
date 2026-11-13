using MotoSaaS.Application.Features.Identity.Models;

namespace MotoSaaS.Application.Features.Identity.Interfaces;

public interface IStaffAuthService
{
    Task<AuthResponse> LoginAsync(StaffLoginRequest request, CancellationToken cancellationToken = default);
    Task<AuthResponse> RefreshTokenAsync(RefreshTokenRequest request, CancellationToken cancellationToken = default);
}

