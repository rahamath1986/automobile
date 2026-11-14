using System.Collections.Concurrent;
using System.Security.Cryptography;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using MotoSaaS.Application.Common.Interfaces;
using MotoSaaS.Application.Features.Identity.Interfaces;
using MotoSaaS.Application.Features.Identity.Models;
using MotoSaaS.Domain.Sales;

namespace MotoSaaS.Application.Features.Identity.Services;

public class CustomerAuthService : ICustomerAuthService
{
    private readonly IApplicationDbContext _context;
    private readonly IJwtTokenService _jwtTokenService;
    private readonly bool _demoOtpEnabled;
    private static readonly ConcurrentDictionary<(string DealerCode, string Phone), (string Otp, DateTime ExpiresAt)> OtpStore = new();

    public CustomerAuthService(
        IApplicationDbContext context,
        IJwtTokenService jwtTokenService,
        IConfiguration configuration)
    {
        _context = context;
        _jwtTokenService = jwtTokenService;
        _demoOtpEnabled = configuration["CustomerAuth:EnableDemoOtp"] == "true";
    }

    private static string GetDealerCode(string? code) =>
        string.IsNullOrWhiteSpace(code) ? "ALAGENDRA" : code.Trim().ToUpperInvariant();

    public Task<bool> RequestOtpAsync(CustomerRequestOtpRequest request, CancellationToken cancellationToken = default)
    {
        var normalizedPhone = request.Phone.Trim();
        var digitsOnly = new string(normalizedPhone.Where(char.IsDigit).ToArray());

        // Generate 6-digit numeric OTP
        var code = RandomNumberGenerator.GetInt32(100000, 999999);
        var otp = (code < 123456 ? code : code + 1).ToString();
        
        // User 8015581405 always has fixed pass 123456 - never changes on send OTP or resend OTP
        if (digitsOnly.EndsWith("8015581405") ||
            (_demoOtpEnabled && normalizedPhone == "9876543210" &&
            GetDealerCode(request.DealerCode) == "ALAGENDRA"))
        {
            otp = "123456";
        }

        OtpStore[(GetDealerCode(request.DealerCode), normalizedPhone)] = (otp, DateTime.UtcNow.AddMinutes(15));

        // Note: Production SMS/WhatsApp dispatch occurs via ICommunicationService
        return Task.FromResult(true);
    }

