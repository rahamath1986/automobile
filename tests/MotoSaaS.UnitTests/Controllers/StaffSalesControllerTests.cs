using Microsoft.AspNetCore.Mvc;
using MotoSaaS.Api.Controllers;
using MotoSaaS.Application.Common.Models;
using MotoSaaS.Application.Features.Sales;
using MotoSaaS.Application.Features.Sales.Interfaces;
using MotoSaaS.Application.Features.Sales.Models;
using Xunit;

namespace MotoSaaS.UnitTests.Controllers;

public class StaffSalesControllerTests
{
    private class FakeStaffSalesService : IStaffSalesService
    {
        public Guid CapturedLeadId { get; } = Guid.NewGuid();

        public Task<PagedResult<LeadSummaryDto>> GetPipelineAsync(
            SalesPipelineQuery query,
            CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new PagedResult<LeadSummaryDto>
            {
                Page = query.Page,
                PageSize = query.PageSize,
                TotalCount = 1,
                Items = new List<LeadSummaryDto>
                {
                    new()
                    {
                        Id = Guid.NewGuid(),
                        CustomerName = "Rahul Nair",
                        Phone = "+919876543210",
                        Status = "NEW",
                        Source = "WALKIN"
                    }
                }
            });
        }

        public Task<LeadDetailDto> GetLeadAsync(Guid enquiryId, CancellationToken cancellationToken = default)
        {
            return Task.FromResult(BuildLead(enquiryId));
        }

        public Task<LeadDetailDto> CaptureLeadAsync(
            LeadCaptureRequest request,
            CancellationToken cancellationToken = default)
        {
            var lead = BuildLead(CapturedLeadId);
            lead.CustomerName = $"{request.FirstName} {request.LastName}".Trim();
            lead.Phone = request.Phone;
            return Task.FromResult(lead);
        }

        public Task<LeadDetailDto> AssignLeadAsync(
            Guid enquiryId,
            AssignLeadRequest request,
            CancellationToken cancellationToken = default)
        {
            var lead = BuildLead(enquiryId);
            lead.AssignedSalesExecutiveId = request.SalesExecutiveId;
            return Task.FromResult(lead);
        }

        public Task<LeadDetailDto> UpdateLeadStatusAsync(
            Guid enquiryId,
            UpdateLeadStatusRequest request,
            CancellationToken cancellationToken = default)
        {
            var lead = BuildLead(enquiryId);
            lead.Status = request.Status.ToUpperInvariant();
            return Task.FromResult(lead);
        }

