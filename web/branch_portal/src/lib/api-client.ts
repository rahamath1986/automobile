import { DEMO_LEADS, DEMO_QUOTATIONS, DEMO_INVENTORY, DEMO_JOB_CARDS, DEMO_PAYMENTS } from './mock-data';
import { Lead, Quotation, InventoryItem, JobCard, PaymentReceipt } from './types';

const API_BASE = process.env.NEXT_PUBLIC_API_URL || (typeof window !== 'undefined' ? '/automobile/api/v1' : 'http://localhost:5053/api/v1');

export class BranchApiClient {
  private dealerCode: string;
  private token?: string;

  constructor(dealerCode: string = 'ALAGENDRA', token?: string) {
    this.dealerCode = dealerCode;
    this.token = token;
  }

  private get headers(): HeadersInit {
    const h: Record<string, string> = {
      'Content-Type': 'application/json',
      'X-Dealer-Code': this.dealerCode,
    };
    if (this.token) {
      h['Authorization'] = `Bearer ${this.token}`;
    }
    return h;
  }

  async getLeads(): Promise<Lead[]> {
    try {
      const res = await fetch(`${API_BASE}/staff/sales/leads`, {
        headers: this.headers,
      });
      if (res.ok) {
        const json = await res.json();
        if (json.data && Array.isArray(json.data)) return json.data;
      }
    } catch {
      // fallback
    }
    return DEMO_LEADS;
  }

  async getQuotations(): Promise<Quotation[]> {
    try {
      const res = await fetch(`${API_BASE}/quotations`, {
        headers: this.headers,
      });
      if (res.ok) {
        const json = await res.json();
        if (json.data && Array.isArray(json.data)) return json.data;
      }
    } catch {
      // fallback
    }
    return DEMO_QUOTATIONS;
  }

  async getInventory(): Promise<InventoryItem[]> {
    try {
      const res = await fetch(`${API_BASE}/inventory/stock`, {
        headers: this.headers,
      });
      if (res.ok) {
        const json = await res.json();
        if (json.data && Array.isArray(json.data)) return json.data;
      }
    } catch {
      // fallback
    }
    return DEMO_INVENTORY;
  }

  async getJobCards(): Promise<JobCard[]> {
    try {
      const res = await fetch(`${API_BASE}/service/job-cards`, {
        headers: this.headers,
      });
      if (res.ok) {
        const json = await res.json();
        if (json.data && Array.isArray(json.data)) return json.data;
      }
    } catch {
      // fallback
    }
    return DEMO_JOB_CARDS;
  }

  async getPayments(): Promise<PaymentReceipt[]> {
    try {
      const res = await fetch(`${API_BASE}/billing/payments`, {
        headers: this.headers,
      });
      if (res.ok) {
        const json = await res.json();
        if (json.data && Array.isArray(json.data)) return json.data;
      }
    } catch {
      // fallback
    }
    return DEMO_PAYMENTS;
  }

  async calculateEmi(params: {
    vehiclePrice: number;
    downPayment: number;
    annualInterestRatePercent: number;
    tenureMonths: number;
  }) {
    try {
      const res = await fetch(`${API_BASE}/finance/calculate-emi`, {
        method: 'POST',
        headers: this.headers,
        body: JSON.stringify({
          ...params,
          calculationMethod: 'REDUCING_BALANCE',
        }),
      });
      if (res.ok) {
        const json = await res.json();
        if (json.data) return json.data;
      }
    } catch {
      // Local math fallback
    }

    const principal = Math.max(0, params.vehiclePrice - params.downPayment);
    const r = params.annualInterestRatePercent / 12 / 100;
    const n = params.tenureMonths;
    const emi =
      principal > 0 && r > 0
        ? Math.round((principal * r * Math.pow(1 + r, n)) / (Math.pow(1 + r, n) - 1))
        : Math.round(principal / n);
    const totalPayable = emi * n;
    const totalInterest = Math.max(0, totalPayable - principal);

    return {
      vehiclePrice: params.vehiclePrice,
      downPayment: params.downPayment,
      loanPrincipal: principal,
      monthlyEmi: emi,
      totalInterestPayable: totalInterest,
      totalRepaymentAmount: totalPayable,
    };
  }
}

export const apiClient = new BranchApiClient();

