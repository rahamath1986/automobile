using MotoSaaS.Application.Features.Showroom3D.Models;

namespace MotoSaaS.Application.Features.Showroom3D.Interfaces;

public interface IShowroom3DService
{
    Task<ShowroomAssetDto> GetShowroomAssetAsync(
        Guid variantId,
        Guid? colorId = null,
        CancellationToken cancellationToken = default);

    Task<ShowroomAssetDto> Register3DAssetAsync(
        Register3DAssetRequest request,
        CancellationToken cancellationToken = default);

    Task<CameraPresetsManifestDto> GetCameraPresetsAsync(
        Guid variantId,
        CancellationToken cancellationToken = default);

    Task<List<ShowroomHotspotDto>> GetHotspotsAsync(
        Guid variantId,
        CancellationToken cancellationToken = default);

    bool ValidateAsset(string fileUrl, long fileSizeBytes, out string? validationError);
}

