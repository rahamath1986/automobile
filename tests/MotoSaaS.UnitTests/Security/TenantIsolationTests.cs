using Microsoft.EntityFrameworkCore;
using MotoSaaS.Domain.Inventory;
using MotoSaaS.Domain.Sales;
using MotoSaaS.Infrastructure.Persistence;
using MotoSaaS.Infrastructure.Services;
using Xunit;

namespace MotoSaaS.UnitTests.Security;

public class TenantIsolationTests
{
    private static (ApplicationDbContext context, TenantContext tenantContext) CreateContext(Guid? initialTenantId = null)
    {
        var tenantContext = new TenantContext();
        if (initialTenantId.HasValue)
        {
            tenantContext.SetTenant(initialTenantId.Value);
        }

        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseInMemoryDatabase(databaseName: $"TenantIsolation_{Guid.NewGuid()}")
            .Options;

        var context = new ApplicationDbContext(options, tenantContext);
        return (context, tenantContext);
    }

    [Fact]
    public async Task Inventory_CannotBeAccessedAcrossDifferentTenants()
    {
        // Arrange
        var tenantAId = Guid.NewGuid();
        var tenantBId = Guid.NewGuid();
        var (context, tenantContext) = CreateContext(tenantAId);

        var unitA = new InventoryItem
        {
            Id = Guid.NewGuid(),
            TenantId = tenantAId,
            BranchId = Guid.NewGuid(),
            VariantId = Guid.NewGuid(),
            ColorId = Guid.NewGuid(),
            ChassisNumber = "ME4VINYAMAHA0001",
            EngineNumber = "ENGYAM001",
            Status = InventoryStatus.Available,
            CreatedAt = DateTime.UtcNow
        };

        var unitB = new InventoryItem
        {
            Id = Guid.NewGuid(),
            TenantId = tenantBId,
            BranchId = Guid.NewGuid(),
            VariantId = Guid.NewGuid(),
            ColorId = Guid.NewGuid(),
            ChassisNumber = "ME4VINHONDA00002",
            EngineNumber = "ENGHON002",
            Status = InventoryStatus.Available,
            CreatedAt = DateTime.UtcNow
        };

        context.InventoryItems.AddRange(unitA, unitB);
        await context.SaveChangesAsync();

        // Act 1: Query while scoped to Tenant A
        var tenantAInventory = await context.InventoryItems.ToListAsync();

        // Assert 1: Only Tenant A items visible
        Assert.Single(tenantAInventory);
        Assert.Equal("ME4VINYAMAHA0001", tenantAInventory.First().ChassisNumber);

        // Act 2: Switch context to Tenant B
        tenantContext.SetTenant(tenantBId);
        var tenantBInventory = await context.InventoryItems.ToListAsync();

        // Assert 2: Only Tenant B items visible
        Assert.Single(tenantBInventory);
        Assert.Equal("ME4VINHONDA00002", tenantBInventory.First().ChassisNumber);
    }

    [Fact]
    public async Task Quotation_CannotBeViewedByAnotherTenant()
    {
        // Arrange
        var tenantAId = Guid.NewGuid();
        var tenantBId = Guid.NewGuid();
        var (context, tenantContext) = CreateContext(tenantAId);

        var quoteA = new Quotation
        {
            Id = Guid.NewGuid(),
            TenantId = tenantAId,
            BranchId = Guid.NewGuid(),
            QuotationNumber = "Q-ALAGENDRA-001",
            CustomerId = Guid.NewGuid(),
            VariantId = Guid.NewGuid(),
            ColorId = Guid.NewGuid(),
            ExShowroomPrice = 120000,
            TotalOnRoadPrice = 145000,
            Status = QuotationStatus.Active,
            ValidUntil = DateTime.UtcNow.AddDays(7),
            CreatedAt = DateTime.UtcNow
        };

        var quoteB = new Quotation
        {
            Id = Guid.NewGuid(),
            TenantId = tenantBId,
            BranchId = Guid.NewGuid(),
            QuotationNumber = "Q-HONDA-002",
            CustomerId = Guid.NewGuid(),
            VariantId = Guid.NewGuid(),
            ColorId = Guid.NewGuid(),
            ExShowroomPrice = 90000,
            TotalOnRoadPrice = 105000,
            Status = QuotationStatus.Active,
            ValidUntil = DateTime.UtcNow.AddDays(7),
            CreatedAt = DateTime.UtcNow
        };

        context.Quotations.AddRange(quoteA, quoteB);
        await context.SaveChangesAsync();

        // Act: Scoped to Tenant A
        var tenantAQuotes = await context.Quotations.ToListAsync();

        // Assert: Tenant A cannot see Tenant B's quote
        Assert.Single(tenantAQuotes);
        Assert.Equal("Q-ALAGENDRA-001", tenantAQuotes.First().QuotationNumber);
        Assert.DoesNotContain(tenantAQuotes, q => q.TenantId == tenantBId);
    }

    [Fact]
    public async Task SuperAdmin_CanViewAcrossAllTenants()
    {
        // Arrange
        var tenantAId = Guid.NewGuid();
        var tenantBId = Guid.NewGuid();
        var (context, tenantContext) = CreateContext(tenantAId);

        var enqA = new Enquiry
        {
            Id = Guid.NewGuid(),
            TenantId = tenantAId,
            BranchId = Guid.NewGuid(),
            CustomerId = Guid.NewGuid(),
            VariantId = Guid.NewGuid(),
            Status = EnquiryStatus.New,
            CreatedAt = DateTime.UtcNow
        };

        var enqB = new Enquiry
        {
            Id = Guid.NewGuid(),
            TenantId = tenantBId,
            BranchId = Guid.NewGuid(),
            CustomerId = Guid.NewGuid(),
            VariantId = Guid.NewGuid(),
            Status = EnquiryStatus.New,
            CreatedAt = DateTime.UtcNow
        };

        context.Enquiries.AddRange(enqA, enqB);
        await context.SaveChangesAsync();

        // Verify Tenant A sees only 1
        var enqsTenantA = await context.Enquiries.ToListAsync();
        Assert.Single(enqsTenantA);

        // Act: Elevate to SAAS_ADMIN (Super Admin)
        tenantContext.SetUser(Guid.NewGuid(), "SAAS_ADMIN");
        var allEnquiries = await context.Enquiries.ToListAsync();

        // Assert: Super Admin sees all records across both tenants
        Assert.Equal(2, allEnquiries.Count);
    }
}