        public Task<FollowUpDto> AddFollowUpAsync(
            Guid enquiryId,
            CreateFollowUpRequest request,
            CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new FollowUpDto
            {
                Id = Guid.NewGuid(),
                EnquiryId = enquiryId,
                Channel = request.Channel.ToUpperInvariant(),
                Outcome = request.Outcome.ToUpperInvariant(),
                ContactedAt = DateTime.UtcNow
            });
        }

        public Task<SalesDashboardDto> GetDashboardAsync(
            Guid? branchId,
            CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new SalesDashboardDto
            {
                TotalLeads = 5,
                OpenLeads = 4,
                DueFollowUps = 2,
                TestRidesToday = 1,
                ActiveQuotations = 3
            });
        }

        public Task<List<SalesExecutiveDto>> GetSalesExecutivesAsync(
            Guid? branchId,
            CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new List<SalesExecutiveDto>
            {
                new() { Id = Guid.NewGuid(), FullName = "Kiran Shetty", OpenLeads = 2 }
            });
        }

        public Task<List<StaffTestRideDto>> GetTestRideQueueAsync(
            TestRideQueueQuery query,
            CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new List<StaffTestRideDto>
            {
                new() { Id = Guid.NewGuid(), Status = "SCHEDULED" }
            });
        }

        public Task<StaffTestRideDto> CompleteTestRideAsync(
            Guid testRideId,
            CompleteTestRideRequest request,
            CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new StaffTestRideDto
            {
                Id = testRideId,
                Status = "COMPLETED",
                CompletedAt = DateTime.UtcNow
            });
        }

        public Task<StaffTestRideDto> CancelTestRideAsync(
            Guid testRideId,
            CancelTestRideRequest request,
            CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new StaffTestRideDto { Id = testRideId, Status = "CANCELLED" });
        }

        public Task<StaffTestRideDto> MarkTestRideNoShowAsync(
            Guid testRideId,
            CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new StaffTestRideDto { Id = testRideId, Status = "NOSHOW" });
        }

        private static LeadDetailDto BuildLead(Guid id) => new()
        {
            Id = id,
            CustomerId = Guid.NewGuid(),
            CustomerName = "Rahul Nair",
            Phone = "+919876543210",
            BranchId = Guid.NewGuid(),
            BranchName = "Indiranagar Showroom",
            VariantId = Guid.NewGuid(),
            VariantName = "R15 V4 Standard",
            ModelName = "R15 V4",
            Status = "NEW",
            Source = "WALKIN",
            CreatedAt = DateTime.UtcNow
        };
    }

    private static StaffSalesController CreateController(FakeStaffSalesService service) => new(
        service,
        new LeadCaptureRequestValidator(),
        new AssignLeadRequestValidator(),
        new UpdateLeadStatusRequestValidator(),
        new CreateFollowUpRequestValidator(),
        new CompleteTestRideRequestValidator(),
        new CancelTestRideRequestValidator());

    [Fact]
    public async Task GetPipeline_ReturnsPagedLeads()
    {
        var controller = CreateController(new FakeStaffSalesService());

        var result = await controller.GetPipeline(
            new SalesPipelineQuery { Page = 1, PageSize = 10 },
            CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var envelope = Assert.IsType<ApiResponse<PagedResult<LeadSummaryDto>>>(ok.Value);
        Assert.True(envelope.Success);
        Assert.Equal(1, envelope.Data!.TotalCount);
        Assert.Single(envelope.Data.Items);
        Assert.Equal(1, envelope.Meta!.TotalCount);
    }

    [Fact]
    public async Task CaptureLead_ValidRequest_Returns201()
    {
        var service = new FakeStaffSalesService();
        var controller = CreateController(service);

        var result = await controller.CaptureLead(new LeadCaptureRequest
        {
            FirstName = "Rahul",
            LastName = "Nair",
            Phone = "9876543210",
            VariantId = Guid.NewGuid(),
            Source = "WalkIn"
        }, CancellationToken.None);

        var created = Assert.IsType<ObjectResult>(result);
        Assert.Equal(201, created.StatusCode);
        var envelope = Assert.IsType<ApiResponse<LeadDetailDto>>(created.Value);
        Assert.True(envelope.Success);
        Assert.Equal(service.CapturedLeadId, envelope.Data!.Id);
    }

    [Fact]
    public async Task CaptureLead_MissingPhone_Returns400WithoutCallingService()
    {
        var controller = CreateController(new FakeStaffSalesService());

        var result = await controller.CaptureLead(new LeadCaptureRequest
        {
            FirstName = "Rahul",
            VariantId = Guid.NewGuid()
        }, CancellationToken.None);

        var badRequest = Assert.IsType<BadRequestObjectResult>(result);
        var envelope = Assert.IsType<ApiResponse<object>>(badRequest.Value);
        Assert.False(envelope.Success);
        Assert.Contains(envelope.Errors!, e => e.Field == "Phone");
    }

    [Fact]
    public async Task CompleteTestRide_UnverifiedLicence_Returns400()
    {
        var controller = CreateController(new FakeStaffSalesService());

        var result = await controller.CompleteTestRide(
            Guid.NewGuid(),
            new CompleteTestRideRequest { DrivingLicenseVerified = false },
            CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task GetDashboard_ReturnsCounts()
    {
        var controller = CreateController(new FakeStaffSalesService());

        var result = await controller.GetDashboard(null, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var envelope = Assert.IsType<ApiResponse<SalesDashboardDto>>(ok.Value);
        Assert.Equal(5, envelope.Data!.TotalLeads);
        Assert.Equal(2, envelope.Data.DueFollowUps);
    }
}
