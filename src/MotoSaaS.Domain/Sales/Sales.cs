using MotoSaaS.Domain.Catalog;
using MotoSaaS.Domain.Common;
using MotoSaaS.Domain.Identity;
using MotoSaaS.Domain.Inventory;
using MotoSaaS.Domain.Tenancy;

namespace MotoSaaS.Domain.Sales;

public enum EnquiryStatus
{
    New,
    Contacted,
    TestRide,
    Quoted,
    Booked,
    Lost
}

public enum EnquirySource
{
    WalkIn,
    MobileApp,
    Web,
    Phone
}

public enum TestRideStatus
{
    Scheduled,
    Completed,
    Cancelled,
    NoShow
}

public enum QuotationStatus
{
    Active,
    Converted,
    Expired
}

public enum BookingStatus
{
    Confirmed,
    Allocated,
    Delivered,
    Cancelled
}

public class Customer : BaseEntity, ITenantScopedEntity
{
    public Guid TenantId { get; set; }
    public Tenant? Tenant { get; set; }

    public string FirstName { get; set; } = string.Empty;
    public string? LastName { get; set; }
    public string Phone { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? AddressLine1 { get; set; }
    public string? City { get; set; }
    public string? State { get; set; }
    public string? PostalCode { get; set; }

    public ICollection<Enquiry> Enquiries { get; set; } = new List<Enquiry>();
}

public class Enquiry : BaseEntity, ITenantScopedEntity, IBranchScopedEntity
{
    public Guid TenantId { get; set; }
    public Tenant? Tenant { get; set; }

    public Guid BranchId { get; set; }
    public Branch? Branch { get; set; }

    public Guid CustomerId { get; set; }
    public Customer? Customer { get; set; }

    public Guid VariantId { get; set; }
    public VehicleVariant? Variant { get; set; }

    public Guid? ColorId { get; set; }
    public VehicleColor? Color { get; set; }

    public Guid? AssignedSalesExecId { get; set; }
    public User? AssignedSalesExec { get; set; }

    public EnquiryStatus Status { get; set; } = EnquiryStatus.New;
    public EnquirySource Source { get; set; } = EnquirySource.WalkIn;
    public DateTime? ExpectedPurchaseDate { get; set; }
    public string? Notes { get; set; }
    public string? LostReason { get; set; }

    /// <summary>Timestamp of the most recent sales contact recorded against this lead.</summary>
    public DateTime? LastContactedAt { get; set; }

    /// <summary>Next scheduled follow-up. Cleared when the lead is booked or lost.</summary>
    public DateTime? NextFollowUpAt { get; set; }

    public ICollection<TestRide> TestRides { get; set; } = new List<TestRide>();
    public ICollection<Quotation> Quotations { get; set; } = new List<Quotation>();
    public ICollection<EnquiryFollowUp> FollowUps { get; set; } = new List<EnquiryFollowUp>();
}

public class TestRide : BaseEntity, ITenantScopedEntity, IBranchScopedEntity
{
    public Guid TenantId { get; set; }
    public Tenant? Tenant { get; set; }

    public Guid BranchId { get; set; }
    public Branch? Branch { get; set; }

    public Guid EnquiryId { get; set; }
    public Enquiry? Enquiry { get; set; }

    public Guid CustomerId { get; set; }
    public Customer? Customer { get; set; }

    public Guid VariantId { get; set; }
    public VehicleVariant? Variant { get; set; }

    public DateTime ScheduledAt { get; set; }
    public DateTime? CompletedAt { get; set; }
    public TestRideStatus Status { get; set; } = TestRideStatus.Scheduled;
    public string? DrivingLicenseNumber { get; set; }
    public string? FeedbackNotes { get; set; }
}

public class Quotation : BaseEntity, ITenantScopedEntity, IBranchScopedEntity
{
    public Guid TenantId { get; set; }
    public Tenant? Tenant { get; set; }

    public Guid BranchId { get; set; }
    public Branch? Branch { get; set; }

    public string QuotationNumber { get; set; } = string.Empty;
    public Guid? EnquiryId { get; set; }
    public Enquiry? Enquiry { get; set; }

    public Guid CustomerId { get; set; }
    public Customer? Customer { get; set; }

    public Guid VariantId { get; set; }
    public VehicleVariant? Variant { get; set; }

    public Guid ColorId { get; set; }
    public VehicleColor? Color { get; set; }

    public decimal ExShowroomPrice { get; set; }
    public decimal RtoCharges { get; set; }
    public decimal InsuranceCharges { get; set; }
    public decimal AccessoriesCharges { get; set; }
    public decimal HandlingCharges { get; set; }
    public decimal DiscountAmount { get; set; }
    public decimal TotalOnRoadPrice { get; set; }
    public DateTime ValidUntil { get; set; }
    public QuotationStatus Status { get; set; } = QuotationStatus.Active;
    public string? Notes { get; set; }
}

public class Booking : BaseEntity, ITenantScopedEntity, IBranchScopedEntity
{
    public Guid TenantId { get; set; }
    public Tenant? Tenant { get; set; }

    public Guid BranchId { get; set; }
    public Branch? Branch { get; set; }

    public string BookingNumber { get; set; } = string.Empty;
    public Guid? QuotationId { get; set; }
    public Quotation? Quotation { get; set; }

    public Guid CustomerId { get; set; }
    public Customer? Customer { get; set; }

    public Guid VariantId { get; set; }
    public VehicleVariant? Variant { get; set; }

    public Guid ColorId { get; set; }
    public VehicleColor? Color { get; set; }

    public Guid? AllocatedInventoryId { get; set; }
    public InventoryItem? AllocatedInventory { get; set; }

    public decimal BookingAmount { get; set; }
    public decimal TotalPrice { get; set; }
    public decimal BalanceAmount { get; set; }
    public int ConcurrencyVersion { get; set; }
    public DateTime? InspectionAt { get; set; }
    public Guid? InspectedBy { get; set; }
    public bool? InspectionPassed { get; set; }
    public string? InspectionNotes { get; set; }
    public DateTime? DeliveredAt { get; set; }
    public Guid? DeliveredBy { get; set; }
    public string? HandoverRecipient { get; set; }
    public Guid? CustomerVehicleId { get; set; }
    public Service.CustomerVehicle? CustomerVehicle { get; set; }
    public BookingStatus Status { get; set; } = BookingStatus.Confirmed;
}

