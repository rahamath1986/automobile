# Multi-stage build for MotoSaaS Unified Platform (Backend API + Next.js Portals)

# ==========================================
# Stage 1: Build Super Admin Portal
# ==========================================
FROM node:20-alpine AS build-super-admin
WORKDIR /web/super_admin_portal
COPY web/super_admin_portal/package*.json ./
RUN npm ci || npm install
COPY web/super_admin_portal/ ./
RUN npm run build

# ==========================================
# Stage 2: Build Org Admin Portal
# ==========================================
FROM node:20-alpine AS build-org-admin
WORKDIR /web/org_admin_portal
COPY web/org_admin_portal/package*.json ./
RUN npm ci || npm install
COPY web/org_admin_portal/ ./
RUN npm run build

# ==========================================
# Stage 3: Build Branch Operations Portal
# ==========================================
FROM node:20-alpine AS build-branch
WORKDIR /web/branch_portal
COPY web/branch_portal/package*.json ./
RUN npm ci || npm install
COPY web/branch_portal/ ./
RUN npm run build

# ==========================================
# Stage 4: Build .NET Backend API
# ==========================================
FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine AS build-dotnet
WORKDIR /app

# Copy csproj files and restore to leverage Docker layer caching
COPY src/MotoSaaS.Domain/MotoSaaS.Domain.csproj src/MotoSaaS.Domain/
COPY src/MotoSaaS.Application/MotoSaaS.Application.csproj src/MotoSaaS.Application/
COPY src/MotoSaaS.Infrastructure/MotoSaaS.Infrastructure.csproj src/MotoSaaS.Infrastructure/
COPY src/MotoSaaS.Api/MotoSaaS.Api.csproj src/MotoSaaS.Api/
COPY src/MotoSaaS.sln src/

RUN dotnet restore src/MotoSaaS.Api/MotoSaaS.Api.csproj

# Copy backend source code and publish
COPY src/ src/
WORKDIR /app/src/MotoSaaS.Api
RUN dotnet publish -c Release -o /app/publish /p:UseAppHost=false

# ==========================================
# Stage 5: Production Runtime Container
# ==========================================
FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine AS final
WORKDIR /app

# Install dependencies for invariant-free globalization & timezone support
RUN apk add --no-cache icu-libs tzdata

ENV ASPNETCORE_HTTP_PORTS=8080 \
    ASPNETCORE_ENVIRONMENT=Production \
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false

EXPOSE 8080

COPY --from=build-dotnet /app/publish .

# Copy static export web portals into wwwroot
COPY --from=build-super-admin /web/super_admin_portal/out ./wwwroot/super-admin
COPY --from=build-org-admin /web/org_admin_portal/out ./wwwroot/org-admin
COPY --from=build-branch /web/branch_portal/out ./wwwroot/branch

ENTRYPOINT ["dotnet", "MotoSaaS.Api.dll"]
