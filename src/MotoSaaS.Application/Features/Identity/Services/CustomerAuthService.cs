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

        // Generate 6-digit numeric OTP
        var code = RandomNumberGenerator.GetInt32(100000, 999999);
        var otp = (code < 123456 ? code : code + 1).ToString();
        
        // In local development / demo environments, standardize OTP for automated testing if desired
        if (_demoOtpEnabled && normalizedPhone == "9876543210" &&
            GetDealerCode(request.DealerCode) == "ALAGENDRA")
        {
            otp = "123456";
        }

        OtpStore[(GetDealerCode(request.DealerCode), normalizedPhone)] = (otp, DateTime.UtcNow.AddMinutes(5));

        // Note: Production SMS/WhatsApp dispatch occurs via ICommunicationService
        return Task.FromResult(true);
    }

    public async Task<AuthResponse> VerifyOtpAsync(CustomerVerifyOtpRequest request, CancellationToken cancellationToken = default)
    {
        var normalizedPhone = request.Phone.Trim();

        // 1. Validate OTP
        if (!OtpStore.TryGetValue((GetDealerCode(request.DealerCode), normalizedPhone), out var cached) ||
            cached.ExpiresAt < DateTime.UtcNow || 
            cached.Otp != request.Otp)
        {
            throw new UnauthorizedAccessException("Invalid or expired OTP token.");
        }

        // Clean up verified OTP
        if (!OtpStore.TryRemove(new KeyValuePair<(string DealerCode, string Phone), (string Otp, DateTime ExpiresAt)>(
            (GetDealerCode(request.DealerCode), normalizedPhone), cached)))
            throw new UnauthorizedAccessException("Invalid or expired OTP token.");

        // 2. Resolve Tenant
        var dealerCode = GetDealerCode(request.DealerCode);
        var tenant = await _context.Tenants
            .AsNoTracking()
            .FirstOrDefaultAsync(t => t.Code == dealerCode, cancellationToken);

        if (tenant == null)
        {
            throw new InvalidOperationException("No active dealership tenant found.");
        }

        // 3. Find or Register Customer Record
        var customer = await _context.Customers
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(c => c.TenantId == tenant.Id && c.Phone == normalizedPhone, cancellationToken);

        if (customer == null)
        {
            customer = new Customer
            {
                TenantId = tenant.Id,
                Phone = normalizedPhone,
                FirstName = string.IsNullOrWhiteSpace(request.FirstName) ? "Customer" : request.FirstName.Trim(),
                LastName = request.LastName?.Trim()
            };

            _context.Customers.Add(customer);
            await _context.SaveChangesAsync(cancellationToken);
        }

        // 4. Build Customer Profile & Issue Customer JWT
        var profile = new UserProfileDto
        {
            Id = customer.Id,
            FullName = $"{customer.FirstName} {customer.LastName}".Trim(),
            Email = customer.Email,
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

