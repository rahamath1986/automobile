using MotoSaaS.Application.Features.Sales;
using MotoSaaS.Application.Features.Sales.Models;
using Xunit;

namespace MotoSaaS.UnitTests.Sales;

public class StaffSalesValidatorTests
{
    private readonly LeadCaptureRequestValidator _leadValidator = new();
    private readonly CreateFollowUpRequestValidator _followUpValidator = new();
    private readonly UpdateLeadStatusRequestValidator _statusValidator = new();
    private readonly AssignLeadRequestValidator _assignValidator = new();
    private readonly CompleteTestRideRequestValidator _completeTestRideValidator = new();
    private readonly CancelTestRideRequestValidator _cancelTestRideValidator = new();
    private readonly QuotationDraftRequestValidator _quotationValidator = new();

    [Fact]
    public void LeadCapture_ValidWalkIn_Passes()
    {
        var request = new LeadCaptureRequest
        {
            FirstName = "Rahul",
            LastName = "Nair",
            Phone = "+91 98765 43210",
            Email = "rahul@example.com",
            City = "Bengaluru",
            VariantId = Guid.NewGuid(),
            Source = "WalkIn",
            ExpectedPurchaseDate = DateTime.UtcNow.AddDays(20)
        };

        Assert.True(_leadValidator.Validate(request).IsValid);
    }

    [Fact]
    public void LeadCapture_MissingPhoneAndVariant_Fails()
    {
        var result = _leadValidator.Validate(new LeadCaptureRequest
        {
            FirstName = "Rahul",
            Phone = string.Empty,
            VariantId = Guid.Empty
        });

        Assert.False(result.IsValid);
        Assert.Contains(result.Errors, e => e.PropertyName == "Phone");
        Assert.Contains(result.Errors, e => e.PropertyName == "VariantId");
    }

    [Fact]
    public void LeadCapture_InvalidSource_Fails()
    {
        var result = _leadValidator.Validate(new LeadCaptureRequest
        {
            FirstName = "Rahul",
            Phone = "9876543210",
            VariantId = Guid.NewGuid(),
            Source = "CarrierPigeon"
        });

        Assert.False(result.IsValid);
        Assert.Contains(result.Errors, e => e.PropertyName == "Source");
    }

    [Fact]
    public void FollowUp_ValidSchedule_Passes()
    {
        var request = new CreateFollowUpRequest
        {
            Channel = "WhatsApp",
            Outcome = "Interested",
            Notes = "Wants an R15 in blue, comparing with the MT-15.",
            NextFollowUpAt = DateTime.UtcNow.AddDays(2)
        };

        Assert.True(_followUpValidator.Validate(request).IsValid);
    }

    [Fact]
    public void FollowUp_UnknownOutcomeAndPastSchedule_Fails()
    {
        var request = new CreateFollowUpRequest
        {
            Channel = "Phone",
            Outcome = "MaybeLater",
            NextFollowUpAt = DateTime.UtcNow.AddDays(-2)
        };

        var result = _followUpValidator.Validate(request);

        Assert.False(result.IsValid);
        Assert.Contains(result.Errors, e => e.PropertyName == "Outcome");
        Assert.Contains(result.Errors, e => e.PropertyName == "NextFollowUpAt");
    }

    [Fact]
    public void UpdateStatus_LostWithoutReason_Fails()
    {
        var result = _statusValidator.Validate(new UpdateLeadStatusRequest
        {
            Status = "Lost"
        });

        Assert.False(result.IsValid);
        Assert.Contains(result.Errors, e => e.PropertyName == "LostReason");
    }

    [Fact]
    public void UpdateStatus_LostWithReason_Passes()
    {
        var result = _statusValidator.Validate(new UpdateLeadStatusRequest
        {
            Status = "Lost",
            LostReason = "Purchased a competitor motorcycle."
        });

        Assert.True(result.IsValid);
    }

    [Fact]
    public void Assign_EmptyExecutive_Fails()
    {
        var result = _assignValidator.Validate(new AssignLeadRequest());

        Assert.False(result.IsValid);
        Assert.Contains(result.Errors, e => e.PropertyName == "SalesExecutiveId");
    }

    [Fact]
    public void CompleteTestRide_UnverifiedLicence_Fails()
    {
        var result = _completeTestRideValidator.Validate(new CompleteTestRideRequest
        {
            DrivingLicenseVerified = false,
            FeedbackNotes = "Good ride."
        });

        Assert.False(result.IsValid);
        Assert.Contains(result.Errors, e => e.PropertyName == "DrivingLicenseVerified");
    }

    [Fact]
    public void CancelTestRide_MissingReason_Fails()
    {
        var result = _cancelTestRideValidator.Validate(new CancelTestRideRequest());

        Assert.False(result.IsValid);
        Assert.Contains(result.Errors, e => e.PropertyName == "Reason");
    }

    [Fact]
    public void Quotation_EnquiryOnly_Passes()
    {
        var result = _quotationValidator.Validate(new QuotationDraftRequest
        {
            EnquiryId = Guid.NewGuid(),
            AccessoriesCharges = 2500m,
            DiscountAmount = 1000m,
            ValidDays = 7
        });

        Assert.True(result.IsValid);
    }

    [Fact]
    public void Quotation_DirectWithoutCustomer_Fails()
    {
        var result = _quotationValidator.Validate(new QuotationDraftRequest
        {
            VariantId = Guid.NewGuid(),
            ValidDays = 7
        });

        Assert.False(result.IsValid);
        Assert.Contains(result.Errors, e => e.PropertyName == "CustomerId");
    }

    [Fact]
    public void Quotation_NegativeDiscountAndInvalidValidity_Fails()
    {
        var result = _quotationValidator.Validate(new QuotationDraftRequest
        {
            EnquiryId = Guid.NewGuid(),
            DiscountAmount = -500m,
            ValidDays = 90
        });

        Assert.False(result.IsValid);
        Assert.Contains(result.Errors, e => e.PropertyName == "DiscountAmount");
        Assert.Contains(result.Errors, e => e.PropertyName == "ValidDays");
    }
}
