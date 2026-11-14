'use client';

import React, { useState } from 'react';
import { 
  Activity, 
  CheckCircle2, 
  AlertTriangle, 
  Cloud, 
  Database, 
  Server, 
  HardDrive, 
  Cpu, 
  Wifi, 
  RefreshCw,
  ExternalLink,
  ShieldCheck
} from 'lucide-react';
import { PLATFORM_HEALTH_METRICS } from '@/lib/mock-data';
import { PlatformHealthMetric } from '@/lib/types';

export default function PlatformHealthPage() {
  const [metrics, setMetrics] = useState<PlatformHealthMetric[]>(PLATFORM_HEALTH_METRICS);
  const [refreshing, setRefreshing] = useState(false);

  const handleRefresh = () => {
    setRefreshing(true);
    setTimeout(() => setRefreshing(false), 800);
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white tracking-tight flex items-center gap-2">
            <Activity className="w-6 h-6 text-emerald-400" />
            Platform Infrastructure & Telemetry
          </h1>
          <p className="text-sm text-slate-400 mt-1">
            Real-time status of Azure Container Apps cluster, PostgreSQL Flexible Server, Redis, and multi-tenant isolation telemetry.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2 px-3 py-1.5 rounded-xl bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 text-xs font-semibold">
            <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
            All 5 Core Clusters Operational
          </div>

          <button
            onClick={handleRefresh}
            className={`p-2 rounded-xl bg-slate-900 border border-slate-800 text-slate-400 hover:text-white transition-all ${
              refreshing ? 'animate-spin text-purple-400' : ''
            }`}
            title="Refresh Diagnostics"
          >
            <RefreshCw className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* KPI Overview Tiles */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-slate-900 p-5 rounded-2xl border border-slate-800">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-xs font-semibold uppercase tracking-wider">Overall Uptime</span>
            <CheckCircle2 className="w-4 h-4 text-emerald-400" />
          </div>
          <div className="text-2xl font-extrabold text-white mt-2">99.98%</div>
          <div className="text-xs text-emerald-400 font-medium mt-1">SLA target exceeded (30-day window)</div>
        </div>

        <div className="bg-slate-900 p-5 rounded-2xl border border-slate-800">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-xs font-semibold uppercase tracking-wider">Average API Latency</span>
            <Wifi className="w-4 h-4 text-purple-400" />
          </div>
          <div className="text-2xl font-extrabold text-white mt-2">32 ms</div>
          <div className="text-xs text-slate-400 font-medium mt-1">p50: 24ms · p99: 88ms (Central India)</div>
        </div>

        <div className="bg-slate-900 p-5 rounded-2xl border border-slate-800">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-xs font-semibold uppercase tracking-wider">Container Scaling</span>
            <Cloud className="w-4 h-4 text-blue-400" />
          </div>
          <div className="text-2xl font-extrabold text-white mt-2">Scale-to-Zero</div>
          <div className="text-xs text-emerald-400 font-medium mt-1">₹0.00 billable idle compute cost</div>
        </div>

        <div className="bg-slate-900 p-5 rounded-2xl border border-slate-800">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-xs font-semibold uppercase tracking-wider">DB Connection Pool</span>
            <Database className="w-4 h-4 text-amber-400" />
          </div>
          <div className="text-2xl font-extrabold text-white mt-2">18 / 100</div>
          <div className="text-xs text-slate-400 font-medium mt-1">PostgreSQL Flexible Server (B1ms)</div>
        </div>
      </div>

      {/* Services Health Grid */}
      <div className="space-y-4">
        <h2 className="text-base font-bold text-white">Tier Breakdown & Service Health</h2>

        <div className="bg-slate-900 rounded-2xl border border-slate-800 overflow-hidden divide-y divide-slate-800">
          {metrics.map((service) => (
            <div key={service.service} className="p-5 flex flex-col md:flex-row md:items-center justify-between gap-4 hover:bg-slate-800/40 transition-colors">
              <div className="flex items-start gap-3.5">
                <div className="w-10 h-10 rounded-xl bg-slate-950 border border-slate-800 flex items-center justify-center text-purple-400 shrink-0 mt-0.5">
                  {service.category === 'Compute' && <Server className="w-5 h-5 text-indigo-400" />}
                  {service.category === 'Database' && <Database className="w-5 h-5 text-amber-400" />}
                  {service.category === 'Cache' && <Cpu className="w-5 h-5 text-red-400" />}
                  {service.category === 'Storage' && <HardDrive className="w-5 h-5 text-cyan-400" />}
                  {service.category === 'Gateway' && <Cloud className="w-5 h-5 text-emerald-400" />}
                </div>

                <div>
                  <div className="flex items-center gap-2">
                    <h3 className="text-sm font-bold text-white">{service.service}</h3>
                    <span className="text-[10px] font-semibold uppercase px-2 py-0.5 rounded bg-slate-800 text-slate-300 border border-slate-700">
                      {service.category}
                    </span>
                  </div>
                  <p className="text-xs text-slate-400 mt-1">{service.details}</p>
                </div>
              </div>

              <div className="flex flex-wrap items-center gap-6 text-xs text-slate-300 pl-13 md:pl-0">
                <div>
                  <div className="text-[10px] text-slate-400 uppercase font-semibold">Latency</div>
                  <div className="font-bold text-slate-200 mt-0.5">{service.latencyMs} ms</div>
                </div>

                <div>
                  <div className="text-[10px] text-slate-400 uppercase font-semibold">Uptime</div>
                  <div className="font-bold text-emerald-400 mt-0.5">{service.uptimePercent}%</div>
                </div>

                <div>
                  <div className="text-[10px] text-slate-400 uppercase font-semibold">CPU Load</div>
                  <div className="font-bold text-slate-200 mt-0.5">{service.cpuUsagePercent}%</div>
                </div>

                <div>
                  <div className="text-[10px] text-slate-400 uppercase font-semibold">Status</div>
                  <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 mt-0.5">
                    <span className="w-1.5 h-1.5 rounded-full bg-emerald-400"></span>
                    {service.status}
                  </span>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
