using MotoSaaS.Application.Features.Sales.Models;

namespace MotoSaaS.Application.Features.Sales.Interfaces;

public interface ICustomerSalesService
{
    Task<EnquiryDto> CreateEnquiryAsync(CreateEnquiryRequest request, CancellationToken cancellationToken = default);
    Task<List<EnquiryDto>> GetMyEnquiriesAsync(CancellationToken cancellationToken = default);
    Task<TestRideDto> CreateTestRideAsync(CreateTestRideRequest request, CancellationToken cancellationToken = default);
    Task<List<TestRideDto>> GetMyTestRidesAsync(CancellationToken cancellationToken = default);
}
