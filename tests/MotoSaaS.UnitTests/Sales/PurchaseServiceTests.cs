using Microsoft.EntityFrameworkCore;
using MotoSaaS.Application.Features.Purchase;
using MotoSaaS.Domain.Billing;
using MotoSaaS.Domain.Catalog;
using MotoSaaS.Domain.Identity;
using MotoSaaS.Domain.Inventory;
using MotoSaaS.Domain.Sales;
using MotoSaaS.Domain.Tenancy;
using MotoSaaS.Infrastructure.Persistence;
using MotoSaaS.Infrastructure.Services;
using Xunit;

namespace MotoSaaS.UnitTests.Sales;

public class PurchaseServiceTests
{
    private (ApplicationDbContext db, TenantContext context, PurchaseService service) CreateContext()
    {
        var tenantId = Guid.NewGuid();
        var branchId = Guid.NewGuid();
        var userId = Guid.NewGuid();

        var tenantContext = new TenantContext();
        tenantContext.SetTenant(tenantId);
        tenantContext.SetBranch(branchId);
        tenantContext.SetUser(userId, "DEALER_STAFF");

        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;

        var db = new ApplicationDbContext(options, tenantContext);
        var service = new PurchaseService(db, tenantContext);

        return (db, tenantContext, service);
    }

    [Fact]
    public async Task ConfirmAsync_ValidActiveQuotation_CreatesBookingAndConvertsQuotation()
    {
        var (db, context, service) = CreateContext();

        var enquiry = new Enquiry
        {
            TenantId = context.TenantId!.Value,
            BranchId = context.BranchId!.Value,
            Status = EnquiryStatus.Quoted,
            CreatedBy = context.UserId!.Value
        };
        db.Enquiries.Add(enquiry);

        var quote = new Quotation
        {
            TenantId = context.TenantId!.Value,
            BranchId = context.BranchId!.Value,
            EnquiryId = enquiry.Id,
            CustomerId = Guid.NewGuid(),
            VariantId = Guid.NewGuid(),
            ColorId = Guid.NewGuid(),
            TotalOnRoadPrice = 185000m,
            Status = QuotationStatus.Active,
            ValidUntil = DateTime.UtcNow.AddDays(7),
            CreatedBy = context.UserId!.Value
        };
        db.Quotations.Add(quote);
        await db.SaveChangesAsync();

        var booking = await service.ConfirmAsync(quote.Id, CancellationToken.None);

        Assert.NotNull(booking);
        Assert.Equal(quote.TotalOnRoadPrice, booking.TotalPrice);
        Assert.Equal(quote.TotalOnRoadPrice, booking.BalanceAmount);
        Assert.Equal(BookingStatus.Confirmed, booking.Status);
        Assert.StartsWith("BKG-", booking.BookingNumber);

        var updatedQuote = await db.Quotations.FindAsync(quote.Id);
        Assert.Equal(QuotationStatus.Converted, updatedQuote!.Status);

        var updatedEnquiry = await db.Enquiries.FindAsync(enquiry.Id);
        Assert.Equal(EnquiryStatus.Booked, updatedEnquiry!.Status);
    }

