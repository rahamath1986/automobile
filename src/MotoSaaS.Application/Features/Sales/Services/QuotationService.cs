using Microsoft.EntityFrameworkCore;
using MotoSaaS.Application.Common.Interfaces;
using MotoSaaS.Application.Features.Sales.Interfaces;
using MotoSaaS.Application.Features.Sales.Models;
using MotoSaaS.Domain.Catalog;
using MotoSaaS.Domain.Sales;
using MotoSaaS.Domain.Tenancy;

namespace MotoSaaS.Application.Features.Sales.Services;

public class QuotationService : IQuotationService
{
    private readonly IApplicationDbContext _context;
    private readonly ICurrentTenantContext _tenantContext;

    public QuotationService(
        IApplicationDbContext context,
        ICurrentTenantContext tenantContext)
    {
        _context = context;
        _tenantContext = tenantContext;
    }

    public async Task<QuotationCalculationDto> PreviewAsync(
        QuotationDraftRequest request,
        CancellationToken cancellationToken = default)
    {
        var context = await ResolveQuotationContextAsync(request, cancellationToken);
        return BuildPreview(context, request);
    }

    public async Task<QuotationDto> CreateAsync(
        CreateQuotationRequest request,
        CancellationToken cancellationToken = default)
    {
        var context = await ResolveQuotationContextAsync(request, cancellationToken);
        var preview = BuildPreview(context, request);

        var quotation = new Quotation
        {
            TenantId = context.Branch.TenantId,
            BranchId = context.Branch.Id,
            QuotationNumber = await GenerateQuotationNumberAsync(context.Branch, cancellationToken),
            EnquiryId = context.Enquiry?.Id,
            CustomerId = context.Customer.Id,
            VariantId = context.Variant.Id,
            ColorId = context.Color.Id,
            ExShowroomPrice = preview.ExShowroomPrice,
            RtoCharges = preview.RtoCharges,
            InsuranceCharges = preview.InsuranceCharges,
            AccessoriesCharges = preview.AccessoriesCharges,
            HandlingCharges = preview.HandlingCharges,
            DiscountAmount = preview.DiscountAmount,
            TotalOnRoadPrice = preview.TotalOnRoadPrice,
            ValidUntil = preview.ValidUntil,
            Status = QuotationStatus.Active,
            Notes = Clean(request.Notes)
        };

        _context.Quotations.Add(quotation);

        if (context.Enquiry != null)
        {
            var now = DateTime.UtcNow;
            context.Enquiry.LastContactedAt = now;

            if (SalesPipelineRules.CanTransition(context.Enquiry.Status, EnquiryStatus.Quoted))
            {
                context.Enquiry.Status = EnquiryStatus.Quoted;
            }

            if (SalesPipelineRules.IsOpen(context.Enquiry.Status))
            {
                context.Enquiry.NextFollowUpAt = now.AddDays(2);
            }
        }

        await _context.SaveChangesAsync(cancellationToken);
        return MapQuotation(quotation, context);
    }

