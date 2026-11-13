using System.Linq.Expressions;
using Microsoft.EntityFrameworkCore;
using MotoSaaS.Application.Common.Interfaces;
using MotoSaaS.Domain.Billing;
using MotoSaaS.Domain.Catalog;
using MotoSaaS.Domain.Common;
using MotoSaaS.Domain.Finance;
using MotoSaaS.Domain.Identity;
using MotoSaaS.Domain.Inventory;
using MotoSaaS.Domain.Sales;
using MotoSaaS.Domain.Service;
using MotoSaaS.Domain.Subscription;
using MotoSaaS.Domain.Tenancy;

namespace MotoSaaS.Infrastructure.Persistence;

public class ApplicationDbContext : DbContext, IApplicationDbContext
{
    private readonly ICurrentTenantContext _tenantContext;

    public ApplicationDbContext(
        DbContextOptions<ApplicationDbContext> options,
        ICurrentTenantContext tenantContext) : base(options)
    {
        _tenantContext = tenantContext;
    }

    public DbSet<Tenant> Tenants => Set<Tenant>();
    public DbSet<Branch> Branches => Set<Branch>();
    public DbSet<User> Users => Set<User>();
    public DbSet<Role> Roles => Set<Role>();
    public DbSet<UserRole> UserRoles => Set<UserRole>();

    public DbSet<SubscriptionPlan> SubscriptionPlans => Set<SubscriptionPlan>();
    public DbSet<TenantSubscription> TenantSubscriptions => Set<TenantSubscription>();

    public DbSet<Manufacturer> Manufacturers => Set<Manufacturer>();
    public DbSet<TenantManufacturer> TenantManufacturers => Set<TenantManufacturer>();
    public DbSet<VehicleModel> VehicleModels => Set<VehicleModel>();
    public DbSet<VehicleVariant> VehicleVariants => Set<VehicleVariant>();
    public DbSet<VehicleColor> VehicleColors => Set<VehicleColor>();
    public DbSet<Asset3D> Assets3D => Set<Asset3D>();

    public DbSet<InventoryItem> InventoryItems => Set<InventoryItem>();
    public DbSet<InventoryMovement> InventoryMovements => Set<InventoryMovement>();

    public DbSet<Customer> Customers => Set<Customer>();
    public DbSet<Enquiry> Enquiries => Set<Enquiry>();
    public DbSet<EnquiryFollowUp> EnquiryFollowUps => Set<EnquiryFollowUp>();
    public DbSet<TestRide> TestRides => Set<TestRide>();
    public DbSet<Quotation> Quotations => Set<Quotation>();
    public DbSet<Booking> Bookings => Set<Booking>();

    public DbSet<Financier> Financiers => Set<Financier>();
    public DbSet<FinancierScheme> FinancierSchemes => Set<FinancierScheme>();
    public DbSet<FinanceApplication> FinanceApplications => Set<FinanceApplication>();

    public DbSet<Invoice> Invoices => Set<Invoice>();
    public DbSet<Payment> Payments => Set<Payment>();

    public DbSet<CustomerVehicle> CustomerVehicles => Set<CustomerVehicle>();
    public DbSet<ServiceBooking> ServiceBookings => Set<ServiceBooking>();
    public DbSet<JobCard> JobCards => Set<JobCard>();
    public DbSet<JobCardItem> JobCardItems => Set<JobCardItem>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Composite keys
        modelBuilder.Entity<TenantManufacturer>()
            .HasKey(tm => new { tm.TenantId, tm.ManufacturerId });

        modelBuilder.Entity<UserRole>()
            .HasKey(ur => new { ur.UserId, ur.RoleId, ur.BranchId });

        // Unique constraints
        modelBuilder.Entity<Tenant>()
            .HasIndex(t => t.Code).IsUnique();

        modelBuilder.Entity<SubscriptionPlan>()
            .HasIndex(sp => sp.Code).IsUnique();

        modelBuilder.Entity<TenantSubscription>()
            .HasIndex(ts => ts.TenantId).IsUnique();

        modelBuilder.Entity<Branch>()
            .HasIndex(b => new { b.TenantId, b.Code }).IsUnique();

        modelBuilder.Entity<User>()
            .HasIndex(u => u.Email).IsUnique();

        modelBuilder.Entity<Manufacturer>()
            .HasIndex(m => m.Code).IsUnique();

        modelBuilder.Entity<InventoryItem>()
            .HasIndex(i => new { i.TenantId, i.ChassisNumber }).IsUnique();

