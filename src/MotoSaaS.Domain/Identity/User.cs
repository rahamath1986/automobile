using MotoSaaS.Domain.Common;
using MotoSaaS.Domain.Tenancy;

namespace MotoSaaS.Domain.Identity;

public enum UserType
{
    SaasAdmin,
    DealerStaff,
    Customer
}

public class User : BaseEntity
{
    public Guid? TenantId { get; set; }
    public Tenant? Tenant { get; set; }

    public Guid? DefaultBranchId { get; set; }
    public Branch? DefaultBranch { get; set; }

    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public UserType UserType { get; set; } = UserType.DealerStaff;
    public bool IsActive { get; set; } = true;

    public ICollection<UserRole> UserRoles { get; set; } = new List<UserRole>();
}

public class Role : BaseEntity
{
    public Guid? TenantId { get; set; }
    public Tenant? Tenant { get; set; }

    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool IsSystemRole { get; set; } = false;

    public ICollection<UserRole> UserRoles { get; set; } = new List<UserRole>();
}

public class UserRole
{
    public Guid UserId { get; set; }
    public User? User { get; set; }

    public Guid RoleId { get; set; }
    public Role? Role { get; set; }

    public Guid? BranchId { get; set; }
    public Branch? Branch { get; set; }
}

