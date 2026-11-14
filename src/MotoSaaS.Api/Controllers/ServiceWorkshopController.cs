using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MotoSaaS.Application.Common.Interfaces;
using MotoSaaS.Application.Common.Models;
using MotoSaaS.Domain.Billing;
using MotoSaaS.Domain.Service;

namespace MotoSaaS.Api.Controllers;

[ApiController]
[Route("api/v1/service")]
[Authorize]
public sealed class ServiceWorkshopController(IApplicationDbContext db, ICurrentTenantContext scope) : ControllerBase
{
    private IQueryable<ServiceBooking> BranchBookings => db.ServiceBookings.Where(b =>
        b.TenantId == scope.TenantId && b.BranchId == scope.BranchId && !b.IsDeleted);

    private const string Advisors = "ServiceAdvisor,BranchManager";

    [Authorize(Policy = "StaffOnly", Roles = Advisors)]
    [HttpGet("bookings")]
    public async Task<IActionResult> GetBookings(CancellationToken ct) =>
        Ok(ApiResponse<object>.Ok(await BranchBookings.OrderByDescending(b => b.ScheduledDate)
            .Select(b => new { b.Id, b.CustomerVehicleId, b.ScheduledDate, b.TimeSlot, b.Status, b.ServiceType })
            .ToListAsync(ct)));

    [Authorize(Policy = "StaffOnly", Roles = Advisors)]
    [HttpPost("job-cards")]
    public async Task<IActionResult> CheckIn(CheckInRequest request, CancellationToken ct)
    {
        if (scope.UserId is not Guid advisorId || scope.BranchId is null)
            return Forbid();

        if (request.OdometerReading is null or < 0 || request.FuelLevelPercent is null or < 0 or > 100)
            return BadRequest(ApiResponse<object>.Failure("Supply a nonnegative odometer reading and a fuel level from 0 to 100."));

        var booking = await BranchBookings.FirstOrDefaultAsync(b => b.Id == request.ServiceBookingId, ct);
        if (booking is null)
            return NotFound(ApiResponse<object>.Failure("Service booking not found.", 404));

        var existing = await db.JobCards.FirstOrDefaultAsync(j => j.TenantId == booking.TenantId &&
            j.BranchId == booking.BranchId && j.ServiceBookingId == booking.Id && !j.IsDeleted, ct);
        if (existing is not null)
            return Ok(ApiResponse<object>.Ok(ToResponse(existing)));

        if (booking.Status != "BOOKED")
            return Conflict(ApiResponse<object>.Failure("Only booked appointments can be checked in.", 409));

        var card = new JobCard
        {
            TenantId = booking.TenantId,
            BranchId = booking.BranchId,
            ServiceBookingId = booking.Id,
            CustomerVehicleId = booking.CustomerVehicleId,
            ServiceAdvisorId = advisorId,
            OdometerReading = request.OdometerReading.Value,
            FuelLevelPercent = request.FuelLevelPercent.Value
        };
        card.JobCardNumber = $"JC-{card.Id:N}";
        booking.Status = "CHECKED_IN";
        db.JobCards.Add(card);
        await db.SaveChangesAsync(ct);
        return Ok(ApiResponse<object>.Ok(ToResponse(card)));
    }

    [Authorize(Policy = "StaffOnly", Roles = Advisors)]
    [HttpPut("job-cards/{id:guid}/estimate")]
    public async Task<IActionResult> Estimate(Guid id, EstimateRequest request, CancellationToken ct)
    {
        if (request.Items is not { Count: > 0 and <= 100 } || request.Items.Any(item =>
            item is null || !Enum.IsDefined(item.Type) || string.IsNullOrWhiteSpace(item.Description) ||
            item.Description.Length > 500 || item.Quantity is <= 0 or > 10000 ||
            item.UnitPrice is < 0 or > 10000000 || decimal.Round(item.UnitPrice, 2) != item.UnitPrice))
            return BadRequest(ApiResponse<object>.Failure("Supply valid labour, spare part, or consumable lines."));

        var card = await db.JobCards.Include(j => j.Items).FirstOrDefaultAsync(j => j.Id == id &&
            j.TenantId == scope.TenantId && j.BranchId == scope.BranchId && !j.IsDeleted, ct);
        if (card is null)
            return NotFound(ApiResponse<object>.Failure("Job card not found.", 404));

        if (card.Status != JobCardStatus.Open || card.CustomerApproved)
            return Conflict(ApiResponse<object>.Failure("Only open job cards can receive an estimate.", 409));

        db.JobCardItems.RemoveRange(card.Items);
        var items = request.Items.Select(item => new JobCardItem
        {
            TenantId = card.TenantId,
            JobCardId = card.Id,
            ItemType = item.Type,
            Description = item.Description.Trim(),
            Quantity = item.Quantity,
            UnitPrice = item.UnitPrice,
            TotalPrice = decimal.Round(item.Quantity * item.UnitPrice, 2, MidpointRounding.AwayFromZero)
        }).ToList();
        db.JobCardItems.AddRange(items);
        card.EstimatedCost = items.Sum(item => item.TotalPrice);
        card.Status = JobCardStatus.Estimated;
        await db.SaveChangesAsync(ct);
        return Ok(ApiResponse<object>.Ok(ToResponse(card)));
    }