    public async Task<PagedResult<QuotationDto>> GetQuotationsAsync(
        QuotationQuery query,
        CancellationToken cancellationToken = default)
    {
        var tenantId = RequireTenant();
        var branchId = ResolveBranchScope(query.BranchId);
        var now = DateTime.UtcNow;

        await ExpireLapsedQuotationsAsync(tenantId, now, cancellationToken);

        var statuses = ParseStatusFilter(query.Status);
        var page = Math.Max(query.Page, 1);
        var pageSize = Math.Clamp(query.PageSize, 1, 100);

        var quotations = _context.Quotations
            .Include(q => q.Branch)
            .Include(q => q.Customer)
            .Include(q => q.Variant)
                .ThenInclude(v => v!.Model)
            .Include(q => q.Color)
            .AsNoTracking()
            .Where(q => q.TenantId == tenantId);

        if (branchId.HasValue)
        {
            quotations = quotations.Where(q => q.BranchId == branchId.Value);
        }

        if (statuses != null)
        {
            quotations = quotations.Where(q => statuses.Contains(q.Status));
        }

        if (!query.IncludeExpired)
        {
            quotations = quotations.Where(q => q.Status != QuotationStatus.Expired && q.ValidUntil >= now);
        }

        if (query.EnquiryId.HasValue)
        {
            quotations = quotations.Where(q => q.EnquiryId == query.EnquiryId.Value);
        }

        if (query.CustomerId.HasValue)
        {
            quotations = quotations.Where(q => q.CustomerId == query.CustomerId.Value);
        }

        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var term = query.Search.Trim();
            quotations = quotations.Where(q =>
                q.QuotationNumber.Contains(term)
                || q.Customer!.FirstName.Contains(term)
                || (q.Customer.LastName != null && q.Customer.LastName.Contains(term))
                || q.Customer.Phone.Contains(term)
                || q.Variant!.Name.Contains(term)
                || q.Variant.Model!.Name.Contains(term));
        }

        var totalCount = await quotations.CountAsync(cancellationToken);
        var rows = await quotations
            .OrderByDescending(q => q.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        return new PagedResult<QuotationDto>
        {
            Items = rows.Select(q => MapQuotation(q)).ToList(),
            Page = page,
            PageSize = pageSize,
            TotalCount = totalCount
        };
    }

    public async Task<QuotationDto> GetQuotationAsync(
        Guid quotationId,
        CancellationToken cancellationToken = default)
    {
        var quotation = await LoadQuotationAsync(quotationId, tracking: true, cancellationToken);
        EnsureBranchAccess(quotation.BranchId);

        if (quotation.Status == QuotationStatus.Active && quotation.ValidUntil < DateTime.UtcNow)
        {
            quotation.Status = QuotationStatus.Expired;
            await _context.SaveChangesAsync(cancellationToken);
        }

        return MapQuotation(quotation);
    }

    public async Task<QuotationDto> ExpireAsync(
        Guid quotationId,
        CancellationToken cancellationToken = default)
    {
        var quotation = await LoadQuotationAsync(quotationId, tracking: true, cancellationToken);
        EnsureBranchAccess(quotation.BranchId);

        if (quotation.Status != QuotationStatus.Active)
        {
            throw new InvalidOperationException(
                $"Only an active quotation can be expired. Current status: {quotation.Status}.");
        }

        quotation.Status = QuotationStatus.Expired;
        await _context.SaveChangesAsync(cancellationToken);
        return MapQuotation(quotation);
    }

