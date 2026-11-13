using MotoSaaS.Domain.Common;
using MotoSaaS.Domain.Identity;
using MotoSaaS.Domain.Tenancy;

namespace MotoSaaS.Domain.Sales;

/// <summary>
/// Contact channels used by sales executives when working a lead.
/// </summary>
public enum FollowUpChannel
{
    Phone,
    WhatsApp,
    Sms,
    Email,
    InPerson
}

/// <summary>
/// Recorded result of a sales follow-up. Outcomes drive the lead pipeline stage.
/// </summary>
public enum FollowUpOutcome
{
    Contacted,
    NotReachable,
    Interested,
    NotInterested,
    TestRideBooked,
    QuotationShared,
    Converted,
    Lost
}

/// <summary>
/// Immutable CRM history entry for a lead. The latest entry also carries the next
/// scheduled follow-up so a branch can work its pipeline from one query.
/// </summary>
public class EnquiryFollowUp : BaseEntity, ITenantScopedEntity, IBranchScopedEntity
{
    public Guid TenantId { get; set; }
    public Tenant? Tenant { get; set; }

    public Guid BranchId { get; set; }
    public Branch? Branch { get; set; }

    public Guid EnquiryId { get; set; }
    public Enquiry? Enquiry { get; set; }

    public Guid? PerformedByUserId { get; set; }
    public User? PerformedByUser { get; set; }

    public FollowUpChannel Channel { get; set; } = FollowUpChannel.Phone;
    public FollowUpOutcome Outcome { get; set; } = FollowUpOutcome.Contacted;
    public string? Notes { get; set; }
    public DateTime ContactedAt { get; set; } = DateTime.UtcNow;
    public DateTime? NextFollowUpAt { get; set; }
}
