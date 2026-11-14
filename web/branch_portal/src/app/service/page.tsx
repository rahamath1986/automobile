'use client';

import React, { useState } from 'react';
import {
  Wrench,
  Search,
  Plus,
  Clock,
  CheckCircle2,
  AlertCircle,
  FileText,
  User,
  ShieldCheck,
  ChevronRight
} from 'lucide-react';
import { DEMO_JOB_CARDS } from '@/lib/mock-data';
import { JobCard, JobCardStatus } from '@/lib/types';

const STAGE_LABELS: Record<JobCardStatus, { label: string; bg: string; text: string }> = {
  OPEN: { label: 'Vehicle Received', bg: 'bg-slate-100', text: 'text-slate-700' },
  ESTIMATED: { label: 'Estimate Pending', bg: 'bg-amber-100', text: 'text-amber-800' },
  APPROVED: { label: 'Customer Approved', bg: 'bg-emerald-100', text: 'text-emerald-800' },
  WORK_IN_PROGRESS: { label: 'In Service Bay', bg: 'bg-blue-100', text: 'text-blue-800' },
  QUALITY_CHECK: { label: 'Quality Check Gate', bg: 'bg-purple-100', text: 'text-purple-800' },
  READY_FOR_DELIVERY: { label: 'Ready for Handover', bg: 'bg-emerald-100', text: 'text-emerald-800' },
  CLOSED: { label: 'Invoice Paid & Closed', bg: 'bg-slate-200', text: 'text-slate-800' },
};

