using MotoSaaS.Application.Features.Sales;
using MotoSaaS.Application.Features.Sales.Models;
using MotoSaaS.Application.Features.Sales.Services;
using Xunit;

namespace MotoSaaS.UnitTests.Sales;

public class CustomerSalesValidatorTests
{
    private readonly CreateEnquiryRequestValidator _enquiryValidator = new();
    private readonly CreateTestRideRequestValidator _testRideValidator = new();

    [Fact]
    public void Enquiry_ValidGuestLead_PassesValidation()
    {
        var request = new CreateEnquiryRequest
        {
            BranchId = Guid.NewGuid(),
            VariantId = Guid.NewGuid(),
            FirstName = "Aarav",
            Phone = "+91 98765 43210",
            Email = "aarav@example.com",
            Notes = "Interested in the R15M",
            ExpectedPurchaseDate = DateTime.UtcNow.AddDays(10)
        };

        var result = _enquiryValidator.Validate(request);

        Assert.True(result.IsValid);
    }

    [Fact]
    public void Enquiry_MissingIds_FailsValidation()
    {
        var result = _enquiryValidator.Validate(new CreateEnquiryRequest());

        Assert.False(result.IsValid);
        Assert.Contains(result.Errors, e => e.PropertyName == "BranchId");
        Assert.Contains(result.Errors, e => e.PropertyName == "VariantId");
    }

    [Fact]
    public void Enquiry_InvalidEmail_FailsValidation()
    {
        var request = new CreateEnquiryRequest
        {
            BranchId = Guid.NewGuid(),
            VariantId = Guid.NewGuid(),
            Email = "not-an-email"
        };

        var result = _enquiryValidator.Validate(request);

        Assert.False(result.IsValid);
        Assert.Contains(result.Errors, e => e.PropertyName == "Email");
    }

    [Fact]
    public void TestRide_PastDate_FailsValidation()
    {
        var request = new CreateTestRideRequest
        {
            BranchId = Guid.NewGuid(),
            VariantId = Guid.NewGuid(),
            ScheduledAt = DateTime.UtcNow.AddHours(-1)
        };

        var result = _testRideValidator.Validate(request);

        Assert.False(result.IsValid);
        Assert.Contains(result.Errors, e => e.PropertyName == "ScheduledAt");
    }

    [Fact]
    public void TestRide_FutureDate_PassesValidation()
    {
        var request = new CreateTestRideRequest
        {
            BranchId = Guid.NewGuid(),
            VariantId = Guid.NewGuid(),
            ScheduledAt = DateTime.UtcNow.AddDays(2),
            DrivingLicenseNumber = "KA0120230001234"
        };

        var result = _testRideValidator.Validate(request);

        Assert.True(result.IsValid);
    }

    [Theory]
    [InlineData("9876543210", "+919876543210")]
    [InlineData("+919876543210", "+919876543210")]
    [InlineData("09876543210", "+919876543210")]
    [InlineData("919876543210", "+919876543210")]
    public void NormalizePhone_ProducesConsistentIndianFormat(string input, string expected)
    {
        Assert.Equal(expected, CustomerSalesService.NormalizePhone(input));
    }
}
