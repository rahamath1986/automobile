# Multi-stage build for MotoSaaS ASP.NET Core Web API
FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine AS build
WORKDIR /app

# Copy csproj files and restore to leverage Docker layer caching
COPY src/MotoSaaS.Domain/MotoSaaS.Domain.csproj src/MotoSaaS.Domain/
COPY src/MotoSaaS.Application/MotoSaaS.Application.csproj src/MotoSaaS.Application/
COPY src/MotoSaaS.Infrastructure/MotoSaaS.Infrastructure.csproj src/MotoSaaS.Infrastructure/
COPY src/MotoSaaS.Api/MotoSaaS.Api.csproj src/MotoSaaS.Api/
COPY src/MotoSaaS.sln src/

RUN dotnet restore src/MotoSaaS.Api/MotoSaaS.Api.csproj

# Copy the entire source code and publish
COPY src/ src/
WORKDIR /app/src/MotoSaaS.Api
RUN dotnet publish -c Release -o /app/publish /p:UseAppHost=false

# Production runtime image
FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine AS final
WORKDIR /app

# Install dependencies for invariant-free globalization & timezone support
RUN apk add --no-cache icu-libs tzdata

ENV ASPNETCORE_HTTP_PORTS=8080 \
    ASPNETCORE_ENVIRONMENT=Production \
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false

EXPOSE 8080

COPY --from=build /app/publish .

ENTRYPOINT ["dotnet", "MotoSaaS.Api.dll"]

