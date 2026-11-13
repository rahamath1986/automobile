using Microsoft.AspNetCore.Mvc;
using MotoSaaS.Api.Controllers;
using MotoSaaS.Application.Common.Models;
using MotoSaaS.Application.Features.Sales;
using MotoSaaS.Application.Features.Sales.Interfaces;
using MotoSaaS.Application.Features.Sales.Models;
using Xunit;

namespace MotoSaaS.UnitTests.Controllers;

public class QuotationsControllerTests
{
    private class FakeQuotationService : IQuotationService
    {
        public bool ExpireThrowsNotFound { get; set; }

        public Task<QuotationCalculationDto> PreviewAsync(
            QuotationDraftRequest request,
            CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new QuotationCalculationDto
            {
                BranchId = Guid.NewGuid(),
                BranchName = "Indiranagar Showroom",
                CustomerId = Guid.NewGuid(),
                CustomerName = "Rahul Nair",
                VariantId = request.VariantId ?? Guid.NewGuid(),
                VariantName = "R15 V4 Standard",
                ModelName = "R15 V4",
                ExShowroomPrice = 182000m,
                RtoPercent = 12m,
                RtoCharges = 21840m,
                InsurancePercent = 3.5m,
                InsuranceCharges = 6370m,
                AccessoriesCharges = request.AccessoriesCharges,
                HandlingCharges = request.HandlingCharges ?? 2500m,
                Subtotal = 217710m,
                DiscountAmount = request.DiscountAmount,
                TotalOnRoadPrice = 214710m,
                ValidUntil = DateTime.UtcNow.AddDays(7)
            });
        }

        public Task<QuotationDto> CreateAsync(
            CreateQuotationRequest request,
            CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new QuotationDto
            {
                Id = Guid.NewGuid(),
                QuotationNumber = "QTN-BLRIND-20261113-0001",
                Status = "ACTIVE",
                EnquiryId = request.EnquiryId,
                CustomerId = request.CustomerId ?? Guid.NewGuid(),
                CustomerName = "Rahul Nair",
                VariantId = request.VariantId ?? Guid.NewGuid(),
                VariantName = "R15 V4 Standard",
                ColorId = Guid.NewGuid(),
                ColorName = "Racing Blue",
                ExShowroomPrice = 182000m,
                RtoCharges = 21840m,
                InsuranceCharges = 6370m,
                AccessoriesCharges = request.AccessoriesCharges,
                HandlingCharges = request.HandlingCharges ?? 2500m,
                DiscountAmount = request.DiscountAmount,
                Subtotal = 217710m,
                TotalOnRoadPrice = 214710m,
                ValidUntil = DateTime.UtcNow.AddDays(request.ValidDays),
                CreatedAt = DateTime.UtcNow
            });
        }

        public Task<PagedResult<QuotationDto>> GetQuotationsAsync(
            QuotationQuery query,
            CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new PagedResult<QuotationDto>
            {
                Page = query.Page,
                PageSize = query.PageSize,
                TotalCount = 0,
                Items = new List<QuotationDto>()
            });
        }

        public Task<QuotationDto> GetQuotationAsync(Guid quotationId, CancellationToken cancellationToken = default)
        {
            if (ExpireThrowsNotFound)
            {
                throw new KeyNotFoundException("The quotation was not found.");
            }

            return Task.FromResult(new QuotationDto { Id = quotationId, Status = "ACTIVE" });
        }

        public Task<QuotationDto> ExpireAsync(Guid quotationId, CancellationToken cancellationToken = default)
        {
            if (ExpireThrowsNotFound)
            {
                throw new KeyNotFoundException("The quotation was not found.");
            }

            return Task.FromResult(new QuotationDto { Id = quotationId, Status = "EXPIRED" });
        }
    }

    private static QuotationsController CreateController(FakeQuotationService service) =>
        new(service, new QuotationDraftRequestValidator());

    [Fact]
    public async Task Preview_ValidEnquiry_ReturnsCalculation()
    {
        var controller = CreateController(new FakeQuotationService());

        var result = await controller.Preview(new QuotationDraftRequest
        {
            EnquiryId = Guid.NewGuid(),
            AccessoriesCharges = 5000m,
            DiscountAmount = 3000m,
            ValidDays = 7
        }, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var envelope = Assert.IsType<ApiResponse<QuotationCalculationDto>>(ok.Value);
        Assert.True(envelope.Success);
        Assert.Equal(214710m, envelope.Data!.TotalOnRoadPrice);
        Assert.Equal(12m, envelope.Data.RtoPercent);
    }

    [Fact]
    public async Task Preview_MissingLeadAndCustomer_Returns400()
    {
        var controller = CreateController(new FakeQuotationService());

        var result = await controller.Preview(new QuotationDraftRequest
        {
            ValidDays = 7
        }, CancellationToken.None);

        var badRequest = Assert.IsType<BadRequestObjectResult>(result);
        var envelope = Assert.IsType<ApiResponse<object>>(badRequest.Value);
        Assert.False(envelope.Success);
        Assert.Contains(envelope.Errors!, e => e.Field == "EnquiryId");
    }

    [Fact]
    public async Task Create_ValidEnquiry_Returns201()
    {
        var controller = CreateController(new FakeQuotationService());
        var enquiryId = Guid.NewGuid();

        var result = await controller.Create(new CreateQuotationRequest
        {
            EnquiryId = enquiryId,
            AccessoriesCharges = 5000m,
            DiscountAmount = 3000m,
            ValidDays = 7
        }, CancellationToken.None);

        var created = Assert.IsType<ObjectResult>(result);
        Assert.Equal(201, created.StatusCode);
        var envelope = Assert.IsType<ApiResponse<QuotationDto>>(created.Value);
        Assert.True(envelope.Success);
        Assert.Equal(enquiryId, envelope.Data!.EnquiryId);
        Assert.StartsWith("QTN-", envelope.Data.QuotationNumber);
    }

    [Fact]
    public async Task Expire_NotFound_Returns404()
    {
        var controller = CreateController(new FakeQuotationService { ExpireThrowsNotFound = true });

        var result = await controller.Expire(Guid.NewGuid(), CancellationToken.None);

        Assert.IsType<NotFoundObjectResult>(result);
    }

    [Fact]
    public async Task GetQuotations_ReturnsPagedEnvelope()
    {
        var controller = CreateController(new FakeQuotationService());

        var result = await controller.GetQuotations(
            new QuotationQuery { Page = 2, PageSize = 10 },
            CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var envelope = Assert.IsType<ApiResponse<PagedResult<QuotationDto>>>(ok.Value);
        Assert.Equal(2, envelope.Meta!.Page);
        Assert.Equal(10, envelope.Meta.PageSize);
    }
}
