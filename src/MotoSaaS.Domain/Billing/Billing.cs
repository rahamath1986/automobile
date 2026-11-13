using MotoSaaS.Domain.Common;
using MotoSaaS.Domain.Identity;
using MotoSaaS.Domain.Sales;
using MotoSaaS.Domain.Tenancy;

namespace MotoSaaS.Domain.Billing;

public enum InvoiceType
{
    VehicleSale,
    Service,
    SpareParts
}

public enum InvoiceStatus
{
    Issued,
    Paid,
    Cancelled
}

public enum PaymentMode
{
    Cash,
    Upi,
    Card,
    NetBanking,
    Financier
}

public enum PaymentStatus
{
    Success,
    Pending,
    Failed,
    Refunded
}

public class Invoice : BaseEntity, ITenantScopedEntity, IBranchScopedEntity
{
    public Guid TenantId { get; set; }
    public Tenant? Tenant { get; set; }

    public Guid BranchId { get; set; }
    public Branch? Branch { get; set; }

    public string InvoiceNumber { get; set; } = string.Empty;
    public InvoiceType InvoiceType { get; set; } = InvoiceType.VehicleSale;
    public Guid? BookingId { get; set; }
    public Booking? Booking { get; set; }
    public Guid? JobCardId { get; set; }
    public Guid CustomerId { get; set; }
    public Customer? Customer { get; set; }

    public decimal Subtotal { get; set; }
    public decimal TaxAmount { get; set; }
    public decimal TotalAmount { get; set; }
    public InvoiceStatus Status { get; set; } = InvoiceStatus.Issued;
}

public class Payment : BaseEntity, ITenantScopedEntity, IBranchScopedEntity
{
    public Guid TenantId { get; set; }
    public Tenant? Tenant { get; set; }

    public Guid BranchId { get; set; }
    public Branch? Branch { get; set; }

    public string ReceiptNumber { get; set; } = string.Empty;
    public Guid? BookingId { get; set; }
    public Booking? Booking { get; set; }
    public Guid? InvoiceId { get; set; }
    public Invoice? Invoice { get; set; }

    public decimal Amount { get; set; }
    public PaymentMode PaymentMode { get; set; } = PaymentMode.Upi;
    public string? TransactionRef { get; set; }
    public Guid CollectedBy { get; set; }
    public User? CollectedByUser { get; set; }
    public DateTime PaidAt { get; set; } = DateTime.UtcNow;
    public PaymentStatus Status { get; set; } = PaymentStatus.Success;
}

