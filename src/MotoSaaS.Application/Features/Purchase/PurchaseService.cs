using Microsoft.EntityFrameworkCore;
using MotoSaaS.Application.Common.Interfaces;
using MotoSaaS.Domain.Billing;
using MotoSaaS.Domain.Inventory;
using MotoSaaS.Domain.Sales;
using MotoSaaS.Domain.Service;

namespace MotoSaaS.Application.Features.Purchase;

public record CollectPaymentRequest(Guid BookingId, Guid RequestId, decimal Amount, PaymentMode Mode, string? TransactionRef);
public record InspectionRequest(bool? Passed, string? Notes);
public record HandoverRequest(string Recipient, string RegistrationNumber);

public sealed class PurchaseService(IApplicationDbContext db, ICurrentTenantContext scope)
{
    private Guid TenantId => scope.TenantId ?? throw new UnauthorizedAccessException("Tenant context is required.");
    private Guid UserId => scope.UserId ?? throw new UnauthorizedAccessException("User context is required.");

    private IQueryable<Booking> BranchBookings => db.Bookings.Where(b =>
        b.TenantId == TenantId && (scope.IsSuperAdmin || b.BranchId == scope.BranchId));

    public async Task<Booking> GetBookingAsync(Guid id, CancellationToken ct) =>
        await BranchBookings.FirstOrDefaultAsync(b => b.Id == id, ct)
        ?? throw new KeyNotFoundException("Booking not found.");

    public async Task<Booking> ConfirmAsync(Guid quotationId, CancellationToken ct)
    {
        var quote = await db.Quotations.Include(q => q.Enquiry).FirstOrDefaultAsync(q =>
            q.Id == quotationId && q.TenantId == TenantId &&
            (scope.IsSuperAdmin || q.BranchId == scope.BranchId), ct)
            ?? throw new KeyNotFoundException("Quotation not found.");

        var existing = await BranchBookings.FirstOrDefaultAsync(b => b.QuotationId == quotationId, ct);
        if (existing is not null)
            return existing;

        if (quote.Status != QuotationStatus.Active || quote.ValidUntil <= DateTime.UtcNow || quote.TotalOnRoadPrice <= 0)
            throw new InvalidOperationException("An active, unexpired quotation with a positive total is required.");

        if (quote.Enquiry?.Status is EnquiryStatus.Lost or EnquiryStatus.Booked)
            throw new InvalidOperationException("This enquiry is closed.");

        var booking = new Booking
        {
            TenantId = quote.TenantId,
            BranchId = quote.BranchId,
            QuotationId = quote.Id,
            CustomerId = quote.CustomerId,
            VariantId = quote.VariantId,
            ColorId = quote.ColorId,
            TotalPrice = quote.TotalOnRoadPrice,
            BalanceAmount = quote.TotalOnRoadPrice,
            CreatedBy = UserId
        };
        booking.BookingNumber = $"BKG-{booking.Id:N}";
        quote.Status = QuotationStatus.Converted;
        if (quote.Enquiry is { } enquiry)
        {
            enquiry.Status = EnquiryStatus.Booked;
            enquiry.NextFollowUpAt = null;
            enquiry.LastContactedAt = DateTime.UtcNow;
        }

        db.Bookings.Add(booking);
        await db.SaveChangesAsync(ct);
        return booking;
    }

