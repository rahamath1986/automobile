using MotoSaaS.Application.Features.Manufacturer.Models;

namespace MotoSaaS.Application.Features.Manufacturer.Interfaces;

public interface ITenantManufacturerService
{
    Task<List<TenantManufacturerDto>> GetTenantManufacturersAsync(Guid tenantId, CancellationToken cancellationToken = default);
    Task<TenantManufacturerDto> AssociateManufacturerAsync(Guid tenantId, AssociateManufacturerRequest request, CancellationToken cancellationToken = default);
    Task<bool> RemoveAssociationAsync(Guid tenantId, Guid manufacturerId, CancellationToken cancellationToken = default);
}

