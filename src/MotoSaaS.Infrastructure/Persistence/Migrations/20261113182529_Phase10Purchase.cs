using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MotoSaaS.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class Phase10Purchase : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Payments_TenantId",
                table: "Payments");

            migrationBuilder.AddColumn<Guid>(
                name: "RequestId",
                table: "Payments",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsDemo",
                table: "Invoices",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<int>(
                name: "ConcurrencyVersion",
                table: "Bookings",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<Guid>(
                name: "CustomerVehicleId",
                table: "Bookings",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "DeliveredAt",
                table: "Bookings",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "DeliveredBy",
                table: "Bookings",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "HandoverRecipient",
                table: "Bookings",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "InspectedBy",
                table: "Bookings",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "InspectionAt",
                table: "Bookings",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "InspectionNotes",
                table: "Bookings",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "InspectionPassed",
                table: "Bookings",
                type: "boolean",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Payments_TenantId_BookingId_RequestId",
                table: "Payments",
                columns: new[] { "TenantId", "BookingId", "RequestId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Bookings_CustomerVehicleId",
                table: "Bookings",
                column: "CustomerVehicleId");

            migrationBuilder.AddForeignKey(
                name: "FK_Bookings_CustomerVehicles_CustomerVehicleId",
                table: "Bookings",
                column: "CustomerVehicleId",
                principalTable: "CustomerVehicles",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Bookings_CustomerVehicles_CustomerVehicleId",
                table: "Bookings");

            migrationBuilder.DropIndex(
                name: "IX_Payments_TenantId_BookingId_RequestId",
                table: "Payments");

            migrationBuilder.DropIndex(
                name: "IX_Bookings_CustomerVehicleId",
                table: "Bookings");

            migrationBuilder.DropColumn(
                name: "RequestId",
                table: "Payments");

            migrationBuilder.DropColumn(
                name: "IsDemo",
                table: "Invoices");

            migrationBuilder.DropColumn(
                name: "ConcurrencyVersion",
                table: "Bookings");

            migrationBuilder.DropColumn(
                name: "CustomerVehicleId",
                table: "Bookings");

            migrationBuilder.DropColumn(
                name: "DeliveredAt",
                table: "Bookings");

            migrationBuilder.DropColumn(
                name: "DeliveredBy",
                table: "Bookings");

            migrationBuilder.DropColumn(
                name: "HandoverRecipient",
                table: "Bookings");

            migrationBuilder.DropColumn(
                name: "InspectedBy",
                table: "Bookings");

            migrationBuilder.DropColumn(
                name: "InspectionAt",
                table: "Bookings");

            migrationBuilder.DropColumn(
                name: "InspectionNotes",
                table: "Bookings");

            migrationBuilder.DropColumn(
                name: "InspectionPassed",
                table: "Bookings");

            migrationBuilder.CreateIndex(
                name: "IX_Payments_TenantId",
                table: "Payments",
                column: "TenantId");
        }
    }
}
