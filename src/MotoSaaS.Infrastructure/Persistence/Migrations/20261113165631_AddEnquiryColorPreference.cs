using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MotoSaaS.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddEnquiryColorPreference : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "ColorId",
                table: "Enquiries",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Enquiries_ColorId",
                table: "Enquiries",
                column: "ColorId");

            migrationBuilder.AddForeignKey(
                name: "FK_Enquiries_VehicleColors_ColorId",
                table: "Enquiries",
                column: "ColorId",
                principalTable: "VehicleColors",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Enquiries_VehicleColors_ColorId",
                table: "Enquiries");

            migrationBuilder.DropIndex(
                name: "IX_Enquiries_ColorId",
                table: "Enquiries");

            migrationBuilder.DropColumn(
                name: "ColorId",
                table: "Enquiries");
        }
    }
}
