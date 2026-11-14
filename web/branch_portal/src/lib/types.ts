export type StaffRole = 
  | 'BranchManager' 
  | 'SalesExecutive' 
  | 'ServiceAdvisor' 
  | 'Technician' 
  | 'Cashier' 
  | 'OrgAdmin';

export interface StaffUser {
  id: string;
  name: string;
  email: string;
  role: StaffRole;
  tenantId: string;
  tenantCode: string;
  tenantName: string;
  branchId: string;
  branchName: string;
}

export interface Branch {
  id: string;
  name: string;
  code: string;
  city: string;
  address: string;
  phone: string;
}

export type LeadStage = 
  | 'NEW' 
  | 'CONTACTED' 
  | 'TEST_RIDE_BOOKED' 
  | 'QUOTATION_SHARED' 
  | 'BOOKED' 
  | 'LOST';

export interface Lead {
  id: string;
  customerName: string;
  phone: string;
  email?: string;
  preferredModel: string;
  preferredVariant?: string;
  preferredColor?: string;
  stage: LeadStage;
  assignedStaffId?: string;
  assignedStaffName?: string;
  notes?: string;
  source: 'WALK_IN' | 'MOBILE_APP' | 'WEBSITE' | 'PHONE';
  createdAt: string;
  updatedAt: string;
}

export interface Quotation {
  id: string;
  quotationNumber: string;
  customerName: string;
  customerPhone: string;
  modelName: string;
  variantName: string;
  colorName: string;
  exShowroom: number;
  rtoCharges: number;
  insuranceCharges: number;
  accessoriesAmount: number;
  handlingCharges: number;
  discountAmount: number;
  onRoadPrice: number;
  downPayment: number;
  loanAmount: number;
  interestRate: number;
  tenureMonths: number;
  monthlyEmi: number;
  status: 'DRAFT' | 'CONFIRMED' | 'EXPIRED';
  createdAt: string;
}

export type InventoryStatus = 
  | 'EXPECTED' 
  | 'RECEIVED' 
  | 'AVAILABLE' 
  | 'RESERVED' 
  | 'ALLOCATED' 
  | 'SOLD' 
  | 'DELIVERED';

export interface InventoryItem {
  id: string;
  vin: string;
  engineNumber: string;
  modelName: string;
  variantName: string;
  colorName: string;
  status: InventoryStatus;
  branchId: string;
  branchName: string;
  arrivalDate: string;
  customerName?: string;
  bookingId?: string;
}

export type JobCardStatus = 
  | 'OPEN' 
  | 'ESTIMATED' 
  | 'APPROVED' 
  | 'WORK_IN_PROGRESS' 
  | 'QUALITY_CHECK' 
  | 'READY_FOR_DELIVERY' 
  | 'CLOSED';

export interface JobCard {
  id: string;
  jobCardNumber: string;
  customerName: string;
  customerPhone: string;
  registrationNumber: string;
  modelName: string;
  serviceType: 'FREE_SERVICE' | 'PAID_PERIODIC' | 'RUNNING_REPAIR' | 'ACCIDENTAL';
  status: JobCardStatus;
  assignedTechnician?: string;
  bayNumber?: string;
  odometerReading: number;
  fuelLevelPercent: number;
  complaints: string[];
  estimatedLabourCost: number;
  estimatedPartsCost: number;
  totalEstimatedAmount: number;
  customerApproved: boolean;
  createdAt: string;
  promisedDeliveryAt: string;
}

export type PaymentMethod = 
  | 'CASH' 
  | 'UPI' 
  | 'CREDIT_DEBIT_CARD' 
  | 'NET_BANKING' 
  | 'FINANCE_DISBURSEMENT';

export interface PaymentReceipt {
  id: string;
  receiptNumber: string;
  customerName: string;
  referenceType: 'VEHICLE_BOOKING' | 'SERVICE_INVOICE' | 'ACCESSORIES';
  referenceId: string;
  amount: number;
  paymentMethod: PaymentMethod;
  transactionRef?: string;
  financierName?: string;
  collectedBy: string;
  createdAt: string;
  notes?: string;
}

