namespace MotoSaaS.Application.Features.Service.Models;

public class CustomerVehicleDto
{
    public Guid Id { get; set; }
    public Guid VariantId { get; set; }
    public string ModelName { get; set; } = string.Empty;
    public string VariantName { get; set; } = string.Empty;
    public string RegistrationNumber { get; set; } = string.Empty;
    public string ChassisNumberMasked { get; set; } = string.Empty;
    public string? EngineNumberMasked { get; set; }
    public DateTime? DeliveryDate { get; set; }
    public string? HeroImageUrl { get; set; }
    public DateTime? LastServiceDate { get; set; }
    public string? LastServiceStatus { get; set; }
}

public class CreateServiceBookingRequest
{
    public Guid CustomerVehicleId { get; set; }
    public Guid BranchId { get; set; }
    public string ServiceType { get; set; } = "PAID_GENERAL";
    public DateTime ScheduledDate { get; set; }
    public string TimeSlot { get; set; } = "09:00 - 10:00";
    public string? CustomerComplaints { get; set; }
}

public class ServiceBookingDto
{
    public Guid Id { get; set; }
    public Guid BranchId { get; set; }
    public string BranchName { get; set; } = string.Empty;
    public Guid CustomerVehicleId { get; set; }
    public string RegistrationNumber { get; set; } = string.Empty;
    public string ModelName { get; set; } = string.Empty;
    public string VariantName { get; set; } = string.Empty;
    public string ServiceType { get; set; } = string.Empty;
    public DateTime ScheduledDate { get; set; }
    public string TimeSlot { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public Guid? JobCardId { get; set; }
    public string? JobCardStatus { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class ServiceProgressItemDto
{
    public Guid Id { get; set; }
    public string ItemType { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public decimal Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal TotalPrice { get; set; }
    public bool IsApproved { get; set; }
}

public class JobCardProgressDto
{
    public Guid Id { get; set; }
    public string JobCardNumber { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public int OdometerReading { get; set; }
    public int FuelLevelPercent { get; set; }
    public decimal EstimatedCost { get; set; }
    public bool CustomerApproved { get; set; }
    public string? TechnicianName { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public List<ServiceProgressItemDto> Items { get; set; } = new();
}

public class ServiceTimelineStepDto
{
    public string Label { get; set; } = string.Empty;
    public bool Completed { get; set; }
    public bool Current { get; set; }
}

public class ServiceTrackingDto
{
    public ServiceBookingDto Booking { get; set; } = new();
    public JobCardProgressDto? JobCard { get; set; }
    public string CurrentStage { get; set; } = string.Empty;
    public int ProgressPercent { get; set; }
    public bool AwaitingCustomerApproval { get; set; }
    public List<ServiceTimelineStepDto> Timeline { get; set; } = new();
}
