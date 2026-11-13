namespace MotoSaaS.Application.Features.Identity.Models;

public class StaffLoginRequest
{
    public string DealerCode { get; set; } = string.Empty;
    public string UsernameOrEmail { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}

public class CustomerRequestOtpRequest
{
    public string Phone { get; set; } = string.Empty;
    public string? DealerCode { get; set; }
}

public class CustomerVerifyOtpRequest
{
    public string Phone { get; set; } = string.Empty;
    public string Otp { get; set; } = string.Empty;
    public string? DealerCode { get; set; }
    public string? FirstName { get; set; }
    public string? LastName { get; set; }
}

public class RefreshTokenRequest
{
    public string RefreshToken { get; set; } = string.Empty;
}

public class AuthResponse
{
    public string AccessToken { get; set; } = string.Empty;
    public string RefreshToken { get; set; } = string.Empty;
    public string TokenType { get; set; } = "Bearer";
    public int ExpiresInSeconds { get; set; } = 900; // 15 mins
    public UserProfileDto User { get; set; } = new();
}

public class UserProfileDto
{
    public Guid Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string Phone { get; set; } = string.Empty;
    public string UserType { get; set; } = string.Empty; // SAAS_ADMIN, DEALER_STAFF, CUSTOMER
    public Guid? TenantId { get; set; }
    public string? TenantCode { get; set; }
    public string? TenantName { get; set; }
    public Guid? DefaultBranchId { get; set; }
    public string? BranchCode { get; set; }
    public string? BranchName { get; set; }
    public List<string> Roles { get; set; } = new();
}

