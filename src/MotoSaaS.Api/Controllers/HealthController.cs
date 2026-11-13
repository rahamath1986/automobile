using Microsoft.AspNetCore.Mvc;
using MotoSaaS.Application.Common.Models;

namespace MotoSaaS.Api.Controllers;

[ApiController]
public class HealthController : ControllerBase
{
    private static readonly DateTime StartTime = DateTime.UtcNow;

    [HttpGet("health/live")]
    public IActionResult Live()
    {
        return Ok(new
        {
            status = "Healthy",
            service = "MotoSaaS.Api",
            uptimeSeconds = (DateTime.UtcNow - StartTime).TotalSeconds,
            timestamp = DateTime.UtcNow
        });
    }

    [HttpGet("health/ready")]
    public IActionResult Ready()
    {
        return Ok(new
        {
            status = "Ready",
            service = "MotoSaaS.Api",
            environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Production",
            timestamp = DateTime.UtcNow
        });
    }
}

