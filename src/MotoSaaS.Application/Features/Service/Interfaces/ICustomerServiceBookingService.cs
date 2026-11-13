using MotoSaaS.Application.Features.Service.Models;

namespace MotoSaaS.Application.Features.Service.Interfaces;

public interface ICustomerServiceBookingService
{
    Task<List<CustomerVehicleDto>> GetMyVehiclesAsync(CancellationToken cancellationToken = default);
    Task<List<ServiceBookingDto>> GetMyBookingsAsync(CancellationToken cancellationToken = default);
    Task<ServiceBookingDto> CreateBookingAsync(CreateServiceBookingRequest request, CancellationToken cancellationToken = default);
    Task<ServiceTrackingDto> GetTrackingAsync(Guid bookingId, CancellationToken cancellationToken = default);
    Task<ServiceTrackingDto> ApproveEstimateAsync(Guid jobCardId, CancellationToken cancellationToken = default);
}
