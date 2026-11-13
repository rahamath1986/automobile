using Microsoft.AspNetCore.Mvc;
using MotoSaaS.Api.Controllers;
using MotoSaaS.Application.Common.Models;
using MotoSaaS.Application.Features.Catalog.Interfaces;
using MotoSaaS.Application.Features.Catalog.Models;
using MotoSaaS.Domain.Catalog;
using MotoSaaS.Infrastructure.Services;
using Xunit;

namespace MotoSaaS.UnitTests.Controllers;

public class CatalogControllerTests
{
    private class FakeCatalogService : IVehicleCatalogService
    {
        public Task<List<VehicleModelSummaryDto>> GetModelsAsync(
            VehicleCategory? category = null,
            Guid? manufacturerId = null,
            FuelType? fuelType = null,
            CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new List<VehicleModelSummaryDto>
            {
                new() { Code = "YZF-R15", Name = "Yamaha R15", Category = "MOTORCYCLE" },
                new() { Code = "AEROX", Name = "Yamaha Aerox", Category = "SCOOTER" }
            });
        }

        public Task<List<VehicleModelSummaryDto>> GetCatalogForTenantAsync(
            Guid tenantId,
            VehicleCategory? category = null,
            CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new List<VehicleModelSummaryDto>
            {
                new() { Code = "YZF-R15", Name = "Yamaha R15", Category = "MOTORCYCLE" }
            });
        }

        public Task<VehicleModelDetailDto?> GetModelDetailsByIdAsync(Guid modelId, CancellationToken cancellationToken = default)
        {
            return Task.FromResult<VehicleModelDetailDto?>(new VehicleModelDetailDto
            {
                Id = modelId,
                Code = "YZF-R15",
                Name = "Yamaha R15"
            });
        }

        public Task<VariantBranchPricingDto?> GetVariantBranchPricingAsync(
            Guid variantId,
            Guid? branchId = null,
            CancellationToken cancellationToken = default)
        {
            return Task.FromResult<VariantBranchPricingDto?>(new VariantBranchPricingDto
            {
                VariantId = variantId,
                BranchId = branchId,
                BranchName = "Mangalore Central",
                ExShowroomPrice = 195000m,
                EstimatedOnRoadPrice = 224000m,
                AvailableUnits = 2,
                InStock = true
            });
        }

        public Task<VehicleModelSummaryDto> CreateModelAsync(CreateModelRequest request, CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new VehicleModelSummaryDto { Code = request.Code, Name = request.Name });
        }

        public Task<VehicleVariantDto> CreateVariantAsync(CreateVariantRequest request, CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new VehicleVariantDto { Code = request.Code, Name = request.Name });
        }

        public Task<VehicleColorDto> CreateColorAsync(CreateColorRequest request, CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new VehicleColorDto { ColorName = request.ColorName });
        }
    }

    [Fact]
    public async Task GetModels_AnonymousCall_ReturnsOkWithList()
    {
        var tenantContext = new TenantContext();
        var controller = new CatalogController(new FakeCatalogService(), tenantContext);

        var result = await controller.GetModels(null, null, null, CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var envelope = Assert.IsType<ApiResponse<List<VehicleModelSummaryDto>>>(okResult.Value);

        Assert.True(envelope.Success);
        Assert.Equal(2, envelope.Data!.Count);
    }

    [Fact]
    public async Task GetVariantPricing_ReturnsBranchEstimate()
    {
        var tenantContext = new TenantContext();
        var controller = new CatalogController(new FakeCatalogService(), tenantContext);

        var result = await controller.GetVariantPricing(Guid.NewGuid(), Guid.NewGuid(), CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var envelope = Assert.IsType<ApiResponse<VariantBranchPricingDto>>(okResult.Value);
        Assert.True(envelope.Success);
        Assert.True(envelope.Data!.InStock);
        Assert.Equal(224000m, envelope.Data.EstimatedOnRoadPrice);
    }
}

