using FluentValidation;
using Microsoft.AspNetCore.Mvc;
using MotoSaaS.Application.Common.Models;
using MotoSaaS.Application.Features.Finance;

namespace MotoSaaS.Api.Controllers;

public class FinanceController : BaseApiController
{
    private readonly IEmiCalculatorService _emiCalculatorService;
    private readonly IValidator<CalculateEmiRequest> _validator;

    public FinanceController(
        IEmiCalculatorService emiCalculatorService,
        IValidator<CalculateEmiRequest> validator)
    {
        _emiCalculatorService = emiCalculatorService;
        _validator = validator;
    }

    /// <summary>
    /// Calculates monthly EMI and amortization schedule using bank-agnostic mathematical algorithms (Reducing Balance or Flat Rate).
    /// </summary>
    [HttpPost("calculate-emi")]
    [ProducesResponseType(typeof(ApiResponse<CalculateEmiResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CalculateEmi([FromBody] CalculateEmiRequest request)
    {
        var validationResult = await _validator.ValidateAsync(request);
        if (!validationResult.IsValid)
        {
            var errors = validationResult.Errors.Select(e => new ValidationErrorItem
            {
                Field = e.PropertyName,
                Message = e.ErrorMessage
            }).ToList();

            return BadRequest(ApiResponse<object>.Failure("Invalid EMI calculation parameters.", 400, errors));
        }

        var result = _emiCalculatorService.Calculate(request);
        return Ok(ApiResponse<CalculateEmiResponse>.Ok(result, "EMI calculation completed successfully."));
    }
}