        modelBuilder.Entity<Customer>()
            .HasIndex(c => new { c.TenantId, c.Phone }).IsUnique();

        modelBuilder.Entity<Enquiry>()
            .HasIndex(e => new { e.TenantId, e.BranchId, e.Status });

        modelBuilder.Entity<Enquiry>()
            .HasIndex(e => new { e.TenantId, e.NextFollowUpAt });

        modelBuilder.Entity<EnquiryFollowUp>()
            .HasIndex(f => new { f.TenantId, f.EnquiryId, f.ContactedAt });

        modelBuilder.Entity<EnquiryFollowUp>()
            .HasOne(f => f.PerformedByUser)
            .WithMany()
            .HasForeignKey(f => f.PerformedByUserId)
            .OnDelete(DeleteBehavior.SetNull);

        modelBuilder.Entity<Enquiry>()
            .HasMany(e => e.FollowUps)
            .WithOne(f => f.Enquiry)
            .HasForeignKey(f => f.EnquiryId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<TestRide>()
            .HasIndex(t => new { t.TenantId, t.BranchId, t.ScheduledAt });

        modelBuilder.Entity<Quotation>()
            .HasIndex(q => new { q.TenantId, q.QuotationNumber }).IsUnique();

        modelBuilder.Entity<Quotation>()
            .HasIndex(q => new { q.TenantId, q.BranchId, q.Status });

        modelBuilder.Entity<Booking>()
            .HasIndex(b => new { b.TenantId, b.BookingNumber }).IsUnique();

        modelBuilder.Entity<Invoice>()
            .HasIndex(i => new { i.TenantId, i.InvoiceNumber }).IsUnique();

        modelBuilder.Entity<JobCard>()
            .HasIndex(j => new { j.TenantId, j.JobCardNumber }).IsUnique();

        modelBuilder.Entity<CustomerVehicle>()
            .HasIndex(cv => new { cv.TenantId, cv.RegistrationNumber }).IsUnique();

        modelBuilder.Entity<Financier>()
            .HasIndex(f => new { f.TenantId, f.Code }).IsUnique();

        // Global Query Filters for ITenantScopedEntity
        foreach (var entityType in modelBuilder.Model.GetEntityTypes())
        {
            if (typeof(ITenantScopedEntity).IsAssignableFrom(entityType.ClrType))
            {
                var parameter = Expression.Parameter(entityType.ClrType, "e");
                var property = Expression.Property(parameter, nameof(ITenantScopedEntity.TenantId));

                // Filter: e.TenantId == _tenantContext.TenantId || _tenantContext.IsSuperAdmin
                var tenantIdProp = Expression.Property(Expression.Constant(this), nameof(CurrentTenantId));
                var isSuperAdminProp = Expression.Property(Expression.Constant(this), nameof(IsSuperAdmin));

                var filterCondition = Expression.OrElse(
                    Expression.Equal(property, Expression.Convert(tenantIdProp, typeof(Guid))),
                    isSuperAdminProp
                );

                var lambda = Expression.Lambda(filterCondition, parameter);
                modelBuilder.Entity(entityType.ClrType).HasQueryFilter(lambda);
            }
        }
    }

    public Guid CurrentTenantId => _tenantContext.TenantId ?? Guid.Empty;
    public bool IsSuperAdmin => _tenantContext.IsSuperAdmin;

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        foreach (var entry in ChangeTracker.Entries<BaseEntity>())
        {
            switch (entry.State)
            {
                case EntityState.Added:
                    entry.Entity.CreatedAt = DateTime.UtcNow;
                    entry.Entity.UpdatedAt = DateTime.UtcNow;
                    if (_tenantContext.UserId.HasValue && !entry.Entity.CreatedBy.HasValue)
                    {
                        entry.Entity.CreatedBy = _tenantContext.UserId;
                    }
                    break;
                case EntityState.Modified:
                    entry.Entity.UpdatedAt = DateTime.UtcNow;
                    if (_tenantContext.UserId.HasValue)
                    {
                        entry.Entity.UpdatedBy = _tenantContext.UserId;
                    }
                    break;
            }
        }

        // Automatic tenant ID injection for added entities
        if (_tenantContext.TenantId.HasValue)
        {
            foreach (var entry in ChangeTracker.Entries<ITenantScopedEntity>())
            {
                if (entry.State == EntityState.Added && entry.Entity.TenantId == Guid.Empty)
                {
                    entry.Entity.TenantId = _tenantContext.TenantId.Value;
                }
            }
        }

        return base.SaveChangesAsync(cancellationToken);
    }
}

