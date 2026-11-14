'use client';

import React, { useState } from 'react';
import {
  ArrowLeftRight,
  Plus,
  Search,
  CheckCircle2,
  Clock,
  Truck,
  Building2,
  Layers,
  ChevronRight
} from 'lucide-react';
import { DEMO_TRANSFERS, DEMO_BRANCHES } from '@/lib/mock-data';
import { InterBranchTransfer, TransferStatus } from '@/lib/types';

const STATUS_LABELS: Record<TransferStatus, { label: string; bg: string; text: string }> = {
  REQUESTED: { label: 'Transfer Requested', bg: 'bg-amber-100', text: 'text-amber-800' },
  APPROVED: { label: 'Dispatch Approved', bg: 'bg-purple-100', text: 'text-purple-800' },
  DISPATCHED: { label: 'In Transit on Road', bg: 'bg-blue-100', text: 'text-blue-800' },
  RECEIVED: { label: 'Delivered & Accepted', bg: 'bg-emerald-100', text: 'text-emerald-800' },
  REJECTED: { label: 'Rejected / Cancelled', bg: 'bg-rose-100', text: 'text-rose-800' },
};

export default function TransfersPage() {
  const [transfers, setTransfers] = useState<InterBranchTransfer[]>(DEMO_TRANSFERS);
  const [showAddModal, setShowAddModal] = useState(false);
  const [search, setSearch] = useState('');

  // Form state
  const [modelName, setModelName] = useState('Yamaha YZF-R15 V4');
  const [vin, setVin] = useState('ME4RG55A9RA019941');
  const [fromBranchId, setFromBranchId] = useState(DEMO_BRANCHES[0].id);
  const [toBranchId, setToBranchId] = useState(DEMO_BRANCHES[1].id);
  const [carrier, setCarrier] = useState('Alagendra Logistics Shuttle');

  const handleInitiate = (e: React.FormEvent) => {
    e.preventDefault();
    if (!vin) return;

    const fromB = DEMO_BRANCHES.find((b) => b.id === fromBranchId) || DEMO_BRANCHES[0];
    const toB = DEMO_BRANCHES.find((b) => b.id === toBranchId) || DEMO_BRANCHES[1];

    const newTransfer: InterBranchTransfer = {
      id: 'tr-' + Date.now(),
      transferNumber: `TR-2026-0${80 + transfers.length + 1}`,
      vin,
      modelName,
      variantName: 'Standard',
      colorName: 'Factory Color',
      fromBranchId: fromB.id,
      fromBranchName: fromB.name,
      toBranchId: toB.id,
      toBranchName: toB.name,
      status: 'REQUESTED',
      requestedBy: 'Head-Office Dispatch Desk',
      transitCarrier: carrier,
      requestedAt: new Date().toISOString(),
    };

    setTransfers([newTransfer, ...transfers]);
    setShowAddModal(false);
  };

  const handleAdvanceStatus = (id: string, nextStatus: TransferStatus) => {
    setTransfers((prev) =>
      prev.map((t) => (t.id === id ? { ...t, status: nextStatus } : t))
    );
  };

  const filtered = transfers.filter(
    (t) =>
      t.transferNumber.toLowerCase().includes(search.toLowerCase()) ||
      t.vin.toLowerCase().includes(search.toLowerCase()) ||
      t.modelName.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 text-xs font-semibold uppercase tracking-wider text-amber-600">
            <span>Logistics & Balancing</span>
            <span>•</span>
            <span>Inter-Branch Stock Movement</span>
          </div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900 mt-1">
            Inter-Branch Stock Transfers
          </h1>
          <p className="text-sm text-slate-500">
            Authorize vehicle reallocation between Madurai Central, Anna Nagar, and regional branches to meet spot customer demand.
          </p>
        </div>

        <button
          onClick={() => setShowAddModal(true)}
          className="bg-amber-600 hover:bg-amber-500 text-white px-4 py-2 rounded-xl text-xs font-semibold shadow-sm transition-colors flex items-center gap-2 self-start sm:self-auto"
        >
          <Plus className="w-4 h-4" />
          <span>Initiate Stock Transfer</span>
        </button>
      </div>

      {/* Transfers Cards List */}
      <div className="space-y-4">
        {filtered.map((t) => {
          const config = STATUS_LABELS[t.status];
          return (
            <div
              key={t.id}
              className="bg-white rounded-2xl border border-slate-200 p-5 shadow-xs hover:border-amber-300 transition-all flex flex-col md:flex-row md:items-center justify-between gap-4"
            >
              <div className="space-y-1.5">
                <div className="flex items-center gap-3">
                  <span className="font-mono text-xs font-bold text-amber-600 bg-amber-50 px-2 py-0.5 rounded border border-amber-200">
                    {t.transferNumber}
                  </span>
                  <span className="text-sm font-bold text-slate-900">{t.modelName}</span>
                  <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${config.bg} ${config.text}`}>
                    {config.label}
                  </span>
                </div>

                <div className="text-xs text-slate-600 flex flex-wrap items-center gap-2">
                  <span className="font-semibold text-slate-800">{t.fromBranchName}</span>
                  <span className="text-slate-400">➔</span>
                  <span className="font-semibold text-slate-800">{t.toBranchName}</span>
                  <span className="text-slate-400">•</span>
                  <span className="font-mono text-slate-500 font-bold">VIN: {t.vin}</span>
                </div>

                <div className="text-[11px] text-slate-400 flex items-center gap-3">
                  <span>Carrier: {t.transitCarrier || 'Internal Logistics'}</span>
                  <span>Requested: {new Date(t.requestedAt).toLocaleDateString()}</span>
                  {t.approvedBy && <span>Approved by: {t.approvedBy}</span>}
                </div>
              </div>

              {/* Action Buttons */}
              <div className="flex items-center gap-2 shrink-0 pt-2 md:pt-0 border-t md:border-t-0 border-slate-100">
                {t.status === 'REQUESTED' && (
                  <button
                    onClick={() => handleAdvanceStatus(t.id, 'APPROVED')}
                    className="bg-purple-600 hover:bg-purple-500 text-white px-3 py-1.5 rounded-xl text-xs font-semibold"
                  >
                    Approve Dispatch
                  </button>
                )}
                {t.status === 'APPROVED' && (
                  <button
                    onClick={() => handleAdvanceStatus(t.id, 'DISPATCHED')}
                    className="bg-blue-600 hover:bg-blue-500 text-white px-3 py-1.5 rounded-xl text-xs font-semibold flex items-center gap-1"
                  >
                    <Truck className="w-3.5 h-3.5" />
                    <span>Dispatch Vehicle</span>
                  </button>
                )}
                {t.status === 'DISPATCHED' && (
                  <button
                    onClick={() => handleAdvanceStatus(t.id, 'RECEIVED')}
                    className="bg-emerald-600 hover:bg-emerald-500 text-white px-3 py-1.5 rounded-xl text-xs font-semibold flex items-center gap-1"
                  >
                    <CheckCircle2 className="w-3.5 h-3.5" />
                    <span>Acknowledge Receipt</span>
                  </button>
                )}
                {t.status === 'RECEIVED' && (
                  <span className="text-emerald-700 text-xs font-semibold flex items-center gap-1">
                    <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                    <span>Yard Stock Updated</span>
                  </span>
                )}
              </div>
            </div>
          );
        })}
      </div>

      {/* Add Transfer Modal */}
      {showAddModal && (
        <div className="fixed inset-0 z-50 bg-slate-900/40 backdrop-blur-xs flex items-center justify-center p-4">
          <form
            onSubmit={handleInitiate}
            className="bg-white rounded-2xl max-w-md w-full p-6 shadow-xl border border-slate-200 space-y-4 animate-in fade-in zoom-in-95 duration-150"
          >
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <h2 className="text-lg font-bold text-slate-900">Initiate Inter-Branch Transfer</h2>
              <button
                type="button"
                onClick={() => setShowAddModal(false)}
                className="w-8 h-8 rounded-lg text-slate-400 hover:text-slate-600"
              >
                ✕
              </button>
            </div>

            <div>
              <label className="text-xs font-semibold text-slate-700">Vehicle Model</label>
              <select
                value={modelName}
                onChange={(e) => setModelName(e.target.value)}
                className="w-full mt-1 px-3 py-2 border border-slate-200 rounded-xl text-xs bg-white outline-none cursor-pointer"
              >
                <option value="Yamaha YZF-R15 V4">Yamaha YZF-R15 V4</option>
                <option value="Yamaha Aerox 155">Yamaha Aerox 155</option>
                <option value="Yamaha RayZR 125 Fi Hybrid">Yamaha RayZR 125 Fi Hybrid</option>
                <option value="Yamaha MT-15 V2">Yamaha MT-15 V2</option>
              </select>
            </div>

            <div>
              <label className="text-xs font-semibold text-slate-700">Chassis / VIN Number *</label>
              <input
                type="text"
                required
                value={vin}
                onChange={(e) => setVin(e.target.value)}
                placeholder="e.g. ME4RG55A..."
                className="w-full mt-1 px-3 py-2 border border-slate-200 rounded-xl text-xs font-mono outline-none"
              />
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-xs font-semibold text-slate-700">Source Branch (From)</label>
                <select
                  value={fromBranchId}
                  onChange={(e) => setFromBranchId(e.target.value)}
                  className="w-full mt-1 px-3 py-2 border border-slate-200 rounded-xl text-xs bg-white outline-none"
                >
                  {DEMO_BRANCHES.map((b) => (
                    <option key={b.id} value={b.id}>
                      {b.name}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="text-xs font-semibold text-slate-700">Receiving Branch (To)</label>
                <select
                  value={toBranchId}
                  onChange={(e) => setToBranchId(e.target.value)}
                  className="w-full mt-1 px-3 py-2 border border-slate-200 rounded-xl text-xs bg-white outline-none"
                >
                  {DEMO_BRANCHES.map((b) => (
                    <option key={b.id} value={b.id}>
                      {b.name}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div>
              <label className="text-xs font-semibold text-slate-700">Assigned Transit Carrier / Driver</label>
              <input
                type="text"
                value={carrier}
                onChange={(e) => setCarrier(e.target.value)}
                placeholder="Logistics carrier or company vehicle"
                className="w-full mt-1 px-3 py-2 border border-slate-200 rounded-xl text-xs outline-none"
              />
            </div>

            <div className="flex justify-end gap-2 pt-2 border-t border-slate-100">
              <button
                type="button"
                onClick={() => setShowAddModal(false)}
                className="px-4 py-2 rounded-xl text-xs font-semibold text-slate-600 hover:bg-slate-100"
              >
                Cancel
              </button>
              <button
                type="submit"
                className="bg-amber-600 hover:bg-amber-500 text-white px-4 py-2 rounded-xl text-xs font-semibold shadow-xs"
              >
                Create Transfer Order
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
}

