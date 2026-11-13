using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MotoSaaS.Application.Common.Models;
using MotoSaaS.Application.Features.Manufacturer.Interfaces;
using MotoSaaS.Application.Features.Manufacturer.Models;

namespace MotoSaaS.Api.Controllers;

public class ManufacturersController : BaseApiController
{
    private readonly IManufacturerService _manufacturerService;

    public ManufacturersController(IManufacturerService manufacturerService)
    {
        _manufacturerService = manufacturerService;
    }

    /// <summary>
    /// Retrieves all active two-wheeler vehicle manufacturers (Yamaha, Honda, TVS, Hero, Bajaj, Suzuki, Royal Enfield).
    /// </summary>
    [HttpGet]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<List<ManufacturerDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetManufacturers(CancellationToken cancellationToken)
    {
        var list = await _manufacturerService.GetManufacturersAsync(cancellationToken);
        return Ok(ApiResponse<List<ManufacturerDto>>.Ok(list));
    }

    /// <summary>
    /// Retrieves manufacturer details by unique ID.
    /// </summary>
    [HttpGet("{id:guid}")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<ManufacturerDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetManufacturerById(Guid id, CancellationToken cancellationToken)
    {
        var item = await _manufacturerService.GetManufacturerByIdAsync(id, cancellationToken);
        if (item == null)
        {
            return NotFound(ApiResponse<object>.Failure($"Manufacturer with ID '{id}' not found.", 404));
        }

        return Ok(ApiResponse<ManufacturerDto>.Ok(item));
    }

    /// <summary>
    /// Creates a new manufacturer profile (Restricted to SaaS Super Admin).
    /// </summary>
    [HttpPost]
    [Authorize(Policy = "SuperAdminOnly")]
    [ProducesResponseType(typeof(ApiResponse<ManufacturerDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CreateManufacturer([FromBody] CreateManufacturerRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var created = await _manufacturerService.CreateManufacturerAsync(request, cancellationToken);
            return StatusCode(StatusCodes.Status201Created, ApiResponse<ManufacturerDto>.Ok(created, "Manufacturer created successfully."));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResponse<object>.Failure(ex.Message));
        }
    }
}

