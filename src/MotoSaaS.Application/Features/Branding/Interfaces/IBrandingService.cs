using MotoSaaS.Application.Features.Branding.Models;

namespace MotoSaaS.Application.Features.Branding.Interfaces;

public interface IBrandingService
{
    Task<WhiteLabelBrandingDto?> GetBrandingAsync(Guid tenantId, CancellationToken cancellationToken = default);
    Task<WhiteLabelBrandingDto?> GetBrandingByCodeAsync(string dealerCode, CancellationToken cancellationToken = default);
    Task<WhiteLabelBrandingDto> UpdateBrandingAsync(Guid tenantId, UpdateBrandingRequest request, CancellationToken cancellationToken = default);
}

