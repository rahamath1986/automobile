using Microsoft.EntityFrameworkCore;
using MotoSaaS.Application.Common.Interfaces;
using MotoSaaS.Application.Features.Inventory.Interfaces;
using MotoSaaS.Application.Features.Inventory.Models;
using MotoSaaS.Domain.Inventory;
using MotoSaaS.Domain.Sales;

namespace MotoSaaS.Application.Features.Inventory.Services;

public class InventoryService : IInventoryService
{
    private readonly IApplicationDbContext _context;

    private readonly ICurrentTenantContext? _tenantContext;

    public InventoryService(IApplicationDbContext context, ICurrentTenantContext? tenantContext = null)
    {
        _context = context;
        _tenantContext = tenantContext;
    }

    public async Task<List<InventoryItemDto>> GetBranchStockAsync(
        Guid tenantId,
        Guid branchId,
        Guid? variantId = null,
        InventoryStatus? status = null,
        CancellationToken cancellationToken = default)
    {
        var query = _context.InventoryItems
            .Include(i => i.Branch)
            .Include(i => i.Variant)
                .ThenInclude(v => v!.Model)
            .Include(i => i.Color)
            .Where(i => i.TenantId == tenantId && i.BranchId == branchId)
            .AsNoTracking();

        if (variantId.HasValue)
        {
            query = query.Where(i => i.VariantId == variantId.Value);
        }

        if (status.HasValue)
        {
            query = query.Where(i => i.Status == status.Value);
        }
        else
        {
            // Default: omit delivered vehicles from regular active stock list
            query = query.Where(i => i.Status != InventoryStatus.Delivered);
        }

        var list = await query.ToListAsync(cancellationToken);

        return list.Select(i => MapToDto(i)).ToList();
    }

    public async Task<InventoryItemDto> ReceiveStockAsync(
        Guid tenantId,
        ReceiveStockRequest request,
        Guid performedByUserId,
        CancellationToken cancellationToken = default)
    {
        var normalizedChassis = request.ChassisNumber.Trim().ToUpperInvariant();
        var normalizedEngine = request.EngineNumber.Trim().ToUpperInvariant();

        // 1. Concurrency & Duplicate Check
        var exists = await _context.InventoryItems
            .AnyAsync(i => i.TenantId == tenantId && i.ChassisNumber == normalizedChassis, cancellationToken);

        if (exists)
        {
            throw new InvalidOperationException($"Vehicle chassis number '{request.ChassisNumber}' already exists in inventory.");
        }

        // 2. Validate Branch
        var branch = await _context.Branches
            .FirstOrDefaultAsync(b => b.TenantId == tenantId && b.Id == request.BranchId, cancellationToken);

        if (branch == null)
        {
            throw new KeyNotFoundException($"Branch with ID '{request.BranchId}' not found.");
        }

        // 3. Create Inventory Record
        var item = new InventoryItem
        {
            TenantId = tenantId,
            BranchId = request.BranchId,
            VariantId = request.VariantId,
            ColorId = request.ColorId,
            ChassisNumber = normalizedChassis,
            EngineNumber = normalizedEngine,
            Status = InventoryStatus.Available, // Received and available for booking
            ManufacturingDate = request.ManufacturingDate,
            ReceivedDate = DateTime.UtcNow,
            PurchaseCost = request.PurchaseCost,
            ConcurrencyVersion = 1
        };

        _context.InventoryItems.Add(item);

        // 4. Record Audit Movement
        var movement = new InventoryMovement
        {
            TenantId = tenantId,
            InventoryItemId = item.Id,
            ToBranchId = request.BranchId,
            FromStatus = InventoryStatus.Expected,
            ToStatus = InventoryStatus.Available,
            PerformedBy = performedByUserId,
            Notes = "Stock intake reception at yard."
        };

        _context.InventoryMovements.Add(movement);
        await _context.SaveChangesAsync(cancellationToken);

        return await GetInventoryDtoAsync(tenantId, item.Id, cancellationToken);
    }

