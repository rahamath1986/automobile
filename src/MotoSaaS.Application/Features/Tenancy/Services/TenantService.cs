using Microsoft.EntityFrameworkCore;
using MotoSaaS.Application.Common.Interfaces;
using MotoSaaS.Application.Features.Tenancy.Interfaces;
using MotoSaaS.Application.Features.Tenancy.Models;

namespace MotoSaaS.Application.Features.Tenancy.Services;

public class TenantService : ITenantService
{
    private readonly IApplicationDbContext _context;

    public TenantService(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<TenantDto?> GetTenantByCodeAsync(string code, CancellationToken cancellationToken = default)
    {
        var normalized = code.Trim().ToUpperInvariant();
        var tenant = await _context.Tenants
            .Include(t => t.Branches.Where(b => b.IsActive))
            .AsNoTracking()
            .FirstOrDefaultAsync(t => t.Code == normalized, cancellationToken);

        if (tenant == null)
        {
            return null;
        }

        var branches = tenant.Branches.Select(b => new BranchDto
        {
            Id = b.Id,
            TenantId = b.TenantId,
            Code = b.Code,
            Name = b.Name,
            AddressLine1 = b.AddressLine1,
            City = b.City,
            State = b.State,
            PostalCode = b.PostalCode,
            Phone = b.Phone,
            Email = b.Email,
            IsHeadquarters = b.IsHeadquarters,
            IsActive = b.IsActive
        }).ToList();

        if (branches.Count == 0)
        {
            branches.Add(new BranchDto
            {
                Id = Guid.Parse("22222222-2222-2222-2222-222222222222"),
                TenantId = tenant.Id,
                Code = "KOTCHADAI",
                Name = "Alagendra Kotchadai Branch",
                AddressLine1 = "Theni Main Road, Kotchadai",
                City = "Madurai",
                State = "Tamil Nadu",
                PostalCode = "625016",
                Phone = "+91 80155 81405",
                Email = "kotchadai@alagendra.in",
                IsHeadquarters = true,
                IsActive = true
            });
        }

        return new TenantDto
        {
            Id = tenant.Id,
            Code = tenant.Code,
            LegalName = tenant.LegalName,
            TradeName = tenant.TradeName,
            TaxId = tenant.TaxId,
            LogoUrl = tenant.LogoUrl,
            PrimaryColor = string.IsNullOrWhiteSpace(tenant.PrimaryColor) || tenant.PrimaryColor == "#002C6C" ? "#DC2626" : tenant.PrimaryColor,
            SecondaryColor = string.IsNullOrWhiteSpace(tenant.SecondaryColor) || tenant.SecondaryColor == "#E60012" ? "#0F172A" : tenant.SecondaryColor,
            Status = tenant.Status.ToString().ToUpperInvariant(),
            Branches = branches
        };
    }

    public async Task<TenantDto?> GetTenantByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var tenant = await _context.Tenants
            .Include(t => t.Branches.Where(b => b.IsActive))
            .AsNoTracking()
            .FirstOrDefaultAsync(t => t.Id == id, cancellationToken);

        if (tenant == null)
        {
            return null;
        }

        var branches = tenant.Branches.Select(b => new BranchDto
        {
            Id = b.Id,
            TenantId = b.TenantId,
            Code = b.Code,
            Name = b.Name,
            AddressLine1 = b.AddressLine1,
            City = b.City,
            State = b.State,
            PostalCode = b.PostalCode,
            Phone = b.Phone,
            Email = b.Email,
            IsHeadquarters = b.IsHeadquarters,
            IsActive = b.IsActive
        }).ToList();

        if (branches.Count == 0)
        {
            branches.Add(new BranchDto
            {
                Id = Guid.Parse("22222222-2222-2222-2222-222222222222"),
                TenantId = tenant.Id,
                Code = "KOTCHADAI",
                Name = "Alagendra Kotchadai Branch",
                AddressLine1 = "Theni Main Road, Kotchadai",
                City = "Madurai",
                State = "Tamil Nadu",
                PostalCode = "625016",
                Phone = "+91 80155 81405",
                Email = "kotchadai@alagendra.in",
                IsHeadquarters = true,
                IsActive = true
            });
        }

        return new TenantDto
        {
            Id = tenant.Id,
            Code = tenant.Code,
            LegalName = tenant.LegalName,
            TradeName = tenant.TradeName,
            TaxId = tenant.TaxId,
            LogoUrl = tenant.LogoUrl,
            PrimaryColor = string.IsNullOrWhiteSpace(tenant.PrimaryColor) || tenant.PrimaryColor == "#002C6C" ? "#DC2626" : tenant.PrimaryColor,
            SecondaryColor = string.IsNullOrWhiteSpace(tenant.SecondaryColor) || tenant.SecondaryColor == "#E60012" ? "#0F172A" : tenant.SecondaryColor,
            Status = tenant.Status.ToString().ToUpperInvariant(),
            Branches = branches
        };
    }

    public async Task<List<BranchDto>> GetBranchesByTenantIdAsync(Guid tenantId, CancellationToken cancellationToken = default)
    {
        var branches = await _context.Branches
            .Where(b => b.TenantId == tenantId && b.IsActive)
            .AsNoTracking()
            .Select(b => new BranchDto
            {
                Id = b.Id,
                TenantId = b.TenantId,
                Code = b.Code,
                Name = b.Name,
                AddressLine1 = b.AddressLine1,
                City = b.City,
                State = b.State,
                PostalCode = b.PostalCode,
                Phone = b.Phone,
                Email = b.Email,
                IsHeadquarters = b.IsHeadquarters,
                IsActive = b.IsActive
            })
            .ToListAsync(cancellationToken);

        if (branches.Count == 0)
        {
            branches.Add(new BranchDto
            {
                Id = Guid.Parse("22222222-2222-2222-2222-222222222222"),
                TenantId = tenantId,
                Code = "KOTCHADAI",
                Name = "Alagendra Kotchadai Branch",
                AddressLine1 = "Theni Main Road, Kotchadai",
                City = "Madurai",
                State = "Tamil Nadu",
                PostalCode = "625016",
                Phone = "+91 80155 81405",
                Email = "kotchadai@alagendra.in",
                IsHeadquarters = true,
                IsActive = true
            });
        }

        return branches;
    }
}

