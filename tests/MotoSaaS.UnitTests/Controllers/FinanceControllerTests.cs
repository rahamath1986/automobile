using Microsoft.AspNetCore.Mvc;
using MotoSaaS.Api.Controllers;
using MotoSaaS.Application.Common.Models;
using MotoSaaS.Application.Features.Finance;
using Xunit;

namespace MotoSaaS.UnitTests.Controllers;

public class FinanceControllerTests
{
    private readonly EmiCalculatorService _emiService = new();
    private readonly CalculateEmiRequestValidator _validator = new();

    [Fact]
    public async Task CalculateEmi_ValidRequest_ReturnsOkWithCalculatedData()
    {
        // Arrange
        var controller = new FinanceController(_emiService, _validator);
        var request = new CalculateEmiRequest
        {
            VehiclePrice = 200000m,
            DownPayment = 40000m,
            AnnualInterestRatePercent = 10m,
            TenureMonths = 24,
            CalculationMethod = EmiCalculationMethod.ReducingBalance
        };

        // Act
        var actionResult = await controller.CalculateEmi(request);

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(actionResult);
        var response = Assert.IsType<ApiResponse<CalculateEmiResponse>>(okResult.Value);

        Assert.True(response.Success);
        Assert.NotNull(response.Data);
        Assert.Equal(160000m, response.Data.LoanPrincipal);
        Assert.True(response.Data.MonthlyEmi > 0);
        Assert.Equal(24, response.Data.AmortizationSchedule.Count);
    }

    [Fact]
    public async Task CalculateEmi_InvalidRequest_ReturnsBadRequestWithValidationErrors()
    {
        // Arrange
        var controller = new FinanceController(_emiService, _validator);
        var request = new CalculateEmiRequest
        {
            VehiclePrice = 0m, // Invalid
            DownPayment = 50000m,
            AnnualInterestRatePercent = 10m,
            TenureMonths = 24
        };

        // Act
        var actionResult = await controller.CalculateEmi(request);

        // Assert
        var badRequestResult = Assert.IsType<BadRequestObjectResult>(actionResult);
        var response = Assert.IsType<ApiResponse<object>>(badRequestResult.Value);

        Assert.False(response.Success);
        Assert.NotNull(response.Errors);
        Assert.NotEmpty(response.Errors);
    }
}