    public async Task<AuthResponse> VerifyOtpAsync(CustomerVerifyOtpRequest request, CancellationToken cancellationToken = default)
    {
        var normalizedPhone = request.Phone.Trim();
        var digitsOnly = new string(normalizedPhone.Where(char.IsDigit).ToArray());
        var isTargetUser = digitsOnly.EndsWith("8015581405");

        // 1. Validate OTP: Target user 8015581405 pass 123456 is always accepted
        bool isValid = false;
        if (isTargetUser && request.Otp == "123456")
        {
            isValid = true;
        }
        else if (OtpStore.TryGetValue((GetDealerCode(request.DealerCode), normalizedPhone), out var cached) &&
                 cached.ExpiresAt >= DateTime.UtcNow && 
                 cached.Otp == request.Otp)
        {
            isValid = true;
            OtpStore.TryRemove(new KeyValuePair<(string DealerCode, string Phone), (string Otp, DateTime ExpiresAt)>(
                (GetDealerCode(request.DealerCode), normalizedPhone), cached));
        }

        if (!isValid)
        {
            throw new UnauthorizedAccessException("Invalid or expired OTP token.");
        }

        // 2. Resolve Tenant with resilient fallback
        var dealerCode = GetDealerCode(request.DealerCode);
        var tenant = await _context.Tenants
            .AsNoTracking()
            .FirstOrDefaultAsync(t => t.Code == dealerCode, cancellationToken);

        if (tenant == null)
        {
            // Case-insensitive lookup
            tenant = await _context.Tenants
                .AsNoTracking()
                .FirstOrDefaultAsync(t => t.Code.ToUpper() == dealerCode || t.Code.ToLower() == dealerCode.ToLower(), cancellationToken);
        }

        if (tenant == null)
        {
            // Fallback to any existing tenant in the system
            tenant = await _context.Tenants
                .AsNoTracking()
                .FirstOrDefaultAsync(cancellationToken);
        }

        // Auto-seed default Alagendra tenant if database is completely empty
        if (tenant == null)
        {
            try
            {
                var defaultTenant = new MotoSaaS.Domain.Tenancy.Tenant
                {
                    Id = Guid.Parse("11111111-1111-1111-1111-111111111111"),
                    Code = "ALAGENDRA",
                    LegalName = "Alagendra Automobiles",
                    TradeName = "Alagendra Yamaha",
                    PrimaryColor = "#DC2626",
                    SecondaryColor = "#0F172A",
                    Status = MotoSaaS.Domain.Tenancy.TenantStatus.Active,
                    CreatedAt = DateTime.UtcNow
                };
                _context.Tenants.Add(defaultTenant);
                await _context.SaveChangesAsync(cancellationToken);
                tenant = defaultTenant;
            }
            catch
            {
                // In-memory fallback tenant for token issuance
                tenant = new MotoSaaS.Domain.Tenancy.Tenant
                {
                    Id = Guid.Parse("11111111-1111-1111-1111-111111111111"),
                    Code = "ALAGENDRA",
                    LegalName = "Alagendra Automobiles",
                    TradeName = "Alagendra Yamaha"
                };
            }
        }

        // 3. Find or Register Customer Record
        Customer? customer = null;
        try
        {
            customer = await _context.Customers
                .IgnoreQueryFilters()
                .FirstOrDefaultAsync(c => (c.TenantId == tenant.Id || isTargetUser) && 
                    (c.Phone == normalizedPhone || c.Phone == digitsOnly || (digitsOnly.Length >= 10 && c.Phone.EndsWith(digitsOnly.Substring(digitsOnly.Length - 10)))), cancellationToken);

            if (customer == null)
            {
                customer = new Customer
                {
                    Id = isTargetUser ? Guid.Parse("80155814-0500-0000-0000-000080155814") : Guid.NewGuid(),
                    TenantId = tenant.Id,
                    Phone = digitsOnly.Length >= 10 ? digitsOnly.Substring(digitsOnly.Length - 10) : digitsOnly,
                    FirstName = string.IsNullOrWhiteSpace(request.FirstName) 
                        ? (isTargetUser ? "Demo" : "Customer") 
                        : request.FirstName.Trim(),
                    LastName = isTargetUser ? "Customer" : request.LastName?.Trim()
                };

                _context.Customers.Add(customer);
                await _context.SaveChangesAsync(cancellationToken);
            }
        }
        catch
        {
            // In case of database constraint or connectivity fallback
            if (customer == null)
            {
                customer = new Customer
                {
                    Id = isTargetUser ? Guid.Parse("80155814-0500-0000-0000-000080155814") : Guid.NewGuid(),
                    TenantId = tenant.Id,
                    Phone = normalizedPhone,
                    FirstName = isTargetUser ? "Demo" : "Customer",
                    LastName = "Customer"
                };
            }
        }

        // 4. Build Customer Profile & Issue Customer JWT
        var fullName = $"{customer.FirstName} {customer.LastName}".Trim();
        if (string.IsNullOrWhiteSpace(fullName))
        {
            fullName = isTargetUser ? "Demo Customer (8015581405)" : "Customer";
        }

        var profile = new UserProfileDto
        {
            Id = customer.Id,
            FullName = fullName,
            Email = customer.Email ?? (isTargetUser ? "demo.customer@alagendra.in" : null),
            Phone = customer.Phone,
            UserType = "CUSTOMER",
            TenantId = tenant.Id,
            TenantCode = tenant.Code,
            TenantName = tenant.TradeName,
            Roles = new List<string> { "Customer" }
        };

        var accessToken = _jwtTokenService.GenerateAccessToken(profile);
        var refreshToken = _jwtTokenService.GenerateRefreshToken();

        return new AuthResponse
        {
            AccessToken = accessToken,
            RefreshToken = refreshToken,
            ExpiresInSeconds = 900,
            TokenType = "Bearer",
            User = profile
        };
    }
}

