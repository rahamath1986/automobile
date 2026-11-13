using MotoSaaS.Domain.Catalog;
using MotoSaaS.Domain.Common;
using MotoSaaS.Domain.Identity;
using MotoSaaS.Domain.Tenancy;

namespace MotoSaaS.Domain.Inventory;

public enum InventoryStatus
{
    Expected,
    Received,
    Available,
    Reserved,
    Allocated,
    Sold,
    Delivered
}

public class InventoryItem : BaseEntity, ITenantScopedEntity, IBranchScopedEntity
{
    public Guid TenantId { get; set; }
    public Tenant? Tenant { get; set; }

    public Guid BranchId { get; set; }
    public Branch? Branch { get; set; }

    public Guid VariantId { get; set; }
    public VehicleVariant? Variant { get; set; }

    public Guid ColorId { get; set; }
    public VehicleColor? Color { get; set; }

    public string ChassisNumber { get; set; } = string.Empty; // VIN / Frame No
    public string EngineNumber { get; set; } = string.Empty;
    public InventoryStatus Status { get; set; } = InventoryStatus.Available;

    public DateTime? ManufacturingDate { get; set; }
    public DateTime? ReceivedDate { get; set; }
    public decimal? PurchaseCost { get; set; }
    public int ConcurrencyVersion { get; set; } = 1;

    public ICollection<InventoryMovement> Movements { get; set; } = new List<InventoryMovement>();
}

public class InventoryMovement : BaseEntity, ITenantScopedEntity
{
    public Guid TenantId { get; set; }
    public Tenant? Tenant { get; set; }

    public Guid InventoryItemId { get; set; }
    public InventoryItem? InventoryItem { get; set; }

    public Guid? FromBranchId { get; set; }
    public Branch? FromBranch { get; set; }

    public Guid? ToBranchId { get; set; }
    public Branch? ToBranch { get; set; }

    public InventoryStatus FromStatus { get; set; }
    public InventoryStatus ToStatus { get; set; }

    public Guid PerformedBy { get; set; }
    public User? PerformedByUser { get; set; }

    public string? Notes { get; set; }
}