    public async Task<Payment> CollectAsync(CollectPaymentRequest request, CancellationToken ct)
    {
        if (request.RequestId == Guid.Empty || request.Amount <= 0 || decimal.Round(request.Amount, 2) != request.Amount ||
            !Enum.IsDefined(request.Mode) || request.TransactionRef?.Length > 200)
            throw new ArgumentException("A request ID, valid mode and positive amount with at most two decimal places are required.");

        var booking = await GetBookingAsync(request.BookingId, ct);
        var reference = request.TransactionRef?.Trim();
        if (request.Mode != PaymentMode.Cash && string.IsNullOrWhiteSpace(reference))
            throw new ArgumentException("A transaction reference is required for non-cash payments.");

        var existing = await db.Payments.FirstOrDefaultAsync(p =>
            p.TenantId == booking.TenantId && p.BookingId == booking.Id && p.RequestId == request.RequestId, ct);
        if (existing is not null)
        {
            if (existing.Amount != request.Amount || existing.PaymentMode != request.Mode || existing.TransactionRef != reference)
                throw new InvalidOperationException("The request ID already belongs to a different payment.");
            return existing;
        }

        if (booking.Status is not (BookingStatus.Confirmed or BookingStatus.Allocated) || request.Amount > booking.BalanceAmount)
            throw new InvalidOperationException("Payment requires an open booking and cannot exceed the outstanding balance.");

        var payment = new Payment
        {
            TenantId = booking.TenantId,
            BranchId = booking.BranchId,
            BookingId = booking.Id,
            RequestId = request.RequestId,
            Amount = request.Amount,
            PaymentMode = request.Mode,
            TransactionRef = reference,
            CollectedBy = UserId
        };
        payment.ReceiptNumber = $"RCT-{payment.Id:N}";
        if (booking.BalanceAmount == booking.TotalPrice)
            booking.BookingAmount = payment.Amount;
        booking.BalanceAmount -= payment.Amount;
        booking.ConcurrencyVersion++;
        db.Payments.Add(payment);
        await db.SaveChangesAsync(ct);
        return payment;
    }

    public async Task<Invoice> GenerateInvoiceAsync(Guid bookingId, CancellationToken ct)
    {
        var booking = await GetBookingAsync(bookingId, ct);
        var existing = await VehicleInvoices(booking).FirstOrDefaultAsync(ct);
        if (existing is not null)
            return existing;

        if (booking.Status != BookingStatus.Allocated || booking.BalanceAmount != 0)
            throw new InvalidOperationException("A fully paid booking with an allocated chassis is required.");

        var invoice = new Invoice
        {
            TenantId = booking.TenantId,
            BranchId = booking.BranchId,
            BookingId = booking.Id,
            CustomerId = booking.CustomerId,
            Subtotal = booking.TotalPrice,
            TotalAmount = booking.TotalPrice,
            Status = InvoiceStatus.Paid,
            IsDemo = true,
            CreatedBy = UserId
        };
        invoice.InvoiceNumber = $"DEMO-INV-{invoice.Id:N}";
        var payments = await db.Payments.Where(p => p.TenantId == booking.TenantId &&
            p.BookingId == booking.Id && p.InvoiceId == null && p.Status == PaymentStatus.Success).ToListAsync(ct);
        foreach (var payment in payments)
            payment.InvoiceId = invoice.Id;

        booking.ConcurrencyVersion++;
        db.Invoices.Add(invoice);
        await db.SaveChangesAsync(ct);
        return invoice;
    }

    public async Task<Invoice> GetInvoiceAsync(Guid id, CancellationToken ct)
    {
        var invoices = db.Invoices.Where(i => i.TenantId == TenantId && i.Id == id);
        if (scope.UserType == "CUSTOMER")
            invoices = invoices.Where(i => i.CustomerId == UserId);
        else
            invoices = invoices.Where(i => scope.IsSuperAdmin || i.BranchId == scope.BranchId);

        return await invoices.FirstOrDefaultAsync(ct) ?? throw new KeyNotFoundException("Invoice not found.");
    }

