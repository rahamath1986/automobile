using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MotoSaaS.Application.Common.Interfaces;
using MotoSaaS.Application.Common.Models;
using MotoSaaS.Application.Features.Inventory.Interfaces;
using MotoSaaS.Application.Features.Inventory.Models;
using MotoSaaS.Domain.Inventory;

namespace MotoSaaS.Api.Controllers;

[Authorize(Policy = "StaffOnly")]
public class InventoryController : BaseApiController
{
    private readonly IInventoryService _inventoryService;
    private readonly ICurrentTenantContext _tenantContext;

    public InventoryController(
        IInventoryService inventoryService,
        ICurrentTenantContext tenantContext)
    {
        _inventoryService = inventoryService;
        _tenantContext = tenantContext;
    }

    /// <summary>
    /// Retrieves physical stock units for a specific branch, filtered by variant and status.
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<InventoryItemDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> GetStock(
        [FromQuery] Guid? branchId,
        [FromQuery] Guid? variantId,
        [FromQuery] InventoryStatus? status,
        CancellationToken cancellationToken)
    {
        if (!_tenantContext.TenantId.HasValue)
        {
            return BadRequest(ApiResponse<object>.Failure("Tenant context not found."));
        }

        var effectiveBranchId = branchId ?? _tenantContext.BranchId;
        if (!effectiveBranchId.HasValue)
        {
            return BadRequest(ApiResponse<object>.Failure("Branch ID is required to inspect local stock."));
        }

        var stock = await _inventoryService.GetBranchStockAsync(
            _tenantContext.TenantId.Value,
            effectiveBranchId.Value,
            variantId,
            status,
            cancellationToken);

        return Ok(ApiResponse<List<InventoryItemDto>>.Ok(stock));
    }

    /// <summary>
    /// Records vehicle stock reception at the yard with Chassis Number (VIN) and Engine Number.
    /// </summary>
    [HttpPost("receive")]
    [ProducesResponseType(typeof(ApiResponse<InventoryItemDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> ReceiveStock([FromBody] ReceiveStockRequest request, CancellationToken cancellationToken)
    {
        if (!_tenantContext.TenantId.HasValue)
        {
            return BadRequest(ApiResponse<object>.Failure("Tenant context not found."));
        }

        var userId = _tenantContext.UserId ?? Guid.Empty;

        try
        {
            var item = await _inventoryService.ReceiveStockAsync(_tenantContext.TenantId.Value, request, userId, cancellationToken);
            return StatusCode(StatusCodes.Status201Created, ApiResponse<InventoryItemDto>.Ok(item, "Vehicle received into yard inventory."));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResponse<object>.Failure(ex.Message));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<object>.Failure(ex.Message, 404));
        }
    }

    /// <summary>
    /// Atomically allocates an available vehicle chassis number to a confirmed booking.
    /// Enforces strict concurrency control to prevent double allocation.
    /// </summary>
    [HttpPost("allocate")]
    [ProducesResponseType(typeof(ApiResponse<InventoryItemDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> AllocateVehicle([FromBody] AllocateVehicleRequest request, CancellationToken cancellationToken)
    {
        if (!_tenantContext.TenantId.HasValue)
        {
            return BadRequest(ApiResponse<object>.Failure("Tenant context not found."));
        }

        var userId = _tenantContext.UserId ?? Guid.Empty;

        try
        {
            var item = await _inventoryService.AllocateVehicleAsync(
                _tenantContext.TenantId.Value,
                request.InventoryItemId,
                request.BookingId,
                userId,
                cancellationToken);

            return Ok(ApiResponse<InventoryItemDto>.Ok(item, "Vehicle chassis successfully allocated to booking."));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResponse<object>.Failure(ex.Message));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<object>.Failure(ex.Message, 404));
        }
    }

    /// <summary>
    /// Initiates inter-branch vehicle transfer. Only available, unallocated vehicles may be transferred.
    /// </summary>
    [HttpPost("transfer")]
    [ProducesResponseType(typeof(ApiResponse<InventoryItemDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> TransferStock([FromBody] StockTransferRequest request, CancellationToken cancellationToken)
    {
        if (!_tenantContext.TenantId.HasValue)
        {
            return BadRequest(ApiResponse<object>.Failure("Tenant context not found."));
        }

        var userId = _tenantContext.UserId ?? Guid.Empty;

        try
        {
            var item = await _inventoryService.TransferStockAsync(_tenantContext.TenantId.Value, request, userId, cancellationToken);
            return Ok(ApiResponse<InventoryItemDto>.Ok(item, "Vehicle transferred to destination branch."));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResponse<object>.Failure(ex.Message));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<object>.Failure(ex.Message, 404));
        }
    }

    /// <summary>
    /// Retrieves complete movement and audit history for a physical chassis number.
    /// </summary>
    [HttpGet("chassis/{chassisNumber}/history")]
    [ProducesResponseType(typeof(ApiResponse<List<InventoryMovementDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetChassisHistory(string chassisNumber, CancellationToken cancellationToken)
    {
        if (!_tenantContext.TenantId.HasValue)
        {
            return BadRequest(ApiResponse<object>.Failure("Tenant context not found."));
        }

        var history = await _inventoryService.GetChassisHistoryAsync(_tenantContext.TenantId.Value, chassisNumber, cancellationToken);
        return Ok(ApiResponse<List<InventoryMovementDto>>.Ok(history));
    }
}

