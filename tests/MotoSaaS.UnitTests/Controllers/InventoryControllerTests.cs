using Microsoft.AspNetCore.Mvc;
using MotoSaaS.Api.Controllers;
using MotoSaaS.Application.Common.Models;
using MotoSaaS.Application.Features.Inventory.Interfaces;
using MotoSaaS.Application.Features.Inventory.Models;
using MotoSaaS.Domain.Inventory;
using MotoSaaS.Infrastructure.Services;
using Xunit;

namespace MotoSaaS.UnitTests.Controllers;

public class InventoryControllerTests
{
    private class FakeInventoryService : IInventoryService
    {
        public Task<List<InventoryItemDto>> GetBranchStockAsync(
            Guid tenantId,
            Guid branchId,
            Guid? variantId = null,
            InventoryStatus? status = null,
            CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new List<InventoryItemDto>
            {
                new()
                {
                    Id = Guid.NewGuid(),
                    BranchId = branchId,
                    ChassisNumber = "MD626BF1234567890",
                    Status = "AVAILABLE"
                }
            });
        }

        public Task<InventoryItemDto> ReceiveStockAsync(Guid tenantId, ReceiveStockRequest request, Guid performedByUserId, CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new InventoryItemDto
            {
                Id = Guid.NewGuid(),
                ChassisNumber = request.ChassisNumber,
                Status = "AVAILABLE"
            });
        }

        public Task<InventoryItemDto> AllocateVehicleAsync(Guid tenantId, Guid inventoryItemId, Guid bookingId, Guid performedByUserId, CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new InventoryItemDto
            {
                Id = inventoryItemId,
                Status = "ALLOCATED"
            });
        }

        public Task<InventoryItemDto> TransferStockAsync(Guid tenantId, StockTransferRequest request, Guid performedByUserId, CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new InventoryItemDto
            {
                Id = request.InventoryItemId,
                BranchId = request.TargetBranchId,
                Status = "AVAILABLE"
            });
        }

        public Task<InventoryItemDto> UpdateStockStatusAsync(Guid tenantId, Guid inventoryItemId, InventoryStatus targetStatus, Guid performedByUserId, string? notes = null, CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new InventoryItemDto
            {
                Id = inventoryItemId,
                Status = targetStatus.ToString().ToUpperInvariant()
            });
        }

        public Task<List<InventoryMovementDto>> GetChassisHistoryAsync(Guid tenantId, string chassisNumber, CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new List<InventoryMovementDto>
            {
                new() { FromStatus = "AVAILABLE", ToStatus = "ALLOCATED" }
            });
        }
    }

    [Fact]
    public async Task GetStock_WithBranchContext_ReturnsOkWithBranchItems()
    {
        var tenantContext = new TenantContext();
        var tenantId = Guid.NewGuid();
        var branchId = Guid.NewGuid();
        tenantContext.SetTenant(tenantId);
        tenantContext.SetBranch(branchId);

        var controller = new InventoryController(new FakeInventoryService(), tenantContext);

        var result = await controller.GetStock(branchId, null, null, CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var envelope = Assert.IsType<ApiResponse<List<InventoryItemDto>>>(okResult.Value);

        Assert.True(envelope.Success);
        Assert.NotNull(envelope.Data);
        Assert.Single(envelope.Data);
        Assert.Equal("MD626BF1234567890", envelope.Data[0].ChassisNumber);
    }

    [Fact]
    public async Task AllocateVehicle_ValidRequest_ReturnsOkWithAllocatedStatus()
    {
        var tenantContext = new TenantContext();
        var tenantId = Guid.NewGuid();
        tenantContext.SetTenant(tenantId);

        var controller = new InventoryController(new FakeInventoryService(), tenantContext);
        var itemId = Guid.NewGuid();
        var bookingId = Guid.NewGuid();

        var result = await controller.AllocateVehicle(new AllocateVehicleRequest
        {
            InventoryItemId = itemId,
            BookingId = bookingId
        }, CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var envelope = Assert.IsType<ApiResponse<InventoryItemDto>>(okResult.Value);

        Assert.True(envelope.Success);
        Assert.Equal("ALLOCATED", envelope.Data!.Status);
    }
}
