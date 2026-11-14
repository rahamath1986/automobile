using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MotoSaaS.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class Phase11ServiceWorkshop : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "FeedbackComment",
                table: "JobCards",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "FeedbackRating",
                table: "JobCards",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "InspectionChecklist",
                table: "JobCards",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "FeedbackComment",
                table: "JobCards");

            migrationBuilder.DropColumn(
                name: "FeedbackRating",
                table: "JobCards");

            migrationBuilder.DropColumn(
                name: "InspectionChecklist",
                table: "JobCards");
        }
    }
}