    [Fact]
    public async Task ConfirmAsync_ExpiredQuotation_ThrowsInvalidOperationException()
    {
        var (db, context, service) = CreateContext();

        var quote = new Quotation
        {
            TenantId = context.TenantId!.Value,
            BranchId = context.BranchId!.Value,
            TotalOnRoadPrice = 150000m,
            Status = QuotationStatus.Active,
            ValidUntil = DateTime.UtcNow.AddMinutes(-5),
            CreatedBy = context.UserId!.Value
        };
        db.Quotations.Add(quote);
        await db.SaveChangesAsync();

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            service.ConfirmAsync(quote.Id, CancellationToken.None));
    }

    [Fact]
    public async Task CollectAsync_ValidPayment_ReducesBalanceAndSetsBookingAmount()
    {
        var (db, context, service) = CreateContext();

        var booking = new Booking
        {
            TenantId = context.TenantId!.Value,
            BranchId = context.BranchId!.Value,
            CustomerId = Guid.NewGuid(),
            TotalPrice = 200000m,
            BalanceAmount = 200000m,
            Status = BookingStatus.Confirmed,
            CreatedBy = context.UserId!.Value
        };
        db.Bookings.Add(booking);
        await db.SaveChangesAsync();

        var requestId = Guid.NewGuid();
        var request = new CollectPaymentRequest(booking.Id, requestId, 25000m, PaymentMode.Upi, "UPI-REF-12345");

        var payment = await service.CollectAsync(request, CancellationToken.None);

        Assert.NotNull(payment);
        Assert.Equal(25000m, payment.Amount);
        Assert.StartsWith("RCT-", payment.ReceiptNumber);
        Assert.Equal(25000m, booking.BookingAmount);
        Assert.Equal(175000m, booking.BalanceAmount);
    }

    [Fact]
    public async Task CollectAsync_IdempotentRetry_ReturnsExistingPayment()
    {
        var (db, context, service) = CreateContext();

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

        var requestId = Guid.NewGuid();
        var request = new CollectPaymentRequest(booking.Id, requestId, 10000m, PaymentMode.Cash, null);

        var first = await service.CollectAsync(request, CancellationToken.None);
        var second = await service.CollectAsync(request, CancellationToken.None);

        Assert.Equal(first.Id, second.Id);
        Assert.Equal(90000m, booking.BalanceAmount);
    }

    [Fact]
    public async Task CollectAsync_ExceedsBalance_ThrowsInvalidOperationException()
    {
        var (db, context, service) = CreateContext();

        var booking = new Booking
        {
            TenantId = context.TenantId!.Value,
            BranchId = context.BranchId!.Value,
            CustomerId = Guid.NewGuid(),
            TotalPrice = 50000m,
            BalanceAmount = 50000m,
            Status = BookingStatus.Confirmed,
            CreatedBy = context.UserId!.Value
        };
        db.Bookings.Add(booking);
        await db.SaveChangesAsync();

        var request = new CollectPaymentRequest(booking.Id, Guid.NewGuid(), 60000m, PaymentMode.Cash, null);

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            service.CollectAsync(request, CancellationToken.None));
    }

    [Fact]
    public async Task GenerateInvoiceAsync_FullyPaidAndAllocated_CreatesDemoInvoice()
    {
        var (db, context, service) = CreateContext();

        var booking = new Booking
        {
            TenantId = context.TenantId!.Value,
            BranchId = context.BranchId!.Value,
            CustomerId = Guid.NewGuid(),
            TotalPrice = 120000m,
            BalanceAmount = 0m,
            Status = BookingStatus.Allocated,
            AllocatedInventoryId = Guid.NewGuid(),
            CreatedBy = context.UserId!.Value
        };
        db.Bookings.Add(booking);
        await db.SaveChangesAsync();

        var invoice = await service.GenerateInvoiceAsync(booking.Id, CancellationToken.None);

        Assert.NotNull(invoice);
        Assert.StartsWith("DEMO-INV-", invoice.InvoiceNumber);
        Assert.True(invoice.IsDemo);
        Assert.Equal(120000m, invoice.TotalAmount);
        Assert.Equal(InvoiceStatus.Paid, invoice.Status);
    }

    [Fact]
    public async Task InspectAsync_AllocatedChassis_UpdatesInspection()
    {
        var (db, context, service) = CreateContext();

        var booking = new Booking
        {
            TenantId = context.TenantId!.Value,
            BranchId = context.BranchId!.Value,
            CustomerId = Guid.NewGuid(),
            Status = BookingStatus.Allocated,
            AllocatedInventoryId = Guid.NewGuid(),
            CreatedBy = context.UserId!.Value
        };
        db.Bookings.Add(booking);
        await db.SaveChangesAsync();

        var updated = await service.InspectAsync(booking.Id, new InspectionRequest(true, "All 25 checklist points cleared"), CancellationToken.None);

        Assert.True(updated.InspectionPassed);
        Assert.Equal("All 25 checklist points cleared", updated.InspectionNotes);
        Assert.NotNull(updated.InspectionAt);
    }

    [Fact]
    public async Task HandoverAsync_FullyQualified_DeliversChassisAndRegistersCustomerVehicle()
    {
        var (db, context, service) = CreateContext();

        var item = new InventoryItem
        {
            TenantId = context.TenantId!.Value,
            BranchId = context.BranchId!.Value,
            VariantId = Guid.NewGuid(),
            ColorId = Guid.NewGuid(),
            ChassisNumber = "MD626CHASSIS001",
            EngineNumber = "ENG998877",
            Status = InventoryStatus.Allocated
        };
        db.InventoryItems.Add(item);

        var booking = new Booking
        {
            TenantId = context.TenantId!.Value,
            BranchId = context.BranchId!.Value,
            CustomerId = Guid.NewGuid(),
            VariantId = item.VariantId,
            ColorId = item.ColorId,
            AllocatedInventoryId = item.Id,
            TotalPrice = 150000m,
            BalanceAmount = 0m,
            Status = BookingStatus.Allocated,
            InspectionPassed = true,
            CreatedBy = context.UserId!.Value
        };
        db.Bookings.Add(booking);

        var invoice = new Invoice
        {
            TenantId = context.TenantId!.Value,
            BranchId = context.BranchId!.Value,
            BookingId = booking.Id,
            CustomerId = booking.CustomerId,
            InvoiceType = InvoiceType.VehicleSale,
            Status = InvoiceStatus.Paid,
            TotalAmount = 150000m
        };
        db.Invoices.Add(invoice);
        await db.SaveChangesAsync();

        var request = new HandoverRequest("John Doe", "TN58AB1234");
        var delivered = await service.HandoverAsync(booking.Id, request, CancellationToken.None);

        Assert.Equal(BookingStatus.Delivered, delivered.Status);
        Assert.NotNull(delivered.DeliveredAt);
        Assert.Equal("John Doe", delivered.HandoverRecipient);
        Assert.NotNull(delivered.CustomerVehicleId);

        var vehicle = await db.CustomerVehicles.FindAsync(delivered.CustomerVehicleId.Value);
        Assert.NotNull(vehicle);
        Assert.Equal("TN58AB1234", vehicle!.RegistrationNumber);
        Assert.Equal("MD626CHASSIS001", vehicle.ChassisNumber);

        var updatedItem = await db.InventoryItems.FindAsync(item.Id);
        Assert.Equal(InventoryStatus.Delivered, updatedItem!.Status);
    }
}
