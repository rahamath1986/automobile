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

        return new TenantDto
        {
            Id = tenant.Id,
            Code = tenant.Code,
            LegalName = tenant.LegalName,
            TradeName = tenant.TradeName,
            TaxId = tenant.TaxId,
            LogoUrl = tenant.LogoUrl,
            PrimaryColor = tenant.PrimaryColor,
            SecondaryColor = tenant.SecondaryColor,
            Status = tenant.Status.ToString().ToUpperInvariant(),
            Branches = tenant.Branches.Select(b => new BranchDto
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
            }).ToList()
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

        return new TenantDto
        {
            Id = tenant.Id,
            Code = tenant.Code,
            LegalName = tenant.LegalName,
            TradeName = tenant.TradeName,
            TaxId = tenant.TaxId,
            LogoUrl = tenant.LogoUrl,
            PrimaryColor = tenant.PrimaryColor,
            SecondaryColor = tenant.SecondaryColor,
            Status = tenant.Status.ToString().ToUpperInvariant(),
            Branches = tenant.Branches.Select(b => new BranchDto
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
            }).ToList()
        };
    }

    public async Task<List<BranchDto>> GetBranchesByTenantIdAsync(Guid tenantId, CancellationToken cancellationToken = default)
    {
        return await _context.Branches
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
    }
}

