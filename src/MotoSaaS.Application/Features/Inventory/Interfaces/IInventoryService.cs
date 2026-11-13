using MotoSaaS.Application.Features.Inventory.Models;
using MotoSaaS.Domain.Inventory;

namespace MotoSaaS.Application.Features.Inventory.Interfaces;

public interface IInventoryService
{
    Task<List<InventoryItemDto>> GetBranchStockAsync(
        Guid tenantId,
        Guid branchId,
        Guid? variantId = null,
        InventoryStatus? status = null,
        CancellationToken cancellationToken = default);

    Task<InventoryItemDto> ReceiveStockAsync(
        Guid tenantId,
        ReceiveStockRequest request,
        Guid performedByUserId,
        CancellationToken cancellationToken = default);

    Task<InventoryItemDto> AllocateVehicleAsync(
        Guid tenantId,
        Guid inventoryItemId,
        Guid bookingId,
        Guid performedByUserId,
        CancellationToken cancellationToken = default);

    Task<InventoryItemDto> TransferStockAsync(
        Guid tenantId,
        StockTransferRequest request,
        Guid performedByUserId,
        CancellationToken cancellationToken = default);

    Task<InventoryItemDto> UpdateStockStatusAsync(
        Guid tenantId,
        Guid inventoryItemId,
        InventoryStatus targetStatus,
        Guid performedByUserId,
        string? notes = null,
        CancellationToken cancellationToken = default);

    Task<List<InventoryMovementDto>> GetChassisHistoryAsync(
        Guid tenantId,
        string chassisNumber,
        CancellationToken cancellationToken = default);
}

