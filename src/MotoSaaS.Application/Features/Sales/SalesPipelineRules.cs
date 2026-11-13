using MotoSaaS.Domain.Sales;

namespace MotoSaaS.Application.Features.Sales;

/// <summary>
/// Central definition of the sales lead state machine. Keeping this in one place
/// prevents the API, follow-up automation and tests from drifting apart.
/// </summary>
public static class SalesPipelineRules
{
    private static readonly Dictionary<EnquiryStatus, HashSet<EnquiryStatus>> AllowedTransitions = new()
    {
        [EnquiryStatus.New] = new()
        {
            EnquiryStatus.Contacted,
            EnquiryStatus.TestRide,
            EnquiryStatus.Quoted,
            EnquiryStatus.Booked,
            EnquiryStatus.Lost
        },
        [EnquiryStatus.Contacted] = new()
        {
            EnquiryStatus.TestRide,
            EnquiryStatus.Quoted,
            EnquiryStatus.Booked,
            EnquiryStatus.Lost
        },
        [EnquiryStatus.TestRide] = new()
        {
            EnquiryStatus.Contacted,
            EnquiryStatus.Quoted,
            EnquiryStatus.Booked,
            EnquiryStatus.Lost
        },
        [EnquiryStatus.Quoted] = new()
        {
            EnquiryStatus.TestRide,
            EnquiryStatus.Booked,
            EnquiryStatus.Lost
        },
        [EnquiryStatus.Booked] = new()
        {
            EnquiryStatus.Lost
        },
        [EnquiryStatus.Lost] = new()
        {
            EnquiryStatus.New,
            EnquiryStatus.Contacted
        }
    };

    public static bool CanTransition(EnquiryStatus from, EnquiryStatus to) =>
        from == to || AllowedTransitions.TryGetValue(from, out var allowed) && allowed.Contains(to);

    /// <summary>
    /// Maps a recorded follow-up outcome to the pipeline stage it implies.
    /// Returns null when the outcome should not change the stage (e.g. not reachable).
    /// </summary>
    public static EnquiryStatus? MapOutcome(FollowUpOutcome outcome) => outcome switch
    {
        FollowUpOutcome.Interested => EnquiryStatus.Contacted,
        FollowUpOutcome.TestRideBooked => EnquiryStatus.TestRide,
        FollowUpOutcome.QuotationShared => EnquiryStatus.Quoted,
        FollowUpOutcome.Converted => EnquiryStatus.Booked,
        FollowUpOutcome.NotInterested => EnquiryStatus.Lost,
        FollowUpOutcome.Lost => EnquiryStatus.Lost,
        _ => null
    };

    public static bool IsOpen(EnquiryStatus status) =>
        status is not EnquiryStatus.Booked and not EnquiryStatus.Lost;
}
