using MotoSaaS.Application.Features.Branding.Models;
using Xunit;

namespace MotoSaaS.UnitTests.Branding;

public class BrandingServiceTests
{
    [Fact]
    public void WhiteLabelBrandingDto_DefaultColors_MatchesTheme()
    {
        var dto = new WhiteLabelBrandingDto
        {
            TenantId = Guid.NewGuid(),
            DealerCode = "ALAGENDRA",
            TradeName = "Alagendra Automobiles",
            PrimaryColor = "#002C6C",
            SecondaryColor = "#E60012",
            AssociatedManufacturerNames = new List<string> { "Yamaha" }
        };

        Assert.Equal("ALAGENDRA", dto.DealerCode);
        Assert.Equal("#002C6C", dto.PrimaryColor);
        Assert.Equal("#E60012", dto.SecondaryColor);
        Assert.Contains("Yamaha", dto.AssociatedManufacturerNames);
    }
}

