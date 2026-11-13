namespace MotoSaaS.Application.Features.Sales.Models;

/// <summary>Common paged envelope used by CRM list endpoints.</summary>
public class PagedResult<T>
{
    public List<T> Items { get; set; } = new();
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int TotalCount { get; set; }
}

public class SalesPipelineQuery
{
    public Guid? BranchId { get; set; }
    public string? Status { get; set; }
    public Guid? AssignedToUserId { get; set; }
    public string? Search { get; set; }
    public bool? FollowUpDue { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 25;
}

public class LeadSummaryDto
{
    public Guid Id { get; set; }
    public Guid CustomerId { get; set; }
    public string CustomerName { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string? Email { get; set; }

    public Guid BranchId { get; set; }
    public string BranchName { get; set; } = string.Empty;

    public Guid VariantId { get; set; }
    public string VariantName { get; set; } = string.Empty;
    public string ModelName { get; set; } = string.Empty;
    public Guid? ColorId { get; set; }
    public string? ColorName { get; set; }

    public string Status { get; set; } = string.Empty;
    public string Source { get; set; } = string.Empty;
    public string? LostReason { get; set; }
    public DateTime? ExpectedPurchaseDate { get; set; }
    public DateTime CreatedAt { get; set; }

    public Guid? AssignedSalesExecutiveId { get; set; }
    public string? AssignedSalesExecutiveName { get; set; }

    public DateTime? LastContactedAt { get; set; }
    public DateTime? NextFollowUpAt { get; set; }
    public bool FollowUpDue { get; set; }
    public int FollowUpCount { get; set; }

    public DateTime? UpcomingTestRideAt { get; set; }
    public string? LatestQuotationNumber { get; set; }
    public decimal? LatestQuotationOnRoadPrice { get; set; }
}

public class LeadDetailDto : LeadSummaryDto
{
    public string? Notes { get; set; }
    public List<FollowUpDto> FollowUps { get; set; } = new();
    public List<TestRideSummaryDto> TestRides { get; set; } = new();
    public List<QuotationSummaryDto> Quotations { get; set; } = new();
}

public class LeadCaptureRequest
{
    public Guid? BranchId { get; set; }
    public Guid VariantId { get; set; }
    public Guid? ColorId { get; set; }

    public string FirstName { get; set; } = string.Empty;
    public string? LastName { get; set; }
    public string Phone { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? City { get; set; }

    public string Source { get; set; } = "WalkIn";
    public string? Notes { get; set; }
    public DateTime? ExpectedPurchaseDate { get; set; }
    public Guid? AssignedSalesExecutiveId { get; set; }
}

public class AssignLeadRequest
{
    public Guid SalesExecutiveId { get; set; }
}

public class UpdateLeadStatusRequest
{
    public string Status { get; set; } = string.Empty;
    public string? LostReason { get; set; }
}

public class CreateFollowUpRequest
{
    public string Channel { get; set; } = "Phone";
    public string Outcome { get; set; } = "Contacted";
    public string? Notes { get; set; }
    public DateTime? ContactedAt { get; set; }
    public DateTime? NextFollowUpAt { get; set; }
}

public class FollowUpDto
{
    public Guid Id { get; set; }
    public Guid EnquiryId { get; set; }
    public string Channel { get; set; } = string.Empty;
    public string Outcome { get; set; } = string.Empty;
    public string? Notes { get; set; }
    public DateTime ContactedAt { get; set; }
    public DateTime? NextFollowUpAt { get; set; }
    public Guid? PerformedByUserId { get; set; }
    public string? PerformedByName { get; set; }
}

public class TestRideSummaryDto
{
    public Guid Id { get; set; }
    public DateTime ScheduledAt { get; set; }
    public DateTime? CompletedAt { get; set; }
    public string Status { get; set; } = string.Empty;
    public string? DrivingLicenseNumber { get; set; }
    public string? FeedbackNotes { get; set; }
}

public class QuotationSummaryDto
{
    public Guid Id { get; set; }
    public string QuotationNumber { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public decimal TotalOnRoadPrice { get; set; }
    public DateTime ValidUntil { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class SalesExecutiveDto
{
    public Guid Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public Guid? BranchId { get; set; }
    public string? BranchName { get; set; }
    public List<string> Roles { get; set; } = new();
    public int OpenLeads { get; set; }
}

public class SalesPipelineStageDto
{
    public string Status { get; set; } = string.Empty;
    public int Count { get; set; }
}

public class BranchSalesSnapshotDto
{
    public Guid BranchId { get; set; }
    public string BranchName { get; set; } = string.Empty;
    public int OpenLeads { get; set; }
    public int DueFollowUps { get; set; }
    public int ScheduledTestRides { get; set; }
    public int ActiveQuotations { get; set; }
}

public class SalesDashboardDto
{
    public int TotalLeads { get; set; }
    public int OpenLeads { get; set; }
    public int NewLeads { get; set; }
    public int BookedLeads { get; set; }
    public int LostLeads { get; set; }
    public int DueFollowUps { get; set; }
    public int OverdueFollowUps { get; set; }
    public int TestRidesToday { get; set; }
    public int ScheduledTestRides { get; set; }
    public int CompletedTestRides { get; set; }
    public int ActiveQuotations { get; set; }
    public int QuotationsExpiringInSevenDays { get; set; }
    public decimal ConversionRate { get; set; }
    public DateTime GeneratedAt { get; set; } = DateTime.UtcNow;
    public List<SalesPipelineStageDto> Pipeline { get; set; } = new();
    public List<BranchSalesSnapshotDto> Branches { get; set; } = new();
}

public class TestRideQueueQuery
{
    public Guid? BranchId { get; set; }
    public string? Status { get; set; }
    public DateTime? From { get; set; }
    public DateTime? To { get; set; }
}

public class StaffTestRideDto
{
    public Guid Id { get; set; }
    public Guid EnquiryId { get; set; }
    public Guid CustomerId { get; set; }
    public string CustomerName { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public Guid BranchId { get; set; }
    public string BranchName { get; set; } = string.Empty;
    public Guid VariantId { get; set; }
    public string VariantName { get; set; } = string.Empty;
    public string ModelName { get; set; } = string.Empty;
    public DateTime ScheduledAt { get; set; }
    public DateTime? CompletedAt { get; set; }
    public string Status { get; set; } = string.Empty;
    public string? DrivingLicenseNumber { get; set; }
    public string? FeedbackNotes { get; set; }
    public string? AssignedSalesExecutiveName { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class CompleteTestRideRequest
{
    public bool DrivingLicenseVerified { get; set; }
    public string? DrivingLicenseNumber { get; set; }
    public string? FeedbackNotes { get; set; }
}

public class CancelTestRideRequest
{
    public string Reason { get; set; } = string.Empty;
}
