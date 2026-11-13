namespace MotoSaaS.Application.Features.Customers.Models;

public class CustomerProfileDto
{
    public Guid Id { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string? LastName { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? AddressLine1 { get; set; }
    public string? City { get; set; }
    public string? State { get; set; }
    public string? PostalCode { get; set; }
    public DateTime MemberSince { get; set; }
    public Guid? TenantId { get; set; }
    public string? TenantName { get; set; }
    public int VehicleCount { get; set; }
    public int EnquiryCount { get; set; }
    public int ActiveServiceBookingCount { get; set; }
}

public class UpdateCustomerProfileRequest
{
    public string? FirstName { get; set; }
    public string? LastName { get; set; }
    public string? Email { get; set; }
    public string? AddressLine1 { get; set; }
    public string? City { get; set; }
    public string? State { get; set; }
    public string? PostalCode { get; set; }
}
