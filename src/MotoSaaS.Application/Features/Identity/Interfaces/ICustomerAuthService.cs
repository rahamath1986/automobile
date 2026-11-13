using MotoSaaS.Application.Features.Identity.Models;

namespace MotoSaaS.Application.Features.Identity.Interfaces;

public interface ICustomerAuthService
{
    Task<bool> RequestOtpAsync(CustomerRequestOtpRequest request, CancellationToken cancellationToken = default);
    Task<AuthResponse> VerifyOtpAsync(CustomerVerifyOtpRequest request, CancellationToken cancellationToken = default);
}