    public async Task<Booking> InspectAsync(Guid id, InspectionRequest request, CancellationToken ct)
    {
        if (request.Passed is null || request.Notes?.Length > 2000 ||
            (request.Passed == false && string.IsNullOrWhiteSpace(request.Notes)))
            throw new ArgumentException("Provide an inspection result and document any failures.");

        var booking = await GetBookingAsync(id, ct);
        if (booking.Status != BookingStatus.Allocated || booking.AllocatedInventoryId is null)
            throw new InvalidOperationException("Inspection requires an allocated chassis.");

        booking.InspectionAt = DateTime.UtcNow;
        booking.InspectedBy = UserId;
        booking.InspectionPassed = request.Passed;
        booking.InspectionNotes = request.Notes?.Trim();
        booking.ConcurrencyVersion++;
        await db.SaveChangesAsync(ct);
        return booking;
    }

    public async Task<Booking> HandoverAsync(Guid id, HandoverRequest request, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(request.Recipient) || request.Recipient.Length > 200 ||
            string.IsNullOrWhiteSpace(request.RegistrationNumber) || request.RegistrationNumber.Length > 32)
            throw new ArgumentException("A recipient and vehicle registration number are required.");

        var booking = await GetBookingAsync(id, ct);
        var registration = request.RegistrationNumber.Trim().ToUpperInvariant();
        var recipient = request.Recipient.Trim();
        if (booking.Status == BookingStatus.Delivered && booking.CustomerVehicleId.HasValue)
        {
            var vehicle = await db.CustomerVehicles.FindAsync([booking.CustomerVehicleId.Value], ct);
            if (vehicle?.RegistrationNumber == registration && booking.HandoverRecipient == recipient)
                return booking;
        }

        if (booking.Status != BookingStatus.Allocated || booking.BalanceAmount != 0 || booking.InspectionPassed != true ||
            !await VehicleInvoices(booking).AnyAsync(i => i.Status == InvoiceStatus.Paid, ct))
            throw new InvalidOperationException("Handover requires allocation, full payment, a paid invoice and a passed inspection.");

        var item = await db.InventoryItems.FirstOrDefaultAsync(i => i.Id == booking.AllocatedInventoryId &&
            i.TenantId == booking.TenantId && i.BranchId == booking.BranchId && i.Status == InventoryStatus.Allocated, ct)
            ?? throw new InvalidOperationException("The allocated chassis is unavailable for handover.");

        if (await db.CustomerVehicles.AnyAsync(v => v.TenantId == booking.TenantId &&
            v.RegistrationNumber == registration, ct))
            throw new InvalidOperationException("The registration number already belongs to a customer vehicle.");

        var deliveredAt = DateTime.UtcNow;
        var customerVehicle = new CustomerVehicle
        {
            TenantId = booking.TenantId,
            CustomerId = booking.CustomerId,
            VariantId = booking.VariantId,
            RegistrationNumber = registration,
            ChassisNumber = item.ChassisNumber,
            EngineNumber = item.EngineNumber,
            DeliveryDate = deliveredAt,
            CreatedBy = UserId
        };
        db.CustomerVehicles.Add(customerVehicle);
        db.InventoryMovements.Add(new InventoryMovement
        {
            TenantId = booking.TenantId,
            InventoryItemId = item.Id,
            FromBranchId = item.BranchId,
            ToBranchId = item.BranchId,
            FromStatus = item.Status,
            ToStatus = InventoryStatus.Delivered,
            PerformedBy = UserId,
            Notes = $"Handover for booking {booking.BookingNumber}."
        });
        item.Status = InventoryStatus.Delivered;
        item.ConcurrencyVersion++;
        booking.Status = BookingStatus.Delivered;
        booking.DeliveredAt = deliveredAt;
        booking.DeliveredBy = UserId;
        booking.HandoverRecipient = recipient;
        booking.CustomerVehicleId = customerVehicle.Id;
        booking.ConcurrencyVersion++;
        await db.SaveChangesAsync(ct);
        return booking;
    }

    private IQueryable<Invoice> VehicleInvoices(Booking booking) => db.Invoices.Where(i =>
        i.TenantId == booking.TenantId && i.BranchId == booking.BranchId &&
        i.BookingId == booking.Id && i.InvoiceType == InvoiceType.VehicleSale);
}
