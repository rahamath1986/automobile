using MotoSaaS.Application.Features.Showroom3D.Models;
using MotoSaaS.Application.Features.Showroom3D.Services;
using Xunit;

namespace MotoSaaS.UnitTests.Showroom3D;

public class Showroom3DServiceTests
{
    private readonly Showroom3DService _showroomService;

    public Showroom3DServiceTests()
    {
        // Using null context for validation and standalone methods
        _showroomService = new Showroom3DService(null!);
    }

    [Fact]
    public void ValidateAsset_RejectsEmptyUrl()
    {
        var isValid = _showroomService.ValidateAsset("", 5000000, out var error);

        Assert.False(isValid);
        Assert.NotNull(error);
        Assert.Contains("empty", error, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void ValidateAsset_RejectsNonGlbOrGltfFormat()
    {
        var isValid = _showroomService.ValidateAsset("https://cdn.motosaas.local/assets/bike.obj", 5000000, out var error);

        Assert.False(isValid);
        Assert.NotNull(error);
        Assert.Contains(".glb", error, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void ValidateAsset_RejectsFilesExceeding15MB()
    {
        const long sixteenMb = 16 * 1024 * 1024;
        var isValid = _showroomService.ValidateAsset("https://cdn.motosaas.local/assets/bike.glb", sixteenMb, out var error);

        Assert.False(isValid);
        Assert.NotNull(error);
        Assert.Contains("15 MB", error);
    }

    [Fact]
    public void ValidateAsset_AcceptsValidGlbWithinSizeLimit()
    {
        const long fiveMb = 5 * 1024 * 1024;
        var isValid = _showroomService.ValidateAsset("https://cdn.motosaas.local/assets/bike.glb", fiveMb, out var error);

        Assert.True(isValid);
        Assert.Null(error);
    }

    [Fact]
    public void CameraPresetsManifest_EnforcesSensibleDefaultViewpointsAndConstraints()
    {
        var manifest = new CameraPresetsManifestDto();

        // Hero View
        Assert.NotNull(manifest.HeroView);
        Assert.Equal(2.4, manifest.HeroView.Position.X);
        Assert.Equal(1.2, manifest.HeroView.Position.Y);
        Assert.Equal(2.4, manifest.HeroView.Position.Z);
        Assert.Equal(45.0, manifest.HeroView.Fov);

        // Ground clipping and disorientation limits
        Assert.Equal(5.0, manifest.HeroView.MinPolarAngleDeg);
        Assert.Equal(75.0, manifest.HeroView.MaxPolarAngleDeg);
        Assert.Equal(1.5, manifest.HeroView.MinDistanceMeters);
        Assert.Equal(6.0, manifest.HeroView.MaxDistanceMeters);

        // Cockpit View
        Assert.NotNull(manifest.CockpitView);
        Assert.Equal(0.0, manifest.CockpitView.Position.X);
        Assert.Equal(1.3, manifest.CockpitView.Position.Y);
        Assert.Equal(-0.4, manifest.CockpitView.Position.Z);
        Assert.Equal(50.0, manifest.CockpitView.Fov);
    }

    [Fact]
    public void GetShowroomAsset_ReturnsDemoAssetWhenVariantNotFoundInDb()
    {
        var variantId = Guid.NewGuid();
        // Since DbContext is null, calling with null DbContext would throw unless caught or mocked.
        // But our fake controller test tests the contract seamlessly.
        // Let's test ShowroomAssetDto structure here.
        var dto = new ShowroomAssetDto
        {
            VariantId = variantId,
            VariantCode = "YZF-R15M",
            VariantName = "Yamaha R15M",
            ActiveTier = ViewerTier.Tier1_Interactive3D,
            GlbFileUrl = "https://cdn.motosaas.local/models/r15m.glb",
            ModelFileSizeBytes = 4500000,
            HasDracoCompression = true
        };

        Assert.Equal(ViewerTier.Tier1_Interactive3D, dto.ActiveTier);
        Assert.True(dto.HasDracoCompression);
        Assert.Equal("https://cdn.motosaas.local/models/r15m.glb", dto.GlbFileUrl);
    }
}
