using Microsoft.EntityFrameworkCore;
using MotoSaaS.Application.Common.Interfaces;
using MotoSaaS.Application.Features.Manufacturer.Interfaces;
using MotoSaaS.Application.Features.Manufacturer.Models;
using MotoSaaS.Domain.Catalog;

namespace MotoSaaS.Application.Features.Manufacturer.Services;

public class ManufacturerService : IManufacturerService
{
    private readonly IApplicationDbContext _context;

    public ManufacturerService(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<List<ManufacturerDto>> GetManufacturersAsync(CancellationToken cancellationToken = default)
    {
        var list = await _context.Manufacturers
            .Where(m => m.IsActive)
            .OrderBy(m => m.Name)
            .AsNoTracking()
            .ToListAsync(cancellationToken);

        if (list.Count == 0)
        {
            return GetDefaultOems();
        }

        return list.Select(m => new ManufacturerDto
        {
            Id = m.Id,
            Code = m.Code,
            Name = m.Name,
            LogoUrl = m.LogoUrl,
            CountryOfOrigin = m.CountryOfOrigin,
            IsActive = m.IsActive
        }).ToList();
    }

    public async Task<ManufacturerDto?> GetManufacturerByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var m = await _context.Manufacturers
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == id, cancellationToken);

        if (m == null)
        {
            return GetDefaultOems().FirstOrDefault(x => x.Id == id);
        }

        return new ManufacturerDto
        {
            Id = m.Id,
            Code = m.Code,
            Name = m.Name,
            LogoUrl = m.LogoUrl,
            CountryOfOrigin = m.CountryOfOrigin,
            IsActive = m.IsActive
        };
    }

    public async Task<ManufacturerDto?> GetManufacturerByCodeAsync(string code, CancellationToken cancellationToken = default)
    {
        var normalized = code.Trim().ToUpperInvariant();
        var m = await _context.Manufacturers
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Code == normalized, cancellationToken);

        if (m == null)
        {
            return GetDefaultOems().FirstOrDefault(x => x.Code == normalized);
        }

        return new ManufacturerDto
        {
            Id = m.Id,
            Code = m.Code,
            Name = m.Name,
            LogoUrl = m.LogoUrl,
            CountryOfOrigin = m.CountryOfOrigin,
            IsActive = m.IsActive
        };
    }

    public async Task<ManufacturerDto> CreateManufacturerAsync(CreateManufacturerRequest request, CancellationToken cancellationToken = default)
    {
        var normalized = request.Code.Trim().ToUpperInvariant();
        var existing = await _context.Manufacturers
            .FirstOrDefaultAsync(x => x.Code == normalized, cancellationToken);

        if (existing != null)
        {
            throw new InvalidOperationException($"Manufacturer with code '{request.Code}' already exists.");
        }

        var entity = new Domain.Catalog.Manufacturer
        {
            Code = normalized,
            Name = request.Name.Trim(),
            LogoUrl = request.LogoUrl,
            CountryOfOrigin = request.CountryOfOrigin,
            IsActive = true
        };

        _context.Manufacturers.Add(entity);
        await _context.SaveChangesAsync(cancellationToken);

        return new ManufacturerDto
        {
            Id = entity.Id,
            Code = entity.Code,
            Name = entity.Name,
            LogoUrl = entity.LogoUrl,
            CountryOfOrigin = entity.CountryOfOrigin,
            IsActive = entity.IsActive
        };
    }

    private static List<ManufacturerDto> GetDefaultOems()
    {
        return new List<ManufacturerDto>
        {
            new() { Id = Guid.Parse("11111111-1111-1111-1111-111111111101"), Code = "YAMAHA", Name = "Yamaha Motor Company", CountryOfOrigin = "Japan", IsActive = true },
            new() { Id = Guid.Parse("11111111-1111-1111-1111-111111111102"), Code = "HONDA", Name = "Honda Motorcycle & Scooter", CountryOfOrigin = "Japan", IsActive = true },
            new() { Id = Guid.Parse("11111111-1111-1111-1111-111111111103"), Code = "TVS", Name = "TVS Motor Company", CountryOfOrigin = "India", IsActive = true },
            new() { Id = Guid.Parse("11111111-1111-1111-1111-111111111104"), Code = "HERO", Name = "Hero MotoCorp", CountryOfOrigin = "India", IsActive = true },
            new() { Id = Guid.Parse("11111111-1111-1111-1111-111111111105"), Code = "BAJAJ", Name = "Bajaj Auto", CountryOfOrigin = "India", IsActive = true },
            new() { Id = Guid.Parse("11111111-1111-1111-1111-111111111106"), Code = "SUZUKI", Name = "Suzuki Motorcycle", CountryOfOrigin = "Japan", IsActive = true },
            new() { Id = Guid.Parse("11111111-1111-1111-1111-111111111107"), Code = "ROYAL_ENFIELD", Name = "Royal Enfield", CountryOfOrigin = "India", IsActive = true }
        };
    }
}

