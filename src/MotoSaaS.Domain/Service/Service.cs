using MotoSaaS.Domain.Catalog;
using MotoSaaS.Domain.Common;
using MotoSaaS.Domain.Identity;
using MotoSaaS.Domain.Sales;
using MotoSaaS.Domain.Tenancy;

namespace MotoSaaS.Domain.Service;

public enum JobCardStatus
{
    Open,
    Estimated,
    Approved,
    WorkInProgress,
    QualityCheckPending,
    QualityCheckPassed,
    Billed,
    Closed
}

public enum JobCardItemType
{
    Labour,
    SparePart,
    Consumable
}

public class CustomerVehicle : BaseEntity, ITenantScopedEntity
{
    public Guid TenantId { get; set; }
    public Tenant? Tenant { get; set; }

    public Guid CustomerId { get; set; }
    public Customer? Customer { get; set; }

    public Guid VariantId { get; set; }
    public VehicleVariant? Variant { get; set; }

    public string RegistrationNumber { get; set; } = string.Empty;
    public string ChassisNumber { get; set; } = string.Empty;
    public string? EngineNumber { get; set; }
    public DateTime? DeliveryDate { get; set; }

    public ICollection<ServiceBooking> ServiceBookings { get; set; } = new List<ServiceBooking>();
}

public class ServiceBooking : BaseEntity, ITenantScopedEntity, IBranchScopedEntity
{
    public Guid TenantId { get; set; }
    public Tenant? Tenant { get; set; }

    public Guid BranchId { get; set; }
    public Branch? Branch { get; set; }

    public Guid CustomerVehicleId { get; set; }
    public CustomerVehicle? CustomerVehicle { get; set; }

    public string ServiceType { get; set; } = "PAID_GENERAL";
    public DateTime ScheduledDate { get; set; }
    public string TimeSlot { get; set; } = "09:00 - 10:00";
    public string? CustomerComplaints { get; set; }
    public string Status { get; set; } = "BOOKED";
}

public class JobCard : BaseEntity, ITenantScopedEntity, IBranchScopedEntity
{
    public Guid TenantId { get; set; }
    public Tenant? Tenant { get; set; }

    public Guid BranchId { get; set; }
    public Branch? Branch { get; set; }

    public string JobCardNumber { get; set; } = string.Empty;
    public Guid? ServiceBookingId { get; set; }
    public ServiceBooking? ServiceBooking { get; set; }

    public Guid CustomerVehicleId { get; set; }
    public CustomerVehicle? CustomerVehicle { get; set; }

    public Guid ServiceAdvisorId { get; set; }
    public User? ServiceAdvisor { get; set; }

    public Guid? TechnicianId { get; set; }
    public User? Technician { get; set; }

    public int OdometerReading { get; set; }
    public int FuelLevelPercent { get; set; }
    public decimal EstimatedCost { get; set; } = 0.00m;
    public bool CustomerApproved { get; set; } = false;
    public JobCardStatus Status { get; set; } = JobCardStatus.Open;

    public ICollection<JobCardItem> Items { get; set; } = new List<JobCardItem>();
}

public class JobCardItem : BaseEntity, ITenantScopedEntity
{
    public Guid TenantId { get; set; }
    public Guid JobCardId { get; set; }
    public JobCard? JobCard { get; set; }

    public JobCardItemType ItemType { get; set; } = JobCardItemType.Labour;
    public string Description { get; set; } = string.Empty;
    public decimal Quantity { get; set; } = 1.00m;
    public decimal UnitPrice { get; set; }
    public decimal TotalPrice { get; set; }
    public bool IsApproved { get; set; } = true;
}
