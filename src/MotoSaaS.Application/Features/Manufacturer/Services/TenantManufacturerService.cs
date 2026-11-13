using Microsoft.EntityFrameworkCore;
using MotoSaaS.Application.Common.Interfaces;
using MotoSaaS.Application.Features.Manufacturer.Interfaces;
using MotoSaaS.Application.Features.Manufacturer.Models;
using MotoSaaS.Domain.Catalog;

namespace MotoSaaS.Application.Features.Manufacturer.Services;

public class TenantManufacturerService : ITenantManufacturerService
{
    private readonly IApplicationDbContext _context;

    public TenantManufacturerService(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<List<TenantManufacturerDto>> GetTenantManufacturersAsync(Guid tenantId, CancellationToken cancellationToken = default)
    {
        return await _context.TenantManufacturers
            .Include(tm => tm.Manufacturer)
            .Where(tm => tm.TenantId == tenantId)
            .AsNoTracking()
            .Select(tm => new TenantManufacturerDto
            {
                TenantId = tm.TenantId,
                ManufacturerId = tm.ManufacturerId,
                ManufacturerCode = tm.Manufacturer != null ? tm.Manufacturer.Code : string.Empty,
                ManufacturerName = tm.Manufacturer != null ? tm.Manufacturer.Name : string.Empty,
                LogoUrl = tm.Manufacturer != null ? tm.Manufacturer.LogoUrl : null,
                DealerCodeWithOem = tm.DealerCodeWithOem,
                IsPrimary = tm.IsPrimary
            })
            .ToListAsync(cancellationToken);
    }

    public async Task<TenantManufacturerDto> AssociateManufacturerAsync(
        Guid tenantId,
        AssociateManufacturerRequest request,
        CancellationToken cancellationToken = default)
    {
        var manufacturer = await _context.Manufacturers
            .FirstOrDefaultAsync(m => m.Id == request.ManufacturerId, cancellationToken);

        if (manufacturer == null)
        {
            throw new KeyNotFoundException($"Manufacturer with ID '{request.ManufacturerId}' not found.");
        }

        var existing = await _context.TenantManufacturers
            .FirstOrDefaultAsync(tm => tm.TenantId == tenantId && tm.ManufacturerId == request.ManufacturerId, cancellationToken);

        if (existing == null)
        {
            if (request.IsPrimary)
            {
                // Unset existing primary mappings
                var otherPrimaries = await _context.TenantManufacturers
                    .Where(tm => tm.TenantId == tenantId && tm.IsPrimary)
                    .ToListAsync(cancellationToken);

                foreach (var item in otherPrimaries)
                {
                    item.IsPrimary = false;
                }
            }

            existing = new TenantManufacturer
            {
                TenantId = tenantId,
                ManufacturerId = request.ManufacturerId,
                DealerCodeWithOem = request.DealerCodeWithOem,
                IsPrimary = request.IsPrimary
            };

            _context.TenantManufacturers.Add(existing);
        }
        else
        {
            existing.DealerCodeWithOem = request.DealerCodeWithOem;
            existing.IsPrimary = request.IsPrimary;
        }

        await _context.SaveChangesAsync(cancellationToken);

        return new TenantManufacturerDto
        {
            TenantId = existing.TenantId,
            ManufacturerId = existing.ManufacturerId,
            ManufacturerCode = manufacturer.Code,
            ManufacturerName = manufacturer.Name,
            LogoUrl = manufacturer.LogoUrl,
            DealerCodeWithOem = existing.DealerCodeWithOem,
            IsPrimary = existing.IsPrimary
        };
    }

    public async Task<bool> RemoveAssociationAsync(Guid tenantId, Guid manufacturerId, CancellationToken cancellationToken = default)
    {
        var existing = await _context.TenantManufacturers
            .FirstOrDefaultAsync(tm => tm.TenantId == tenantId && tm.ManufacturerId == manufacturerId, cancellationToken);

        if (existing == null)
        {
            return false;
        }

        _context.TenantManufacturers.Remove(existing);
        await _context.SaveChangesAsync(cancellationToken);
        return true;
    }
}

