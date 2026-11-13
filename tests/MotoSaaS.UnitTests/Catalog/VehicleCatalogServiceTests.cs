using MotoSaaS.Application.Features.Catalog.Models;
using Xunit;

namespace MotoSaaS.UnitTests.Catalog;

public class VehicleCatalogServiceTests
{
    [Fact]
    public void VehicleModelSummaryDto_CapturesTwoWheelerDetails()
    {
        var model = new VehicleModelSummaryDto
        {
            Id = Guid.NewGuid(),
            ManufacturerCode = "YAMAHA",
            ManufacturerName = "Yamaha Motor Company",
            Code = "YZF-R15-V4",
            Name = "Yamaha YZF R15 V4",
            Category = "MOTORCYCLE",
            FuelType = "PETROL",
            DisplacementCc = 155,
            StartingPrice = 182000m,
            VariantCount = 3,
            ColorCount = 5,
            Has3DAsset = true
        };

        Assert.Equal("YAMAHA", model.ManufacturerCode);
        Assert.Equal("MOTORCYCLE", model.Category);
        Assert.Equal(155, model.DisplacementCc);
        Assert.True(model.Has3DAsset);
        Assert.Equal(182000m, model.StartingPrice);
    }

    [Fact]
    public void VehicleVariantDto_IncludesColorsAnd3DAssets()
    {
        var variant = new VehicleVariantDto
        {
            Id = Guid.NewGuid(),
            Code = "R15M",
            Name = "R15M Metallic Grey",
            BasePrice = 195000m,
            Colors = new List<VehicleColorDto>
            {
                new() { ColorName = "Metallic Grey", HexCode = "#808080", IsPrimary = true },
                new() { ColorName = "Racing Blue", HexCode = "#002C6C" }
            },
            Assets3D = new List<Asset3DDto>
            {
                new() { GlbFileUrl = "https://cdn.motosaas.local/assets/r15m.glb", ModelFileSizeBytes = 4500000 }
            }
        };

        Assert.Equal("R15M", variant.Code);
        Assert.Equal(2, variant.Colors.Count);
        Assert.Single(variant.Assets3D);
        Assert.Equal("https://cdn.motosaas.local/assets/r15m.glb", variant.Assets3D[0].GlbFileUrl);
    }
}

