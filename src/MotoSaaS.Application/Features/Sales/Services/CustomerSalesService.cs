using System.Text.RegularExpressions;
using Microsoft.EntityFrameworkCore;
using MotoSaaS.Application.Common.Interfaces;
using MotoSaaS.Application.Features.Sales.Interfaces;
using MotoSaaS.Application.Features.Sales.Models;
using MotoSaaS.Domain.Catalog;
using MotoSaaS.Domain.Identity;
using MotoSaaS.Domain.Sales;
using MotoSaaS.Domain.Tenancy;

namespace MotoSaaS.Application.Features.Sales.Services;

public class CustomerSalesService : ICustomerSalesService
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentTenantContext _tenantContext;

    public CustomerSalesService(
        IApplicationDbContext context,
        ICurrentTenantContext tenantContext)
    {
        _context = context;
        _tenantContext = tenantContext;
    }

    public async Task<EnquiryDto> CreateEnquiryAsync(
        CreateEnquiryRequest request,
        CancellationToken cancellationToken = default)
    {
        var tenant = await ResolveTenantAsync(cancellationToken);
        var branch = await GetActiveBranchAsync(tenant.Id, request.BranchId, cancellationToken);
        var variant = await GetActiveVariantAsync(request.VariantId, request.ColorId, cancellationToken);
        var customer = await ResolveCustomerAsync(tenant.Id, request.FirstName, request.LastName, request.Phone, request.Email, cancellationToken);
        var salesExec = await FindSalesExecutiveAsync(tenant.Id, branch.Id, cancellationToken);

        var color = ResolveColor(variant, request.ColorId);
        var enquiry = new Enquiry
        {
            TenantId = tenant.Id,
            BranchId = branch.Id,
            CustomerId = customer.Id,
            VariantId = variant.Id,
            ColorId = color?.Id,
            AssignedSalesExecId = salesExec?.Id,
            Status = EnquiryStatus.New,
            Source = EnquirySource.MobileApp,
            ExpectedPurchaseDate = request.ExpectedPurchaseDate?.ToUniversalTime(),
            Notes = string.IsNullOrWhiteSpace(request.Notes) ? null : request.Notes.Trim()
        };

        _context.Enquiries.Add(enquiry);
        await _context.SaveChangesAsync(cancellationToken);

        return new EnquiryDto
        {
            Id = enquiry.Id,
            BranchId = branch.Id,
            BranchName = branch.Name,
            VariantId = variant.Id,
            VariantName = variant.Name,
            ModelName = variant.Model?.Name ?? string.Empty,
            ColorId = color?.Id,
            ColorName = color?.ColorName,
            Status = enquiry.Status.ToString().ToUpperInvariant(),
            Source = enquiry.Source.ToString().ToUpperInvariant(),
            Notes = enquiry.Notes,
            ExpectedPurchaseDate = enquiry.ExpectedPurchaseDate,
            AssignedSalesExecutiveName = salesExec?.FullName,
            CreatedAt = enquiry.CreatedAt
        };
    }

    public async Task<List<EnquiryDto>> GetMyEnquiriesAsync(CancellationToken cancellationToken = default)
    {
        var customerId = GetAuthenticatedCustomerId();
        var tenantId = _tenantContext.TenantId;

        var enquiries = await _context.Enquiries
            .Include(e => e.Branch)
            .Include(e => e.Color)
            .Include(e => e.Variant)
                .ThenInclude(v => v!.Model)
            .Include(e => e.AssignedSalesExec)
            .AsNoTracking()
            .Where(e => e.CustomerId == customerId && (!tenantId.HasValue || e.TenantId == tenantId.Value))
            .OrderByDescending(e => e.CreatedAt)
            .ToListAsync(cancellationToken);

        return enquiries.Select(e => new EnquiryDto
        {
            Id = e.Id,
            BranchId = e.BranchId,
            BranchName = e.Branch?.Name ?? string.Empty,
            VariantId = e.VariantId,
            VariantName = e.Variant?.Name ?? string.Empty,
            ModelName = e.Variant?.Model?.Name ?? string.Empty,
            ColorId = e.ColorId,
            ColorName = e.Color?.ColorName,
            Status = e.Status.ToString().ToUpperInvariant(),
            Source = e.Source.ToString().ToUpperInvariant(),
            Notes = e.Notes,
            ExpectedPurchaseDate = e.ExpectedPurchaseDate,
            AssignedSalesExecutiveName = e.AssignedSalesExec?.FullName,
            CreatedAt = e.CreatedAt
        }).ToList();
    }

    public async Task<TestRideDto> CreateTestRideAsync(
        CreateTestRideRequest request,
        CancellationToken cancellationToken = default)
    {
        var tenant = await ResolveTenantAsync(cancellationToken);
        var branch = await GetActiveBranchAsync(tenant.Id, request.BranchId, cancellationToken);
        var variant = await GetActiveVariantAsync(request.VariantId, null, cancellationToken);
        var customer = await ResolveCustomerAsync(tenant.Id, request.FirstName, request.LastName, request.Phone, request.Email, cancellationToken);

        Enquiry enquiry;
        if (request.EnquiryId.HasValue)
        {
            enquiry = await _context.Enquiries
                .FirstOrDefaultAsync(e => e.Id == request.EnquiryId.Value && e.CustomerId == customer.Id, cancellationToken)
                ?? throw new KeyNotFoundException("The enquiry for this test ride was not found.");

            if (enquiry.VariantId != variant.Id)
            {
                throw new ArgumentException("The test ride variant does not match the selected enquiry.");
            }

            enquiry.Status = EnquiryStatus.TestRide;
        }
        else
        {
            enquiry = new Enquiry
            {
                TenantId = tenant.Id,
                BranchId = branch.Id,
                CustomerId = customer.Id,
                VariantId = variant.Id,
                AssignedSalesExecId = (await FindSalesExecutiveAsync(tenant.Id, branch.Id, cancellationToken))?.Id,
                Status = EnquiryStatus.TestRide,
                Source = EnquirySource.MobileApp,
                Notes = "Test ride requested from the customer mobile app."
            };

            _context.Enquiries.Add(enquiry);
        }

        var testRide = new TestRide
        {
            TenantId = tenant.Id,
            BranchId = branch.Id,
            CustomerId = customer.Id,
            EnquiryId = enquiry.Id,
            Enquiry = enquiry,
            VariantId = variant.Id,
            ScheduledAt = request.ScheduledAt.ToUniversalTime(),
            Status = TestRideStatus.Scheduled,
            DrivingLicenseNumber = string.IsNullOrWhiteSpace(request.DrivingLicenseNumber)
                ? null
                : request.DrivingLicenseNumber.Trim().ToUpperInvariant()
        };

        _context.TestRides.Add(testRide);
        await _context.SaveChangesAsync(cancellationToken);

        return new TestRideDto
        {
            Id = testRide.Id,
            EnquiryId = enquiry.Id,
            BranchId = branch.Id,
            BranchName = branch.Name,
            VariantId = variant.Id,
            VariantName = variant.Name,
            ModelName = variant.Model?.Name ?? string.Empty,
            ScheduledAt = testRide.ScheduledAt,
            Status = testRide.Status.ToString().ToUpperInvariant(),
            DrivingLicenseNumber = testRide.DrivingLicenseNumber,
            FeedbackNotes = testRide.FeedbackNotes,
            CreatedAt = testRide.CreatedAt
        };
    }

    public async Task<List<TestRideDto>> GetMyTestRidesAsync(CancellationToken cancellationToken = default)
    {
        var customerId = GetAuthenticatedCustomerId();
        var tenantId = _tenantContext.TenantId;

        var testRides = await _context.TestRides
            .Include(t => t.Branch)
            .Include(t => t.Variant)
                .ThenInclude(v => v!.Model)
            .AsNoTracking()
            .Where(t => t.CustomerId == customerId && (!tenantId.HasValue || t.TenantId == tenantId.Value))
            .OrderByDescending(t => t.ScheduledAt)
            .ToListAsync(cancellationToken);

        return testRides.Select(t => new TestRideDto
        {
            Id = t.Id,
            EnquiryId = t.EnquiryId,
            BranchId = t.BranchId,
            BranchName = t.Branch?.Name ?? string.Empty,
            VariantId = t.VariantId,
            VariantName = t.Variant?.Name ?? string.Empty,
            ModelName = t.Variant?.Model?.Name ?? string.Empty,
            ScheduledAt = t.ScheduledAt,
            Status = t.Status.ToString().ToUpperInvariant(),
            DrivingLicenseNumber = t.DrivingLicenseNumber,
            FeedbackNotes = t.FeedbackNotes,
            CreatedAt = t.CreatedAt
        }).ToList();
    }

    private Guid GetAuthenticatedCustomerId()
    {
        if (string.Equals(_tenantContext.UserType, "CUSTOMER", StringComparison.OrdinalIgnoreCase)
            && _tenantContext.UserId.HasValue)
        {
            return _tenantContext.UserId.Value;
        }

        throw new UnauthorizedAccessException("Please sign in with your mobile number to view this information.");
    }

    private async Task<Tenant> ResolveTenantAsync(CancellationToken cancellationToken)
    {
        Tenant? tenant = null;

        if (_tenantContext.TenantId.HasValue)
        {
            tenant = await _context.Tenants
                .AsNoTracking()
                .FirstOrDefaultAsync(t => t.Id == _tenantContext.TenantId.Value, cancellationToken);
        }

        tenant ??= await _context.Tenants
            .AsNoTracking()
            .FirstOrDefaultAsync(t => t.Code == "ALAGENDRA", cancellationToken);

        tenant ??= await _context.Tenants
            .AsNoTracking()
            .Where(t => t.Status != TenantStatus.Suspended)
            .OrderBy(t => t.Code)
            .FirstOrDefaultAsync(cancellationToken);

        if (tenant == null)
        {
            throw new InvalidOperationException("No active dealership is available to accept this request.");
        }

        if (!_tenantContext.TenantId.HasValue)
        {
            _tenantContext.SetTenant(tenant.Id);
        }

        return tenant;
    }

    private async Task<Branch> GetActiveBranchAsync(Guid tenantId, Guid branchId, CancellationToken cancellationToken)
    {
        var branch = await _context.Branches
            .AsNoTracking()
            .FirstOrDefaultAsync(b => b.Id == branchId && b.TenantId == tenantId && b.IsActive, cancellationToken);

        return branch ?? throw new ArgumentException("The selected dealership branch is not available.");
    }

    private async Task<VehicleVariant> GetActiveVariantAsync(
        Guid variantId,
        Guid? colorId,
        CancellationToken cancellationToken)
    {
        var variant = await _context.VehicleVariants
            .Include(v => v.Model)
            .Include(v => v.Colors)
            .AsNoTracking()
            .FirstOrDefaultAsync(v => v.Id == variantId && v.IsActive, cancellationToken);

        if (variant == null)
        {
            throw new ArgumentException("The selected vehicle variant is not available.");
        }

        if (colorId.HasValue && variant.Colors.All(c => c.Id != colorId.Value))
        {
            throw new ArgumentException("The selected colour is not offered for this variant.");
        }

        return variant;
    }

    private static VehicleColor? ResolveColor(VehicleVariant variant, Guid? colorId)
    {
        if (colorId.HasValue)
        {
            return variant.Colors.FirstOrDefault(c => c.Id == colorId.Value);
        }

        return variant.Colors.FirstOrDefault(c => c.IsPrimary) ?? variant.Colors.FirstOrDefault();
    }

    private async Task<Customer> ResolveCustomerAsync(
        Guid tenantId,
        string? firstName,
        string? lastName,
        string? phone,
        string? email,
        CancellationToken cancellationToken)
    {
        var authenticatedCustomerId = string.Equals(_tenantContext.UserType, "CUSTOMER", StringComparison.OrdinalIgnoreCase)
            ? _tenantContext.UserId
            : null;

        if (authenticatedCustomerId.HasValue)
        {
            var existing = await _context.Customers
                .FirstOrDefaultAsync(c => c.Id == authenticatedCustomerId.Value && c.TenantId == tenantId, cancellationToken);

            if (existing == null)
            {
                throw new UnauthorizedAccessException("Customer profile could not be resolved. Please sign in again.");
            }

            return existing;
        }

        if (string.IsNullOrWhiteSpace(phone))
        {
            throw new ArgumentException("Mobile number is required for guest enquiries and test rides.");
        }

        if (string.IsNullOrWhiteSpace(firstName))
        {
            throw new ArgumentException("First name is required for guest enquiries and test rides.");
        }

        var normalizedPhone = NormalizePhone(phone);
        var customer = await _context.Customers
            .FirstOrDefaultAsync(c => c.TenantId == tenantId && c.Phone == normalizedPhone, cancellationToken);

        if (customer == null)
        {
            customer = new Customer
            {
                TenantId = tenantId,
                FirstName = firstName.Trim(),
                LastName = string.IsNullOrWhiteSpace(lastName) ? null : lastName.Trim(),
                Phone = normalizedPhone,
                Email = string.IsNullOrWhiteSpace(email) ? null : email.Trim().ToLowerInvariant()
            };
            _context.Customers.Add(customer);
        }
        else
        {
            if (string.IsNullOrWhiteSpace(customer.FirstName) || customer.FirstName == "Customer")
            {
                customer.FirstName = firstName.Trim();
            }

            if (string.IsNullOrWhiteSpace(customer.LastName) && !string.IsNullOrWhiteSpace(lastName))
            {
                customer.LastName = lastName.Trim();
            }

            if (string.IsNullOrWhiteSpace(customer.Email) && !string.IsNullOrWhiteSpace(email))
            {
                customer.Email = email.Trim().ToLowerInvariant();
            }
        }

        await _context.SaveChangesAsync(cancellationToken);
        return customer;
    }

    private async Task<User?> FindSalesExecutiveAsync(
        Guid tenantId,
        Guid branchId,
        CancellationToken cancellationToken)
    {
        var candidates = await _context.Users
            .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
            .AsNoTracking()
            .Where(u => u.TenantId == tenantId
                        && u.IsActive
                        && u.UserType == UserType.DealerStaff
                        && u.UserRoles.Any(ur => ur.Role != null
                                                 && (ur.Role.Name == "SalesExecutive"
                                                     || ur.Role.Name == "SalesManager"
                                                     || ur.Role.Name == "BranchManager")))
            .ToListAsync(cancellationToken);

        if (candidates.Count == 0)
        {
            return null;
        }

        var candidateIds = candidates.Select(u => u.Id).ToList();
        var openLeadCounts = await _context.Enquiries
            .AsNoTracking()
            .Where(e => e.AssignedSalesExecId != null
                        && candidateIds.Contains(e.AssignedSalesExecId.Value)
                        && e.Status != EnquiryStatus.Booked
                        && e.Status != EnquiryStatus.Lost)
            .GroupBy(e => e.AssignedSalesExecId!.Value)
            .Select(g => new { UserId = g.Key, Count = g.Count() })
            .ToListAsync(cancellationToken);

        var countByUser = openLeadCounts.ToDictionary(x => x.UserId, x => x.Count);

        return candidates
            .OrderBy(SalesAssignmentRules.GetRoleRank)
            .ThenBy(u => countByUser.GetValueOrDefault(u.Id))
            .ThenBy(u => u.DefaultBranchId == branchId ? 0 : 1)
            .ThenBy(u => u.FullName)
            .FirstOrDefault();
    }

    public static string NormalizePhone(string phone)
    {
        var digits = Regex.Replace(phone, "[^0-9]", string.Empty);

        if (digits.Length == 10)
        {
            return $"+91{digits}";
        }

        if (digits.Length == 12 && digits.StartsWith("91", StringComparison.Ordinal))
        {
            return $"+{digits}";
        }

        if (digits.Length == 11 && digits.StartsWith("0", StringComparison.Ordinal))
        {
            return $"+91{digits[1..]}";
        }

        return digits.Length > 0 ? $"+{digits}" : string.Empty;
    }
}
