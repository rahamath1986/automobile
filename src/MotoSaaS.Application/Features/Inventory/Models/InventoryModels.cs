using MotoSaaS.Domain.Inventory;

namespace MotoSaaS.Application.Features.Inventory.Models;

public class InventoryItemDto
{
    public Guid Id { get; set; }
    public Guid TenantId { get; set; }
    public Guid BranchId { get; set; }
    public string BranchName { get; set; } = string.Empty;
    public string BranchCode { get; set; } = string.Empty;

    public Guid VariantId { get; set; }
    public string ModelName { get; set; } = string.Empty;
    public string VariantName { get; set; } = string.Empty;
    public string ModelCategory { get; set; } = string.Empty;

    public Guid ColorId { get; set; }
    public string ColorName { get; set; } = string.Empty;
    public string HexCode { get; set; } = string.Empty;

    public string ChassisNumber { get; set; } = string.Empty; // VIN
    public string EngineNumber { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public int ConcurrencyVersion { get; set; }
    public DateTime? ReceivedDate { get; set; }
    public decimal? PurchaseCost { get; set; }
}

public class ReceiveStockRequest
{
    public Guid BranchId { get; set; }
    public Guid VariantId { get; set; }
    public Guid ColorId { get; set; }
    public string ChassisNumber { get; set; } = string.Empty;
    public string EngineNumber { get; set; } = string.Empty;
    public decimal? PurchaseCost { get; set; }
    public DateTime? ManufacturingDate { get; set; }
}

public class AllocateVehicleRequest
{
    public Guid InventoryItemId { get; set; }
    public Guid BookingId { get; set; }
}

public class StockTransferRequest
{
    public Guid InventoryItemId { get; set; }
    public Guid TargetBranchId { get; set; }
    public string? Notes { get; set; }
}

public class UpdateStockStatusRequest
{
    public InventoryStatus TargetStatus { get; set; }
    public string? Notes { get; set; }
}

public class InventoryMovementDto
{
    public Guid Id { get; set; }
    public Guid InventoryItemId { get; set; }
    public string? FromBranchName { get; set; }
    public string? ToBranchName { get; set; }
    public string FromStatus { get; set; } = string.Empty;
    public string ToStatus { get; set; } = string.Empty;
    public string PerformedBy { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public string? Notes { get; set; }
}

