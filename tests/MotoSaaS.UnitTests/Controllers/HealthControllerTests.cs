using Microsoft.AspNetCore.Mvc;
using MotoSaaS.Api.Controllers;
using Xunit;

namespace MotoSaaS.UnitTests.Controllers;

public class HealthControllerTests
{
    private readonly HealthController _controller = new();

    [Fact]
    public void Live_ReturnsOkWithHealthyStatus()
    {
        var result = _controller.Live();
        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);
    }

    [Fact]
    public void Ready_ReturnsOkWithReadyStatus()
    {
        var result = _controller.Ready();
        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);
    }
}

