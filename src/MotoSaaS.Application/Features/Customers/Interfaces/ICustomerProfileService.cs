using MotoSaaS.Application.Features.Customers.Models;

namespace MotoSaaS.Application.Features.Customers.Interfaces;

public interface ICustomerProfileService
{
    Task<CustomerProfileDto> GetProfileAsync(CancellationToken cancellationToken = default);
    Task<CustomerProfileDto> UpdateProfileAsync(UpdateCustomerProfileRequest request, CancellationToken cancellationToken = default);
}
