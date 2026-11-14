using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MotoSaaS.Api.Controllers;
using MotoSaaS.Application.Common.Models;
using MotoSaaS.Application.Features.Purchase;
using MotoSaaS.Domain.Billing;
using MotoSaaS.Domain.Sales;
using MotoSaaS.Infrastructure.Persistence;
using MotoSaaS.Infrastructure.Services;
using Xunit;

namespace MotoSaaS.UnitTests.Controllers;

public class PurchaseControllerTests
{
    private (PurchaseController controller, ApplicationDbContext db, TenantContext context) CreateController()
    {
        var tenantId = Guid.NewGuid();
        var branchId = Guid.NewGuid();
        var userId = Guid.NewGuid();

        var context = new TenantContext();
        context.SetTenant(tenantId);
        context.SetBranch(branchId);
        context.SetUser(userId, "DEALER_STAFF");

        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;

        var db = new ApplicationDbContext(options, context);
        var service = new PurchaseService(db, context);
        var controller = new PurchaseController(service);

        return (controller, db, context);
    }

    [Fact]
    public async Task GetBooking_ExistingBooking_ReturnsOk()
    {
        var (controller, db, context) = CreateController();

        var booking = new Booking
        {
            TenantId = context.TenantId!.Value,
            BranchId = context.BranchId!.Value,
            CustomerId = Guid.NewGuid(),
            TotalPrice = 100000m,
            BalanceAmount = 100000m,
            Status = BookingStatus.Confirmed,
            CreatedBy = context.UserId!.Value
        };
        db.Bookings.Add(booking);
        await db.SaveChangesAsync();

        var result = await controller.GetBooking(booking.Id, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var response = Assert.IsType<ApiResponse<object>>(ok.Value);
        Assert.True(response.Success);
    }

    [Fact]
    public async Task GetBooking_NonExistentBooking_ReturnsNotFound()
    {
        var (controller, _, _) = CreateController();

        var result = await controller.GetBooking(Guid.NewGuid(), CancellationToken.None);

        var notFound = Assert.IsType<NotFoundObjectResult>(result);
        var response = Assert.IsType<ApiResponse<object>>(notFound.Value);
        Assert.False(response.Success);
        Assert.Equal(404, response.StatusCode);
    }

    [Fact]
    public async Task CollectPayment_ValidRequest_ReturnsOkWithPaymentDetails()
    {
        var (controller, db, context) = CreateController();

        var booking = new Booking
        {
            TenantId = context.TenantId!.Value,
            BranchId = context.BranchId!.Value,
            CustomerId = Guid.NewGuid(),
            TotalPrice = 150000m,
            BalanceAmount = 150000m,
            Status = BookingStatus.Confirmed,
            CreatedBy = context.UserId!.Value
        };
        db.Bookings.Add(booking);
        await db.SaveChangesAsync();

        var request = new CollectPaymentRequest(booking.Id, Guid.NewGuid(), 15000m, PaymentMode.Cash, null);
        var result = await controller.Collect(request, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var response = Assert.IsType<ApiResponse<object>>(ok.Value);
        Assert.True(response.Success);
    }
}
