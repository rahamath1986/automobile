using Microsoft.AspNetCore.Mvc;
using MotoSaaS.Api.Controllers;
using MotoSaaS.Application.Common.Models;
using MotoSaaS.Application.Features.Showroom3D.Interfaces;
using MotoSaaS.Application.Features.Showroom3D.Models;
using Xunit;

namespace MotoSaaS.UnitTests.Controllers;

public class ShowroomControllerTests
{
    private class FakeShowroomService : IShowroom3DService
    {
        public Task<ShowroomAssetDto> GetShowroomAssetAsync(Guid variantId, Guid? colorId = null, CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new ShowroomAssetDto
            {
                VariantId = variantId,
                VariantCode = "YZF-R15-V4",
                VariantName = "Yamaha R15 V4",
                ActiveTier = ViewerTier.Tier1_Interactive3D,
                GlbFileUrl = "https://cdn.motosaas.local/assets/r15.glb",
                ModelFileSizeBytes = 5000000,
                HasDracoCompression = true
            });
        }

        public Task<ShowroomAssetDto> Register3DAssetAsync(Register3DAssetRequest request, CancellationToken cancellationToken = default)
        {
            if (request.GlbFileUrl.EndsWith(".obj"))
            {
                throw new ArgumentException("File must be a valid glTF 2.0 binary (.glb) or .gltf container.");
            }

            return Task.FromResult(new ShowroomAssetDto
            {
                VariantId = request.VariantId,
                GlbFileUrl = request.GlbFileUrl,
                ModelFileSizeBytes = request.ModelFileSizeBytes,
                ActiveTier = ViewerTier.Tier1_Interactive3D
            });
        }

        public Task<CameraPresetsManifestDto> GetCameraPresetsAsync(Guid variantId, CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new CameraPresetsManifestDto());
        }

        public Task<List<ShowroomHotspotDto>> GetHotspotsAsync(Guid variantId, CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new List<ShowroomHotspotDto>
            {
                new() { Id = "abs", Title = "Dual-Channel ABS", Category = "Safety" },
                new() { Id = "engine", Title = "155cc LC4V Engine", Category = "Mechanical" }
            });
        }

        public bool ValidateAsset(string fileUrl, long fileSizeBytes, out string? validationError)
        {
            validationError = null;
            return true;
        }
    }

    [Fact]
    public async Task GetShowroomAsset_ReturnsOkWithTier1Manifest()
    {
        var controller = new ShowroomController(new FakeShowroomService());
        var variantId = Guid.NewGuid();

        var result = await controller.GetShowroomAsset(variantId, null, CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var envelope = Assert.IsType<ApiResponse<ShowroomAssetDto>>(okResult.Value);
        Assert.True(envelope.Success);
        Assert.NotNull(envelope.Data);
        Assert.Equal(ViewerTier.Tier1_Interactive3D, envelope.Data.ActiveTier);
        Assert.Equal("YZF-R15-V4", envelope.Data.VariantCode);
        Assert.Equal("https://cdn.motosaas.local/assets/r15.glb", envelope.Data.GlbFileUrl);
    }

    [Fact]
    public async Task GetHotspots_ReturnsOkWithHotspotList()
    {
        var controller = new ShowroomController(new FakeShowroomService());
        var variantId = Guid.NewGuid();

        var result = await controller.GetHotspots(variantId, CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var envelope = Assert.IsType<ApiResponse<List<ShowroomHotspotDto>>>(okResult.Value);
        Assert.True(envelope.Success);
        Assert.NotNull(envelope.Data);
        Assert.Equal(2, envelope.Data.Count);
        Assert.Equal("Dual-Channel ABS", envelope.Data[0].Title);
    }

    [Fact]
    public async Task GetCameraPresets_ReturnsOkWithCameraPresets()
    {
        var controller = new ShowroomController(new FakeShowroomService());
        var variantId = Guid.NewGuid();

        var result = await controller.GetCameraPresets(variantId, CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var envelope = Assert.IsType<ApiResponse<CameraPresetsManifestDto>>(okResult.Value);
        Assert.True(envelope.Success);
        Assert.NotNull(envelope.Data);
        Assert.NotNull(envelope.Data.HeroView);
        Assert.NotNull(envelope.Data.CockpitView);
    }

    [Fact]
    public async Task Register3DAsset_ReturnsCreatedWhenValid()
    {
        var controller = new ShowroomController(new FakeShowroomService());
        var request = new Register3DAssetRequest
        {
            VariantId = Guid.NewGuid(),
            GlbFileUrl = "https://cdn.motosaas.local/assets/aerox.glb",
            ModelFileSizeBytes = 4200000,
            HasDracoCompression = true
        };

        var result = await controller.Register3DAsset(request, CancellationToken.None);

        var createdResult = Assert.IsType<ObjectResult>(result);
        Assert.Equal(201, createdResult.StatusCode);
        var envelope = Assert.IsType<ApiResponse<ShowroomAssetDto>>(createdResult.Value);
        Assert.True(envelope.Success);
        Assert.NotNull(envelope.Data);
        Assert.Equal("https://cdn.motosaas.local/assets/aerox.glb", envelope.Data.GlbFileUrl);
    }

    [Fact]
    public async Task Register3DAsset_ReturnsBadRequestWhenInvalidFormat()
    {
        var controller = new ShowroomController(new FakeShowroomService());
        var request = new Register3DAssetRequest
        {
            VariantId = Guid.NewGuid(),
            GlbFileUrl = "https://cdn.motosaas.local/assets/invalid.obj",
            ModelFileSizeBytes = 4200000
        };

        var result = await controller.Register3DAsset(request, CancellationToken.None);

        var badRequestResult = Assert.IsType<BadRequestObjectResult>(result);
        var envelope = Assert.IsType<ApiResponse<object>>(badRequestResult.Value);
        Assert.False(envelope.Success);
        Assert.Contains("glTF 2.0", envelope.Message);
    }
}

