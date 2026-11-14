'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { 
  Building2, 
  TrendingUp, 
  CreditCard, 
  Layers, 
  Server, 
  ShieldCheck, 
  AlertTriangle,
  ArrowUpRight,
  ExternalLink,
  Users,
  CheckCircle2,
  Clock,
  Sparkles,
  Zap,
  HardDrive
} from 'lucide-react';
import { 
  PLATFORM_KPIS, 
  INITIAL_TENANTS, 
  SUBSCRIPTION_PLANS, 
  PLATFORM_HEALTH_METRICS,
  AUDIT_LOGS 
} from '@/lib/mock-data';

export default function SuperAdminDashboard() {
  const [tenants] = useState(INITIAL_TENANTS);

  const activeTenants = tenants.filter(t => t.status === 'Active');
  const trialTenants = tenants.filter(t => t.status === 'Trial');
  const suspendedTenants = tenants.filter(t => t.status === 'Suspended');

  return (
    <div className="space-y-8 max-w-7xl mx-auto">
      {/* Top Welcome & Control Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 pb-2 border-b border-slate-200">
        <div>
          <div className="flex items-center gap-2.5">
            <h1 className="text-2xl font-bold tracking-tight text-slate-900">
              Platform Command Center
            </h1>
            <span className="px-2.5 py-0.5 text-xs font-bold rounded-full bg-purple-100 text-purple-700 border border-purple-200">
              v2.4.0 SaaS Engine
            </span>
          </div>
          <p className="text-sm text-slate-500 mt-1">
            Global multi-tenant governance, live cloud telemetry, and OEM franchise distribution.
          </p>
        </div>

        {/* Global Quick Action Bar */}
        <div className="flex items-center gap-2.5 flex-wrap">
          <Link
            href="/tenants?action=new"
            className="inline-flex items-center gap-2 px-4 py-2 bg-purple-600 hover:bg-purple-700 text-white text-sm font-semibold rounded-lg shadow-sm shadow-purple-500/20 transition-colors"
          >
            <Building2 className="w-4 h-4" />
            <span>Onboard Dealership</span>
          </Link>
          <Link
            href="/oem-catalog"
            className="inline-flex items-center gap-2 px-3.5 py-2 bg-white hover:bg-slate-50 border border-slate-200 text-slate-700 text-sm font-medium rounded-lg shadow-xs transition-colors"
          >
            <Layers className="w-4 h-4 text-slate-500" />
            <span>OEM Catalog</span>
          </Link>
          <Link
            href="/platform-health"
            className="inline-flex items-center gap-2 px-3.5 py-2 bg-white hover:bg-slate-50 border border-slate-200 text-slate-700 text-sm font-medium rounded-lg shadow-xs transition-colors"
          >
            <Server className="w-4 h-4 text-emerald-600" />
            <span>Cloud Health</span>
          </Link>
        </div>
      </div>

      {/* KPI Cards Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
        {PLATFORM_KPIS.map((kpi, idx) => (
          <div
            key={idx}
            className="bg-white p-5 rounded-xl border border-slate-200/80 shadow-xs hover:border-purple-200 hover:shadow-md transition-all duration-200"
          >
            <div className="flex items-center justify-between">
              <span className="text-xs font-medium text-slate-500 uppercase tracking-wider">
                {kpi.title}
              </span>
              <span className={`text-xs font-semibold px-2 py-0.5 rounded-full ${
                kpi.trend === 'up' 
                  ? 'bg-emerald-50 text-emerald-700 border border-emerald-200' 
                  : 'bg-slate-100 text-slate-600'
              }`}>
                {kpi.change}
              </span>
            </div>
            <div className="mt-3 text-2xl font-bold text-slate-900 tracking-tight">
              {kpi.value}
            </div>
            <p className="mt-1.5 text-xs text-slate-500">
              {kpi.subtext}
            </p>
          </div>
        ))}
      </div>

      {/* Dealership Tenancy Breakdown & Live Quotas */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Active Tenants Roster Highlights */}
        <div className="lg:col-span-2 bg-white rounded-xl border border-slate-200/80 shadow-xs p-6">
          <div className="flex items-center justify-between pb-4 border-b border-slate-100">
            <div>
              <h2 className="text-base font-bold text-slate-900">
                Franchised Dealership Network
              </h2>
              <p className="text-xs text-slate-500 mt-0.5">
                Active tenant environments, subscribed tiers, and branch footprints
              </p>
            </div>
            <Link
              href="/tenants"
              className="text-xs font-semibold text-purple-600 hover:text-purple-700 flex items-center gap-1"
            >
              <span>Manage all ({tenants.length})</span>
              <ArrowUpRight className="w-3.5 h-3.5" />
            </Link>
          </div>

          <div className="divide-y divide-slate-100 mt-2">
            {tenants.slice(0, 4).map((tenant) => (
              <div key={tenant.id} className="py-3.5 flex items-center justify-between gap-4">
                <div className="flex items-center gap-3 min-w-0">
                  <div 
                    className="w-10 h-10 rounded-lg flex items-center justify-center font-bold text-xs text-white shrink-0 shadow-xs"
                    style={{ backgroundColor: tenant.primaryColor }}
                  >
                    {tenant.code.slice(0, 2)}
                  </div>
                  <div className="min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="font-bold text-sm text-slate-900 truncate">
                        {tenant.tradeName}
                      </span>
                      <span className="text-[11px] font-mono px-1.5 py-0.2 bg-slate-100 text-slate-600 rounded">
                        {tenant.code}
                      </span>
                    </div>
                    <div className="text-xs text-slate-500 flex items-center gap-2 mt-0.5">
                      <span>OEM: <strong className="text-slate-700">{tenant.primaryOem}</strong></span>
                      <span>•</span>
                      <span>{tenant.branchesCount} Branches</span>
                      <span>•</span>
                      <span>{tenant.staffCount} Staff</span>
                    </div>
                  </div>
                </div>

                <div className="flex items-center gap-3 shrink-0">
                  <span className={`text-[11px] font-semibold px-2.5 py-0.5 rounded-full ${
                    tenant.subscriptionPlan === 'ENTERPRISE'
                      ? 'bg-purple-100 text-purple-800 border border-purple-200'
                      : tenant.subscriptionPlan === 'PROFESSIONAL'
                      ? 'bg-blue-100 text-blue-800 border border-blue-200'
                      : 'bg-slate-100 text-slate-700 border border-slate-200'
                  }`}>
                    {tenant.subscriptionPlan}
                  </span>

                  <span className={`text-xs font-semibold px-2 py-0.5 rounded-md ${
                    tenant.status === 'Active'
                      ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                      : tenant.status === 'Trial'
                      ? 'bg-amber-50 text-amber-700 border border-amber-200'
                      : 'bg-rose-50 text-rose-700 border border-rose-200'
                  }`}>
                    {tenant.status}
                  </span>
                </div>
              </div>
            ))}
          </div>

          {/* Pilot Highlight Banner */}
          <div className="mt-4 p-3.5 bg-gradient-to-r from-purple-50 to-indigo-50 border border-purple-200 rounded-xl flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-lg bg-purple-600 text-white flex items-center justify-center font-bold text-xs">
                ★
              </div>
              <div className="text-xs">
                <span className="font-bold text-purple-950">Primary Pilot: ALAGENDRA (Alagendra Yamaha)</span>
                <p className="text-purple-700">Dedicated static test user 8015581405 PIN: 123456 verified active.</p>
              </div>
            </div>
            <a
              href="http://localhost:3001"
              target="_blank"
              rel="noreferrer"
              className="text-xs font-semibold text-purple-700 hover:text-purple-900 bg-white px-3 py-1.5 rounded-lg border border-purple-200 shadow-2xs flex items-center gap-1"
            >
              <span>Org Admin Portal</span>
              <ExternalLink className="w-3 h-3" />
            </a>
          </div>
        </div>

        {/* Platform Tier & Health Snapshot */}
        <div className="space-y-6">
          {/* Subscription Tiers Distribution */}
          <div className="bg-white rounded-xl border border-slate-200/80 shadow-xs p-5">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <h3 className="text-sm font-bold text-slate-900">
                Subscription Plan Tiers
              </h3>
              <Link href="/plans" className="text-xs font-semibold text-purple-600 hover:text-purple-700">
                Plan Matrix
              </Link>
            </div>

            <div className="space-y-3 pt-3">
              {SUBSCRIPTION_PLANS.map((plan) => (
                <div key={plan.id} className="p-3 rounded-lg border border-slate-100 bg-slate-50/70 hover:bg-slate-50 transition-colors">
                  <div className="flex items-center justify-between">
                    <span className="font-bold text-xs text-slate-900">{plan.name}</span>
                    <span className="text-xs font-bold text-purple-700">
                      ₹{plan.monthlyPrice.toLocaleString()}<span className="text-[10px] text-slate-500 font-normal">/mo</span>
                    </span>
                  </div>
                  <div className="flex items-center justify-between text-[11px] text-slate-500 mt-1">
                    <span>Quota: {plan.maxBranches === 999 ? 'Unlimited' : `${plan.maxBranches} Branches`}</span>
                    <span className="font-semibold text-slate-700">{plan.activeTenantsCount} Active Tenants</span>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Infrastructure Health Card */}
          <div className="bg-white rounded-xl border border-slate-200/80 shadow-xs p-5">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <div className="flex items-center gap-2">
                <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
                <h3 className="text-sm font-bold text-slate-900">Azure Cloud Health</h3>
              </div>
              <Link href="/platform-health" className="text-xs font-semibold text-purple-600 hover:text-purple-700">
                Telemetry
              </Link>
            </div>

            <div className="space-y-2.5 pt-3">
              {PLATFORM_HEALTH_METRICS.slice(0, 3).map((metric, idx) => (
                <div key={idx} className="flex items-center justify-between text-xs">
                  <span className="text-slate-600 truncate max-w-[180px]">{metric.service}</span>
                  <div className="flex items-center gap-2">
                    <span className="font-mono text-slate-500">{metric.latencyMs}ms</span>
                    <span className="px-1.5 py-0.2 rounded bg-emerald-50 text-emerald-700 font-semibold text-[10px]">
                      {metric.uptimePercent}%
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Cross-Tenant Recent Security & Audit Ledger */}
      <div className="bg-white rounded-xl border border-slate-200/80 shadow-xs p-6">
        <div className="flex items-center justify-between pb-4 border-b border-slate-100">
          <div>
            <h2 className="text-base font-bold text-slate-900 flex items-center gap-2">
              <ShieldCheck className="w-4 h-4 text-purple-600" />
              <span>Cross-Tenant Security & Audit Trail</span>
            </h2>
            <p className="text-xs text-slate-500 mt-0.5">
              Immutable ledger of platform actions, quota overrides, and tenant authentication events
            </p>
          </div>
          <Link
            href="/audit-logs"
            className="text-xs font-semibold text-purple-600 hover:text-purple-700 flex items-center gap-1"
          >
            <span>Full Audit Log ({AUDIT_LOGS.length})</span>
            <ArrowUpRight className="w-3.5 h-3.5" />
          </Link>
        </div>

        <div className="overflow-x-auto mt-2">
          <table className="w-full text-left text-xs">
            <thead>
              <tr className="text-slate-400 border-b border-slate-100 uppercase tracking-wider text-[11px]">
                <th className="py-3 font-semibold">Timestamp</th>
                <th className="py-3 font-semibold">Tenant</th>
                <th className="py-3 font-semibold">Category</th>
                <th className="py-3 font-semibold">Action & Details</th>
                <th className="py-3 font-semibold">Actor</th>
                <th className="py-3 font-semibold text-right">Severity</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {AUDIT_LOGS.slice(0, 4).map((entry) => (
                <tr key={entry.id} className="hover:bg-slate-50/60">
                  <td className="py-3 font-mono text-slate-500 whitespace-nowrap">
                    {entry.timestamp}
                  </td>
                  <td className="py-3 font-bold text-slate-900 whitespace-nowrap">
                    <span className="px-1.5 py-0.5 bg-slate-100 rounded text-slate-700 font-mono">
                      {entry.tenantCode}
                    </span>
                  </td>
                  <td className="py-3 text-slate-600">
                    {entry.category}
                  </td>
                  <td className="py-3 max-w-md">
                    <div className="font-semibold text-slate-900">{entry.action}</div>
                    <div className="text-slate-500 text-[11px] truncate">{entry.details}</div>
                  </td>
                  <td className="py-3 text-slate-500 whitespace-nowrap">
                    {entry.actorEmail}
                  </td>
                  <td className="py-3 text-right">
                    <span className={`px-2 py-0.5 rounded-full text-[10px] font-semibold ${
                      entry.severity === 'Critical'
                        ? 'bg-rose-100 text-rose-700'
                        : entry.severity === 'Warning'
                        ? 'bg-amber-100 text-amber-700'
                        : 'bg-slate-100 text-slate-700'
                    }`}>
                      {entry.severity}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