    private async Task<QuotationContext> ResolveQuotationContextAsync(
        QuotationDraftRequest request,
        CancellationToken cancellationToken)
    {
        var tenantId = RequireTenant();

        if (request.EnquiryId.HasValue)
        {
            var enquiry = await _context.Enquiries
                .Include(e => e.Branch)
                .Include(e => e.Customer)
                .Include(e => e.Variant)
                    .ThenInclude(v => v!.Model)
                .Include(e => e.Variant)
                    .ThenInclude(v => v!.Colors)
                .Include(e => e.Color)
                .FirstOrDefaultAsync(e => e.Id == request.EnquiryId.Value, cancellationToken)
                ?? throw new KeyNotFoundException("The sales lead for this quotation was not found.");

            EnsureBranchAccess(enquiry.BranchId);

            if (request.BranchId.HasValue && request.BranchId.Value != enquiry.BranchId)
            {
                throw new ArgumentException("The quotation branch must match the lead branch.");
            }

            if (request.CustomerId.HasValue && request.CustomerId.Value != enquiry.CustomerId)
            {
                throw new ArgumentException("The quotation customer must match the lead customer.");
            }

            if (request.VariantId.HasValue && request.VariantId.Value != enquiry.VariantId)
            {
                throw new ArgumentException("The quotation variant must match the lead variant.");
            }

            var branch = enquiry.Branch
                         ?? throw new InvalidOperationException("The lead branch is no longer available.");
            var customer = enquiry.Customer
                           ?? throw new InvalidOperationException("The lead customer is no longer available.");
            var variant = enquiry.Variant
                          ?? throw new InvalidOperationException("The lead variant is no longer available.");

            var requestedColorId = request.ColorId ?? enquiry.ColorId;
            var color = ResolveColor(variant, requestedColorId);

            return new QuotationContext(tenantId, branch, customer, variant, color, enquiry);
        }

        if (!request.CustomerId.HasValue || !request.VariantId.HasValue)
        {
            throw new ArgumentException("A direct quotation requires a customer and a vehicle variant.");
        }

        var directCustomer = await _context.Customers
            .FirstOrDefaultAsync(c => c.Id == request.CustomerId.Value, cancellationToken)
            ?? throw new KeyNotFoundException("The customer for this quotation was not found.");

        var directVariant = await _context.VehicleVariants
            .Include(v => v.Model)
            .Include(v => v.Colors)
            .FirstOrDefaultAsync(v => v.Id == request.VariantId.Value && v.IsActive, cancellationToken)
            ?? throw new ArgumentException("The selected vehicle variant is not available.");

        var directBranch = await ResolveBranchAsync(tenantId, request.BranchId, cancellationToken);
        EnsureBranchAccess(directBranch.Id);

        var directColor = ResolveColor(directVariant, request.ColorId);

        return new QuotationContext(tenantId, directBranch, directCustomer, directVariant, directColor, null);
    }

    private static QuotationCalculationDto BuildPreview(QuotationContext context, QuotationDraftRequest request)
    {
        var calculation = QuotationCalculator.Calculate(
            context.Variant.BasePrice,
            context.Branch.State,
            request.AccessoriesCharges,
            request.HandlingCharges,
            request.DiscountAmount,
            request.ValidDays);

        return new QuotationCalculationDto
        {
            BranchId = context.Branch.Id,
            BranchName = context.Branch.Name,
            EnquiryId = context.Enquiry?.Id,
            CustomerId = context.Customer.Id,
            CustomerName = BuildCustomerName(context.Customer.FirstName, context.Customer.LastName),
            Phone = context.Customer.Phone,
            VariantId = context.Variant.Id,
            VariantName = context.Variant.Name,
            ModelName = context.Variant.Model?.Name ?? string.Empty,
            ColorId = context.Color.Id,
            ColorName = context.Color.ColorName,
            ExShowroomPrice = calculation.ExShowroomPrice,
            RtoPercent = calculation.RtoPercent,
            RtoCharges = calculation.RtoCharges,
            InsurancePercent = calculation.InsurancePercent,
            InsuranceCharges = calculation.InsuranceCharges,
            AccessoriesCharges = calculation.AccessoriesCharges,
            HandlingCharges = calculation.HandlingCharges,
            Subtotal = calculation.Subtotal,
            DiscountAmount = calculation.DiscountAmount,
            TotalOnRoadPrice = calculation.TotalOnRoadPrice,
            ValidUntil = calculation.ValidUntil,
            Warnings = calculation.Warnings.ToList()
        };
    }

