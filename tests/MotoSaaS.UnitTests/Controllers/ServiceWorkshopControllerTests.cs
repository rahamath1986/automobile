using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MotoSaaS.Api.Controllers;
using MotoSaaS.Application.Common.Models;
using MotoSaaS.Domain.Billing;
using MotoSaaS.Domain.Identity;
using MotoSaaS.Domain.Service;
using MotoSaaS.Infrastructure.Persistence;
using MotoSaaS.Infrastructure.Services;
using Xunit;

namespace MotoSaaS.UnitTests.Controllers;

public class ServiceWorkshopControllerTests
{
    private (ServiceWorkshopController controller, ApplicationDbContext db, TenantContext context) CreateController(string role = "ServiceAdvisor")
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
        var controller = new ServiceWorkshopController(db, context);

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, userId.ToString()),
            new(ClaimTypes.Role, role)
        };
        var identity = new ClaimsIdentity(claims, "TestAuth");
        var principal = new ClaimsPrincipal(identity);
        controller.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext { User = principal }
        };

        return (controller, db, context);
    }

    [Fact]
    public async Task CheckIn_ValidBookedAppointment_CreatesJobCardAndUpdatesBooking()
    {
        var (controller, db, context) = CreateController();

        var booking = new ServiceBooking
        {
            TenantId = context.TenantId!.Value,
            BranchId = context.BranchId!.Value,
            CustomerVehicleId = Guid.NewGuid(),
            ScheduledDate = DateTime.UtcNow.Date,
            TimeSlot = "10:00 - 11:00",
            ServiceType = "PERIODIC",
            Status = "BOOKED"
        };
        db.ServiceBookings.Add(booking);
        await db.SaveChangesAsync();

        var request = new ServiceWorkshopController.CheckInRequest(booking.Id, 12500, 75);
        var result = await controller.CheckIn(request, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var response = Assert.IsType<ApiResponse<object>>(ok.Value);
        Assert.True(response.Success);

        var updatedBooking = await db.ServiceBookings.FindAsync(booking.Id);
        Assert.Equal("CHECKED_IN", updatedBooking!.Status);

        var jobCard = await db.JobCards.FirstOrDefaultAsync(j => j.ServiceBookingId == booking.Id);
        Assert.NotNull(jobCard);
        Assert.StartsWith("JC-", jobCard.JobCardNumber);
        Assert.Equal(12500, jobCard.OdometerReading);
        Assert.Equal(75, jobCard.FuelLevelPercent);
        Assert.Equal(JobCardStatus.Open, jobCard.Status);
    }

    [Fact]
    public async Task CheckIn_InvalidFuelLevel_ReturnsBadRequest()
    {
        var (controller, _, _) = CreateController();

        var request = new ServiceWorkshopController.CheckInRequest(Guid.NewGuid(), 1000, 150); // > 100
        var result = await controller.CheckIn(request, CancellationToken.None);

        var badRequest = Assert.IsType<BadRequestObjectResult>(result);
        var response = Assert.IsType<ApiResponse<object>>(badRequest.Value);
        Assert.False(response.Success);
    }

    [Fact]
    public async Task Estimate_ValidItems_CalculatesTotalAndSetsStatusEstimated()
    {
        var (controller, db, context) = CreateController();

        var card = new JobCard
        {
            TenantId = context.TenantId!.Value,
            BranchId = context.BranchId!.Value,
            ServiceBookingId = Guid.NewGuid(),
            CustomerVehicleId = Guid.NewGuid(),
            Status = JobCardStatus.Open
        };
        db.JobCards.Add(card);
        await db.SaveChangesAsync();

        var items = new List<ServiceWorkshopController.EstimateItem>
        {
            new(JobCardItemType.Labour, "General Service Labour", 1m, 650m),
            new(JobCardItemType.SparePart, "Engine Oil (Yamalube 10W-40)", 1m, 450m),
            new(JobCardItemType.SparePart, "Oil Filter", 1m, 120m)
        };
        var request = new ServiceWorkshopController.EstimateRequest(items);

        var result = await controller.Estimate(card.Id, request, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var response = Assert.IsType<ApiResponse<object>>(ok.Value);
        Assert.True(response.Success);

        var updatedCard = await db.JobCards.Include(j => j.Items).FirstOrDefaultAsync(j => j.Id == card.Id);
        Assert.Equal(JobCardStatus.Estimated, updatedCard!.Status);
        Assert.Equal(1220m, updatedCard.EstimatedCost);
        Assert.Equal(3, updatedCard.Items.Count);
    }

    [Fact]
    public async Task CheckQuality_Passed_TransitionsToQualityCheckPassed()
    {
        var (controller, db, context) = CreateController();

        var card = new JobCard
        {
            TenantId = context.TenantId!.Value,
            BranchId = context.BranchId!.Value,
            ServiceBookingId = Guid.NewGuid(),
            CustomerVehicleId = Guid.NewGuid(),
            Status = JobCardStatus.QualityCheckPending
        };
        db.JobCards.Add(card);
        await db.SaveChangesAsync();

        var request = new ServiceWorkshopController.QualityRequest(true);
        var result = await controller.CheckQuality(card.Id, request, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var updatedCard = await db.JobCards.FindAsync(card.Id);
        Assert.Equal(JobCardStatus.QualityCheckPassed, updatedCard!.Status);
    }

    [Fact]
    public async Task Invoice_QualityCheckedJobCard_GeneratesServiceInvoiceAndSetsBilled()
    {
        var (controller, db, context) = CreateController(role: "Cashier");

        var vehicle = new CustomerVehicle
        {
            TenantId = context.TenantId!.Value,
            CustomerId = Guid.NewGuid(),
            RegistrationNumber = "TN58XY9999",
            ChassisNumber = "CHASSIS999",
            EngineNumber = "ENG999"
        };
        db.CustomerVehicles.Add(vehicle);

        var card = new JobCard
        {
            TenantId = context.TenantId!.Value,
            BranchId = context.BranchId!.Value,
            ServiceBookingId = Guid.NewGuid(),
            CustomerVehicleId = vehicle.Id,
            CustomerVehicle = vehicle,
            EstimatedCost = 1500m,
            Status = JobCardStatus.QualityCheckPassed
        };
        db.JobCards.Add(card);
        await db.SaveChangesAsync();

        var result = await controller.Invoice(card.Id, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var updatedCard = await db.JobCards.FindAsync(card.Id);
        Assert.Equal(JobCardStatus.Billed, updatedCard!.Status);

        var invoice = await db.Invoices.FirstOrDefaultAsync(i => i.JobCardId == card.Id);
        Assert.NotNull(invoice);
        Assert.Equal(InvoiceType.Service, invoice.InvoiceType);
        Assert.StartsWith("DEMO-SVC-", invoice.InvoiceNumber);
        Assert.Equal(1500m, invoice.TotalAmount);
    }

    [Fact]
    public async Task Close_BilledJobCard_SetsClosedAndCompletesBooking()
    {
        var (controller, db, context) = CreateController();

        var booking = new ServiceBooking
        {
            TenantId = context.TenantId!.Value,
            BranchId = context.BranchId!.Value,
            CustomerVehicleId = Guid.NewGuid(),
            Status = "IN_SERVICE"
        };
        db.ServiceBookings.Add(booking);

        var card = new JobCard
        {
            TenantId = context.TenantId!.Value,
            BranchId = context.BranchId!.Value,
            ServiceBookingId = booking.Id,
            CustomerVehicleId = booking.CustomerVehicleId,
            Status = JobCardStatus.Billed
        };
        db.JobCards.Add(card);
        await db.SaveChangesAsync();

        var result = await controller.Close(card.Id, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var updatedCard = await db.JobCards.FindAsync(card.Id);
        Assert.Equal(JobCardStatus.Closed, updatedCard!.Status);

        var updatedBooking = await db.ServiceBookings.FindAsync(booking.Id);
        Assert.Equal("COMPLETED", updatedBooking!.Status);
    }
}
