export type SubscriptionTier = 'STARTER' | 'PROFESSIONAL' | 'ENTERPRISE';
export type TenantStatus = 'Active' | 'Trial' | 'Suspended' | 'PastDue' | 'Cancelled';
export type HealthStatus = 'Healthy' | 'Degraded' | 'Critical';
export type AuditSeverity = 'Info' | 'Warning' | 'Critical';

export interface SuperAdminUser {
  id: string;
  name: string;
  email: string;
  role: 'SuperAdmin' | 'PlatformOps' | 'ComplianceOfficer';
  avatar?: string;
}

export interface TenantSummary {
  id: string;
  code: string;
  legalName: string;
  tradeName: string;
  taxId: string;
  primaryOem: string;
  oemBrands: string[];
  status: TenantStatus;
  subscriptionPlan: SubscriptionTier;
  branchesCount: number;
  maxBranches: number;
  staffCount: number;
  maxStaff: number;
  inventoryUnits: number;
  maxInventory: number;
  mrr: number; // in INR
  billingCycle: 'Monthly' | 'Annual';
  trialEndsAt?: string;
  createdAt: string;
  contactEmail: string;
  contactPhone: string;
  customDomain?: string;
  primaryColor: string;
  secondaryColor: string;
}

export interface SubscriptionPlanDef {
  id: string;
  code: SubscriptionTier;
  name: string;
  description: string;
  monthlyPrice: number;
  annualPrice: number;
  maxBranches: number;
  maxStaff: number;
  maxInventory: number;
  features: {
    showroom3D: boolean;
    afterSalesService: boolean;
    emiCalculator: boolean;
    financierSchemes: boolean;
    multiBranchTransfer: boolean;
    accountingExport: boolean;
    advancedAnalytics: boolean;
    customBranding: boolean;
    prioritySLA: boolean;
    whatsappIntegration: boolean;
  };
  activeTenantsCount: number;
  isPopular?: boolean;
}

export interface OemBrand {
  id: string;
  code: string;
  name: string;
  country: string;
  logoUrl?: string;
  totalModels: number;
  franchisedTenantsCount: number;
  isActive: boolean;
}

export interface GlobalVehicleModel {
  id: string;
  oemCode: string;
  oemName: string;
  code: string;
  name: string;
  category: 'Motorcycle' | 'Scooter' | 'ElectricVehicle';
  fuelType: 'Petrol' | 'Electric';
  engineCc?: number;
  powerBhp?: string;
  torqueNm?: string;
  transmission: string;
  mileageKmpl?: number;
  baseExShowroomPrice: number;
  variantsCount: number;
  colorsCount: number;
  imageUrl: string;
  isActive: boolean;
  syncedTenantsCount: number;
}

export interface PlatformMetric {
  title: string;
  value: string;
  change: string;
  trend: 'up' | 'down' | 'neutral';
  subtext: string;
}

export interface PlatformHealthMetric {
  service: string;
  category: 'Compute' | 'Database' | 'Cache' | 'Storage' | 'Gateway';
  status: HealthStatus;
  latencyMs: number;
  uptimePercent: number;
  cpuUsagePercent: number;
  memoryUsagePercent: number;
  lastChecked: string;
  details: string;
}

export interface AuditLogEntry {
  id: string;
  timestamp: string;
  actorEmail: string;
  actorRole: string;
  tenantCode: string;
  tenantName: string;
  category: 'TenantLifecycle' | 'Subscription' | 'Security' | 'CatalogSync' | 'QuotaOverride';
  action: string;
  severity: AuditSeverity;
  ipAddress: string;
  details: string;
}