    private static QuotationDto MapQuotation(Quotation quotation, QuotationContext? context = null)
    {
        var now = DateTime.UtcNow;
        var exShowroom = quotation.ExShowroomPrice;
        var rtoPercent = exShowroom > 0
            ? Math.Round(quotation.RtoCharges / exShowroom * 100m, 2, MidpointRounding.AwayFromZero)
            : 0m;
        var insurancePercent = exShowroom > 0
            ? Math.Round(quotation.InsuranceCharges / exShowroom * 100m, 2, MidpointRounding.AwayFromZero)
            : 0m;
        var subtotal = quotation.ExShowroomPrice
                       + quotation.RtoCharges
                       + quotation.InsuranceCharges
                       + quotation.AccessoriesCharges
                       + quotation.HandlingCharges;

        var warnings = new List<string>();
        if (quotation.Status == QuotationStatus.Expired || quotation.ValidUntil < now)
        {
            warnings.Add("This quotation has expired and must be reissued before booking.");
        }

        if (quotation.DiscountAmount > quotation.ExShowroomPrice * 0.05m)
        {
            warnings.Add("Discount exceeds 5% of the ex-showroom price and may require manager approval.");
        }

        return new QuotationDto
        {
            Id = quotation.Id,
            QuotationNumber = quotation.QuotationNumber,
            Status = quotation.Status.ToString().ToUpperInvariant(),
            IsExpired = quotation.Status == QuotationStatus.Expired || quotation.ValidUntil < now,
            BranchId = quotation.BranchId,
            BranchName = quotation.Branch?.Name ?? context?.Branch.Name ?? string.Empty,
            EnquiryId = quotation.EnquiryId,
            CustomerId = quotation.CustomerId,
            CustomerName = quotation.Customer != null
                ? BuildCustomerName(quotation.Customer.FirstName, quotation.Customer.LastName)
                : context != null
                    ? BuildCustomerName(context.Customer.FirstName, context.Customer.LastName)
                    : string.Empty,
            Phone = quotation.Customer?.Phone ?? context?.Customer.Phone ?? string.Empty,
            VariantId = quotation.VariantId,
            VariantName = quotation.Variant?.Name ?? context?.Variant.Name ?? string.Empty,
            ModelName = quotation.Variant?.Model?.Name ?? context?.Variant.Model?.Name ?? string.Empty,
            ColorId = quotation.ColorId,
            ColorName = quotation.Color?.ColorName ?? context?.Color.ColorName ?? string.Empty,
            ExShowroomPrice = quotation.ExShowroomPrice,
            RtoPercent = rtoPercent,
            RtoCharges = quotation.RtoCharges,
            InsurancePercent = insurancePercent,
            InsuranceCharges = quotation.InsuranceCharges,
            AccessoriesCharges = quotation.AccessoriesCharges,
            HandlingCharges = quotation.HandlingCharges,
            Subtotal = subtotal,
            DiscountAmount = quotation.DiscountAmount,
            TotalOnRoadPrice = quotation.TotalOnRoadPrice,
            ValidUntil = quotation.ValidUntil,
            Warnings = warnings,
            Notes = quotation.Notes,
            CreatedByUserId = quotation.CreatedBy,
            CreatedAt = quotation.CreatedAt,
            UpdatedAt = quotation.UpdatedAt
        };
    }

    private async Task<Quotation> LoadQuotationAsync(
        Guid quotationId,
        bool tracking,
        CancellationToken cancellationToken)
    {
        IQueryable<Quotation> query = tracking
            ? _context.Quotations
            : _context.Quotations.AsNoTracking();

        query = query
            .Include(q => q.Branch)
            .Include(q => q.Customer)
            .Include(q => q.Variant)
                .ThenInclude(v => v!.Model)
            .Include(q => q.Color);

        var quotation = await query.FirstOrDefaultAsync(q => q.Id == quotationId, cancellationToken);
        return quotation ?? throw new KeyNotFoundException("The quotation was not found.");
    }

    private async Task<string> GenerateQuotationNumberAsync(Branch branch, CancellationToken cancellationToken)
    {
        var branchCode = new string(branch.Code.Where(char.IsLetterOrDigit).ToArray()).ToUpperInvariant();
        if (string.IsNullOrWhiteSpace(branchCode))
        {
            branchCode = "BR";
        }

        var prefix = $"QTN-{branchCode}-{DateTime.UtcNow:yyyyMMdd}-";
        var lastNumber = await _context.Quotations
            .AsNoTracking()
            .Where(q => q.TenantId == branch.TenantId && q.QuotationNumber.StartsWith(prefix))
            .OrderByDescending(q => q.QuotationNumber)
            .Select(q => q.QuotationNumber)
            .FirstOrDefaultAsync(cancellationToken);

        var nextSequence = 1;
        if (!string.IsNullOrWhiteSpace(lastNumber)
            && int.TryParse(lastNumber[prefix.Length..], out var parsedSequence))
        {
            nextSequence = parsedSequence + 1;
        }

        return $"{prefix}{nextSequence:D4}";
    }

