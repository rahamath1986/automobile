using Microsoft.EntityFrameworkCore;
using MotoSaaS.Domain.Billing;
using MotoSaaS.Domain.Catalog;
using MotoSaaS.Domain.Finance;
using MotoSaaS.Domain.Identity;
using MotoSaaS.Domain.Inventory;
using MotoSaaS.Domain.Sales;
using MotoSaaS.Domain.Service;
using MotoSaaS.Domain.Subscription;
using MotoSaaS.Domain.Tenancy;

namespace MotoSaaS.Application.Common.Interfaces;

public interface IApplicationDbContext
{
    DbSet<Tenant> Tenants { get; }
    DbSet<Branch> Branches { get; }
    DbSet<User> Users { get; }
    DbSet<Role> Roles { get; }
    DbSet<UserRole> UserRoles { get; }

    DbSet<SubscriptionPlan> SubscriptionPlans { get; }
    DbSet<TenantSubscription> TenantSubscriptions { get; }

    DbSet<Manufacturer> Manufacturers { get; }
    DbSet<TenantManufacturer> TenantManufacturers { get; }
    DbSet<VehicleModel> VehicleModels { get; }
    DbSet<VehicleVariant> VehicleVariants { get; }
    DbSet<VehicleColor> VehicleColors { get; }
    DbSet<Asset3D> Assets3D { get; }

    DbSet<InventoryItem> InventoryItems { get; }
    DbSet<InventoryMovement> InventoryMovements { get; }

    DbSet<Customer> Customers { get; }
    DbSet<Enquiry> Enquiries { get; }
    DbSet<EnquiryFollowUp> EnquiryFollowUps { get; }
    DbSet<TestRide> TestRides { get; }
    DbSet<Quotation> Quotations { get; }
    DbSet<Booking> Bookings { get; }

    DbSet<Financier> Financiers { get; }
    DbSet<FinancierScheme> FinancierSchemes { get; }
    DbSet<FinanceApplication> FinanceApplications { get; }

    DbSet<Invoice> Invoices { get; }
    DbSet<Payment> Payments { get; }

    DbSet<CustomerVehicle> CustomerVehicles { get; }
    DbSet<ServiceBooking> ServiceBookings { get; }
    DbSet<JobCard> JobCards { get; }
    DbSet<JobCardItem> JobCardItems { get; }

    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}