    [Authorize(Policy = "StaffOnly", Roles = Advisors)]
    [HttpPut("job-cards/{id:guid}/assign")]
    public async Task<IActionResult> Assign(Guid id, AssignRequest request, CancellationToken ct)
    {
        var card = await FindCard(id, ct);
        if (card is null)
            return MissingCard();

        if (card.Status != JobCardStatus.Approved)
            return Conflict(ApiResponse<object>.Failure("The customer must approve the estimate before assignment.", 409));

        var technicianExists = await db.UserRoles.AnyAsync(r => r.UserId == request.TechnicianId &&
            r.BranchId == card.BranchId && r.Role != null && r.Role.Name == "Technician" &&
            r.User != null && r.User.TenantId == card.TenantId && !r.User.IsDeleted && r.User.IsActive, ct);
        if (!technicianExists)
            return BadRequest(ApiResponse<object>.Failure("Select a technician from this branch."));

        card.TechnicianId = request.TechnicianId;
        return await SaveStatus(card, JobCardStatus.WorkInProgress, ct);
    }

    [Authorize(Policy = "StaffOnly", Roles = "Technician")]
    [HttpPut("job-cards/{id:guid}/progress")]
    public async Task<IActionResult> FinishWork(Guid id, ProgressRequest request, CancellationToken ct)
    {
        if (request.Checklist is not { Count: > 0 and <= 50 } || request.Checklist.Any(check =>
            check is null || string.IsNullOrWhiteSpace(check.Item) || check.Item.Length > 200 || check.Passed is null ||
            check.Notes?.Length > 500 || (check.Passed == false && string.IsNullOrWhiteSpace(check.Notes))))
            return BadRequest(ApiResponse<object>.Failure("Supply inspection results and notes for failed checks."));

        var card = await FindCard(id, ct);
        if (card is null || card.TechnicianId != scope.UserId)
            return MissingCard();

        if (card.Status != JobCardStatus.WorkInProgress)
            return Conflict(ApiResponse<object>.Failure("The job card must be in progress.", 409));

        card.InspectionChecklist = JsonSerializer.Serialize(request.Checklist);
        return await SaveStatus(card, JobCardStatus.QualityCheckPending, ct);
    }

    [Authorize(Policy = "StaffOnly", Roles = Advisors)]
    [HttpPut("job-cards/{id:guid}/qc")]
    public async Task<IActionResult> CheckQuality(Guid id, QualityRequest request, CancellationToken ct)
    {
        if (request.Passed is null)
            return BadRequest(ApiResponse<object>.Failure("Provide a quality check result."));

        var card = await FindCard(id, ct);
        if (card is null)
            return MissingCard();

        if (card.Status != JobCardStatus.QualityCheckPending)
            return Conflict(ApiResponse<object>.Failure("The job card must be awaiting a quality check.", 409));

        return await SaveStatus(card, request.Passed.Value ? JobCardStatus.QualityCheckPassed : JobCardStatus.WorkInProgress, ct);
    }

    [Authorize(Policy = "StaffOnly", Roles = "Cashier,BranchManager")]
    [HttpPost("job-cards/{id:guid}/invoice")]
    public async Task<IActionResult> Invoice(Guid id, CancellationToken ct)
    {
        var card = await db.JobCards.Include(j => j.CustomerVehicle).FirstOrDefaultAsync(j => j.Id == id &&
            j.TenantId == scope.TenantId && j.BranchId == scope.BranchId && !j.IsDeleted, ct);
        if (card?.CustomerVehicle is null)
            return MissingCard();

        var existing = await db.Invoices.FirstOrDefaultAsync(i => i.JobCardId == id &&
            i.TenantId == card.TenantId && i.BranchId == card.BranchId && i.InvoiceType == InvoiceType.Service && !i.IsDeleted, ct);
        if (existing is not null)
            return Ok(ApiResponse<object>.Ok(new { existing.Id, existing.InvoiceNumber, existing.TotalAmount }));

        if (card.Status != JobCardStatus.QualityCheckPassed)
            return Conflict(ApiResponse<object>.Failure("The job card must pass its quality check before billing.", 409));

        var invoice = new Invoice
        {
            TenantId = card.TenantId,
            BranchId = card.BranchId,
            JobCardId = card.Id,
            CustomerId = card.CustomerVehicle.CustomerId,
            InvoiceType = InvoiceType.Service,
            Subtotal = card.EstimatedCost,
            TotalAmount = card.EstimatedCost,
            IsDemo = true
        };
        invoice.InvoiceNumber = $"DEMO-SVC-{invoice.Id:N}";
        db.Invoices.Add(invoice);
        card.Status = JobCardStatus.Billed;
        await db.SaveChangesAsync(ct);
        return Ok(ApiResponse<object>.Ok(new { invoice.Id, invoice.InvoiceNumber, invoice.TotalAmount }));
    }

