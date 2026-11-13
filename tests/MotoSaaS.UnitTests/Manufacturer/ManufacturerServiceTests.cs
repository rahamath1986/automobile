using MotoSaaS.Application.Features.Manufacturer.Models;
using MotoSaaS.Application.Features.Manufacturer.Services;
using Xunit;

namespace MotoSaaS.UnitTests.Manufacturer;

public class ManufacturerServiceTests
{
    [Fact]
    public void ManufacturerDto_ValidFields_RetainsValues()
    {
        var id = Guid.NewGuid();
        var dto = new ManufacturerDto
        {
            Id = id,
            Code = "YAMAHA",
            Name = "Yamaha Motor Company",
            CountryOfOrigin = "Japan",
            IsActive = true
        };

        Assert.Equal(id, dto.Id);
        Assert.Equal("YAMAHA", dto.Code);
        Assert.Equal("Yamaha Motor Company", dto.Name);
        Assert.Equal("Japan", dto.CountryOfOrigin);
        Assert.True(dto.IsActive);
    }

    [Fact]
    public void TenantManufacturerDto_MultiBrandMapping_CapturesDealerCodeWithOem()
    {
        var tenantId = Guid.NewGuid();
        var oemId = Guid.NewGuid();

        var mapping = new TenantManufacturerDto
        {
            TenantId = tenantId,
            ManufacturerId = oemId,
            ManufacturerCode = "YAMAHA",
            ManufacturerName = "Yamaha Motor Company",
            DealerCodeWithOem = "YAM-IND-0482",
            IsPrimary = true
        };

        Assert.Equal(tenantId, mapping.TenantId);
        Assert.Equal(oemId, mapping.ManufacturerId);
        Assert.Equal("YAM-IND-0482", mapping.DealerCodeWithOem);
        Assert.True(mapping.IsPrimary);
    }
}

