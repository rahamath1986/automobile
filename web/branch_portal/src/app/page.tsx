'use client';

import React from 'react';
import Link from 'next/link';
import {
  Users,
  Bike,
  Wrench,
  Receipt,
  TrendingUp,
  Clock,
  ArrowRight,
  ShieldCheck,
  CheckCircle2,
  Calendar,
  AlertCircle
} from 'lucide-react';
import { DEMO_LEADS, DEMO_INVENTORY, DEMO_JOB_CARDS, DEMO_PAYMENTS } from '@/lib/mock-data';
import { useAuth } from '@/lib/auth-context';

export default function DashboardPage() {
  const { user, activeBranch } = useAuth();

  const totalCollectedToday = DEMO_PAYMENTS.reduce((sum, p) => sum + p.amount, 0);
  const activeBays = DEMO_JOB_CARDS.filter((j) => j.status === 'WORK_IN_PROGRESS').length;
  const availableStock = DEMO_INVENTORY.filter((i) => i.status === 'AVAILABLE').length;

  return (
    <div className="space-y-8">
      {/* Welcome Banner */}
      <div className="bg-gradient-to-r from-slate-900 via-slate-850 to-blue-950 rounded-2xl p-6 text-white shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4 border border-slate-800">
        <div>
          <div className="flex items-center gap-2 text-xs font-semibold uppercase tracking-wider text-blue-400">
            <span>Branch Overview</span>
            <span>•</span>
            <span>{activeBranch?.name}</span>
          </div>
          <h1 className="text-2xl font-bold tracking-tight mt-1">
            Good morning, {user?.name.split(' ')[0]} 👋
          </h1>
          <p className="text-slate-300 text-sm mt-1 max-w-xl">
            Here is your live showroom, inventory, and workshop pulse for today. 3 test rides scheduled and 5 vehicles in service bays.
          </p>
        </div>
        <div className="flex items-center gap-3 shrink-0">
          <Link
            href="/quotations"
            className="bg-blue-600 hover:bg-blue-500 text-white px-4 py-2 rounded-xl text-xs font-semibold shadow-sm transition-colors flex items-center gap-2"
          >
            <span>+ New Quotation</span>
          </Link>
          <Link
            href="/sales"
            className="bg-white/10 hover:bg-white/20 text-white px-4 py-2 rounded-xl text-xs font-semibold transition-colors flex items-center gap-2"
          >
            <span>+ Add Lead</span>
          </Link>
        </div>
      </div>

      {/* KPI Cards Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Metric 1 */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
              Active CRM Leads
            </span>
            <div className="w-9 h-9 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center">
              <Users className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-4">
            <div className="text-3xl font-extrabold text-slate-900 tracking-tight">
              {DEMO_LEADS.length}
            </div>
            <div className="flex items-center gap-1.5 text-xs text-emerald-600 font-medium mt-1">
              <TrendingUp className="w-3.5 h-3.5" />
              <span>+18% from last week</span>
            </div>
          </div>
        </div>

        {/* Metric 2 */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
              Chassis In Stock
            </span>
            <div className="w-9 h-9 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center">
              <Bike className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-4">
            <div className="text-3xl font-extrabold text-slate-900 tracking-tight">
              {availableStock}
              <span className="text-sm font-semibold text-slate-400 ml-1">/ {DEMO_INVENTORY.length} total</span>
            </div>
            <div className="flex items-center gap-1.5 text-xs text-blue-600 font-medium mt-1">
              <ShieldCheck className="w-3.5 h-3.5" />
              <span>All chassis VIN verified</span>
            </div>
          </div>
        </div>

        {/* Metric 3 */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
              Workshop Bays
            </span>
            <div className="w-9 h-9 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center">
              <Wrench className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-4">
            <div className="text-3xl font-extrabold text-slate-900 tracking-tight">
              {activeBays} Active
            </div>
            <div className="flex items-center gap-1.5 text-xs text-amber-600 font-medium mt-1">
              <Clock className="w-3.5 h-3.5" />
              <span>2 ready for delivery</span>
            </div>
          </div>
        </div>

        {/* Metric 4 */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
              Today's Receipts
            </span>
            <div className="w-9 h-9 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <Receipt className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-4">
            <div className="text-3xl font-extrabold text-slate-900 tracking-tight">
              ₹{(totalCollectedToday / 1000).toFixed(1)}k
            </div>
            <div className="flex items-center gap-1.5 text-xs text-emerald-600 font-medium mt-1">
              <CheckCircle2 className="w-3.5 h-3.5" />
              <span>Reconciled to Cashier</span>
            </div>
          </div>
        </div>
      </div>

      {/* Two Column Layout: CRM Pipeline Preview & Workshop Bay Status */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Sales Pipeline Widget */}
        <div className="bg-white rounded-2xl border border-slate-200/80 p-6 shadow-xs">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h2 className="text-base font-bold text-slate-900">High-Priority Leads</h2>
              <p className="text-xs text-slate-500">Customers awaiting action or test rides</p>
            </div>
            <Link
              href="/sales"
              className="text-xs font-semibold text-blue-600 hover:text-blue-700 flex items-center gap-1"
            >
              <span>View CRM Board</span>
              <ArrowRight className="w-3 h-3" />
            </Link>
          </div>

          <div className="divide-y divide-slate-100">
            {DEMO_LEADS.slice(0, 4).map((lead) => (
              <div key={lead.id} className="py-3 flex items-center justify-between gap-3">
                <div className="min-w-0">
                  <div className="text-sm font-semibold text-slate-900 truncate">
                    {lead.customerName}
                  </div>
                  <div className="text-xs text-slate-500 truncate">
                    {lead.preferredModel} • <span className="font-mono text-[11px]">{lead.phone}</span>
                  </div>
                </div>
                <div className="flex items-center gap-2 shrink-0">
                  <span
                    className={`text-[10px] font-bold px-2.5 py-1 rounded-full ${
                      lead.stage === 'BOOKED'
                        ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                        : lead.stage === 'TEST_RIDE_BOOKED'
                        ? 'bg-blue-50 text-blue-700 border border-blue-200'
                        : lead.stage === 'QUOTATION_SHARED'
                        ? 'bg-purple-50 text-purple-700 border border-purple-200'
                        : 'bg-slate-100 text-slate-700 border border-slate-200'
                    }`}
                  >
                    {lead.stage.replace(/_/g, ' ')}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Workshop Bay Status Widget */}
        <div className="bg-white rounded-2xl border border-slate-200/80 p-6 shadow-xs">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h2 className="text-base font-bold text-slate-900">Service Bay Operations</h2>
              <p className="text-xs text-slate-500">Live job cards & delivery commitments</p>
            </div>
            <Link
              href="/service"
              className="text-xs font-semibold text-blue-600 hover:text-blue-700 flex items-center gap-1"
            >
              <span>Open Workshop</span>
              <ArrowRight className="w-3 h-3" />
            </Link>
          </div>

          <div className="space-y-3">
            {DEMO_JOB_CARDS.map((jc) => (
              <div
                key={jc.id}
                className="p-3.5 rounded-xl border border-slate-200 bg-slate-50/50 flex items-center justify-between gap-3"
              >
                <div>
                  <div className="flex items-center gap-2">
                    <span className="font-mono text-xs font-bold text-blue-600">
                      {jc.jobCardNumber}
                    </span>
                    <span className="text-xs font-semibold text-slate-800">
                      {jc.registrationNumber}
                    </span>
                  </div>
                  <div className="text-xs text-slate-500 mt-0.5">
                    {jc.modelName} • {jc.bayNumber || 'Awaiting Bay'}
                  </div>
                </div>

                <div className="text-right">
                  <span
                    className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                      jc.status === 'WORK_IN_PROGRESS'
                        ? 'bg-amber-100 text-amber-800'
                        : jc.status === 'QUALITY_CHECK'
                        ? 'bg-blue-100 text-blue-800'
                        : 'bg-emerald-100 text-emerald-800'
                    }`}
                  >
                    {jc.status.replace(/_/g, ' ')}
                  </span>
                  <div className="text-[11px] text-slate-400 mt-1">
                    Est: ₹{jc.totalEstimatedAmount}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

