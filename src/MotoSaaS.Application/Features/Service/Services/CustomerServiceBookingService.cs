using Microsoft.EntityFrameworkCore;
using MotoSaaS.Application.Common.Interfaces;
using MotoSaaS.Application.Features.Service.Interfaces;
using MotoSaaS.Application.Features.Service.Models;
using MotoSaaS.Domain.Service;

namespace MotoSaaS.Application.Features.Service.Services;

public class CustomerServiceBookingService : ICustomerServiceBookingService
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentTenantContext _tenantContext;

    private static readonly string[] JobCardStages =
    {
        "Vehicle received",
        "Estimate prepared",
        "Estimate approved",
        "Technician assigned",
        "Work in progress",
        "Quality check",
        "Ready for delivery",
        "Billed",
        "Closed"
    };

    public CustomerServiceBookingService(
        IApplicationDbContext context,
        ICurrentTenantContext tenantContext)
    {
        _context = context;
        _tenantContext = tenantContext;
    }

    public async Task<List<CustomerVehicleDto>> GetMyVehiclesAsync(CancellationToken cancellationToken = default)
    {
        var customerId = GetCustomerId();

        var vehicles = await _context.CustomerVehicles
            .Include(v => v.Variant)
                .ThenInclude(v => v!.Model)
            .Include(v => v.Variant)
                .ThenInclude(v => v!.Colors)
            .AsNoTracking()
            .Where(v => v.CustomerId == customerId)
            .OrderByDescending(v => v.DeliveryDate)
            .ThenBy(v => v.RegistrationNumber)
            .ToListAsync(cancellationToken);

        if (vehicles.Count == 0)
        {
            return new List<CustomerVehicleDto>();
        }

        var vehicleIds = vehicles.Select(v => v.Id).ToList();
        var recentBookings = await _context.ServiceBookings
            .AsNoTracking()
            .Where(b => vehicleIds.Contains(b.CustomerVehicleId))
            .OrderByDescending(b => b.ScheduledDate)
            .ToListAsync(cancellationToken);

        var latestByVehicle = recentBookings
            .GroupBy(b => b.CustomerVehicleId)
            .ToDictionary(g => g.Key, g => g.First());

        return vehicles.Select(v =>
        {
            latestByVehicle.TryGetValue(v.Id, out var latestBooking);
            var primaryColor = v.Variant?.Colors.FirstOrDefault(c => c.IsPrimary)
                               ?? v.Variant?.Colors.FirstOrDefault();

            return new CustomerVehicleDto
            {
                Id = v.Id,
                VariantId = v.VariantId,
                ModelName = v.Variant?.Model?.Name ?? string.Empty,
                VariantName = v.Variant?.Name ?? string.Empty,
                RegistrationNumber = v.RegistrationNumber,
                ChassisNumberMasked = Mask(v.ChassisNumber),
                EngineNumberMasked = Mask(v.EngineNumber),
                DeliveryDate = v.DeliveryDate,
                HeroImageUrl = primaryColor?.ImageUrl,
                LastServiceDate = latestBooking?.ScheduledDate,
                LastServiceStatus = latestBooking?.Status
            };
        }).ToList();
    }

    public async Task<List<ServiceBookingDto>> GetMyBookingsAsync(CancellationToken cancellationToken = default)
    {
        var customerId = GetCustomerId();

        var bookings = await _context.ServiceBookings
            .Include(b => b.Branch)
            .Include(b => b.CustomerVehicle)
                .ThenInclude(v => v!.Variant)
                    .ThenInclude(v => v!.Model)
            .AsNoTracking()
            .Where(b => b.CustomerVehicle != null && b.CustomerVehicle.CustomerId == customerId)
            .OrderByDescending(b => b.ScheduledDate)
            .ToListAsync(cancellationToken);

        if (bookings.Count == 0)
        {
            return new List<ServiceBookingDto>();
        }

        var bookingIds = bookings.Select(b => b.Id).ToList();
        var jobCards = await _context.JobCards
            .AsNoTracking()
            .Where(j => j.ServiceBookingId.HasValue && bookingIds.Contains(j.ServiceBookingId.Value))
            .ToListAsync(cancellationToken);

        var jobCardByBooking = jobCards
            .GroupBy(j => j.ServiceBookingId!.Value)
            .ToDictionary(g => g.Key, g => g.OrderByDescending(j => j.CreatedAt).First());

        return bookings.Select(b => MapBooking(b, jobCardByBooking.GetValueOrDefault(b.Id))).ToList();
    }

    public async Task<ServiceBookingDto> CreateBookingAsync(
        CreateServiceBookingRequest request,
        CancellationToken cancellationToken = default)
    {
        var customerId = GetCustomerId();
        var tenantId = _tenantContext.TenantId
                       ?? throw new UnauthorizedAccessException("Dealership context could not be resolved.");

        var vehicle = await _context.CustomerVehicles
            .Include(v => v.Variant)
                .ThenInclude(v => v!.Model)
            .AsNoTracking()
            .FirstOrDefaultAsync(v => v.Id == request.CustomerVehicleId && v.CustomerId == customerId, cancellationToken)
            ?? throw new KeyNotFoundException("The selected vehicle was not found in your garage.");

        var branch = await _context.Branches
            .AsNoTracking()
            .FirstOrDefaultAsync(b => b.Id == request.BranchId && b.TenantId == tenantId && b.IsActive, cancellationToken)
            ?? throw new ArgumentException("The selected service branch is not available.");

        var serviceType = request.ServiceType.Trim().ToUpperInvariant();

        var booking = new ServiceBooking
        {
            TenantId = tenantId,
            BranchId = branch.Id,
            CustomerVehicleId = vehicle.Id,
            ServiceType = serviceType,
            ScheduledDate = DateTime.SpecifyKind(request.ScheduledDate.Date, DateTimeKind.Utc),
            TimeSlot = request.TimeSlot.Trim(),
            CustomerComplaints = string.IsNullOrWhiteSpace(request.CustomerComplaints)
                ? null
                : request.CustomerComplaints.Trim(),
            Status = "BOOKED"
        };

        _context.ServiceBookings.Add(booking);
        await _context.SaveChangesAsync(cancellationToken);

        return new ServiceBookingDto
        {
            Id = booking.Id,
            BranchId = branch.Id,
            BranchName = branch.Name,
            CustomerVehicleId = vehicle.Id,
            RegistrationNumber = vehicle.RegistrationNumber,
            ModelName = vehicle.Variant?.Model?.Name ?? string.Empty,
            VariantName = vehicle.Variant?.Name ?? string.Empty,
            ServiceType = booking.ServiceType,
            ScheduledDate = booking.ScheduledDate,
            TimeSlot = booking.TimeSlot,
            Status = booking.Status,
            CreatedAt = booking.CreatedAt
        };
    }

    public async Task<ServiceTrackingDto> GetTrackingAsync(Guid bookingId, CancellationToken cancellationToken = default)
    {
        var customerId = GetCustomerId();

        var booking = await _context.ServiceBookings
            .Include(b => b.Branch)
            .Include(b => b.CustomerVehicle)
                .ThenInclude(v => v!.Variant)
                    .ThenInclude(v => v!.Model)
            .AsNoTracking()
            .FirstOrDefaultAsync(b => b.Id == bookingId
                                      && b.CustomerVehicle != null
                                      && b.CustomerVehicle.CustomerId == customerId, cancellationToken)
            ?? throw new KeyNotFoundException("Service booking not found.");

        var jobCard = await _context.JobCards
            .Include(j => j.Items)
            .Include(j => j.Technician)
            .AsNoTracking()
            .Where(j => j.ServiceBookingId == bookingId)
            .OrderByDescending(j => j.CreatedAt)
            .FirstOrDefaultAsync(cancellationToken);

        if (jobCard == null)
        {
            jobCard = await _context.JobCards
                .Include(j => j.Items)
                .Include(j => j.Technician)
                .AsNoTracking()
                .Where(j => j.CustomerVehicleId == booking.CustomerVehicleId
                            && j.Status != JobCardStatus.Closed)
                .OrderByDescending(j => j.CreatedAt)
                .FirstOrDefaultAsync(cancellationToken);
        }

        return BuildTracking(booking, jobCard);
    }

    public async Task<ServiceTrackingDto> ApproveEstimateAsync(Guid jobCardId, CancellationToken cancellationToken = default)
    {
        var customerId = GetCustomerId();

        var jobCard = await _context.JobCards
            .Include(j => j.Items)
            .Include(j => j.Technician)
            .Include(j => j.CustomerVehicle)
            .FirstOrDefaultAsync(j => j.Id == jobCardId
                                      && j.CustomerVehicle != null
                                      && j.CustomerVehicle.CustomerId == customerId, cancellationToken)
            ?? throw new KeyNotFoundException("Job card not found.");

        if (!jobCard.CustomerApproved)
        {
            if (jobCard.Status != JobCardStatus.Estimated && jobCard.Status != JobCardStatus.Open)
            {
                throw new ArgumentException("This estimate is no longer awaiting approval.");
            }

            jobCard.CustomerApproved = true;
            jobCard.Status = JobCardStatus.Approved;
            foreach (var item in jobCard.Items)
            {
                item.IsApproved = true;
            }

            await _context.SaveChangesAsync(cancellationToken);
        }

        if (!jobCard.ServiceBookingId.HasValue)
        {
            throw new ArgumentException("This job card is not linked to a service appointment.");
        }

        return await GetTrackingAsync(jobCard.ServiceBookingId.Value, cancellationToken);
    }

    private Guid GetCustomerId()
    {
        if (string.Equals(_tenantContext.UserType, "CUSTOMER", StringComparison.OrdinalIgnoreCase)
            && _tenantContext.UserId.HasValue)
        {
            return _tenantContext.UserId.Value;
        }

        throw new UnauthorizedAccessException("Please sign in with your mobile number to view your garage.");
    }

    private static ServiceBookingDto MapBooking(ServiceBooking booking, JobCard? jobCard) =>
        new()
        {
            Id = booking.Id,
            BranchId = booking.BranchId,
            BranchName = booking.Branch?.Name ?? string.Empty,
            CustomerVehicleId = booking.CustomerVehicleId,
            RegistrationNumber = booking.CustomerVehicle?.RegistrationNumber ?? string.Empty,
            ModelName = booking.CustomerVehicle?.Variant?.Model?.Name ?? string.Empty,
            VariantName = booking.CustomerVehicle?.Variant?.Name ?? string.Empty,
            ServiceType = booking.ServiceType,
            ScheduledDate = booking.ScheduledDate,
            TimeSlot = booking.TimeSlot,
            Status = booking.Status,
            JobCardId = jobCard?.Id,
            JobCardStatus = jobCard?.Status.ToString().ToUpperInvariant(),
            CreatedAt = booking.CreatedAt
        };

    private static ServiceTrackingDto BuildTracking(ServiceBooking booking, JobCard? jobCard)
    {
        var bookingDto = MapBooking(booking, jobCard);
        var progress = BuildJobCardProgress(jobCard);
        var currentStage = jobCard == null
            ? booking.Status switch
            {
                "CONFIRMED" => "Appointment confirmed",
                "COMPLETED" => "Service completed",
                "CANCELLED" => "Appointment cancelled",
                _ => "Appointment booked"
            }
            : GetStageLabel(jobCard.Status);

        var timeline = BuildTimeline(booking.Status, jobCard);

        return new ServiceTrackingDto
        {
            Booking = bookingDto,
            JobCard = progress,
            CurrentStage = currentStage,
            ProgressPercent = GetProgressPercent(booking.Status, jobCard?.Status),
            AwaitingCustomerApproval = jobCard != null
                                       && !jobCard.CustomerApproved
                                       && jobCard.Status == JobCardStatus.Estimated,
            Timeline = timeline
        };
    }

    private static JobCardProgressDto? BuildJobCardProgress(JobCard? jobCard) =>
        jobCard == null
            ? null
            : new JobCardProgressDto
            {
                Id = jobCard.Id,
                JobCardNumber = jobCard.JobCardNumber,
                Status = jobCard.Status.ToString().ToUpperInvariant(),
                OdometerReading = jobCard.OdometerReading,
                FuelLevelPercent = jobCard.FuelLevelPercent,
                EstimatedCost = jobCard.EstimatedCost,
                CustomerApproved = jobCard.CustomerApproved,
                TechnicianName = jobCard.Technician?.FullName,
                CreatedAt = jobCard.CreatedAt,
                UpdatedAt = jobCard.UpdatedAt,
                Items = jobCard.Items.Select(i => new ServiceProgressItemDto
                {
                    Id = i.Id,
                    ItemType = i.ItemType.ToString().ToUpperInvariant(),
                    Description = i.Description,
                    Quantity = i.Quantity,
                    UnitPrice = i.UnitPrice,
                    TotalPrice = i.TotalPrice,
                    IsApproved = i.IsApproved
                }).ToList()
            };

    private static string GetStageLabel(JobCardStatus status) => status switch
    {
        JobCardStatus.Open => JobCardStages[0],
        JobCardStatus.Estimated => JobCardStages[1],
        JobCardStatus.Approved => JobCardStages[2],
        JobCardStatus.WorkInProgress => JobCardStages[4],
        JobCardStatus.QualityCheckPending => JobCardStages[5],
        JobCardStatus.QualityCheckPassed => JobCardStages[6],
        JobCardStatus.Billed => JobCardStages[7],
        JobCardStatus.Closed => JobCardStages[8],
        _ => "In service"
    };

    private static int GetProgressPercent(string bookingStatus, JobCardStatus? jobCardStatus)
    {
        if (bookingStatus.Equals("CANCELLED", StringComparison.OrdinalIgnoreCase))
        {
            return 0;
        }

        if (!jobCardStatus.HasValue)
        {
            return bookingStatus.Equals("COMPLETED", StringComparison.OrdinalIgnoreCase) ? 100 : 10;
        }

        return jobCardStatus.Value switch
        {
            JobCardStatus.Open => 15,
            JobCardStatus.Estimated => 30,
            JobCardStatus.Approved => 45,
            JobCardStatus.WorkInProgress => 65,
            JobCardStatus.QualityCheckPending => 80,
            JobCardStatus.QualityCheckPassed => 90,
            JobCardStatus.Billed => 95,
            JobCardStatus.Closed => 100,
            _ => 10
        };
    }

    private static List<ServiceTimelineStepDto> BuildTimeline(string bookingStatus, JobCard? jobCard)
    {
        var steps = new List<ServiceTimelineStepDto>
        {
            new() { Label = "Appointment booked", Completed = true }
        };

        if (bookingStatus.Equals("CANCELLED", StringComparison.OrdinalIgnoreCase))
        {
            steps.Add(new ServiceTimelineStepDto { Label = "Appointment cancelled", Current = true });
            return steps;
        }

        if (jobCard == null)
        {
            steps.Add(new ServiceTimelineStepDto
            {
                Label = "Vehicle check-in",
                Current = true
            });
            return steps;
        }

        var currentIndex = jobCard.Status switch
        {
            JobCardStatus.Open => 1,
            JobCardStatus.Estimated => 2,
            JobCardStatus.Approved => 3,
            JobCardStatus.WorkInProgress => 5,
            JobCardStatus.QualityCheckPending => 6,
            JobCardStatus.QualityCheckPassed => 7,
            JobCardStatus.Billed => 8,
            JobCardStatus.Closed => 8,
            _ => 1
        };

        for (var i = 1; i < JobCardStages.Length; i++)
        {
            steps.Add(new ServiceTimelineStepDto
            {
                Label = JobCardStages[i],
                Completed = i < currentIndex || jobCard.Status == JobCardStatus.Closed,
                Current = i == currentIndex && jobCard.Status != JobCardStatus.Closed
            });
        }

        return steps;
    }

    private static string Mask(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return string.Empty;
        }

        return value.Length <= 4
            ? value
            : $"•••• {value[^4..]}";
    }
}