    public async Task<InventoryItemDto> AllocateVehicleAsync(
        Guid tenantId,
        Guid inventoryItemId,
        Guid bookingId,
        Guid performedByUserId,
        CancellationToken cancellationToken = default)
    {
        var item = await _context.InventoryItems
            .FirstOrDefaultAsync(i => i.TenantId == tenantId && i.Id == inventoryItemId, cancellationToken);

        if (item == null)
        {
            throw new KeyNotFoundException($"Inventory unit with ID '{inventoryItemId}' not found.");
        }

        if (_tenantContext is { IsSuperAdmin: false } && item.BranchId != _tenantContext.BranchId)
            throw new KeyNotFoundException("Inventory unit not found in your branch.");

        var booking = await _context.Bookings
            .FirstOrDefaultAsync(b => b.TenantId == tenantId && b.Id == bookingId, cancellationToken);

        if (booking == null)
        {
            throw new KeyNotFoundException($"Booking with ID '{bookingId}' not found.");
        }

        if (booking.Status == BookingStatus.Allocated && booking.AllocatedInventoryId == item.Id &&
            item.Status == InventoryStatus.Allocated && booking.BranchId == item.BranchId)
            return await GetInventoryDtoAsync(tenantId, item.Id, cancellationToken);

        if (item.Status != InventoryStatus.Available && item.Status != InventoryStatus.Reserved)
        {
            throw new InvalidOperationException(
                $"Vehicle chassis '{item.ChassisNumber}' cannot be allocated because its current status is '{item.Status}'.");
        }

        if (booking.Status != BookingStatus.Confirmed || booking.AllocatedInventoryId.HasValue)
            throw new InvalidOperationException("Only an unallocated, confirmed booking can receive a chassis.");

        if (booking.BranchId != item.BranchId || booking.VariantId != item.VariantId || booking.ColorId != item.ColorId)
            throw new InvalidOperationException("The chassis must match the booking branch, variant and color.");

        var fromStatus = item.Status;

        // Atomically update state
        item.Status = InventoryStatus.Allocated;
        item.ConcurrencyVersion++;

        booking.AllocatedInventoryId = item.Id;
        booking.Status = BookingStatus.Allocated;
        booking.ConcurrencyVersion++;

        var movement = new InventoryMovement
        {
            TenantId = tenantId,
            InventoryItemId = item.Id,
            FromBranchId = item.BranchId,
            ToBranchId = item.BranchId,
            FromStatus = fromStatus,
            ToStatus = InventoryStatus.Allocated,
            PerformedBy = performedByUserId,
            Notes = $"Vehicle allocated to booking '{booking.BookingNumber}'."
        };

        _context.InventoryMovements.Add(movement);
        await _context.SaveChangesAsync(cancellationToken);

        return await GetInventoryDtoAsync(tenantId, item.Id, cancellationToken);
    }

    public async Task<InventoryItemDto> TransferStockAsync(
        Guid tenantId,
        StockTransferRequest request,
        Guid performedByUserId,
        CancellationToken cancellationToken = default)
    {
        var item = await _context.InventoryItems
            .FirstOrDefaultAsync(i => i.TenantId == tenantId && i.Id == request.InventoryItemId, cancellationToken);

        if (item == null)
        {
            throw new KeyNotFoundException($"Inventory unit with ID '{request.InventoryItemId}' not found.");
        }

        // Only unallocated, available stock can be transferred
        if (item.Status != InventoryStatus.Available)
        {
            throw new InvalidOperationException(
                $"Cannot transfer vehicle '{item.ChassisNumber}' because it is in '{item.Status}' status. Only Available vehicles may be transferred.");
        }

        var targetBranch = await _context.Branches
            .FirstOrDefaultAsync(b => b.TenantId == tenantId && b.Id == request.TargetBranchId, cancellationToken);

        if (targetBranch == null)
        {
            throw new KeyNotFoundException($"Target branch with ID '{request.TargetBranchId}' not found under this dealership.");
        }

        var fromBranchId = item.BranchId;
        item.BranchId = request.TargetBranchId;
        item.ConcurrencyVersion++;

        var movement = new InventoryMovement
        {
            TenantId = tenantId,
            InventoryItemId = item.Id,
            FromBranchId = fromBranchId,
            ToBranchId = request.TargetBranchId,
            FromStatus = item.Status,
            ToStatus = item.Status,
            PerformedBy = performedByUserId,
            Notes = request.Notes ?? "Inter-branch stock transfer."
        };

        _context.InventoryMovements.Add(movement);
        await _context.SaveChangesAsync(cancellationToken);

        return await GetInventoryDtoAsync(tenantId, item.Id, cancellationToken);
    }

    public async Task<InventoryItemDto> UpdateStockStatusAsync(
        Guid tenantId,
        Guid inventoryItemId,
        InventoryStatus targetStatus,
        Guid performedByUserId,
        string? notes = null,
        CancellationToken cancellationToken = default)
    {
        var item = await _context.InventoryItems
            .FirstOrDefaultAsync(i => i.TenantId == tenantId && i.Id == inventoryItemId, cancellationToken);

        if (item == null)
        {
            throw new KeyNotFoundException($"Inventory unit with ID '{inventoryItemId}' not found.");
        }

        if (targetStatus == InventoryStatus.Allocated ||
            await _context.Bookings.AnyAsync(b => b.TenantId == tenantId && b.AllocatedInventoryId == item.Id &&
                b.Status == BookingStatus.Allocated, cancellationToken))
            throw new InvalidOperationException("Use the purchase workflow to change the status of allocated stock.");

        // Validate finite state machine transitions
        if (!IsValidTransition(item.Status, targetStatus))
        {
            throw new InvalidOperationException(
                $"Invalid inventory transition from '{item.Status}' to '{targetStatus}'.");
        }

        var fromStatus = item.Status;
        item.Status = targetStatus;
        item.ConcurrencyVersion++;

        var movement = new InventoryMovement
        {
            TenantId = tenantId,
            InventoryItemId = item.Id,
            FromBranchId = item.BranchId,
            ToBranchId = item.BranchId,
            FromStatus = fromStatus,
            ToStatus = targetStatus,
            PerformedBy = performedByUserId,
            Notes = notes ?? $"Status updated to {targetStatus}."
        };

        _context.InventoryMovements.Add(movement);
        await _context.SaveChangesAsync(cancellationToken);

        return await GetInventoryDtoAsync(tenantId, item.Id, cancellationToken);
    }

