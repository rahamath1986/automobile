using MotoSaaS.Application.Features.Catalog.Models;
using MotoSaaS.Domain.Catalog;

namespace MotoSaaS.Application.Features.Catalog.Interfaces;

public interface IVehicleCatalogService
{
    Task<List<VehicleModelSummaryDto>> GetModelsAsync(
        VehicleCategory? category = null,
        Guid? manufacturerId = null,
        FuelType? fuelType = null,
        CancellationToken cancellationToken = default);

    Task<List<VehicleModelSummaryDto>> GetCatalogForTenantAsync(
        Guid tenantId,
        VehicleCategory? category = null,
        CancellationToken cancellationToken = default);

    Task<VehicleModelDetailDto?> GetModelDetailsByIdAsync(
        Guid modelId,
        CancellationToken cancellationToken = default);

    Task<VariantBranchPricingDto?> GetVariantBranchPricingAsync(
        Guid variantId,
        Guid? branchId = null,
        CancellationToken cancellationToken = default);

    Task<VehicleModelSummaryDto> CreateModelAsync(
        CreateModelRequest request,
        CancellationToken cancellationToken = default);

    Task<VehicleVariantDto> CreateVariantAsync(
        CreateVariantRequest request,
        CancellationToken cancellationToken = default);

    Task<VehicleColorDto> CreateColorAsync(
        CreateColorRequest request,
        CancellationToken cancellationToken = default);
}

