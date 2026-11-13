using MotoSaaS.Application.Features.Catalog.Models;

namespace MotoSaaS.Application.Features.Showroom3D.Models;

public enum ViewerTier
{
    Tier1_Interactive3D,
    Tier2_Turntable360,
    Tier3_StaticGallery
}

public class CameraVector3Dto
{
    public double X { get; set; }
    public double Y { get; set; }
    public double Z { get; set; }

    public CameraVector3Dto() { }
    public CameraVector3Dto(double x, double y, double z)
    {
        X = x; Y = y; Z = z;
    }
}

public class CameraPresetDto
{
    public CameraVector3Dto Position { get; set; } = new();
    public CameraVector3Dto Target { get; set; } = new(0, 0.6, 0);
    public double Fov { get; set; } = 45.0;
    public double MinPolarAngleDeg { get; set; } = 5.0;  // Prevent ground clipping
    public double MaxPolarAngleDeg { get; set; } = 75.0; // Prevent disorienting top-down inversion
    public double MinDistanceMeters { get; set; } = 1.5; // Close-up limit
    public double MaxDistanceMeters { get; set; } = 6.0; // Far-out orbit limit
}

public class CameraPresetsManifestDto
{
    public CameraPresetDto HeroView { get; set; } = new()
    {
        Position = new CameraVector3Dto(2.4, 1.2, 2.4),
        Target = new CameraVector3Dto(0, 0.6, 0),
        Fov = 45.0
    };

    public CameraPresetDto ProfileView { get; set; } = new()
    {
        Position = new CameraVector3Dto(3.2, 0.8, 0.0),
        Target = new CameraVector3Dto(0, 0.6, 0),
        Fov = 40.0
    };

    public CameraPresetDto CockpitView { get; set; } = new()
    {
        Position = new CameraVector3Dto(0.0, 1.3, -0.4),
        Target = new CameraVector3Dto(0, 1.0, 0.2),
        Fov = 50.0
    };

    public CameraPresetDto RearView { get; set; } = new()
    {
        Position = new CameraVector3Dto(-2.2, 1.0, -2.0),
        Target = new CameraVector3Dto(0, 0.6, 0),
        Fov = 45.0
    };

    public CameraPresetDto TopView { get; set; } = new()
    {
        Position = new CameraVector3Dto(0.0, 3.5, 0.1),
        Target = new CameraVector3Dto(0, 0.6, 0),
        Fov = 45.0
    };
}

public class ShowroomHotspotDto
{
    public string Id { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Category { get; set; } = "Mechanical"; // Mechanical, Electrical, Ergonomics, Safety
    public CameraVector3Dto Position { get; set; } = new();
    public string? SpecMetric { get; set; }
}

public class ShowroomAssetDto
{
    public Guid VariantId { get; set; }
    public string VariantCode { get; set; } = string.Empty;
    public string VariantName { get; set; } = string.Empty;
    public string ModelName { get; set; } = string.Empty;
    public decimal BasePrice { get; set; }

    public Guid? ColorId { get; set; }
    public string ColorName { get; set; } = string.Empty;
    public string HexCode { get; set; } = string.Empty;

    // Active Tier Pipeline
    public ViewerTier ActiveTier { get; set; } = ViewerTier.Tier1_Interactive3D;

    // Tier 1: Genuine 3D GLB Model
    public string? GlbFileUrl { get; set; }
    public string? UsdzFileUrl { get; set; }
    public long ModelFileSizeBytes { get; set; }
    public bool HasDracoCompression { get; set; }

    // Tier 2: 360-Degree Image Sequence (36-72 frames)
    public List<string> Turntable360FrameUrls { get; set; } = new();
    public int TurntableTotalFrames => Turntable360FrameUrls.Count;

    // Tier 3: Static Multi-Angle Photo Gallery Fallback
    public List<string> StaticGalleryImageUrls { get; set; } = new();

    // Camera viewpoints & Feature Hotspots
    public CameraPresetsManifestDto CameraPresets { get; set; } = new();
    public List<ShowroomHotspotDto> Hotspots { get; set; } = new();

    // Color Swapping without Geometry Reload
    public List<VehicleColorDto> AvailableColors { get; set; } = new();
}

public class Register3DAssetRequest
{
    public Guid VariantId { get; set; }
    public Guid? ColorId { get; set; }
    public string GlbFileUrl { get; set; } = string.Empty;
    public string? UsdzFileUrl { get; set; }
    public long ModelFileSizeBytes { get; set; }
    public bool HasDracoCompression { get; set; } = true;
    public string? HotspotsJson { get; set; }
    public string? CameraPresetsJson { get; set; }
}

public class RegisterTurntableRequest
{
    public Guid VariantId { get; set; }
    public Guid? ColorId { get; set; }
    public List<string> FrameUrls { get; set; } = new();
}

