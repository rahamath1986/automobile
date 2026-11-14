using System.Net;
using System.Text.Json;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using MotoSaaS.Application.Common.Models;

namespace MotoSaaS.Api.Middlewares;

public class GlobalExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<GlobalExceptionHandlingMiddleware> _logger;

    public GlobalExceptionHandlingMiddleware(RequestDelegate next, ILogger<GlobalExceptionHandlingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (ValidationException valEx)
        {
            _logger.LogWarning(valEx, "Validation error occurred during request processing.");
            await HandleValidationExceptionAsync(context, valEx);
        }
        catch (DbUpdateException ex) when (ex is DbUpdateConcurrencyException ||
            ex.InnerException is PostgresException { SqlState: PostgresErrorCodes.UniqueViolation })
        {
            context.Response.StatusCode = StatusCodes.Status409Conflict;
            await context.Response.WriteAsJsonAsync(ApiResponse<object>.Failure(
                "The record changed or already exists. Refresh and retry.", 409));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "An unhandled exception occurred during request execution: {Message}", ex.Message);
            await HandleExceptionAsync(context, ex);
        }
    }

    private static async Task HandleValidationExceptionAsync(HttpContext context, ValidationException exception)
    {
        context.Response.ContentType = "application/json";
        context.Response.StatusCode = (int)HttpStatusCode.BadRequest;

        var errors = exception.Errors.Select(e => new ValidationErrorItem
        {
            Field = e.PropertyName,
            Message = e.ErrorMessage
        }).ToList();

        var response = ApiResponse<object>.Failure(
            message: "Validation failed for one or more fields.",
            statusCode: (int)HttpStatusCode.BadRequest,
            errors: errors
        );

        var json = JsonSerializer.Serialize(response, new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase });
        await context.Response.WriteAsync(json);
    }

    private static async Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        context.Response.ContentType = "application/json";
        context.Response.StatusCode = (int)HttpStatusCode.InternalServerError;

        var response = ApiResponse<object>.Failure(
            message: "An internal server error occurred. Please try again later.",
            statusCode: (int)HttpStatusCode.InternalServerError
        );

        var json = JsonSerializer.Serialize(response, new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase });
        await context.Response.WriteAsync(json);
    }
}

