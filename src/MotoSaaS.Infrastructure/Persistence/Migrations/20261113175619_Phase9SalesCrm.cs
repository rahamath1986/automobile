using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MotoSaaS.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class Phase9SalesCrm : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_TestRides_TenantId",
                table: "TestRides");

            migrationBuilder.DropIndex(
                name: "IX_Enquiries_TenantId",
                table: "Enquiries");

            migrationBuilder.AddColumn<decimal>(
                name: "HandlingCharges",
                table: "Quotations",
                type: "numeric",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<string>(
                name: "Notes",
                table: "Quotations",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "LastContactedAt",
                table: "Enquiries",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "LostReason",
                table: "Enquiries",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "NextFollowUpAt",
                table: "Enquiries",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "EnquiryFollowUps",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TenantId = table.Column<Guid>(type: "uuid", nullable: false),
                    BranchId = table.Column<Guid>(type: "uuid", nullable: false),
                    EnquiryId = table.Column<Guid>(type: "uuid", nullable: false),
                    PerformedByUserId = table.Column<Guid>(type: "uuid", nullable: true),
                    Channel = table.Column<int>(type: "integer", nullable: false),
                    Outcome = table.Column<int>(type: "integer", nullable: false),
                    Notes = table.Column<string>(type: "text", nullable: true),
                    ContactedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    NextFollowUpAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_EnquiryFollowUps", x => x.Id);
                    table.ForeignKey(
                        name: "FK_EnquiryFollowUps_Branches_BranchId",
                        column: x => x.BranchId,
                        principalTable: "Branches",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_EnquiryFollowUps_Enquiries_EnquiryId",
                        column: x => x.EnquiryId,
                        principalTable: "Enquiries",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_EnquiryFollowUps_Tenants_TenantId",
                        column: x => x.TenantId,
                        principalTable: "Tenants",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_EnquiryFollowUps_Users_PerformedByUserId",
                        column: x => x.PerformedByUserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateIndex(
                name: "IX_TestRides_TenantId_BranchId_ScheduledAt",
                table: "TestRides",
                columns: new[] { "TenantId", "BranchId", "ScheduledAt" });

            migrationBuilder.CreateIndex(
                name: "IX_Quotations_TenantId_BranchId_Status",
                table: "Quotations",
                columns: new[] { "TenantId", "BranchId", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_Enquiries_TenantId_BranchId_Status",
                table: "Enquiries",
                columns: new[] { "TenantId", "BranchId", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_Enquiries_TenantId_NextFollowUpAt",
                table: "Enquiries",
                columns: new[] { "TenantId", "NextFollowUpAt" });

            migrationBuilder.CreateIndex(
                name: "IX_EnquiryFollowUps_BranchId",
                table: "EnquiryFollowUps",
                column: "BranchId");

            migrationBuilder.CreateIndex(
                name: "IX_EnquiryFollowUps_EnquiryId",
                table: "EnquiryFollowUps",
                column: "EnquiryId");

            migrationBuilder.CreateIndex(
                name: "IX_EnquiryFollowUps_PerformedByUserId",
                table: "EnquiryFollowUps",
                column: "PerformedByUserId");

            migrationBuilder.CreateIndex(
                name: "IX_EnquiryFollowUps_TenantId_EnquiryId_ContactedAt",
                table: "EnquiryFollowUps",
                columns: new[] { "TenantId", "EnquiryId", "ContactedAt" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "EnquiryFollowUps");

            migrationBuilder.DropIndex(
                name: "IX_TestRides_TenantId_BranchId_ScheduledAt",
                table: "TestRides");

            migrationBuilder.DropIndex(
                name: "IX_Quotations_TenantId_BranchId_Status",
                table: "Quotations");

            migrationBuilder.DropIndex(
                name: "IX_Enquiries_TenantId_BranchId_Status",
                table: "Enquiries");

            migrationBuilder.DropIndex(
                name: "IX_Enquiries_TenantId_NextFollowUpAt",
                table: "Enquiries");

            migrationBuilder.DropColumn(
                name: "HandlingCharges",
                table: "Quotations");

            migrationBuilder.DropColumn(
                name: "Notes",
                table: "Quotations");

            migrationBuilder.DropColumn(
                name: "LastContactedAt",
                table: "Enquiries");

            migrationBuilder.DropColumn(
                name: "LostReason",
                table: "Enquiries");

            migrationBuilder.DropColumn(
                name: "NextFollowUpAt",
                table: "Enquiries");

            migrationBuilder.CreateIndex(
                name: "IX_TestRides_TenantId",
                table: "TestRides",
                column: "TenantId");

            migrationBuilder.CreateIndex(
                name: "IX_Enquiries_TenantId",
                table: "Enquiries",
                column: "TenantId");
        }
    }
}
