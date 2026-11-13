namespace MotoSaaS.Application.Features.Sales.Models;

public class CreateEnquiryRequest
{
    public Guid BranchId { get; set; }
    public Guid VariantId { get; set; }
    public Guid? ColorId { get; set; }
    public string? Notes { get; set; }
    public DateTime? ExpectedPurchaseDate { get; set; }

    // Guest lead capture (required when the caller is not an authenticated customer).
    public string? FirstName { get; set; }
    public string? LastName { get; set; }
    public string? Phone { get; set; }
    public string? Email { get; set; }
}

public class EnquiryDto
{
    public Guid Id { get; set; }
    public Guid BranchId { get; set; }
    public string BranchName { get; set; } = string.Empty;
    public Guid VariantId { get; set; }
    public string VariantName { get; set; } = string.Empty;
    public string ModelName { get; set; } = string.Empty;
    public Guid? ColorId { get; set; }
    public string? ColorName { get; set; }
    public string Status { get; set; } = string.Empty;
    public string Source { get; set; } = string.Empty;
    public string? Notes { get; set; }
    public DateTime? ExpectedPurchaseDate { get; set; }
    public string? AssignedSalesExecutiveName { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class CreateTestRideRequest
{
    public Guid BranchId { get; set; }
    public Guid VariantId { get; set; }
    public Guid? EnquiryId { get; set; }
    public DateTime ScheduledAt { get; set; }
    public string? DrivingLicenseNumber { get; set; }

    // Guest lead capture (required when the caller is not an authenticated customer).
    public string? FirstName { get; set; }
    public string? LastName { get; set; }
    public string? Phone { get; set; }
    public string? Email { get; set; }
}

public class TestRideDto
{
    public Guid Id { get; set; }
    public Guid? EnquiryId { get; set; }
    public Guid BranchId { get; set; }
    public string BranchName { get; set; } = string.Empty;
    public Guid VariantId { get; set; }
    public string VariantName { get; set; } = string.Empty;
    public string ModelName { get; set; } = string.Empty;
    public DateTime ScheduledAt { get; set; }
    public string Status { get; set; } = string.Empty;
    public string? DrivingLicenseNumber { get; set; }
    public string? FeedbackNotes { get; set; }
    public DateTime CreatedAt { get; set; }
}