export default function ServiceWorkshopPage() {
  const [jobCards, setJobCards] = useState<JobCard[]>(DEMO_JOB_CARDS);
  const [selectedJobCard, setSelectedJobCard] = useState<JobCard | null>(null);
  const [search, setSearch] = useState('');

  const filtered = jobCards.filter(
    (jc) =>
      jc.jobCardNumber.toLowerCase().includes(search.toLowerCase()) ||
      jc.registrationNumber.toLowerCase().includes(search.toLowerCase()) ||
      jc.customerName.toLowerCase().includes(search.toLowerCase())
  );

  const handleUpdateStatus = (id: string, newStatus: JobCardStatus) => {
    setJobCards((prev) =>
      prev.map((jc) => (jc.id === id ? { ...jc, status: newStatus } : jc))
    );
    if (selectedJobCard && selectedJobCard.id === id) {
      setSelectedJobCard((prev) => (prev ? { ...prev, status: newStatus } : null));
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 text-xs font-semibold uppercase tracking-wider text-blue-600">
            <span>Branch Workshop</span>
            <span>•</span>
            <span>Digital Job Cards & Service Bays</span>
          </div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900 mt-1">
            Service Workshop Management
          </h1>
          <p className="text-sm text-slate-500">
            Vehicle check-in, parts/labour estimate approval, technician bay queue, and QC gate.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <div className="relative">
            <Search className="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search Reg No, Job Card, Customer..."
              className="pl-9 pr-3 py-2 bg-white border border-slate-200 rounded-xl text-xs font-medium focus:ring-2 focus:ring-blue-500/20 outline-none w-52 sm:w-72"
            />
          </div>
        </div>
      </div>

      {/* Workshop Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {filtered.map((jc) => {
          const config = STAGE_LABELS[jc.status];
          return (
            <div
              key={jc.id}
              onClick={() => setSelectedJobCard(jc)}
              className="bg-white rounded-2xl border border-slate-200 p-5 shadow-xs hover:border-blue-400 hover:shadow-sm cursor-pointer transition-all flex flex-col justify-between space-y-4"
            >
              <div>
                <div className="flex items-start justify-between">
                  <div>
                    <span className="font-mono text-xs font-bold text-blue-600">
                      {jc.jobCardNumber}
                    </span>
                    <h3 className="text-sm font-bold text-slate-900 mt-0.5">
                      {jc.registrationNumber}
                    </h3>
                  </div>
                  <span
                    className={`text-[10px] font-bold px-2.5 py-0.5 rounded-full ${config.bg} ${config.text}`}
                  >
                    {config.label}
                  </span>
                </div>

                <div className="mt-3 text-xs text-slate-600 space-y-1">
                  <div className="font-semibold text-slate-800">{jc.modelName}</div>
                  <div className="text-slate-500">Customer: {jc.customerName} ({jc.customerPhone})</div>
                  <div className="text-slate-500">Bay: <span className="font-medium text-slate-800">{jc.bayNumber || 'Unassigned'}</span></div>
                </div>

                {/* Complaints pill preview */}
                <div className="mt-3 pt-3 border-t border-slate-100 space-y-1">
                  <div className="text-[11px] font-semibold text-slate-500">Reported Issues:</div>
                  <div className="flex flex-wrap gap-1">
                    {jc.complaints.map((c, i) => (
                      <span key={i} className="text-[10px] bg-slate-100 text-slate-600 px-2 py-0.5 rounded">
                        {c}
                      </span>
                    ))}
                  </div>
                </div>
              </div>

              <div className="pt-3 border-t border-slate-100 flex items-center justify-between text-xs">
                <div>
                  <span className="text-[10px] text-slate-400 block">Total Estimate</span>
                  <span className="font-bold font-mono text-slate-900">₹{jc.totalEstimatedAmount}</span>
                </div>
                <div className="flex items-center gap-1 text-blue-600 font-semibold text-xs">
                  <span>Manage</span>
                  <ChevronRight className="w-3.5 h-3.5" />
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Job Card Detailed Inspection Modal */}
      {selectedJobCard && (
        <div className="fixed inset-0 z-50 bg-slate-900/40 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-lg w-full p-6 shadow-xl border border-slate-200 space-y-5 animate-in fade-in zoom-in-95 duration-150">
            <div className="flex items-start justify-between border-b border-slate-100 pb-3">
              <div>
                <span className="font-mono text-xs font-bold text-blue-600">
                  {selectedJobCard.jobCardNumber}
                </span>
                <h2 className="text-xl font-bold text-slate-900">
                  {selectedJobCard.registrationNumber} • {selectedJobCard.modelName}
                </h2>
                <div className="text-xs text-slate-500">
                  Customer: <span className="font-semibold text-slate-800">{selectedJobCard.customerName}</span> ({selectedJobCard.customerPhone})
                </div>
              </div>
              <button
                onClick={() => setSelectedJobCard(null)}
                className="w-8 h-8 rounded-lg text-slate-400 hover:text-slate-600 flex items-center justify-center"
              >
                ✕
              </button>
            </div>

            {/* Check-in parameters */}
            <div className="grid grid-cols-2 gap-3 text-xs">
              <div className="p-3 bg-slate-50 rounded-xl">
                <span className="text-slate-500 block">Odometer Reading</span>
                <span className="font-bold text-slate-900 font-mono text-sm">{selectedJobCard.odometerReading} km</span>
              </div>
              <div className="p-3 bg-slate-50 rounded-xl">
                <span className="text-slate-500 block">Fuel Tank Level</span>
                <span className="font-bold text-slate-900 font-mono text-sm">{selectedJobCard.fuelLevelPercent}%</span>
              </div>
            </div>

            {/* Estimates Breakdown */}
            <div className="p-3.5 bg-blue-50/50 rounded-xl border border-blue-200/60 space-y-1 text-xs">
              <div className="font-bold text-blue-900">Itemized Cost Estimate</div>
              <div className="flex justify-between text-slate-600">
                <span>Labour Charges</span>
                <span className="font-mono font-semibold">₹{selectedJobCard.estimatedLabourCost}</span>
              </div>
              <div className="flex justify-between text-slate-600">
                <span>Spare Parts & Consumables</span>
                <span className="font-mono font-semibold">₹{selectedJobCard.estimatedPartsCost}</span>
              </div>
              <div className="flex justify-between font-bold text-blue-900 pt-1 border-t border-blue-200">
                <span>Total Approved Estimate</span>
                <span className="font-mono">₹{selectedJobCard.totalEstimatedAmount}</span>
              </div>
            </div>

            {/* Advance Status Workflow */}
            <div className="space-y-2 pt-2 border-t border-slate-100">
              <div className="text-xs font-semibold text-slate-700">Workshop Progression</div>
              <div className="flex flex-wrap gap-2">
                {(Object.keys(STAGE_LABELS) as JobCardStatus[]).map((st) => (
                  <button
                    key={st}
                    onClick={() => handleUpdateStatus(selectedJobCard.id, st)}
                    className={`text-xs px-2.5 py-1.5 rounded-lg font-semibold transition-all ${
                      selectedJobCard.status === st
                        ? 'bg-blue-600 text-white shadow-xs'
                        : 'bg-slate-100 hover:bg-slate-200 text-slate-700'
                    }`}
                  >
                    {STAGE_LABELS[st].label}
                  </button>
                ))}
              </div>
            </div>

            <div className="flex justify-end pt-2">
              <button
                onClick={() => setSelectedJobCard(null)}
                className="bg-slate-900 hover:bg-slate-850 text-white px-4 py-2 rounded-xl text-xs font-semibold"
              >
                Done
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

