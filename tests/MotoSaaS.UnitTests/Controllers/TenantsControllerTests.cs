using Microsoft.AspNetCore.Mvc;
using MotoSaaS.Api.Controllers;
using MotoSaaS.Application.Common.Models;
using MotoSaaS.Application.Features.Tenancy.Interfaces;
using MotoSaaS.Application.Features.Tenancy.Models;
using MotoSaaS.Infrastructure.Services;
using Xunit;

namespace MotoSaaS.UnitTests.Controllers;

public class TenantsControllerTests
{
    private class FakeTenantService : ITenantService
    {
        public Task<TenantDto?> GetTenantByCodeAsync(string code, CancellationToken cancellationToken = default)
        {
            if (code.ToUpperInvariant() == "ALAGENDRA")
            {
                return Task.FromResult<TenantDto?>(new TenantDto
                {
                    Id = Guid.NewGuid(),
                    Code = "ALAGENDRA",
                    TradeName = "Alagendra Automobiles",
                    PrimaryColor = "#002C6C",
                    SecondaryColor = "#E60012",
                    Branches = new List<BranchDto>
                    {
                        new() { Code = "MDU-CTR", Name = "Madurai Central" }
                    }
                });
            }

            return Task.FromResult<TenantDto?>(null);
        }

        public Task<TenantDto?> GetTenantByIdAsync(Guid id, CancellationToken cancellationToken = default)
        {
            return Task.FromResult<TenantDto?>(new TenantDto
            {
                Id = id,
                Code = "ALAGENDRA",
                TradeName = "Alagendra Automobiles"
            });
        }

        public Task<List<BranchDto>> GetBranchesByTenantIdAsync(Guid tenantId, CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new List<BranchDto>
            {
                new() { Id = Guid.NewGuid(), Code = "MDU-CTR", Name = "Madurai Central" }
            });
        }
    }

    [Fact]
    public async Task GetTenantByCode_ExistingCode_ReturnsOkWithTenantProfile()
    {
        var tenantContext = new TenantContext();
        var controller = new TenantsController(new FakeTenantService(), tenantContext);

        var result = await controller.GetTenantByCode("ALAGENDRA", CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var envelope = Assert.IsType<ApiResponse<TenantDto>>(okResult.Value);
        Assert.True(envelope.Success);
        Assert.Equal("ALAGENDRA", envelope.Data!.Code);
        Assert.Single(envelope.Data.Branches);
    }

    [Fact]
    public async Task GetTenantByCode_NonExistentCode_ReturnsNotFound()
    {
        var tenantContext = new TenantContext();
        var controller = new TenantsController(new FakeTenantService(), tenantContext);

        var result = await controller.GetTenantByCode("UNKNOWN_DEALER", CancellationToken.None);

        var notFoundResult = Assert.IsType<NotFoundObjectResult>(result);
        var envelope = Assert.IsType<ApiResponse<object>>(notFoundResult.Value);
        Assert.False(envelope.Success);
        Assert.Equal(404, envelope.StatusCode);
    }
}

