using MotoSaaS.Application.Features.Inventory.Services;
using MotoSaaS.Domain.Inventory;
using Xunit;

namespace MotoSaaS.UnitTests.Inventory;

public class InventoryStateTransitionTests
{
    [Theory]
    [InlineData(InventoryStatus.Expected, InventoryStatus.Received, true)]
    [InlineData(InventoryStatus.Received, InventoryStatus.Available, true)]
    [InlineData(InventoryStatus.Available, InventoryStatus.Reserved, true)]
    [InlineData(InventoryStatus.Available, InventoryStatus.Allocated, true)]
    [InlineData(InventoryStatus.Reserved, InventoryStatus.Allocated, true)]
    [InlineData(InventoryStatus.Reserved, InventoryStatus.Available, true)]
    [InlineData(InventoryStatus.Allocated, InventoryStatus.Sold, true)]
    [InlineData(InventoryStatus.Sold, InventoryStatus.Delivered, true)]
    public void IsValidTransition_AllowedTransitions_ReturnsTrue(InventoryStatus current, InventoryStatus next, bool expected)
    {
        var result = InventoryService.IsValidTransition(current, next);
        Assert.Equal(expected, result);
    }

    [Theory]
    [InlineData(InventoryStatus.Sold, InventoryStatus.Available, false)]
    [InlineData(InventoryStatus.Delivered, InventoryStatus.Allocated, false)]
    [InlineData(InventoryStatus.Expected, InventoryStatus.Sold, false)]
    [InlineData(InventoryStatus.Expected, InventoryStatus.Delivered, false)]
    [InlineData(InventoryStatus.Delivered, InventoryStatus.Available, false)]
    public void IsValidTransition_ForbiddenTransitions_ReturnsFalse(InventoryStatus current, InventoryStatus next, bool expected)
    {
        var result = InventoryService.IsValidTransition(current, next);
        Assert.Equal(expected, result);
    }
}

