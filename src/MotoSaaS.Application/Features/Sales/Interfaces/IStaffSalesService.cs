using MotoSaaS.Application.Features.Sales.Models;

namespace MotoSaaS.Application.Features.Sales.Interfaces;

public interface IStaffSalesService
{
    Task<PagedResult<LeadSummaryDto>> GetPipelineAsync(
        SalesPipelineQuery query,
        CancellationToken cancellationToken = default);

    Task<LeadDetailDto> GetLeadAsync(Guid enquiryId, CancellationToken cancellationToken = default);

    Task<LeadDetailDto> CaptureLeadAsync(
        LeadCaptureRequest request,
        CancellationToken cancellationToken = default);

    Task<LeadDetailDto> AssignLeadAsync(
        Guid enquiryId,
        AssignLeadRequest request,
        CancellationToken cancellationToken = default);

    Task<LeadDetailDto> UpdateLeadStatusAsync(
        Guid enquiryId,
        UpdateLeadStatusRequest request,
        CancellationToken cancellationToken = default);

    Task<FollowUpDto> AddFollowUpAsync(
        Guid enquiryId,
        CreateFollowUpRequest request,
        CancellationToken cancellationToken = default);

    Task<SalesDashboardDto> GetDashboardAsync(
        Guid? branchId,
        CancellationToken cancellationToken = default);

    Task<List<SalesExecutiveDto>> GetSalesExecutivesAsync(
        Guid? branchId,
        CancellationToken cancellationToken = default);

    Task<List<StaffTestRideDto>> GetTestRideQueueAsync(
        TestRideQueueQuery query,
        CancellationToken cancellationToken = default);

    Task<StaffTestRideDto> CompleteTestRideAsync(
        Guid testRideId,
        CompleteTestRideRequest request,
        CancellationToken cancellationToken = default);

    Task<StaffTestRideDto> CancelTestRideAsync(
        Guid testRideId,
        CancelTestRideRequest request,
        CancellationToken cancellationToken = default);

    Task<StaffTestRideDto> MarkTestRideNoShowAsync(
        Guid testRideId,
        CancellationToken cancellationToken = default);
}
