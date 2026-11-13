using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MotoSaaS.Api.Filters;
using MotoSaaS.Application.Common.Models;
using MotoSaaS.Application.Features.Showroom3D.Interfaces;
using MotoSaaS.Application.Features.Showroom3D.Models;
using MotoSaaS.Domain.Subscription;

namespace MotoSaaS.Api.Controllers;

public class ShowroomController : BaseApiController
{
    private readonly IShowroom3DService _showroomService;

    public ShowroomController(IShowroom3DService showroomService)
    {
        _showroomService = showroomService;
    }

    /// <summary>
    /// Resolves the 3-tier progressive showroom manifest for a vehicle variant and color.
    /// Returns Tier 1 interactive GLB 3D model, Tier 2 360-degree turntable frames, or Tier 3 static multi-angle gallery.
    /// Publicly accessible for guest customer discovery.
    /// </summary>
    [HttpGet("variants/{variantId:guid}")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<ShowroomAssetDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetShowroomAsset(
        Guid variantId,
        [FromQuery] Guid? colorId,
        CancellationToken cancellationToken)
    {
        var asset = await _showroomService.GetShowroomAssetAsync(variantId, colorId, cancellationToken);
        return Ok(ApiResponse<ShowroomAssetDto>.Ok(asset));
    }

    /// <summary>
    /// Retrieves technical hotspots and callout annotations positioned in 3D coordinate space.
    /// </summary>
    [HttpGet("variants/{variantId:guid}/hotspots")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<List<ShowroomHotspotDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetHotspots(Guid variantId, CancellationToken cancellationToken)
    {
        var hotspots = await _showroomService.GetHotspotsAsync(variantId, cancellationToken);
        return Ok(ApiResponse<List<ShowroomHotspotDto>>.Ok(hotspots));
    }

    /// <summary>
    /// Retrieves camera orbital presets (Hero, Profile, Cockpit, Rear, Top) and polar/distance constraints.
    /// </summary>
    [HttpGet("variants/{variantId:guid}/camera-presets")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<CameraPresetsManifestDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetCameraPresets(Guid variantId, CancellationToken cancellationToken)
    {
        var presets = await _showroomService.GetCameraPresetsAsync(variantId, cancellationToken);
        return Ok(ApiResponse<CameraPresetsManifestDto>.Ok(presets));
    }

    /// <summary>
    /// Registers or updates a 3D GLB/USDZ asset configuration with Draco compression, camera presets, and hotspots.
    /// Restricted to authorized dealership staff and gated by the Showroom3D subscription feature entitlement.
    /// </summary>
    [HttpPost("assets")]
    [Authorize(Policy = "StaffOnly")]
    [RequiresFeature(SubscriptionFeatures.Showroom3D)]
    [ProducesResponseType(typeof(ApiResponse<ShowroomAssetDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Register3DAsset(
        [FromBody] Register3DAssetRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var asset = await _showroomService.Register3DAssetAsync(request, cancellationToken);
            return StatusCode(StatusCodes.Status201Created, ApiResponse<ShowroomAssetDto>.Ok(asset, "3D Asset registered successfully."));
        }
        catch (ArgumentException ex)
        {
            return BadRequest(ApiResponse<object>.Failure(ex.Message, StatusCodes.Status400BadRequest));
        }
    }
}

