using Microsoft.EntityFrameworkCore;
using MotoSaaS.Application.Common.Interfaces;
using MotoSaaS.Application.Features.Branding.Interfaces;
using MotoSaaS.Application.Features.Branding.Models;

namespace MotoSaaS.Application.Features.Branding.Services;

public class BrandingService : IBrandingService
{
    private readonly IApplicationDbContext _context;

    public BrandingService(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<WhiteLabelBrandingDto?> GetBrandingAsync(Guid tenantId, CancellationToken cancellationToken = default)
    {
        var tenant = await _context.Tenants
            .AsNoTracking()
            .FirstOrDefaultAsync(t => t.Id == tenantId, cancellationToken);

        if (tenant == null)
        {
            return null;
        }

        var brands = await _context.TenantManufacturers
            .Include(tm => tm.Manufacturer)
            .Where(tm => tm.TenantId == tenantId && tm.Manufacturer != null)
            .AsNoTracking()
            .Select(tm => tm.Manufacturer!.Name)
            .ToListAsync(cancellationToken);

        return new WhiteLabelBrandingDto
        {
            TenantId = tenant.Id,
            DealerCode = tenant.Code,
            TradeName = tenant.TradeName,
            LegalName = tenant.LegalName,
            TaxId = tenant.TaxId,
            LogoUrl = tenant.LogoUrl,
            PrimaryColor = tenant.PrimaryColor,
            SecondaryColor = tenant.SecondaryColor,
            AssociatedManufacturerNames = brands
        };
    }

    public async Task<WhiteLabelBrandingDto?> GetBrandingByCodeAsync(string dealerCode, CancellationToken cancellationToken = default)
    {
        var normalized = dealerCode.Trim().ToUpperInvariant();
        var tenant = await _context.Tenants
            .AsNoTracking()
            .FirstOrDefaultAsync(t => t.Code == normalized, cancellationToken);

        if (tenant == null)
        {
            return null;
        }

        return await GetBrandingAsync(tenant.Id, cancellationToken);
    }

    public async Task<WhiteLabelBrandingDto> UpdateBrandingAsync(
        Guid tenantId,
        UpdateBrandingRequest request,
        CancellationToken cancellationToken = default)
    {
        var tenant = await _context.Tenants
            .FirstOrDefaultAsync(t => t.Id == tenantId, cancellationToken);

        if (tenant == null)
        {
            throw new KeyNotFoundException($"Dealership tenant with ID '{tenantId}' not found.");
        }

        if (!string.IsNullOrWhiteSpace(request.TradeName)) tenant.TradeName = request.TradeName.Trim();
        if (!string.IsNullOrWhiteSpace(request.LegalName)) tenant.LegalName = request.LegalName.Trim();
        if (!string.IsNullOrWhiteSpace(request.TaxId)) tenant.TaxId = request.TaxId.Trim();
        if (!string.IsNullOrWhiteSpace(request.LogoUrl)) tenant.LogoUrl = request.LogoUrl.Trim();
        if (!string.IsNullOrWhiteSpace(request.PrimaryColor)) tenant.PrimaryColor = request.PrimaryColor.Trim();
        if (!string.IsNullOrWhiteSpace(request.SecondaryColor)) tenant.SecondaryColor = request.SecondaryColor.Trim();

        await _context.SaveChangesAsync(cancellationToken);

        return (await GetBrandingAsync(tenantId, cancellationToken))!;
    }
}

