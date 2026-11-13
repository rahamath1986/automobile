using MotoSaaS.Application.Features.Manufacturer.Models;

namespace MotoSaaS.Application.Features.Manufacturer.Interfaces;

public interface IManufacturerService
{
    Task<List<ManufacturerDto>> GetManufacturersAsync(CancellationToken cancellationToken = default);
    Task<ManufacturerDto?> GetManufacturerByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<ManufacturerDto?> GetManufacturerByCodeAsync(string code, CancellationToken cancellationToken = default);
    Task<ManufacturerDto> CreateManufacturerAsync(CreateManufacturerRequest request, CancellationToken cancellationToken = default);
}

