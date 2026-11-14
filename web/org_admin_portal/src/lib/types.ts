export type StaffRole = 
  | 'OrgAdmin'
  | 'BranchManager' 
  | 'SalesExecutive' 
  | 'ServiceAdvisor' 
  | 'Technician' 
  | 'Cashier';

export interface OrgAdminUser {
  id: string;
  name: string;
  email: string;
  role: StaffRole;
  tenantId: string;
  tenantCode: string;
  tenantName: string;
}

export interface BranchDetail {
  id: string;
  code: string;
  name: string;
  city: string;
  address: string;
  phone: string;
  isHeadquarters: boolean;
  activeSalesCount: number;
  activeTechCount: number;
  bayCount: number;
  currentStock: number;
  monthlyRevenue: number;
  managerName: string;
}

export interface StaffMember {
  id: string;
  name: string;
  email: string;
  phone: string;
  role: StaffRole;
  branchId: string;
  branchName: string;
  isActive: boolean;
  joinedDate: string;
  monthlyTargetUnits?: number;
  currentUnitsSold?: number;
}

export interface RegionalPricingRule {
  id: string;
  modelCode: string;
  modelName: string;
  variantCode: string;
  variantName: string;
  exShowroomBase: number;
  rtoPercent: number;
  insuranceFloor: number;
  accessoriesPackagePrice: number;
  handlingCap: number;
  maxSalesDiscount: number;
  maxManagerDiscount: number;
  effectiveOnRoadEstimate: number;
}

export type TransferStatus = 
  | 'REQUESTED' 
  | 'APPROVED' 
  | 'DISPATCHED' 
  | 'RECEIVED' 
  | 'REJECTED';

export interface InterBranchTransfer {
  id: string;
  transferNumber: string;
  vin: string;
  modelName: string;
  variantName: string;
  colorName: string;
  fromBranchId: string;
  fromBranchName: string;
  toBranchId: string;
  toBranchName: string;
  status: TransferStatus;
  requestedBy: string;
  approvedBy?: string;
  transitCarrier?: string;
  requestedAt: string;
  completedAt?: string;
}

export interface FinancialMetric {
  period: string;
  grossSalesRevenue: number;
  workshopServiceRevenue: number;
  totalCollected: number;
  gstCollected: number;
  unitsDelivered: number;
  jobCardsCompleted: number;
}

