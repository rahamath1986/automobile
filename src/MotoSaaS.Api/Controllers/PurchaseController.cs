using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MotoSaaS.Application.Common.Models;
using MotoSaaS.Application.Features.Purchase;
using MotoSaaS.Domain.Billing;
using MotoSaaS.Domain.Sales;

namespace MotoSaaS.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/v1")]
public sealed class PurchaseController(PurchaseService purchase) : ControllerBase
{
    private const string Sales = "SalesExecutive,SalesManager,BranchManager,SaaSAdmin";
    private const string Billing = "Cashier,BranchManager,SaaSAdmin";

    [HttpPost("bookings")]
    [Authorize(Policy = "StaffOnly", Roles = Sales)]
    public Task<IActionResult> Confirm(ConfirmBookingRequest request, CancellationToken ct) =>
        Execute(async () => BookingDetails(await purchase.ConfirmAsync(request.QuotationId, ct)));

    [HttpGet("bookings/{id:guid}")]
    [Authorize(Policy = "StaffOnly")]
    public Task<IActionResult> GetBooking(Guid id, CancellationToken ct) =>
        Execute(async () => BookingDetails(await purchase.GetBookingAsync(id, ct)));

    [HttpPost("billing/payments")]
    [Authorize(Policy = "StaffOnly", Roles = Billing)]
    public Task<IActionResult> Collect(CollectPaymentRequest request, CancellationToken ct) =>
        Execute(async () =>
        {
            var payment = await purchase.CollectAsync(request, ct);
            return new
            {
                payment.Id, payment.BookingId, payment.ReceiptNumber, payment.Amount, payment.TransactionRef,
                Mode = payment.PaymentMode.ToString(), Status = payment.Status.ToString(), payment.PaidAt
            };
        });

    [HttpPost("billing/invoices/generate")]
    [Authorize(Policy = "StaffOnly", Roles = Billing)]
    public Task<IActionResult> GenerateInvoice(GenerateInvoiceRequest request, CancellationToken ct) =>
        Execute(async () => InvoiceDetails(await purchase.GenerateInvoiceAsync(request.BookingId, ct)));

    [HttpGet("billing/invoices/{id:guid}")]
    public Task<IActionResult> GetInvoice(Guid id, CancellationToken ct) =>
        Execute(async () => InvoiceDetails(await purchase.GetInvoiceAsync(id, ct)));

    [HttpPut("bookings/{id:guid}/inspection")]
    [Authorize(Policy = "StaffOnly", Roles = "Technician,ServiceAdvisor,BranchManager,SaaSAdmin")]
    public Task<IActionResult> Inspect(Guid id, InspectionRequest request, CancellationToken ct) =>
        Execute(async () => BookingDetails(await purchase.InspectAsync(id, request, ct)));

    [HttpPost("bookings/{id:guid}/handover")]
    [Authorize(Policy = "StaffOnly", Roles = Sales)]
    public Task<IActionResult> Handover(Guid id, HandoverRequest request, CancellationToken ct) =>
        Execute(async () => BookingDetails(await purchase.HandoverAsync(id, request, ct)));

    private async Task<IActionResult> Execute(Func<Task<object>> action)
    {
        try
        {
            return Ok(ApiResponse<object>.Ok(await action()));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<object>.Failure(ex.Message, 404));
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
        catch (ArgumentException ex)
        {
            return BadRequest(ApiResponse<object>.Failure(ex.Message, 400));
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(ApiResponse<object>.Failure(ex.Message, 409));
        }
    }

    private static object BookingDetails(Booking booking) => new
    {
        booking.Id, booking.BookingNumber, booking.BranchId, booking.QuotationId, booking.CustomerId,
        booking.VariantId, booking.ColorId, booking.AllocatedInventoryId, booking.TotalPrice,
        booking.BookingAmount, booking.BalanceAmount, Status = booking.Status.ToString(),
        booking.InspectionAt, booking.InspectedBy, booking.InspectionPassed, booking.InspectionNotes,
        booking.DeliveredAt, booking.DeliveredBy, booking.HandoverRecipient, booking.CustomerVehicleId
    };

    private static object InvoiceDetails(Invoice invoice) => new
    {
        invoice.Id, invoice.InvoiceNumber, invoice.BookingId, invoice.JobCardId, invoice.CustomerId,
        invoice.Subtotal, invoice.TaxAmount, invoice.TotalAmount, invoice.IsDemo, invoice.CreatedAt,
        Type = invoice.InvoiceType.ToString(), Status = invoice.Status.ToString()
    };
}

public record ConfirmBookingRequest(Guid QuotationId);
public record GenerateInvoiceRequest(Guid BookingId);
