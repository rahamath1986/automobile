'use client';

import React, { useState } from 'react';
import {
  Bike,
  Search,
  Filter,
  ShieldCheck,
  CheckCircle2,
  Clock,
  ArrowRight,
  Sparkles,
  Layers
} from 'lucide-react';
import { DEMO_INVENTORY } from '@/lib/mock-data';
import { InventoryItem, InventoryStatus } from '@/lib/types';

const STATUS_CONFIG: Record<InventoryStatus, { label: string; bg: string; text: string; border: string }> = {
  EXPECTED: { label: 'Expected', bg: 'bg-slate-50', text: 'text-slate-700', border: 'border-slate-200' },
  RECEIVED: { label: 'Received in Yard', bg: 'bg-blue-50', text: 'text-blue-700', border: 'border-blue-200' },
  AVAILABLE: { label: 'Ready for Sale', bg: 'bg-emerald-50', text: 'text-emerald-700', border: 'border-emerald-200' },
  RESERVED: { label: 'Reserved / Token', bg: 'bg-amber-50', text: 'text-amber-700', border: 'border-amber-200' },
  ALLOCATED: { label: 'Allocated to Booking', bg: 'bg-purple-50', text: 'text-purple-700', border: 'border-purple-200' },
  SOLD: { label: 'Invoiced / Sold', bg: 'bg-indigo-50', text: 'text-indigo-700', border: 'border-indigo-200' },
  DELIVERED: { label: 'Handed Over', bg: 'bg-slate-100', text: 'text-slate-600', border: 'border-slate-300' },
};

export default function InventoryPage() {
  const [items, setItems] = useState<InventoryItem[]>(DEMO_INVENTORY);
  const [search, setSearch] = useState('');
  const [selectedStatus, setSelectedStatus] = useState<string>('ALL');

  const filtered = items.filter((item) => {
    const matchesSearch =
      item.vin.toLowerCase().includes(search.toLowerCase()) ||
      item.engineNumber.toLowerCase().includes(search.toLowerCase()) ||
      item.modelName.toLowerCase().includes(search.toLowerCase()) ||
      (item.customerName && item.customerName.toLowerCase().includes(search.toLowerCase()));

    const matchesStatus = selectedStatus === 'ALL' || item.status === selectedStatus;
    return matchesSearch && matchesStatus;
  });

  const availableCount = items.filter((i) => i.status === 'AVAILABLE').length;
  const reservedCount = items.filter((i) => i.status === 'RESERVED').length;
  const allocatedCount = items.filter((i) => i.status === 'ALLOCATED').length;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 text-xs font-semibold uppercase tracking-wider text-blue-600">
            <span>Branch Inventory</span>
            <span>•</span>
            <span>Physical Chassis & Engine Registry</span>
          </div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900 mt-1">
            Chassis & VIN Tracking
          </h1>
          <p className="text-sm text-slate-500">
            Real-time individual VIN/chassis lifecycle from factory receipt to customer handover.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <div className="relative">
            <Search className="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search VIN, engine, model..."
              className="pl-9 pr-3 py-2 bg-white border border-slate-200 rounded-xl text-xs font-medium focus:ring-2 focus:ring-blue-500/20 outline-none w-48 sm:w-64"
            />
          </div>

          <select
            value={selectedStatus}
            onChange={(e) => setSelectedStatus(e.target.value)}
            className="px-3 py-2 bg-white border border-slate-200 rounded-xl text-xs font-medium focus:ring-2 focus:ring-blue-500/20 outline-none cursor-pointer"
          >
            <option value="ALL">All Statuses</option>
            <option value="AVAILABLE">Available (Ready)</option>
            <option value="RESERVED">Reserved</option>
            <option value="ALLOCATED">Allocated</option>
            <option value="SOLD">Sold</option>
            <option value="DELIVERED">Delivered</option>
          </select>
        </div>
      </div>

      {/* Stock Summary Metrics */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="bg-white p-4 rounded-2xl border border-slate-200/80 shadow-xs flex items-center justify-between">
          <div>
            <div className="text-xs font-semibold text-slate-500 uppercase tracking-wider">
              Available For Immediate Sale
            </div>
            <div className="text-2xl font-bold text-emerald-600 mt-1">{availableCount} Units</div>
          </div>
          <div className="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
            <CheckCircle2 className="w-5 h-5" />
          </div>
        </div>

        <div className="bg-white p-4 rounded-2xl border border-slate-200/80 shadow-xs flex items-center justify-between">
          <div>
            <div className="text-xs font-semibold text-slate-500 uppercase tracking-wider">
              Reserved With Token
            </div>
            <div className="text-2xl font-bold text-amber-600 mt-1">{reservedCount} Units</div>
          </div>
          <div className="w-10 h-10 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center">
            <Clock className="w-5 h-5" />
          </div>
        </div>

        <div className="bg-white p-4 rounded-2xl border border-slate-200/80 shadow-xs flex items-center justify-between">
          <div>
            <div className="text-xs font-semibold text-slate-500 uppercase tracking-wider">
              Allocated For Delivery
            </div>
            <div className="text-2xl font-bold text-purple-600 mt-1">{allocatedCount} Units</div>
          </div>
          <div className="w-10 h-10 rounded-xl bg-purple-50 text-purple-600 flex items-center justify-center">
            <Layers className="w-5 h-5" />
          </div>
        </div>
      </div>

      {/* Inventory Table */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-xs overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-slate-50 border-b border-slate-200 text-slate-600 font-semibold uppercase tracking-wider text-[11px]">
              <tr>
                <th className="px-5 py-3.5">VIN / Chassis Number</th>
                <th className="px-5 py-3.5">Engine Number</th>
                <th className="px-5 py-3.5">Model & Variant</th>
                <th className="px-5 py-3.5">Colorway</th>
                <th className="px-5 py-3.5">Status</th>
                <th className="px-5 py-3.5">Customer / Booking</th>
                <th className="px-5 py-3.5 text-right">Yard Arrival</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {filtered.map((item) => {
                const config = STATUS_CONFIG[item.status];
                return (
                  <tr key={item.id} className="hover:bg-slate-50/70 transition-colors">
                    <td className="px-5 py-3.5 font-mono font-bold text-slate-900">
                      {item.vin}
                    </td>
                    <td className="px-5 py-3.5 font-mono text-slate-500">
                      {item.engineNumber}
                    </td>
                    <td className="px-5 py-3.5">
                      <div className="font-semibold text-slate-800">{item.modelName}</div>
                      <div className="text-[11px] text-slate-500">{item.variantName}</div>
                    </td>
                    <td className="px-5 py-3.5">
                      <span className="inline-flex items-center gap-1.5 font-medium text-slate-700">
                        <span className="w-2.5 h-2.5 rounded-full bg-slate-400"></span>
                        {item.colorName}
                      </span>
                    </td>
                    <td className="px-5 py-3.5">
                      <span
                        className={`inline-block text-[10px] font-bold px-2.5 py-1 rounded-full border ${config.bg} ${config.text} ${config.border}`}
                      >
                        {config.label}
                      </span>
                    </td>
                    <td className="px-5 py-3.5">
                      {item.customerName ? (
                        <div>
                          <div className="font-semibold text-slate-800">{item.customerName}</div>
                          {item.bookingId && (
                            <div className="font-mono text-[10px] text-blue-600">{item.bookingId}</div>
                          )}
                        </div>
                      ) : (
                        <span className="text-slate-400 italic">Unallocated</span>
                      )}
                    </td>
                    <td className="px-5 py-3.5 text-right font-mono text-slate-500">
                      {item.arrivalDate}
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

