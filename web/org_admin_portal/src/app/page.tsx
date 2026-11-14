'use client';

import React from 'react';
import Link from 'next/link';
import {
  TrendingUp,
  Building2,
  Bike,
  Wrench,
  Users2,
  ArrowRight,
  ShieldCheck,
  CheckCircle2,
  DollarSign,
  Layers,
  ArrowLeftRight
} from 'lucide-react';
import {
  DEMO_BRANCHES,
  DEMO_FINANCIAL_SUMMARY,
  DEMO_STAFF_MEMBERS,
  DEMO_TRANSFERS
} from '@/lib/mock-data';
import { useOrgAdmin } from '@/lib/auth-context';

export default function OrgAdminDashboardPage() {
  const { admin } = useOrgAdmin();

  const totalStockAcrossNetwork = DEMO_BRANCHES.reduce((sum, b) => sum + b.currentStock, 0);
  const totalBays = DEMO_BRANCHES.reduce((sum, b) => sum + b.bayCount, 0);

  return (
    <div className="space-y-8">
      {/* Executive Welcome Banner */}
      <div className="bg-gradient-to-r from-slate-900 via-slate-850 to-amber-950 rounded-2xl p-6 text-white shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4 border border-slate-800">
        <div>
          <div className="flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-amber-400">
            <span>Executive Command Center</span>
            <span>•</span>
            <span>{admin.tenantName}</span>
          </div>
          <h1 className="text-2xl font-bold tracking-tight mt-1">
            Welcome, {admin.name} 👑
          </h1>
          <p className="text-slate-300 text-sm mt-1 max-w-xl">
            Multi-branch governance active across 3 dealerships. Gross organization revenue is ₹1.48 Cr month-to-date with 58 vehicle handovers.
          </p>
        </div>
        <div className="flex items-center gap-3 shrink-0">
          <Link
            href="/transfers"
            className="bg-amber-600 hover:bg-amber-500 text-white px-4 py-2 rounded-xl text-xs font-semibold shadow-sm transition-colors flex items-center gap-2"
          >
            <ArrowLeftRight className="w-4 h-4" />
            <span>Stock Transfer</span>
          </Link>
          <Link
            href="/branches"
            className="bg-white/10 hover:bg-white/20 text-white px-4 py-2 rounded-xl text-xs font-semibold transition-colors flex items-center gap-2"
          >
            <span>+ Add Branch</span>
          </Link>
        </div>
      </div>

      {/* Aggregate Network Metrics */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Metric 1 */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
              Total Org Revenue (MTD)
            </span>
            <div className="w-9 h-9 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <DollarSign className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-4">
            <div className="text-3xl font-extrabold text-slate-900 tracking-tight font-mono">
              ₹{(DEMO_FINANCIAL_SUMMARY.totalCollected / 100000).toFixed(2)} L
            </div>
            <div className="flex items-center gap-1.5 text-xs text-emerald-600 font-medium mt-1">
              <TrendingUp className="w-3.5 h-3.5" />
              <span>+22% vs previous month</span>
            </div>
          </div>
        </div>

        {/* Metric 2 */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
              Units Delivered (MTD)
            </span>
            <div className="w-9 h-9 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center">
              <Bike className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-4">
            <div className="text-3xl font-extrabold text-slate-900 tracking-tight">
              {DEMO_FINANCIAL_SUMMARY.unitsDelivered}
              <span className="text-sm font-semibold text-slate-400 ml-1">vehicles</span>
            </div>
            <div className="flex items-center gap-1.5 text-xs text-blue-600 font-medium mt-1">
              <CheckCircle2 className="w-3.5 h-3.5" />
              <span>Across 3 branches</span>
            </div>
          </div>
        </div>

        {/* Metric 3 */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
              Network Stock Holding
            </span>
            <div className="w-9 h-9 rounded-xl bg-purple-50 text-purple-600 flex items-center justify-center">
              <Layers className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-4">
            <div className="text-3xl font-extrabold text-slate-900 tracking-tight">
              {totalStockAcrossNetwork}
              <span className="text-sm font-semibold text-slate-400 ml-1">units</span>
            </div>
            <div className="flex items-center gap-1.5 text-xs text-purple-600 font-medium mt-1">
              <ShieldCheck className="w-3.5 h-3.5" />
              <span>Avg turnover: 14 days</span>
            </div>
          </div>
        </div>

        {/* Metric 4 */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
              Service Bay Capacity
            </span>
            <div className="w-9 h-9 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center">
              <Wrench className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-4">
            <div className="text-3xl font-extrabold text-slate-900 tracking-tight">
              {totalBays} Bays
            </div>
            <div className="flex items-center gap-1.5 text-xs text-amber-600 font-medium mt-1">
              <span>{DEMO_FINANCIAL_SUMMARY.jobCardsCompleted} jobs closed this month</span>
            </div>
          </div>
        </div>
      </div>

      {/* Branch Performance Comparison Leaderboard */}
      <div className="bg-white rounded-2xl border border-slate-200/80 p-6 shadow-xs space-y-4">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-base font-bold text-slate-900">Branch Performance Leaderboard</h2>
            <p className="text-xs text-slate-500">Monthly gross sales, physical inventory allocation, and branch staff strength</p>
          </div>
          <Link
            href="/branches"
            className="text-xs font-semibold text-amber-600 hover:text-amber-700 flex items-center gap-1"
          >
            <span>Manage Network</span>
            <ArrowRight className="w-3 h-3" />
          </Link>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-slate-50 border-b border-slate-200 text-slate-600 font-semibold uppercase tracking-wider text-[11px]">
              <tr>
                <th className="px-4 py-3">Dealership Branch</th>
                <th className="px-4 py-3">Code & City</th>
                <th className="px-4 py-3">Branch Manager</th>
                <th className="px-4 py-3 text-center">Staff (Sales/Tech)</th>
                <th className="px-4 py-3 text-center">In-Stock Units</th>
                <th className="px-4 py-3 text-right">MTD Revenue</th>
                <th className="px-4 py-3 text-right">Contribution</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {DEMO_BRANCHES.map((b) => {
                const totalRev = DEMO_BRANCHES.reduce((sum, item) => sum + item.monthlyRevenue, 0);
                const percent = Math.round((b.monthlyRevenue / totalRev) * 100);
                return (
                  <tr key={b.id} className="hover:bg-slate-50/70 transition-colors">
                    <td className="px-4 py-3.5 font-bold text-slate-900 flex items-center gap-2">
                      <Building2 className="w-4 h-4 text-amber-600" />
                      <span>{b.name}</span>
                      {b.isHeadquarters && (
                        <span className="text-[10px] font-extrabold bg-amber-100 text-amber-800 px-2 py-0.5 rounded">
                          HQ
                        </span>
                      )}
                    </td>
                    <td className="px-4 py-3.5 font-mono text-slate-600">
                      {b.code} • {b.city}
                    </td>
                    <td className="px-4 py-3.5 text-slate-700 font-medium">
                      {b.managerName}
                    </td>
                    <td className="px-4 py-3.5 text-center text-slate-600">
                      {b.activeSalesCount} Sales / {b.activeTechCount} Techs ({b.bayCount} bays)
                    </td>
                    <td className="px-4 py-3.5 text-center font-bold text-purple-600 font-mono">
                      {b.currentStock}
                    </td>
                    <td className="px-4 py-3.5 text-right font-mono font-bold text-slate-900">
                      ₹{(b.monthlyRevenue / 100000).toFixed(2)} L
                    </td>
                    <td className="px-4 py-3.5 text-right">
                      <div className="flex items-center justify-end gap-2">
                        <span className="font-semibold text-slate-700 font-mono text-xs">{percent}%</span>
                        <div className="w-16 bg-slate-100 h-2 rounded-full overflow-hidden">
                          <div className="bg-amber-500 h-full rounded-full" style={{ width: `${percent}%` }}></div>
                        </div>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* Two Column Layout: Pending Inter-Branch Transfers & Personnel Overview */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Inter-Branch Transfers Preview */}
        <div className="bg-white rounded-2xl border border-slate-200/80 p-6 shadow-xs">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h2 className="text-base font-bold text-slate-900">Active Stock Transfers</h2>
              <p className="text-xs text-slate-500">Vehicles in transit between branches</p>
            </div>
            <Link
              href="/transfers"
              className="text-xs font-semibold text-amber-600 hover:text-amber-700 flex items-center gap-1"
            >
              <span>View Transfers</span>
              <ArrowRight className="w-3 h-3" />
            </Link>
          </div>

          <div className="space-y-3">
            {DEMO_TRANSFERS.map((tr) => (
              <div
                key={tr.id}
                className="p-3.5 rounded-xl border border-slate-200 bg-slate-50/50 flex items-center justify-between gap-3 text-xs"
              >
                <div>
                  <div className="flex items-center gap-2">
                    <span className="font-mono font-bold text-amber-600">{tr.transferNumber}</span>
                    <span className="font-semibold text-slate-800">{tr.modelName}</span>
                  </div>
                  <div className="text-slate-500 text-[11px] mt-0.5">
                    {tr.fromBranchName} ➔ <span className="font-semibold text-slate-800">{tr.toBranchName}</span>
                  </div>
                </div>

                <div className="text-right">
                  <span
                    className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                      tr.status === 'DISPATCHED'
                        ? 'bg-blue-100 text-blue-800'
                        : tr.status === 'RECEIVED'
                        ? 'bg-emerald-100 text-emerald-800'
                        : 'bg-amber-100 text-amber-800'
                    }`}
                  >
                    {tr.status}
                  </span>
                  <div className="text-[10px] font-mono text-slate-400 mt-1">{tr.vin}</div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Staff & RBAC Quick Overview */}
        <div className="bg-white rounded-2xl border border-slate-200/80 p-6 shadow-xs">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h2 className="text-base font-bold text-slate-900">Personnel & Role Distribution</h2>
              <p className="text-xs text-slate-500">Headcount & sales target tracking across all units</p>
            </div>
            <Link
              href="/staff"
              className="text-xs font-semibold text-amber-600 hover:text-amber-700 flex items-center gap-1"
            >
              <span>Manage Roster</span>
              <ArrowRight className="w-3 h-3" />
            </Link>
          </div>

          <div className="divide-y divide-slate-100">
            {DEMO_STAFF_MEMBERS.slice(0, 4).map((member) => (
              <div key={member.id} className="py-3 flex items-center justify-between gap-3 text-xs">
                <div>
                  <div className="font-bold text-slate-900">{member.name}</div>
                  <div className="text-slate-500 text-[11px]">{member.role} • {member.branchName}</div>
                </div>

                {member.monthlyTargetUnits ? (
                  <div className="text-right">
                    <span className="font-mono font-bold text-emerald-600">
                      {member.currentUnitsSold} / {member.monthlyTargetUnits}
                    </span>
                    <span className="text-[10px] text-slate-400 block">units sold</span>
                  </div>
                ) : (
                  <span className="text-[10px] font-bold bg-slate-100 text-slate-600 px-2 py-0.5 rounded">
                    Active
                  </span>
                )}
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

