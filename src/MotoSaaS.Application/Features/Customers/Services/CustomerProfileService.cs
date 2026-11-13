using Microsoft.EntityFrameworkCore;
using MotoSaaS.Application.Common.Interfaces;
using MotoSaaS.Application.Features.Customers.Interfaces;
using MotoSaaS.Application.Features.Customers.Models;

namespace MotoSaaS.Application.Features.Customers.Services;

public class CustomerProfileService : ICustomerProfileService
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentTenantContext _tenantContext;

    public CustomerProfileService(
        IApplicationDbContext context,
        ICurrentTenantContext tenantContext)
    {
        _context = context;
        _tenantContext = tenantContext;
    }

    public async Task<CustomerProfileDto> GetProfileAsync(CancellationToken cancellationToken = default)
    {
        var customer = await GetCustomerAsync(tracking: false, cancellationToken);
        return await MapProfileAsync(customer, cancellationToken);
    }

    public async Task<CustomerProfileDto> UpdateProfileAsync(
        UpdateCustomerProfileRequest request,
        CancellationToken cancellationToken = default)
    {
        var customer = await GetCustomerAsync(tracking: true, cancellationToken);

        if (!string.IsNullOrWhiteSpace(request.FirstName))
        {
            customer.FirstName = request.FirstName.Trim();
        }

        if (request.LastName != null)
        {
            customer.LastName = string.IsNullOrWhiteSpace(request.LastName) ? null : request.LastName.Trim();
        }

        if (request.Email != null)
        {
            customer.Email = string.IsNullOrWhiteSpace(request.Email) ? null : request.Email.Trim().ToLowerInvariant();
        }

        if (request.AddressLine1 != null)
        {
            customer.AddressLine1 = string.IsNullOrWhiteSpace(request.AddressLine1) ? null : request.AddressLine1.Trim();
        }

        if (request.City != null)
        {
            customer.City = string.IsNullOrWhiteSpace(request.City) ? null : request.City.Trim();
        }

        if (request.State != null)
        {
            customer.State = string.IsNullOrWhiteSpace(request.State) ? null : request.State.Trim();
        }

        if (request.PostalCode != null)
        {
            customer.PostalCode = string.IsNullOrWhiteSpace(request.PostalCode) ? null : request.PostalCode.Trim();
        }

        await _context.SaveChangesAsync(cancellationToken);
        return await MapProfileAsync(customer, cancellationToken);
    }

    private async Task<Domain.Sales.Customer> GetCustomerAsync(bool tracking, CancellationToken cancellationToken)
    {
        if (!string.Equals(_tenantContext.UserType, "CUSTOMER", StringComparison.OrdinalIgnoreCase)
            || !_tenantContext.UserId.HasValue)
        {
            throw new UnauthorizedAccessException("Please sign in to manage your profile.");
        }

        var query = _context.Customers
            .Include(c => c.Tenant)
            .AsQueryable();

        if (!tracking)
        {
            query = query.AsNoTracking();
        }

        return await query.FirstOrDefaultAsync(c => c.Id == _tenantContext.UserId.Value, cancellationToken)
               ?? throw new KeyNotFoundException("Customer profile not found.");
    }

    private async Task<CustomerProfileDto> MapProfileAsync(Domain.Sales.Customer customer, CancellationToken cancellationToken)
    {
        var vehicleCount = await _context.CustomerVehicles
            .AsNoTracking()
            .CountAsync(v => v.CustomerId == customer.Id, cancellationToken);

        var enquiryCount = await _context.Enquiries
            .AsNoTracking()
            .CountAsync(e => e.CustomerId == customer.Id, cancellationToken);

        var activeServiceCount = await _context.ServiceBookings
            .AsNoTracking()
            .CountAsync(b => b.CustomerVehicle != null
                             && b.CustomerVehicle.CustomerId == customer.Id
                             && b.Status != "COMPLETED"
                             && b.Status != "CANCELLED", cancellationToken);

        return new CustomerProfileDto
        {
            Id = customer.Id,
            FirstName = customer.FirstName,
            LastName = customer.LastName,
            FullName = $"{customer.FirstName} {customer.LastName}".Trim(),
            Phone = customer.Phone,
            Email = customer.Email,
            AddressLine1 = customer.AddressLine1,
            City = customer.City,
            State = customer.State,
            PostalCode = customer.PostalCode,
            MemberSince = customer.CreatedAt,
            TenantId = customer.TenantId,
            TenantName = customer.Tenant?.TradeName,
            VehicleCount = vehicleCount,
            EnquiryCount = enquiryCount,
            ActiveServiceBookingCount = activeServiceCount
        };
    }
}
