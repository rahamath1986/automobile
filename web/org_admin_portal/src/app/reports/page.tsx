'use client';

import React from 'react';
import {
  BarChart3,
  Printer,
  Download,
  Building,
  DollarSign,
  TrendingUp,
  Receipt,
  FileSpreadsheet
} from 'lucide-react';
import { DEMO_FINANCIAL_SUMMARY, DEMO_BRANCHES } from '@/lib/mock-data';

export default function FinancialReportsPage() {
  const cgst = DEMO_FINANCIAL_SUMMARY.gstCollected / 2;
  const sgst = DEMO_FINANCIAL_SUMMARY.gstCollected / 2;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 text-xs font-semibold uppercase tracking-wider text-amber-600">
            <span>Executive Audits</span>
            <span>•</span>
            <span>Consolidated Financial Intelligence</span>
          </div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900 mt-1">
            Financial & Tax Audit Register
          </h1>
          <p className="text-sm text-slate-500">
            Organization-wide revenue realization, GST tax liability distribution, and financier loan disbursements.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={() => window.print()}
            className="bg-white border border-slate-200 hover:bg-slate-50 text-slate-700 px-4 py-2 rounded-xl text-xs font-semibold shadow-xs flex items-center gap-1.5 transition-colors"
          >
            <Printer className="w-4 h-4 text-slate-500" />
            <span>Print Financial Statement</span>
          </button>
        </div>
      </div>

      {/* Summary Stat Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs">
          <span className="text-xs font-semibold uppercase tracking-wider text-slate-500 block">
            Gross Collections (MTD)
          </span>
          <div className="text-3xl font-extrabold text-slate-900 mt-2 font-mono">
            ₹{(DEMO_FINANCIAL_SUMMARY.totalCollected / 100000).toFixed(2)} Lakh
          </div>
          <div className="text-xs text-slate-400 mt-1">
            Sales: ₹{(DEMO_FINANCIAL_SUMMARY.grossSalesRevenue / 100000).toFixed(2)}L • Service: ₹{(DEMO_FINANCIAL_SUMMARY.workshopServiceRevenue / 100000).toFixed(2)}L
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs">
          <span className="text-xs font-semibold uppercase tracking-wider text-slate-500 block">
            GST Liability Realized (28%)
          </span>
          <div className="text-3xl font-extrabold text-amber-600 mt-2 font-mono">
            ₹{(DEMO_FINANCIAL_SUMMARY.gstCollected / 100000).toFixed(2)} Lakh
          </div>
          <div className="text-xs text-slate-400 mt-1">
            CGST (14%): ₹{(cgst / 100000).toFixed(2)}L • SGST (14%): ₹{(sgst / 100000).toFixed(2)}L
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs">
          <span className="text-xs font-semibold uppercase tracking-wider text-slate-500 block">
            Handovers & Work Orders
          </span>
          <div className="text-3xl font-extrabold text-blue-600 mt-2 font-mono">
            {DEMO_FINANCIAL_SUMMARY.unitsDelivered} Units
          </div>
          <div className="text-xs text-slate-400 mt-1">
            {DEMO_FINANCIAL_SUMMARY.jobCardsCompleted} workshop service invoices sealed
          </div>
        </div>
      </div>

      {/* Branch Financial Breakdown Table */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-xs overflow-hidden">
        <div className="px-6 py-4 border-b border-slate-200 flex items-center justify-between">
          <h2 className="text-sm font-bold text-slate-900">Branch Revenue & Realization Breakdown</h2>
          <span className="text-xs text-slate-500 font-mono">Month-to-Date Performance</span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-slate-50 border-b border-slate-200 text-slate-600 font-semibold uppercase tracking-wider text-[11px]">
              <tr>
                <th className="px-5 py-3.5">Branch Name</th>
                <th className="px-5 py-3.5">Code</th>
                <th className="px-5 py-3.5 text-right">Vehicle Sales</th>
                <th className="px-5 py-3.5 text-right">Workshop Service</th>
                <th className="px-5 py-3.5 text-right">Tax (GST)</th>
                <th className="px-5 py-3.5 text-right">Net Collections</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {DEMO_BRANCHES.map((b) => {
                const sales = Math.round(b.monthlyRevenue * 0.88);
                const service = Math.round(b.monthlyRevenue * 0.12);
                const gst = Math.round(b.monthlyRevenue * 0.18);
                return (
                  <tr key={b.id} className="hover:bg-slate-50/70 transition-colors">
                    <td className="px-5 py-3.5 font-bold text-slate-900">{b.name}</td>
                    <td className="px-5 py-3.5 font-mono text-slate-500">{b.code}</td>
                    <td className="px-5 py-3.5 text-right font-mono font-semibold text-slate-900">
                      ₹{sales.toLocaleString('en-IN')}
                    </td>
                    <td className="px-5 py-3.5 text-right font-mono text-slate-700">
                      ₹{service.toLocaleString('en-IN')}
                    </td>
                    <td className="px-5 py-3.5 text-right font-mono text-amber-700">
                      ₹{gst.toLocaleString('en-IN')}
                    </td>
                    <td className="px-5 py-3.5 text-right font-mono font-bold text-emerald-600 text-sm">
                      ₹{b.monthlyRevenue.toLocaleString('en-IN')}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

