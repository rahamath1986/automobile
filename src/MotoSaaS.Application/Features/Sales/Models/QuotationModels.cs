namespace MotoSaaS.Application.Features.Sales.Models;

/// <summary>
/// Inputs for the dynamic on-road quotation calculator. When <see cref="EnquiryId"/>
/// is supplied the customer, branch, variant and colour are inherited from the lead.
/// </summary>
public class QuotationDraftRequest
{
    public Guid? EnquiryId { get; set; }
    public Guid? CustomerId { get; set; }
    public Guid? BranchId { get; set; }
    public Guid? VariantId { get; set; }
    public Guid? ColorId { get; set; }

    public decimal AccessoriesCharges { get; set; }
    public decimal? HandlingCharges { get; set; }
    public decimal DiscountAmount { get; set; }
    public int ValidDays { get; set; } = 7;
}

public class CreateQuotationRequest : QuotationDraftRequest
{
    public string? Notes { get; set; }
}

public class QuotationQuery
{
    public Guid? BranchId { get; set; }
    public string? Status { get; set; }
    public Guid? EnquiryId { get; set; }
    public Guid? CustomerId { get; set; }
    public string? Search { get; set; }
    public bool IncludeExpired { get; set; } = true;
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 25;
}

public class QuotationCalculationDto
{
    public Guid BranchId { get; set; }
    public string BranchName { get; set; } = string.Empty;
    public Guid? EnquiryId { get; set; }
    public Guid CustomerId { get; set; }
    public string CustomerName { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public Guid VariantId { get; set; }
    public string VariantName { get; set; } = string.Empty;
    public string ModelName { get; set; } = string.Empty;
    public Guid ColorId { get; set; }
    public string ColorName { get; set; } = string.Empty;

    public decimal ExShowroomPrice { get; set; }
    public decimal RtoPercent { get; set; }
    public decimal RtoCharges { get; set; }
    public decimal InsurancePercent { get; set; }
    public decimal InsuranceCharges { get; set; }
    public decimal AccessoriesCharges { get; set; }
    public decimal HandlingCharges { get; set; }
    public decimal Subtotal { get; set; }
    public decimal DiscountAmount { get; set; }
    public decimal TotalOnRoadPrice { get; set; }
    public DateTime ValidUntil { get; set; }
    public List<string> Warnings { get; set; } = new();
}

public class QuotationDto : QuotationCalculationDto
{
    public Guid Id { get; set; }
    public string QuotationNumber { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public bool IsExpired { get; set; }
    public string? Notes { get; set; }
    public Guid? CreatedByUserId { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}