    [Authorize(Policy = "StaffOnly", Roles = Advisors)]
    [HttpPost("job-cards/{id:guid}/close")]
    public async Task<IActionResult> Close(Guid id, CancellationToken ct)
    {
        var card = await FindCard(id, ct);
        if (card is null)
            return MissingCard();
        if (card.Status == JobCardStatus.Closed)
            return Ok(ApiResponse<object>.Ok(ToResponse(card)));
        if (card.Status != JobCardStatus.Billed)
            return Conflict(ApiResponse<object>.Failure("The job card must be billed before closing.", 409));

        var booking = await BranchBookings.FirstOrDefaultAsync(b => b.Id == card.ServiceBookingId, ct);
        if (booking is not null)
            booking.Status = "COMPLETED";
        return await SaveStatus(card, JobCardStatus.Closed, ct);
    }

    [Authorize(Policy = "CustomerOnly")]
    [HttpPut("job-cards/{id:guid}/feedback")]
    public async Task<IActionResult> Feedback(Guid id, FeedbackRequest request, CancellationToken ct)
    {
        if (request.Rating is null or < 1 or > 5 || request.Comment?.Length > 2000)
            return BadRequest(ApiResponse<object>.Failure("Supply a rating from 1 to 5 and up to 2000 characters of feedback."));

        if (scope.UserId is not Guid customerId || scope.TenantId is not Guid tenantId)
            return Forbid();

        var card = await db.JobCards.FirstOrDefaultAsync(j => j.Id == id && j.TenantId == tenantId && !j.IsDeleted &&
            j.CustomerVehicle != null && j.CustomerVehicle.CustomerId == customerId, ct);
        if (card is null)
            return MissingCard();
        if (card.Status != JobCardStatus.Closed)
            return Conflict(ApiResponse<object>.Failure("Feedback is available after the job card closes.", 409));

        card.FeedbackRating = request.Rating;
        card.FeedbackComment = request.Comment?.Trim();
        await db.SaveChangesAsync(ct);
        return Ok(ApiResponse<object>.Ok(new { card.Id, card.FeedbackRating, card.FeedbackComment }));
    }

    public sealed record ProgressRequest(List<InspectionCheck> Checklist);
    public sealed record InspectionCheck(string Item, bool? Passed, string? Notes);
    public sealed record FeedbackRequest(int? Rating, string? Comment);

    [Authorize(Policy = "StaffOnly", Roles = Advisors + ",Technician")]
    [HttpGet("job-cards")]
    public async Task<IActionResult> GetJobCards(CancellationToken ct)
    {
        var technicianOnly = User.IsInRole("Technician") &&
            !User.IsInRole("ServiceAdvisor") && !User.IsInRole("BranchManager");
        var cards = await db.JobCards.AsNoTracking().Where(j => j.TenantId == scope.TenantId &&
            j.BranchId == scope.BranchId && !j.IsDeleted &&
            (!technicianOnly || j.TechnicianId == scope.UserId))
            .OrderByDescending(j => j.CreatedAt).Take(100).ToListAsync(ct);
        return Ok(ApiResponse<object>.Ok(cards.Select(ToResponse)));
    }

    [Authorize(Policy = "StaffOnly", Roles = Advisors)]
    [HttpGet("technicians")]
    public async Task<IActionResult> GetTechnicians(CancellationToken ct) =>
        Ok(ApiResponse<object>.Ok(await db.UserRoles.Where(r => r.BranchId == scope.BranchId &&
            r.Role != null && r.Role.Name == "Technician" && r.User != null &&
            r.User.TenantId == scope.TenantId && r.User.IsActive && !r.User.IsDeleted)
            .Select(r => new { Id = r.UserId, r.User!.FullName }).ToListAsync(ct)));

    private Task<JobCard?> FindCard(Guid id, CancellationToken ct) => db.JobCards.FirstOrDefaultAsync(j =>
        j.Id == id && j.TenantId == scope.TenantId && j.BranchId == scope.BranchId && !j.IsDeleted, ct);

    private IActionResult MissingCard() => NotFound(ApiResponse<object>.Failure("Job card not found.", 404));

    private async Task<IActionResult> SaveStatus(JobCard card, JobCardStatus status, CancellationToken ct)
    {
        card.Status = status;
        await db.SaveChangesAsync(ct);
        return Ok(ApiResponse<object>.Ok(ToResponse(card)));
    }

    public sealed record AssignRequest(Guid TechnicianId);
    public sealed record QualityRequest(bool? Passed);

    private static object ToResponse(JobCard card) => new
    {
        card.Id, card.JobCardNumber, card.ServiceBookingId, card.OdometerReading,
        card.FuelLevelPercent, card.EstimatedCost,
        Checklist = card.InspectionChecklist is null ? null : JsonSerializer.Deserialize<List<InspectionCheck>>(card.InspectionChecklist),
        Status = card.Status.ToString()
    };

    public sealed record EstimateRequest(List<EstimateItem> Items);
    public sealed record EstimateItem(JobCardItemType Type, string Description, decimal Quantity, decimal UnitPrice);

    public sealed record CheckInRequest(Guid ServiceBookingId, int? OdometerReading, int? FuelLevelPercent);
}
