using Microsoft.AspNetCore.Mvc;
using MotoSaaS.Api.Controllers;
using MotoSaaS.Application.Common.Models;
using MotoSaaS.Application.Features.Manufacturer.Interfaces;
using MotoSaaS.Application.Features.Manufacturer.Models;
using Xunit;

namespace MotoSaaS.UnitTests.Controllers;

public class ManufacturersControllerTests
{
    private class FakeManufacturerService : IManufacturerService
    {
        public Task<List<ManufacturerDto>> GetManufacturersAsync(CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new List<ManufacturerDto>
            {
                new() { Id = Guid.NewGuid(), Code = "YAMAHA", Name = "Yamaha" },
                new() { Id = Guid.NewGuid(), Code = "HONDA", Name = "Honda" },
                new() { Id = Guid.NewGuid(), Code = "TVS", Name = "TVS Motor" }
            });
        }

        public Task<ManufacturerDto?> GetManufacturerByIdAsync(Guid id, CancellationToken cancellationToken = default)
        {
            return Task.FromResult<ManufacturerDto?>(new ManufacturerDto { Id = id, Code = "YAMAHA", Name = "Yamaha" });
        }

        public Task<ManufacturerDto?> GetManufacturerByCodeAsync(string code, CancellationToken cancellationToken = default)
        {
            return Task.FromResult<ManufacturerDto?>(new ManufacturerDto { Code = code });
        }

        public Task<ManufacturerDto> CreateManufacturerAsync(CreateManufacturerRequest request, CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new ManufacturerDto { Code = request.Code, Name = request.Name });
        }
    }

    [Fact]
    public async Task GetManufacturers_ReturnsOkWithList()
    {
        var controller = new ManufacturersController(new FakeManufacturerService());

        var result = await controller.GetManufacturers(CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var envelope = Assert.IsType<ApiResponse<List<ManufacturerDto>>>(okResult.Value);

        Assert.True(envelope.Success);
        Assert.Equal(3, envelope.Data!.Count);
    }
}

