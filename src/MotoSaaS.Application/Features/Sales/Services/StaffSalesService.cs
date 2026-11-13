using Microsoft.EntityFrameworkCore;
using MotoSaaS.Application.Common.Interfaces;
using MotoSaaS.Application.Features.Sales.Interfaces;
using MotoSaaS.Application.Features.Sales.Models;
using MotoSaaS.Domain.Catalog;
using MotoSaaS.Domain.Identity;
using MotoSaaS.Domain.Sales;
using MotoSaaS.Domain.Tenancy;

namespace MotoSaaS.Application.Features.Sales.Services;

public class StaffSalesService : IStaffSalesService
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentTenantContext _tenantContext;

    public StaffSalesService(
        IApplicationDbContext context,
        ICurrentTenantContext tenantContext)
    {
        _context = context;
        _tenantContext = tenantContext;
    }

    public async Task<PagedResult<LeadSummaryDto>> GetPipelineAsync(
        SalesPipelineQuery query,
        CancellationToken cancellationToken = default)
    {
        var tenantId = RequireTenant();
        var branchId = ResolveBranchScope(query.BranchId);
        var statuses = ParseStatusFilter(query.Status);
        var now = DateTime.UtcNow;

        var page = Math.Max(query.Page, 1);
        var pageSize = Math.Clamp(query.PageSize, 1, 100);

        var leads = _context.Enquiries
            .AsNoTracking()
            .Where(e => e.TenantId == tenantId);

        if (branchId.HasValue)
        {
            leads = leads.Where(e => e.BranchId == branchId.Value);
        }

        if (statuses != null)
        {
            leads = leads.Where(e => statuses.Contains(e.Status));
        }

        if (query.AssignedToUserId.HasValue)
        {
            leads = leads.Where(e => e.AssignedSalesExecId == query.AssignedToUserId.Value);
        }

        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var term = query.Search.Trim();
            leads = leads.Where(e =>
                e.Customer!.FirstName.Contains(term)
                || (e.Customer.LastName != null && e.Customer.LastName.Contains(term))
                || e.Customer.Phone.Contains(term)
                || e.Variant!.Name.Contains(term)
                || e.Variant.Model!.Name.Contains(term));
        }

        if (query.FollowUpDue.HasValue)
        {
            leads = query.FollowUpDue.Value
                ? leads.Where(e => e.NextFollowUpAt != null
                                   && e.NextFollowUpAt <= now
                                   && e.Status != EnquiryStatus.Booked
                                   && e.Status != EnquiryStatus.Lost)
                : leads.Where(e => e.NextFollowUpAt == null || e.NextFollowUpAt > now);
        }

        var totalCount = await leads.CountAsync(cancellationToken);

        var rows = await leads
            .OrderByDescending(e => e.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(e => new
            {
                e.Id,
                e.CustomerId,
                CustomerFirstName = e.Customer!.FirstName,
                CustomerLastName = e.Customer.LastName,
                e.Customer.Phone,
                e.Customer.Email,
                e.BranchId,
                BranchName = e.Branch!.Name,
                e.VariantId,
                VariantName = e.Variant!.Name,
                ModelName = e.Variant.Model!.Name,
                e.ColorId,
                ColorName = e.Color != null ? e.Color.ColorName : null,
                e.Status,
                e.Source,
                e.LostReason,
                e.ExpectedPurchaseDate,
                e.CreatedAt,
                e.AssignedSalesExecId,
                AssignedSalesExecutiveName = e.AssignedSalesExec != null ? e.AssignedSalesExec.FullName : null,
                e.LastContactedAt,
                e.NextFollowUpAt,
                FollowUpCount = e.FollowUps.Count,
                UpcomingTestRideAt = e.TestRides
                    .Where(t => t.Status == TestRideStatus.Scheduled)
                    .OrderBy(t => t.ScheduledAt)
                    .Select(t => (DateTime?)t.ScheduledAt)
                    .FirstOrDefault(),
                LatestQuotationNumber = e.Quotations
                    .OrderByDescending(q => q.CreatedAt)
                    .Select(q => q.QuotationNumber)
                    .FirstOrDefault(),
                LatestQuotationOnRoadPrice = e.Quotations
                    .OrderByDescending(q => q.CreatedAt)
                    .Select(q => (decimal?)q.TotalOnRoadPrice)
                    .FirstOrDefault()
            })
            .ToListAsync(cancellationToken);

        var items = rows.Select(row => new LeadSummaryDto
        {
            Id = row.Id,
            CustomerId = row.CustomerId,
            CustomerName = BuildCustomerName(row.CustomerFirstName, row.CustomerLastName),
            Phone = row.Phone,
            Email = row.Email,
            BranchId = row.BranchId,
            BranchName = row.BranchName,
            VariantId = row.VariantId,
            VariantName = row.VariantName,
            ModelName = row.ModelName,
            ColorId = row.ColorId,
            ColorName = row.ColorName,
            Status = row.Status.ToString().ToUpperInvariant(),
            Source = row.Source.ToString().ToUpperInvariant(),
            LostReason = row.LostReason,
            ExpectedPurchaseDate = row.ExpectedPurchaseDate,
            CreatedAt = row.CreatedAt,
            AssignedSalesExecutiveId = row.AssignedSalesExecId,
            AssignedSalesExecutiveName = row.AssignedSalesExecutiveName,
            LastContactedAt = row.LastContactedAt,
            NextFollowUpAt = row.NextFollowUpAt,
            FollowUpDue = row.NextFollowUpAt.HasValue
                          && row.NextFollowUpAt <= now
                          && SalesPipelineRules.IsOpen(row.Status),
            FollowUpCount = row.FollowUpCount,
            UpcomingTestRideAt = row.UpcomingTestRideAt,
            LatestQuotationNumber = row.LatestQuotationNumber,
            LatestQuotationOnRoadPrice = row.LatestQuotationOnRoadPrice
        }).ToList();

        return new PagedResult<LeadSummaryDto>
        {
            Items = items,
            Page = page,
            PageSize = pageSize,
            TotalCount = totalCount
        };
    }

    public async Task<LeadDetailDto> GetLeadAsync(Guid enquiryId, CancellationToken cancellationToken = default)
    {
        var lead = await LoadLeadAsync(enquiryId, tracking: false, cancellationToken);
        EnsureBranchAccess(lead.BranchId);
        return MapLeadDetail(lead);
    }

    public async Task<LeadDetailDto> CaptureLeadAsync(
        LeadCaptureRequest request,
        CancellationToken cancellationToken = default)
    {
        var tenantId = RequireTenant();
        var branch = await ResolveBranchAsync(tenantId, request.BranchId, request.City, cancellationToken);
        var variant = await GetActiveVariantAsync(request.VariantId, request.ColorId, cancellationToken);
        var color = ResolveColor(variant, request.ColorId);
        var customer = await ResolveCustomerAsync(tenantId, request, cancellationToken);

        var assignedExecutiveId = request.AssignedSalesExecutiveId;
        if (assignedExecutiveId.HasValue)
        {
            await EnsureAssignableSalesExecutiveAsync(tenantId, branch.Id, assignedExecutiveId.Value, cancellationToken);
        }
        else
        {
            assignedExecutiveId = (await FindLeastLoadedSalesExecutiveAsync(tenantId, branch.Id, cancellationToken))?.Id;
        }

        var lead = new Enquiry
        {
            TenantId = tenantId,
            BranchId = branch.Id,
            CustomerId = customer.Id,
            VariantId = variant.Id,
            ColorId = color.Id,
            AssignedSalesExecId = assignedExecutiveId,
            Status = EnquiryStatus.New,
            Source = ParseEnum(request.Source, EnquirySource.WalkIn, "source"),
            ExpectedPurchaseDate = ToUtc(request.ExpectedPurchaseDate),
            Notes = Clean(request.Notes)
        };

        _context.Enquiries.Add(lead);
        await _context.SaveChangesAsync(cancellationToken);

        return await GetLeadAsync(lead.Id, cancellationToken);
    }

    public async Task<LeadDetailDto> AssignLeadAsync(
        Guid enquiryId,
        AssignLeadRequest request,
        CancellationToken cancellationToken = default)
    {
        var tenantId = RequireTenant();
        var lead = await LoadLeadAsync(enquiryId, tracking: true, cancellationToken);
        EnsureBranchAccess(lead.BranchId);

        await EnsureAssignableSalesExecutiveAsync(tenantId, lead.BranchId, request.SalesExecutiveId, cancellationToken);

        lead.AssignedSalesExecId = request.SalesExecutiveId;
        if (SalesPipelineRules.IsOpen(lead.Status) && !lead.NextFollowUpAt.HasValue)
        {
            lead.NextFollowUpAt = DateTime.UtcNow.AddDays(1);
        }

        await _context.SaveChangesAsync(cancellationToken);
        return await GetLeadAsync(lead.Id, cancellationToken);
    }

    public async Task<LeadDetailDto> UpdateLeadStatusAsync(
        Guid enquiryId,
        UpdateLeadStatusRequest request,
        CancellationToken cancellationToken = default)
    {
        var lead = await LoadLeadAsync(enquiryId, tracking: true, cancellationToken);
        EnsureBranchAccess(lead.BranchId);

        var target = ParseEnum(request.Status, lead.Status, "status");
        if (!SalesPipelineRules.CanTransition(lead.Status, target))
        {
            throw new ArgumentException($"A lead cannot move from {lead.Status} to {target}.");
        }

        if (target == EnquiryStatus.Lost && string.IsNullOrWhiteSpace(request.LostReason))
        {
            throw new ArgumentException("A reason is required when marking a lead as lost.");
        }

        lead.Status = target;
        lead.LostReason = target == EnquiryStatus.Lost ? Clean(request.LostReason) : null;

        if (target is EnquiryStatus.Booked or EnquiryStatus.Lost)
        {
            lead.NextFollowUpAt = null;
        }

        if (target == EnquiryStatus.Booked)
        {
            lead.LastContactedAt = DateTime.UtcNow;
        }

        var openQuotations = await _context.Quotations
            .Where(q => q.EnquiryId == lead.Id && q.Status == QuotationStatus.Active)
            .ToListAsync(cancellationToken);

        if (target == EnquiryStatus.Booked)
        {
            foreach (var quotation in openQuotations)
            {
                quotation.Status = QuotationStatus.Converted;
            }
        }
        else if (target == EnquiryStatus.Lost)
        {
            foreach (var quotation in openQuotations)
            {
                quotation.Status = QuotationStatus.Expired;
            }
        }

        await _context.SaveChangesAsync(cancellationToken);
        return await GetLeadAsync(lead.Id, cancellationToken);
    }

    public async Task<FollowUpDto> AddFollowUpAsync(
        Guid enquiryId,
        CreateFollowUpRequest request,
        CancellationToken cancellationToken = default)
    {
        var tenantId = RequireTenant();
        var userId = _tenantContext.UserId
                     ?? throw new UnauthorizedAccessException("A signed-in sales executive is required.");

        var lead = await LoadLeadAsync(enquiryId, tracking: true, cancellationToken);
        EnsureBranchAccess(lead.BranchId);

        var channel = ParseEnum(request.Channel, FollowUpChannel.Phone, "channel");
        var outcome = ParseEnum(request.Outcome, FollowUpOutcome.Contacted, "outcome");
        var contactedAt = ToUtc(request.ContactedAt) ?? DateTime.UtcNow;
        var isFinalOutcome = outcome is FollowUpOutcome.Converted
            or FollowUpOutcome.Lost
            or FollowUpOutcome.NotInterested;
        var nextFollowUpAt = isFinalOutcome ? null : ToUtc(request.NextFollowUpAt);

        var followUp = new EnquiryFollowUp
        {
            TenantId = tenantId,
            BranchId = lead.BranchId,
            EnquiryId = lead.Id,
            PerformedByUserId = userId,
            Channel = channel,
            Outcome = outcome,
            Notes = Clean(request.Notes),
            ContactedAt = contactedAt,
            NextFollowUpAt = nextFollowUpAt
        };

        _context.EnquiryFollowUps.Add(followUp);

        lead.LastContactedAt = contactedAt;
        lead.NextFollowUpAt = nextFollowUpAt;

        var mappedStatus = SalesPipelineRules.MapOutcome(outcome);
        if (mappedStatus.HasValue && SalesPipelineRules.CanTransition(lead.Status, mappedStatus.Value))
        {
            lead.Status = mappedStatus.Value;

            if (mappedStatus == EnquiryStatus.Lost)
            {
                lead.LostReason = Clean(request.Notes) ?? "Marked lost during sales follow-up.";
            }
            else
            {
                lead.LostReason = null;
            }

            if (mappedStatus is EnquiryStatus.Booked or EnquiryStatus.Lost)
            {
                lead.NextFollowUpAt = null;
            }
        }

        await _context.SaveChangesAsync(cancellationToken);

        var performedByName = await _context.Users
            .AsNoTracking()
            .Where(u => u.Id == userId)
            .Select(u => u.FullName)
            .FirstOrDefaultAsync(cancellationToken);

        return MapFollowUp(followUp, performedByName);
    }

    public async Task<SalesDashboardDto> GetDashboardAsync(
        Guid? branchId,
        CancellationToken cancellationToken = default)
    {
        var tenantId = RequireTenant();
        var scopeBranchId = ResolveBranchScope(branchId);
        var now = DateTime.UtcNow;
        var todayStart = now.Date;
        var todayEnd = todayStart.AddDays(1);
        var sevenDaysFromNow = now.AddDays(7);

        var leads = _context.Enquiries
            .AsNoTracking()
            .Where(e => e.TenantId == tenantId);

        var testRides = _context.TestRides
            .AsNoTracking()
            .Where(t => t.TenantId == tenantId);

        var quotations = _context.Quotations
            .AsNoTracking()
            .Where(q => q.TenantId == tenantId);

        var branches = _context.Branches
            .AsNoTracking()
            .Where(b => b.TenantId == tenantId && b.IsActive);

        if (scopeBranchId.HasValue)
        {
            leads = leads.Where(e => e.BranchId == scopeBranchId.Value);
            testRides = testRides.Where(t => t.BranchId == scopeBranchId.Value);
            quotations = quotations.Where(q => q.BranchId == scopeBranchId.Value);
            branches = branches.Where(b => b.Id == scopeBranchId.Value);
        }

        var totalLeads = await leads.CountAsync(cancellationToken);
        var openLeads = await leads.CountAsync(
            e => e.Status != EnquiryStatus.Booked && e.Status != EnquiryStatus.Lost,
            cancellationToken);
        var newLeads = await leads.CountAsync(e => e.Status == EnquiryStatus.New, cancellationToken);
        var bookedLeads = await leads.CountAsync(e => e.Status == EnquiryStatus.Booked, cancellationToken);
        var lostLeads = await leads.CountAsync(e => e.Status == EnquiryStatus.Lost, cancellationToken);

        var dueFollowUps = await leads.CountAsync(
            e => e.NextFollowUpAt != null
                 && e.NextFollowUpAt <= now
                 && e.Status != EnquiryStatus.Booked
                 && e.Status != EnquiryStatus.Lost,
            cancellationToken);

        var overdueFollowUps = await leads.CountAsync(
            e => e.NextFollowUpAt != null
                 && e.NextFollowUpAt < todayStart
                 && e.Status != EnquiryStatus.Booked
                 && e.Status != EnquiryStatus.Lost,
            cancellationToken);

        var scheduledTestRides = await testRides.CountAsync(
            t => t.Status == TestRideStatus.Scheduled,
            cancellationToken);
        var testRidesToday = await testRides.CountAsync(
            t => t.Status == TestRideStatus.Scheduled
                 && t.ScheduledAt >= todayStart
                 && t.ScheduledAt < todayEnd,
            cancellationToken);
        var completedTestRides = await testRides.CountAsync(
            t => t.Status == TestRideStatus.Completed,
            cancellationToken);

        var activeQuotations = await quotations.CountAsync(
            q => q.Status == QuotationStatus.Active && q.ValidUntil >= now,
            cancellationToken);
        var expiringQuotations = await quotations.CountAsync(
            q => q.Status == QuotationStatus.Active
                 && q.ValidUntil >= now
                 && q.ValidUntil <= sevenDaysFromNow,
            cancellationToken);

        var stageCounts = await leads
            .GroupBy(e => e.Status)
            .Select(g => new { Status = g.Key, Count = g.Count() })
            .ToListAsync(cancellationToken);

        var branchLeadCounts = await leads
            .GroupBy(e => e.BranchId)
            .Select(g => new
            {
                BranchId = g.Key,
                OpenLeads = g.Count(e => e.Status != EnquiryStatus.Booked && e.Status != EnquiryStatus.Lost),
                DueFollowUps = g.Count(e => e.NextFollowUpAt != null
                                             && e.NextFollowUpAt <= now
                                             && e.Status != EnquiryStatus.Booked
                                             && e.Status != EnquiryStatus.Lost)
            })
            .ToListAsync(cancellationToken);

        var branchTestRideCounts = await testRides
            .GroupBy(t => t.BranchId)
            .Select(g => new
            {
                BranchId = g.Key,
                Scheduled = g.Count(t => t.Status == TestRideStatus.Scheduled)
            })
            .ToListAsync(cancellationToken);

        var branchQuotationCounts = await quotations
            .GroupBy(q => q.BranchId)
            .Select(g => new
            {
                BranchId = g.Key,
                Active = g.Count(q => q.Status == QuotationStatus.Active && q.ValidUntil >= now)
            })
            .ToListAsync(cancellationToken);

        var branchList = await branches
            .OrderByDescending(b => b.IsHeadquarters)
            .ThenBy(b => b.Name)
            .Select(b => new { b.Id, b.Name })
            .ToListAsync(cancellationToken);

        var pipeline = Enum.GetValues<EnquiryStatus>()
            .Select(status => new SalesPipelineStageDto
            {
                Status = status.ToString().ToUpperInvariant(),
                Count = stageCounts.FirstOrDefault(c => c.Status == status)?.Count ?? 0
            })
            .ToList();

        var branchSnapshots = branchList.Select(branch => new BranchSalesSnapshotDto
        {
            BranchId = branch.Id,
            BranchName = branch.Name,
            OpenLeads = branchLeadCounts.FirstOrDefault(c => c.BranchId == branch.Id)?.OpenLeads ?? 0,
            DueFollowUps = branchLeadCounts.FirstOrDefault(c => c.BranchId == branch.Id)?.DueFollowUps ?? 0,
            ScheduledTestRides = branchTestRideCounts.FirstOrDefault(c => c.BranchId == branch.Id)?.Scheduled ?? 0,
            ActiveQuotations = branchQuotationCounts.FirstOrDefault(c => c.BranchId == branch.Id)?.Active ?? 0
        }).ToList();

        return new SalesDashboardDto
        {
            TotalLeads = totalLeads,
            OpenLeads = openLeads,
            NewLeads = newLeads,
            BookedLeads = bookedLeads,
            LostLeads = lostLeads,
            DueFollowUps = dueFollowUps,
            OverdueFollowUps = overdueFollowUps,
            TestRidesToday = testRidesToday,
            ScheduledTestRides = scheduledTestRides,
            CompletedTestRides = completedTestRides,
            ActiveQuotations = activeQuotations,
            QuotationsExpiringInSevenDays = expiringQuotations,
            ConversionRate = totalLeads == 0
                ? 0m
                : Math.Round(bookedLeads * 100m / totalLeads, 1, MidpointRounding.AwayFromZero),
            GeneratedAt = now,
            Pipeline = pipeline,
            Branches = branchSnapshots
        };
    }

    public async Task<List<SalesExecutiveDto>> GetSalesExecutivesAsync(
        Guid? branchId,
        CancellationToken cancellationToken = default)
    {
        var tenantId = RequireTenant();
        var scopeBranchId = ResolveBranchScope(branchId);

        var users = await _context.Users
            .Include(u => u.DefaultBranch)
            .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
            .AsNoTracking()
            .Where(u => u.TenantId == tenantId && u.IsActive && u.UserType == UserType.DealerStaff)
            .ToListAsync(cancellationToken);

        users = users
            .Where(u => u.UserRoles.Any(ur => ur.Role != null && SalesAssignmentRules.IsSalesRole(ur.Role.Name)))
            .Where(u => !scopeBranchId.HasValue
                        || u.DefaultBranchId == scopeBranchId
                        || u.UserRoles.Any(ur => ur.BranchId == scopeBranchId))
            .OrderBy(u => u.FullName)
            .ToList();

        var userIds = users.Select(u => u.Id).ToList();
        var openLeadCounts = await _context.Enquiries
            .AsNoTracking()
            .Where(e => e.AssignedSalesExecId != null
                        && userIds.Contains(e.AssignedSalesExecId.Value)
                        && e.Status != EnquiryStatus.Booked
                        && e.Status != EnquiryStatus.Lost)
            .GroupBy(e => e.AssignedSalesExecId!.Value)
            .Select(g => new { UserId = g.Key, Count = g.Count() })
            .ToListAsync(cancellationToken);

        var countByUser = openLeadCounts.ToDictionary(x => x.UserId, x => x.Count);

        return users.Select(user => new SalesExecutiveDto
        {
            Id = user.Id,
            FullName = user.FullName,
            Username = user.Username,
            Email = user.Email,
            Phone = user.Phone,
            BranchId = user.DefaultBranchId,
            BranchName = user.DefaultBranch?.Name,
            Roles = user.UserRoles
                .Where(ur => ur.Role != null)
                .Select(ur => ur.Role!.Name)
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .OrderBy(name => name)
                .ToList(),
            OpenLeads = countByUser.GetValueOrDefault(user.Id)
        }).ToList();
    }

    public async Task<List<StaffTestRideDto>> GetTestRideQueueAsync(
        TestRideQueueQuery query,
        CancellationToken cancellationToken = default)
    {
        var tenantId = RequireTenant();
        var branchId = ResolveBranchScope(query.BranchId);
        var status = string.IsNullOrWhiteSpace(query.Status)
            ? (TestRideStatus?)null
            : ParseEnum(query.Status, TestRideStatus.Scheduled, "status");

        var testRides = _context.TestRides
            .Include(t => t.Branch)
            .Include(t => t.Customer)
            .Include(t => t.Variant)
                .ThenInclude(v => v!.Model)
            .Include(t => t.Enquiry)
                .ThenInclude(e => e!.AssignedSalesExec)
            .AsNoTracking()
            .Where(t => t.TenantId == tenantId);

        if (branchId.HasValue)
        {
            testRides = testRides.Where(t => t.BranchId == branchId.Value);
        }

        if (status.HasValue)
        {
            testRides = testRides.Where(t => t.Status == status.Value);
        }

        if (query.From.HasValue)
        {
            var from = query.From.Value.ToUniversalTime();
            testRides = testRides.Where(t => t.ScheduledAt >= from);
        }

        if (query.To.HasValue)
        {
            var to = query.To.Value.ToUniversalTime();
            testRides = testRides.Where(t => t.ScheduledAt <= to);
        }

        var results = await testRides
            .OrderBy(t => t.ScheduledAt)
            .ToListAsync(cancellationToken);

        return results.Select(MapStaffTestRide).ToList();
    }

    public async Task<StaffTestRideDto> CompleteTestRideAsync(
        Guid testRideId,
        CompleteTestRideRequest request,
        CancellationToken cancellationToken = default)
    {
        var testRide = await LoadTestRideAsync(testRideId, cancellationToken);
        EnsureBranchAccess(testRide.BranchId);

        if (testRide.Status != TestRideStatus.Scheduled)
        {
            throw new InvalidOperationException($"Only a scheduled test ride can be completed. Current status: {testRide.Status}.");
        }

        var license = Clean(testRide.DrivingLicenseNumber) ?? Clean(request.DrivingLicenseNumber);
        if (!request.DrivingLicenseVerified || string.IsNullOrWhiteSpace(license))
        {
            throw new ArgumentException("Verify the customer's driving licence number before completing the test ride.");
        }

        testRide.DrivingLicenseNumber = license.ToUpperInvariant();
        testRide.Status = TestRideStatus.Completed;
        testRide.CompletedAt = DateTime.UtcNow;
        testRide.FeedbackNotes = Clean(request.FeedbackNotes);

        if (testRide.Enquiry != null && testRide.Enquiry.Status == EnquiryStatus.TestRide)
        {
            testRide.Enquiry.Status = EnquiryStatus.Contacted;
            testRide.Enquiry.LastContactedAt = DateTime.UtcNow;
            testRide.Enquiry.NextFollowUpAt ??= DateTime.UtcNow.AddDays(1);
        }

        await _context.SaveChangesAsync(cancellationToken);
        return MapStaffTestRide(testRide);
    }

    public async Task<StaffTestRideDto> CancelTestRideAsync(
        Guid testRideId,
        CancelTestRideRequest request,
        CancellationToken cancellationToken = default)
    {
        var testRide = await LoadTestRideAsync(testRideId, cancellationToken);
        EnsureBranchAccess(testRide.BranchId);
        EnsureTestRideIsScheduled(testRide);

        testRide.Status = TestRideStatus.Cancelled;
        testRide.FeedbackNotes = Clean(request.Reason);
        CancelFollowUp(testRide);

        await _context.SaveChangesAsync(cancellationToken);
        return MapStaffTestRide(testRide);
    }

    public async Task<StaffTestRideDto> MarkTestRideNoShowAsync(
        Guid testRideId,
        CancellationToken cancellationToken = default)
    {
        var testRide = await LoadTestRideAsync(testRideId, cancellationToken);
        EnsureBranchAccess(testRide.BranchId);
        EnsureTestRideIsScheduled(testRide);

        testRide.Status = TestRideStatus.NoShow;
        testRide.FeedbackNotes = Clean(testRide.FeedbackNotes) ?? "Customer did not attend the scheduled test ride.";
        CancelFollowUp(testRide);

        await _context.SaveChangesAsync(cancellationToken);
        return MapStaffTestRide(testRide);
    }

    private static void EnsureTestRideIsScheduled(TestRide testRide)
    {
        if (testRide.Status != TestRideStatus.Scheduled)
        {
            throw new InvalidOperationException(
                $"Only a scheduled test ride can be updated. Current status: {testRide.Status}.");
        }
    }

    private static void CancelFollowUp(TestRide testRide)
    {
        if (testRide.Enquiry != null && testRide.Enquiry.Status == EnquiryStatus.TestRide)
        {
            testRide.Enquiry.Status = EnquiryStatus.Contacted;
            testRide.Enquiry.NextFollowUpAt = DateTime.UtcNow.AddDays(1);
        }
    }

    private async Task<TestRide> LoadTestRideAsync(Guid testRideId, CancellationToken cancellationToken)
    {
        var testRide = await _context.TestRides
            .Include(t => t.Branch)
            .Include(t => t.Customer)
            .Include(t => t.Variant)
                .ThenInclude(v => v!.Model)
            .Include(t => t.Enquiry)
                .ThenInclude(e => e!.AssignedSalesExec)
            .FirstOrDefaultAsync(t => t.Id == testRideId, cancellationToken);

        return testRide ?? throw new KeyNotFoundException("The test ride was not found.");
    }

    private async Task<Enquiry> LoadLeadAsync(
        Guid enquiryId,
        bool tracking,
        CancellationToken cancellationToken)
    {
        IQueryable<Enquiry> query = tracking
            ? _context.Enquiries
            : _context.Enquiries.AsNoTracking();

        query = query
            .Include(e => e.Branch)
            .Include(e => e.Customer)
            .Include(e => e.Variant)
                .ThenInclude(v => v!.Model)
            .Include(e => e.Color)
            .Include(e => e.AssignedSalesExec)
            .Include(e => e.FollowUps)
                .ThenInclude(f => f.PerformedByUser)
            .Include(e => e.TestRides)
            .Include(e => e.Quotations)
            .AsSplitQuery();

        var lead = await query.FirstOrDefaultAsync(e => e.Id == enquiryId, cancellationToken);
        return lead ?? throw new KeyNotFoundException("The sales lead was not found.");
    }

    private async Task<Branch> ResolveBranchAsync(
        Guid tenantId,
        Guid? requestedBranchId,
        string? customerCity,
        CancellationToken cancellationToken)
    {
        var branches = _context.Branches
            .AsNoTracking()
            .Where(b => b.TenantId == tenantId && b.IsActive);

        if (requestedBranchId.HasValue)
        {
            return await branches.FirstOrDefaultAsync(b => b.Id == requestedBranchId.Value, cancellationToken)
                   ?? throw new ArgumentException("The selected dealership branch is not available.");
        }

        if (_tenantContext.BranchId.HasValue)
        {
            var scopedBranch = await branches
                .FirstOrDefaultAsync(b => b.Id == _tenantContext.BranchId.Value, cancellationToken);
            if (scopedBranch != null)
            {
                return scopedBranch;
            }
        }

        if (!string.IsNullOrWhiteSpace(customerCity))
        {
            var city = customerCity.Trim().ToLowerInvariant();
            var cityBranch = await branches
                .Where(b => b.City.ToLower() == city)
                .OrderByDescending(b => b.IsHeadquarters)
                .FirstOrDefaultAsync(cancellationToken);
            if (cityBranch != null)
            {
                return cityBranch;
            }
        }

        return await branches
                   .OrderByDescending(b => b.IsHeadquarters)
                   .ThenBy(b => b.Code)
                   .FirstOrDefaultAsync(cancellationToken)
               ?? throw new InvalidOperationException("No active dealership branch is available to receive this lead.");
    }

    private async Task<VehicleVariant> GetActiveVariantAsync(
        Guid variantId,
        Guid? colorId,
        CancellationToken cancellationToken)
    {
        var variant = await _context.VehicleVariants
            .Include(v => v.Model)
            .Include(v => v.Colors)
            .AsNoTracking()
            .FirstOrDefaultAsync(v => v.Id == variantId && v.IsActive, cancellationToken)
            ?? throw new ArgumentException("The selected vehicle variant is not available.");

        if (colorId.HasValue && variant.Colors.All(c => c.Id != colorId.Value))
        {
            throw new ArgumentException("The selected colour is not offered for this variant.");
        }

        return variant;
    }

    private static VehicleColor ResolveColor(VehicleVariant variant, Guid? colorId)
    {
        var color = colorId.HasValue
            ? variant.Colors.FirstOrDefault(c => c.Id == colorId.Value)
            : variant.Colors.FirstOrDefault(c => c.IsPrimary) ?? variant.Colors.FirstOrDefault();

        return color ?? throw new ArgumentException("The selected vehicle variant has no colours configured.");
    }

    private async Task<Customer> ResolveCustomerAsync(
        Guid tenantId,
        LeadCaptureRequest request,
        CancellationToken cancellationToken)
    {
        var phone = CustomerSalesService.NormalizePhone(request.Phone);
        if (string.IsNullOrWhiteSpace(phone))
        {
            throw new ArgumentException("Customer mobile number is required.");
        }

        var customer = await _context.Customers
            .FirstOrDefaultAsync(c => c.TenantId == tenantId && c.Phone == phone, cancellationToken);

        if (customer == null)
        {
            customer = new Customer
            {
                TenantId = tenantId,
                FirstName = request.FirstName.Trim(),
                LastName = Clean(request.LastName),
                Phone = phone,
                Email = Clean(request.Email)?.ToLowerInvariant(),
                City = Clean(request.City)
            };
            _context.Customers.Add(customer);
        }
        else
        {
            if (string.IsNullOrWhiteSpace(customer.FirstName) || customer.FirstName == "Customer")
            {
                customer.FirstName = request.FirstName.Trim();
            }

            if (string.IsNullOrWhiteSpace(customer.LastName) && !string.IsNullOrWhiteSpace(request.LastName))
            {
                customer.LastName = request.LastName.Trim();
            }

            if (string.IsNullOrWhiteSpace(customer.Email) && !string.IsNullOrWhiteSpace(request.Email))
            {
                customer.Email = request.Email.Trim().ToLowerInvariant();
            }

            if (string.IsNullOrWhiteSpace(customer.City) && !string.IsNullOrWhiteSpace(request.City))
            {
                customer.City = request.City.Trim();
            }
        }

        await _context.SaveChangesAsync(cancellationToken);
        return customer;
    }

    private async Task EnsureAssignableSalesExecutiveAsync(
        Guid tenantId,
        Guid branchId,
        Guid userId,
        CancellationToken cancellationToken)
    {
        var user = await _context.Users
            .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == userId
                                      && u.TenantId == tenantId
                                      && u.IsActive
                                      && u.UserType == UserType.DealerStaff,
                cancellationToken);

        if (user == null)
        {
            throw new ArgumentException("The selected sales executive is not an active staff member of this dealership.");
        }

        var isSalesRole = user.UserRoles.Any(ur => ur.Role != null && SalesAssignmentRules.IsSalesRole(ur.Role.Name));
        if (!isSalesRole)
        {
            throw new ArgumentException("The selected staff member does not hold a sales role.");
        }

        if (user.DefaultBranchId.HasValue && user.DefaultBranchId.Value != branchId)
        {
            throw new ArgumentException("The selected sales executive belongs to a different branch.");
        }
    }

    private async Task<User?> FindLeastLoadedSalesExecutiveAsync(
        Guid tenantId,
        Guid branchId,
        CancellationToken cancellationToken)
    {
        var candidates = await _context.Users
            .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
            .AsNoTracking()
            .Where(u => u.TenantId == tenantId && u.IsActive && u.UserType == UserType.DealerStaff)
            .ToListAsync(cancellationToken);

        candidates = candidates
            .Where(u => u.UserRoles.Any(ur => ur.Role != null && SalesAssignmentRules.IsSalesRole(ur.Role.Name)))
            .OrderBy(u => u.DefaultBranchId == branchId ? 0 : 1)
            .ThenBy(u => u.FullName)
            .ToList();

        if (candidates.Count == 0)
        {
            return null;
        }

        var userIds = candidates.Select(u => u.Id).ToList();
        var openLeadCounts = await _context.Enquiries
            .AsNoTracking()
            .Where(e => e.AssignedSalesExecId != null
                        && userIds.Contains(e.AssignedSalesExecId.Value)
                        && e.Status != EnquiryStatus.Booked
                        && e.Status != EnquiryStatus.Lost)
            .GroupBy(e => e.AssignedSalesExecId!.Value)
            .Select(g => new { UserId = g.Key, Count = g.Count() })
            .ToListAsync(cancellationToken);

        var countByUser = openLeadCounts.ToDictionary(x => x.UserId, x => x.Count);

        return candidates
            .OrderBy(SalesAssignmentRules.GetRoleRank)
            .ThenBy(u => countByUser.GetValueOrDefault(u.Id))
            .ThenBy(u => u.DefaultBranchId == branchId ? 0 : 1)
            .ThenBy(u => u.FullName)
            .First();
    }

    private Guid RequireTenant()
    {
        return _tenantContext.TenantId
               ?? throw new UnauthorizedAccessException("A dealership context is required for sales operations.");
    }

    private Guid? ResolveBranchScope(Guid? requestedBranchId)
    {
        if (_tenantContext.IsSuperAdmin)
        {
            return requestedBranchId;
        }

        return _tenantContext.BranchId ?? requestedBranchId;
    }

    private void EnsureBranchAccess(Guid branchId)
    {
        if (!_tenantContext.IsSuperAdmin
            && _tenantContext.BranchId.HasValue
            && _tenantContext.BranchId.Value != branchId)
        {
            throw new UnauthorizedAccessException("You can only access sales records for your assigned branch.");
        }
    }

    private static List<EnquiryStatus>? ParseStatusFilter(string? status)
    {
        if (string.IsNullOrWhiteSpace(status))
        {
            return null;
        }

        var result = new List<EnquiryStatus>();
        foreach (var token in status.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
        {
            var parsed = ParseEnum(token, EnquiryStatus.New, "status");

            if (!result.Contains(parsed))
            {
                result.Add(parsed);
            }
        }

        return result.Count == 0 ? null : result;
    }

    private static TEnum ParseEnum<TEnum>(string? value, TEnum fallback, string fieldName)
        where TEnum : struct, Enum
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return fallback;
        }

        if (!Enum.TryParse<TEnum>(value, true, out var parsed) || !Enum.IsDefined(parsed))
        {
            throw new ArgumentException($"'{value}' is not a valid {fieldName}.");
        }

        return parsed;
    }

    private static DateTime? ToUtc(DateTime? value) =>
        value.HasValue ? value.Value.ToUniversalTime() : null;

    private static string? Clean(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private static string BuildCustomerName(string firstName, string? lastName) =>
        string.Join(' ', new[] { firstName, lastName }.Where(part => !string.IsNullOrWhiteSpace(part)));

    private static LeadDetailDto MapLeadDetail(Enquiry lead)
    {
        var now = DateTime.UtcNow;
        var summary = new LeadSummaryDto
        {
            Id = lead.Id,
            CustomerId = lead.CustomerId,
            CustomerName = BuildCustomerName(lead.Customer?.FirstName ?? string.Empty, lead.Customer?.LastName),
            Phone = lead.Customer?.Phone ?? string.Empty,
            Email = lead.Customer?.Email,
            BranchId = lead.BranchId,
            BranchName = lead.Branch?.Name ?? string.Empty,
            VariantId = lead.VariantId,
            VariantName = lead.Variant?.Name ?? string.Empty,
            ModelName = lead.Variant?.Model?.Name ?? string.Empty,
            ColorId = lead.ColorId,
            ColorName = lead.Color?.ColorName,
            Status = lead.Status.ToString().ToUpperInvariant(),
            Source = lead.Source.ToString().ToUpperInvariant(),
            LostReason = lead.LostReason,
            ExpectedPurchaseDate = lead.ExpectedPurchaseDate,
            CreatedAt = lead.CreatedAt,
            AssignedSalesExecutiveId = lead.AssignedSalesExecId,
            AssignedSalesExecutiveName = lead.AssignedSalesExec?.FullName,
            LastContactedAt = lead.LastContactedAt,
            NextFollowUpAt = lead.NextFollowUpAt,
            FollowUpDue = lead.NextFollowUpAt.HasValue
                          && lead.NextFollowUpAt <= now
                          && SalesPipelineRules.IsOpen(lead.Status),
            FollowUpCount = lead.FollowUps.Count,
            UpcomingTestRideAt = lead.TestRides
                .Where(t => t.Status == TestRideStatus.Scheduled)
                .OrderBy(t => t.ScheduledAt)
                .Select(t => (DateTime?)t.ScheduledAt)
                .FirstOrDefault(),
            LatestQuotationNumber = lead.Quotations
                .OrderByDescending(q => q.CreatedAt)
                .Select(q => q.QuotationNumber)
                .FirstOrDefault(),
            LatestQuotationOnRoadPrice = lead.Quotations
                .OrderByDescending(q => q.CreatedAt)
                .Select(q => (decimal?)q.TotalOnRoadPrice)
                .FirstOrDefault()
        };

        return new LeadDetailDto
        {
            Id = summary.Id,
            CustomerId = summary.CustomerId,
            CustomerName = summary.CustomerName,
            Phone = summary.Phone,
            Email = summary.Email,
            BranchId = summary.BranchId,
            BranchName = summary.BranchName,
            VariantId = summary.VariantId,
            VariantName = summary.VariantName,
            ModelName = summary.ModelName,
            ColorId = summary.ColorId,
            ColorName = summary.ColorName,
            Status = summary.Status,
            Source = summary.Source,
            LostReason = summary.LostReason,
            ExpectedPurchaseDate = summary.ExpectedPurchaseDate,
            CreatedAt = summary.CreatedAt,
            AssignedSalesExecutiveId = summary.AssignedSalesExecutiveId,
            AssignedSalesExecutiveName = summary.AssignedSalesExecutiveName,
            LastContactedAt = summary.LastContactedAt,
            NextFollowUpAt = summary.NextFollowUpAt,
            FollowUpDue = summary.FollowUpDue,
            FollowUpCount = summary.FollowUpCount,
            UpcomingTestRideAt = summary.UpcomingTestRideAt,
            LatestQuotationNumber = summary.LatestQuotationNumber,
            LatestQuotationOnRoadPrice = summary.LatestQuotationOnRoadPrice,
            Notes = lead.Notes,
            FollowUps = lead.FollowUps
                .OrderByDescending(f => f.ContactedAt)
                .Select(f => MapFollowUp(f, f.PerformedByUser?.FullName))
                .ToList(),
            TestRides = lead.TestRides
                .OrderByDescending(t => t.ScheduledAt)
                .Select(MapTestRideSummary)
                .ToList(),
            Quotations = lead.Quotations
                .OrderByDescending(q => q.CreatedAt)
                .Select(q => new QuotationSummaryDto
                {
                    Id = q.Id,
                    QuotationNumber = q.QuotationNumber,
                    Status = q.Status.ToString().ToUpperInvariant(),
                    TotalOnRoadPrice = q.TotalOnRoadPrice,
                    ValidUntil = q.ValidUntil,
                    CreatedAt = q.CreatedAt
                })
                .ToList()
        };
    }

    private static FollowUpDto MapFollowUp(EnquiryFollowUp followUp, string? performedByName) => new()
    {
        Id = followUp.Id,
        EnquiryId = followUp.EnquiryId,
        Channel = followUp.Channel.ToString().ToUpperInvariant(),
        Outcome = followUp.Outcome.ToString().ToUpperInvariant(),
        Notes = followUp.Notes,
        ContactedAt = followUp.ContactedAt,
        NextFollowUpAt = followUp.NextFollowUpAt,
        PerformedByUserId = followUp.PerformedByUserId,
        PerformedByName = performedByName
    };

    private static TestRideSummaryDto MapTestRideSummary(TestRide testRide) => new()
    {
        Id = testRide.Id,
        ScheduledAt = testRide.ScheduledAt,
        CompletedAt = testRide.CompletedAt,
        Status = testRide.Status.ToString().ToUpperInvariant(),
        DrivingLicenseNumber = testRide.DrivingLicenseNumber,
        FeedbackNotes = testRide.FeedbackNotes
    };

    private static StaffTestRideDto MapStaffTestRide(TestRide testRide) => new()
    {
        Id = testRide.Id,
        EnquiryId = testRide.EnquiryId,
        CustomerId = testRide.CustomerId,
        CustomerName = BuildCustomerName(
            testRide.Customer?.FirstName ?? string.Empty,
            testRide.Customer?.LastName),
        Phone = testRide.Customer?.Phone ?? string.Empty,
        BranchId = testRide.BranchId,
        BranchName = testRide.Branch?.Name ?? string.Empty,
        VariantId = testRide.VariantId,
        VariantName = testRide.Variant?.Name ?? string.Empty,
        ModelName = testRide.Variant?.Model?.Name ?? string.Empty,
        ScheduledAt = testRide.ScheduledAt,
        CompletedAt = testRide.CompletedAt,
        Status = testRide.Status.ToString().ToUpperInvariant(),
        DrivingLicenseNumber = testRide.DrivingLicenseNumber,
        FeedbackNotes = testRide.FeedbackNotes,
        AssignedSalesExecutiveName = testRide.Enquiry?.AssignedSalesExec?.FullName,
        CreatedAt = testRide.CreatedAt
    };
}
