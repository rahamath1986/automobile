using MotoSaaS.Application.Features.Sales.Models;

namespace MotoSaaS.Application.Features.Sales.Interfaces;

public interface IQuotationService
{
    Task<QuotationCalculationDto> PreviewAsync(
        QuotationDraftRequest request,
        CancellationToken cancellationToken = default);

    Task<QuotationDto> CreateAsync(
        CreateQuotationRequest request,
        CancellationToken cancellationToken = default);

    Task<PagedResult<QuotationDto>> GetQuotationsAsync(
        QuotationQuery query,
        CancellationToken cancellationToken = default);

    Task<QuotationDto> GetQuotationAsync(Guid quotationId, CancellationToken cancellationToken = default);

    Task<QuotationDto> ExpireAsync(Guid quotationId, CancellationToken cancellationToken = default);
}