    private async Task<Branch> ResolveBranchAsync(
        Guid tenantId,
        Guid? requestedBranchId,
        CancellationToken cancellationToken)
    {
        var branches = _context.Branches
            .Where(b => b.TenantId == tenantId && b.IsActive);

        if (requestedBranchId.HasValue)
        {
            return await branches.FirstOrDefaultAsync(b => b.Id == requestedBranchId.Value, cancellationToken)
                   ?? throw new ArgumentException("The selected dealership branch is not available.");
        }

        if (_tenantContext.BranchId.HasValue)
        {
            var scoped = await branches
                .FirstOrDefaultAsync(b => b.Id == _tenantContext.BranchId.Value, cancellationToken);
            if (scoped != null)
            {
                return scoped;
            }
        }

        return await branches
                   .OrderByDescending(b => b.IsHeadquarters)
                   .ThenBy(b => b.Code)
                   .FirstOrDefaultAsync(cancellationToken)
               ?? throw new InvalidOperationException("No active dealership branch is available for this quotation.");
    }

    private async Task ExpireLapsedQuotationsAsync(
        Guid tenantId,
        DateTime now,
        CancellationToken cancellationToken)
    {
        var lapsed = await _context.Quotations
            .Where(q => q.TenantId == tenantId
                        && q.Status == QuotationStatus.Active
                        && q.ValidUntil < now)
            .ToListAsync(cancellationToken);

        if (lapsed.Count == 0)
        {
            return;
        }

        foreach (var quotation in lapsed)
        {
            quotation.Status = QuotationStatus.Expired;
        }

        await _context.SaveChangesAsync(cancellationToken);
    }

    private static VehicleColor ResolveColor(VehicleVariant variant, Guid? colorId)
    {
        var color = colorId.HasValue
            ? variant.Colors.FirstOrDefault(c => c.Id == colorId.Value)
            : variant.Colors.FirstOrDefault(c => c.IsPrimary) ?? variant.Colors.FirstOrDefault();

        if (colorId.HasValue && color == null)
        {
            throw new ArgumentException("The selected colour is not offered for this variant.");
        }

        return color ?? throw new ArgumentException("The selected vehicle variant has no colours configured.");
    }

    private Guid RequireTenant()
    {
        return _tenantContext.TenantId
               ?? throw new UnauthorizedAccessException("A dealership context is required for quotation operations.");
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
            throw new UnauthorizedAccessException("You can only access quotations for your assigned branch.");
        }
    }

    private static List<QuotationStatus>? ParseStatusFilter(string? status)
    {
        if (string.IsNullOrWhiteSpace(status))
        {
            return null;
        }

        var result = new List<QuotationStatus>();
        foreach (var token in status.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
        {
            if (!Enum.TryParse<QuotationStatus>(token, true, out var parsed) || !Enum.IsDefined(parsed))
            {
                throw new ArgumentException($"'{token}' is not a valid quotation status.");
            }

            if (!result.Contains(parsed))
            {
                result.Add(parsed);
            }
        }

        return result.Count == 0 ? null : result;
    }

    private static string BuildCustomerName(string firstName, string? lastName) =>
        string.Join(' ', new[] { firstName, lastName }.Where(part => !string.IsNullOrWhiteSpace(part)));

    private static string? Clean(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private sealed record QuotationContext(
        Guid TenantId,
        Branch Branch,
        Customer Customer,
        VehicleVariant Variant,
        VehicleColor Color,
        Enquiry? Enquiry);
}
