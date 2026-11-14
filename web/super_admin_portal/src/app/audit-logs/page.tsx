'use client';

import React, { useState } from 'react';
import { 
  ShieldCheck, 
  Search, 
  Filter, 
  Download, 
  AlertCircle, 
  Info, 
  AlertTriangle,
  Building2,
  Calendar,
  UserCheck
} from 'lucide-react';
import { AUDIT_LOGS } from '@/lib/mock-data';
import { AuditLogEntry, AuditSeverity } from '@/lib/types';

export default function AuditLogsPage() {
  const [logs, setLogs] = useState<AuditLogEntry[]>(AUDIT_LOGS);
  const [searchQuery, setSearchQuery] = useState('');
  const [severityFilter, setSeverityFilter] = useState<string>('ALL');
  const [categoryFilter, setCategoryFilter] = useState<string>('ALL');

  const filteredLogs = logs.filter((log) => {
    const matchSearch =
      log.action.toLowerCase().includes(searchQuery.toLowerCase()) ||
      log.tenantName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      log.actorEmail.toLowerCase().includes(searchQuery.toLowerCase()) ||
      log.details.toLowerCase().includes(searchQuery.toLowerCase());
    const matchSeverity = severityFilter === 'ALL' || log.severity === severityFilter;
    const matchCategory = categoryFilter === 'ALL' || log.category === categoryFilter;
    return matchSearch && matchSeverity && matchCategory;
  });

  const handleExportCsv = () => {
    const headers = 'ID,Timestamp,Actor,Role,TenantCode,Category,Action,Severity,IP,Details\n';
    const rows = filteredLogs
      .map(
        (l) =>
          `"${l.id}","${l.timestamp}","${l.actorEmail}","${l.actorRole}","${l.tenantCode}","${l.category}","${l.action}","${l.severity}","${l.ipAddress}","${l.details}"`
      )
      .join('\n');
    const blob = new Blob([headers + rows], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `motosaas-audit-logs-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white tracking-tight flex items-center gap-2">
            <ShieldCheck className="w-6 h-6 text-purple-400" />
            Cross-Tenant Audit Trails & Compliance Ledger
          </h1>
          <p className="text-sm text-slate-400 mt-1">
            Immutable security event logs tracking tenant provisioning, subscription modifications, credential resets, and cross-tenant boundary verification.
          </p>
        </div>

        <button
          onClick={handleExportCsv}
          className="flex items-center gap-2 bg-slate-900 hover:bg-slate-800 text-white font-semibold px-4 py-2.5 rounded-xl border border-slate-800 text-sm transition-all"
        >
          <Download className="w-4 h-4 text-purple-400" />
          Export Audit CSV
        </button>
      </div>

      {/* Filter and Search Bar */}
      <div className="flex flex-col md:flex-row gap-3 items-center justify-between bg-slate-900 p-4 rounded-xl border border-slate-800">
        <div className="relative w-full md:w-80">
          <Search className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
          <input
            type="text"
            placeholder="Search by action, tenant, actor..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full bg-slate-950 border border-slate-800 rounded-lg pl-10 pr-4 py-2 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-purple-500"
          />
        </div>

        <div className="flex flex-wrap items-center gap-2 w-full md:w-auto">
          {/* Severity filter */}
          <select
            value={severityFilter}
            onChange={(e) => setSeverityFilter(e.target.value)}
            className="bg-slate-950 border border-slate-800 text-xs font-semibold text-slate-300 rounded-lg px-3 py-2 focus:outline-none focus:border-purple-500"
          >
            <option value="ALL">All Severities</option>
            <option value="Info">Info</option>
            <option value="Warning">Warning</option>
            <option value="Critical">Critical</option>
          </select>

          {/* Category filter */}
          <select
            value={categoryFilter}
            onChange={(e) => setCategoryFilter(e.target.value)}
            className="bg-slate-950 border border-slate-800 text-xs font-semibold text-slate-300 rounded-lg px-3 py-2 focus:outline-none focus:border-purple-500"
          >
            <option value="ALL">All Categories</option>
            <option value="TenantLifecycle">Tenant Lifecycle</option>
            <option value="Subscription">Subscription</option>
            <option value="Security">Security</option>
            <option value="CatalogSync">Catalog Sync</option>
            <option value="QuotaOverride">Quota Override</option>
          </select>
        </div>
      </div>

      {/* Logs Table */}
      <div className="bg-slate-900 rounded-2xl border border-slate-800 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs text-slate-300">
            <thead className="bg-slate-950 border-b border-slate-800 text-slate-400 uppercase text-[11px] font-semibold tracking-wider">
              <tr>
                <th className="py-3 px-4">Timestamp</th>
                <th className="py-3 px-4">Severity</th>
                <th className="py-3 px-4">Action & Category</th>
                <th className="py-3 px-4">Tenant</th>
                <th className="py-3 px-4">Actor</th>
                <th className="py-3 px-4">IP Address</th>
                <th className="py-3 px-4">Event Details</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/80">
              {filteredLogs.map((log) => (
                <tr key={log.id} className="hover:bg-slate-800/40 transition-colors">
                  <td className="py-3 px-4 whitespace-nowrap font-mono text-[11px] text-slate-400">
                    {log.timestamp}
                  </td>

                  <td className="py-3 px-4 whitespace-nowrap">
                    {log.severity === 'Critical' && (
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold bg-red-500/10 text-red-400 border border-red-500/20">
                        <AlertCircle className="w-3 h-3" />
                        Critical
                      </span>
                    )}
                    {log.severity === 'Warning' && (
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold bg-amber-500/10 text-amber-400 border border-amber-500/20">
                        <AlertTriangle className="w-3 h-3" />
                        Warning
                      </span>
                    )}
                    {log.severity === 'Info' && (
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold bg-blue-500/10 text-blue-400 border border-blue-500/20">
                        <Info className="w-3 h-3" />
                        Info
                      </span>
                    )}
                  </td>

                  <td className="py-3 px-4 whitespace-nowrap">
                    <div className="font-bold text-white">{log.action}</div>
                    <div className="text-[10px] text-slate-400 uppercase mt-0.5">{log.category}</div>
                  </td>

                  <td className="py-3 px-4 whitespace-nowrap">
                    <div className="font-semibold text-slate-200">{log.tenantCode}</div>
                    <div className="text-[10px] text-slate-400">{log.tenantName}</div>
                  </td>

                  <td className="py-3 px-4 whitespace-nowrap">
                    <div className="font-medium text-slate-200">{log.actorEmail}</div>
                    <div className="text-[10px] text-slate-400">{log.actorRole}</div>
                  </td>

                  <td className="py-3 px-4 whitespace-nowrap font-mono text-[11px] text-slate-400">
                    {log.ipAddress}
                  </td>

                  <td className="py-3 px-4 max-w-xs text-slate-300">
                    {log.details}
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