    public async Task<List<InventoryMovementDto>> GetChassisHistoryAsync(
        Guid tenantId,
        string chassisNumber,
        CancellationToken cancellationToken = default)
    {
        var normalized = chassisNumber.Trim().ToUpperInvariant();
        var item = await _context.InventoryItems
            .AsNoTracking()
            .FirstOrDefaultAsync(i => i.TenantId == tenantId && i.ChassisNumber == normalized, cancellationToken);

        if (item == null)
        {
            return new List<InventoryMovementDto>();
        }

        var movements = await _context.InventoryMovements
            .Include(m => m.FromBranch)
            .Include(m => m.ToBranch)
            .Include(m => m.PerformedByUser)
            .Where(m => m.TenantId == tenantId && m.InventoryItemId == item.Id)
            .OrderByDescending(m => m.CreatedAt)
            .AsNoTracking()
            .ToListAsync(cancellationToken);

        return movements.Select(m => new InventoryMovementDto
        {
            Id = m.Id,
            InventoryItemId = m.InventoryItemId,
            FromBranchName = m.FromBranch?.Name,
            ToBranchName = m.ToBranch?.Name,
            FromStatus = m.FromStatus.ToString().ToUpperInvariant(),
            ToStatus = m.ToStatus.ToString().ToUpperInvariant(),
            PerformedBy = m.PerformedByUser?.FullName ?? "System",
            CreatedAt = m.CreatedAt,
            Notes = m.Notes
        }).ToList();
    }

    public static bool IsValidTransition(InventoryStatus current, InventoryStatus next)
    {
        if (current == next) return true;

        return (current, next) switch
        {
            (InventoryStatus.Expected, InventoryStatus.Received) => true,
            (InventoryStatus.Expected, InventoryStatus.Available) => true,
            (InventoryStatus.Received, InventoryStatus.Available) => true,
            (InventoryStatus.Available, InventoryStatus.Reserved) => true,
            (InventoryStatus.Available, InventoryStatus.Allocated) => true,
            (InventoryStatus.Reserved, InventoryStatus.Allocated) => true,
            (InventoryStatus.Reserved, InventoryStatus.Available) => true, // Reservation expired
            (InventoryStatus.Allocated, InventoryStatus.Sold) => true,
            (InventoryStatus.Allocated, InventoryStatus.Available) => true, // Booking cancelled
            (InventoryStatus.Sold, InventoryStatus.Delivered) => true,
            _ => false
        };
    }

    private async Task<InventoryItemDto> GetInventoryDtoAsync(Guid tenantId, Guid itemId, CancellationToken cancellationToken)
    {
        var item = await _context.InventoryItems
            .Include(i => i.Branch)
            .Include(i => i.Variant)
                .ThenInclude(v => v!.Model)
            .Include(i => i.Color)
            .AsNoTracking()
            .FirstAsync(i => i.TenantId == tenantId && i.Id == itemId, cancellationToken);

        return MapToDto(item);
    }

    private static InventoryItemDto MapToDto(InventoryItem i)
    {
        return new InventoryItemDto
        {
            Id = i.Id,
            TenantId = i.TenantId,
            BranchId = i.BranchId,
            BranchName = i.Branch?.Name ?? string.Empty,
            BranchCode = i.Branch?.Code ?? string.Empty,
            VariantId = i.VariantId,
            ModelName = i.Variant?.Model?.Name ?? string.Empty,
            VariantName = i.Variant?.Name ?? string.Empty,
            ModelCategory = i.Variant?.Model?.Category.ToString().ToUpperInvariant() ?? string.Empty,
            ColorId = i.ColorId,
            ColorName = i.Color?.ColorName ?? string.Empty,
            HexCode = i.Color?.HexCode ?? string.Empty,
            ChassisNumber = i.ChassisNumber,
            EngineNumber = i.EngineNumber,
            Status = i.Status.ToString().ToUpperInvariant(),
            ConcurrencyVersion = i.ConcurrencyVersion,
            ReceivedDate = i.ReceivedDate,
            PurchaseCost = i.PurchaseCost
        };
    }
}

