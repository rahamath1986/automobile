using MotoSaaS.Application.Features.Sales;
using MotoSaaS.Domain.Sales;
using Xunit;

namespace MotoSaaS.UnitTests.Sales;

public class SalesPipelineRulesTests
{
    [Theory]
    [InlineData(EnquiryStatus.New, EnquiryStatus.Contacted)]
    [InlineData(EnquiryStatus.New, EnquiryStatus.Quoted)]
    [InlineData(EnquiryStatus.Contacted, EnquiryStatus.TestRide)]
    [InlineData(EnquiryStatus.TestRide, EnquiryStatus.Quoted)]
    [InlineData(EnquiryStatus.Quoted, EnquiryStatus.Booked)]
    [InlineData(EnquiryStatus.Booked, EnquiryStatus.Lost)]
    [InlineData(EnquiryStatus.Lost, EnquiryStatus.Contacted)]
    public void CanTransition_AllowedMoves_ReturnsTrue(EnquiryStatus from, EnquiryStatus to)
    {
        Assert.True(SalesPipelineRules.CanTransition(from, to));
    }

    [Theory]
    [InlineData(EnquiryStatus.Booked, EnquiryStatus.Quoted)]
    [InlineData(EnquiryStatus.Lost, EnquiryStatus.Quoted)]
    [InlineData(EnquiryStatus.Quoted, EnquiryStatus.New)]
    [InlineData(EnquiryStatus.Contacted, EnquiryStatus.New)]
    public void CanTransition_DisallowedMoves_ReturnsFalse(EnquiryStatus from, EnquiryStatus to)
    {
        Assert.False(SalesPipelineRules.CanTransition(from, to));
    }

    [Theory]
    [InlineData(FollowUpOutcome.Interested, EnquiryStatus.Contacted)]
    [InlineData(FollowUpOutcome.TestRideBooked, EnquiryStatus.TestRide)]
    [InlineData(FollowUpOutcome.QuotationShared, EnquiryStatus.Quoted)]
    [InlineData(FollowUpOutcome.Converted, EnquiryStatus.Booked)]
    [InlineData(FollowUpOutcome.NotInterested, EnquiryStatus.Lost)]
    [InlineData(FollowUpOutcome.Lost, EnquiryStatus.Lost)]
    public void MapOutcome_ReturnsExpectedStage(FollowUpOutcome outcome, EnquiryStatus expected)
    {
        Assert.Equal(expected, SalesPipelineRules.MapOutcome(outcome));
    }

    [Theory]
    [InlineData(FollowUpOutcome.Contacted)]
    [InlineData(FollowUpOutcome.NotReachable)]
    public void MapOutcome_NonStageChangingOutcome_ReturnsNull(FollowUpOutcome outcome)
    {
        Assert.Null(SalesPipelineRules.MapOutcome(outcome));
    }

    [Theory]
    [InlineData(EnquiryStatus.New, true)]
    [InlineData(EnquiryStatus.Quoted, true)]
    [InlineData(EnquiryStatus.Booked, false)]
    [InlineData(EnquiryStatus.Lost, false)]
    public void IsOpen_ReflectsTerminalStages(EnquiryStatus status, bool expected)
    {
        Assert.Equal(expected, SalesPipelineRules.IsOpen(status));
    }
}
