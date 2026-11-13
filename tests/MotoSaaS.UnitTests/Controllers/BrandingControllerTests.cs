using Microsoft.AspNetCore.Mvc;
using MotoSaaS.Api.Controllers;
using MotoSaaS.Application.Common.Models;
using MotoSaaS.Application.Features.Branding.Interfaces;
using MotoSaaS.Application.Features.Branding.Models;
using MotoSaaS.Infrastructure.Services;
using Xunit;

namespace MotoSaaS.UnitTests.Controllers;

public class BrandingControllerTests
{
    private class FakeBrandingService : IBrandingService
    {
        public Task<WhiteLabelBrandingDto?> GetBrandingAsync(Guid tenantId, CancellationToken cancellationToken = default)
        {
            return Task.FromResult<WhiteLabelBrandingDto?>(new WhiteLabelBrandingDto
            {
                TenantId = tenantId,
                DealerCode = "ALAGENDRA",
                TradeName = "Alagendra Automobiles",
                PrimaryColor = "#002C6C"
            });
        }

        public Task<WhiteLabelBrandingDto?> GetBrandingByCodeAsync(string dealerCode, CancellationToken cancellationToken = default)
        {
            if (dealerCode.ToUpperInvariant() == "ALAGENDRA")
            {
                return Task.FromResult<WhiteLabelBrandingDto?>(new WhiteLabelBrandingDto
                {
                    DealerCode = "ALAGENDRA",
                    TradeName = "Alagendra Automobiles",
                    PrimaryColor = "#002C6C"
                });
            }

            return Task.FromResult<WhiteLabelBrandingDto?>(null);
        }

        public Task<WhiteLabelBrandingDto> UpdateBrandingAsync(Guid tenantId, UpdateBrandingRequest request, CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new WhiteLabelBrandingDto
            {
                TenantId = tenantId,
                TradeName = request.TradeName ?? "Alagendra Automobiles",
                PrimaryColor = request.PrimaryColor ?? "#002C6C"
            });
        }
    }

    [Fact]
    public async Task GetBrandingByCode_ValidCode_ReturnsBranding()
    {
        var tenantContext = new TenantContext();
        var controller = new BrandingController(new FakeBrandingService(), tenantContext);

        var result = await controller.GetBrandingByCode("ALAGENDRA", CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var envelope = Assert.IsType<ApiResponse<WhiteLabelBrandingDto>>(okResult.Value);

        Assert.True(envelope.Success);
        Assert.Equal("ALAGENDRA", envelope.Data!.DealerCode);
        Assert.Equal("#002C6C", envelope.Data.PrimaryColor);
    }
}

