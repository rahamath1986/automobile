'use client';

import React, { useState } from 'react';
import {
  Building2,
  Plus,
  Phone,
  MapPin,
  Wrench,
  Bike,
  Users,
  Search,
  ShieldCheck,
  CheckCircle2
} from 'lucide-react';
import { DEMO_BRANCHES } from '@/lib/mock-data';
import { BranchDetail } from '@/lib/types';

export default function BranchesPage() {
  const [branches, setBranches] = useState<BranchDetail[]>(DEMO_BRANCHES);
  const [showAddModal, setShowAddModal] = useState(false);
  const [search, setSearch] = useState('');

  // Form state
  const [code, setCode] = useState('');
  const [name, setName] = useState('');
  const [city, setCity] = useState('Madurai');
  const [address, setAddress] = useState('');
  const [phone, setPhone] = useState('+91 98421 ');
  const [managerName, setManagerName] = useState('');
  const [bayCount, setBayCount] = useState<number>(4);

  const handleAddBranch = (e: React.FormEvent) => {
    e.preventDefault();
    if (!code || !name) return;

    const newBranch: BranchDetail = {
      id: 'br-' + Date.now(),
      code: code.toUpperCase().trim(),
      name,
      city,
      address,
      phone,
      isHeadquarters: false,
      activeSalesCount: 2,
      activeTechCount: 3,
      bayCount,
      currentStock: 0,
      monthlyRevenue: 0,
      managerName: managerName || 'Unassigned',
    };

    setBranches([...branches, newBranch]);
    setShowAddModal(false);
    setCode('');
    setName('');
    setAddress('');
    setManagerName('');
  };

  const filtered = branches.filter(
    (b) =>
      b.name.toLowerCase().includes(search.toLowerCase()) ||
      b.code.toLowerCase().includes(search.toLowerCase()) ||
      b.city.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 text-xs font-semibold uppercase tracking-wider text-amber-600">
            <span>Network Infrastructure</span>
            <span>•</span>
            <span>Dealership Branches</span>
          </div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900 mt-1">
            Dealership Network Administration
          </h1>
          <p className="text-sm text-slate-500">
            Manage showroom locations, workshop service bays, manager appointments, and physical stock distribution.
          </p>
        </div>

        <button
          onClick={() => setShowAddModal(true)}
          className="bg-amber-600 hover:bg-amber-500 text-white px-4 py-2 rounded-xl text-xs font-semibold shadow-sm transition-colors flex items-center gap-2 self-start sm:self-auto"
        >
          <Plus className="w-4 h-4" />
          <span>Add Dealership Branch</span>
        </button>
      </div>

      {/* Branch Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {filtered.map((b) => (
          <div
            key={b.id}
            className="bg-white rounded-2xl border border-slate-200 p-6 shadow-xs hover:border-amber-400 transition-all flex flex-col justify-between space-y-5"
          >
            <div>
              <div className="flex items-start justify-between">
                <div>
                  <div className="flex items-center gap-2">
                    <span className="font-mono text-xs font-bold bg-amber-50 text-amber-800 px-2 py-0.5 rounded border border-amber-200">
                      {b.code}
                    </span>
                    {b.isHeadquarters && (
                      <span className="text-[10px] font-extrabold bg-slate-900 text-white px-2 py-0.5 rounded">
                        HEADQUARTERS
                      </span>
                    )}
                  </div>
                  <h3 className="text-base font-bold text-slate-900 mt-2">{b.name}</h3>
                </div>
              </div>

              <div className="mt-3 space-y-1.5 text-xs text-slate-600">
                <div className="flex items-start gap-2">
                  <MapPin className="w-3.5 h-3.5 text-slate-400 mt-0.5 shrink-0" />
                  <span>{b.address}, {b.city}</span>
                </div>
                <div className="flex items-center gap-2">
                  <Phone className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                  <span className="font-mono">{b.phone}</span>
                </div>
                <div className="flex items-center gap-2 pt-2 border-t border-slate-100">
                  <span className="text-slate-400">Branch Manager:</span>
                  <span className="font-semibold text-slate-800">{b.managerName}</span>
                </div>
              </div>

              {/* Facilities breakdown */}
              <div className="grid grid-cols-3 gap-2 mt-4 pt-4 border-t border-slate-100 text-center">
                <div className="p-2 bg-slate-50 rounded-xl">
                  <span className="text-[10px] text-slate-400 uppercase tracking-wider block">Stock</span>
                  <span className="font-mono font-bold text-purple-600 text-sm">{b.currentStock} Units</span>
                </div>
                <div className="p-2 bg-slate-50 rounded-xl">
                  <span className="text-[10px] text-slate-400 uppercase tracking-wider block">Service Bays</span>
                  <span className="font-mono font-bold text-amber-600 text-sm">{b.bayCount} Bays</span>
                </div>
                <div className="p-2 bg-slate-50 rounded-xl">
                  <span className="text-[10px] text-slate-400 uppercase tracking-wider block">Staff</span>
                  <span className="font-mono font-bold text-slate-800 text-sm">{b.activeSalesCount + b.activeTechCount}</span>
                </div>
              </div>
            </div>

            <div className="pt-3 border-t border-slate-100 flex items-center justify-between text-xs">
              <div>
                <span className="text-[10px] text-slate-400 block">Monthly Gross Sales</span>
                <span className="font-bold font-mono text-slate-900">₹{(b.monthlyRevenue / 100000).toFixed(2)} Lakh</span>
              </div>
              <span className="text-emerald-600 font-semibold text-xs flex items-center gap-1">
                <CheckCircle2 className="w-3.5 h-3.5" />
                <span>Operational</span>
              </span>
            </div>
          </div>
        ))}
      </div>

      {/* Add Branch Modal */}
      {showAddModal && (
        <div className="fixed inset-0 z-50 bg-slate-900/40 backdrop-blur-xs flex items-center justify-center p-4">
          <form
            onSubmit={handleAddBranch}
            className="bg-white rounded-2xl max-w-md w-full p-6 shadow-xl border border-slate-200 space-y-4 animate-in fade-in zoom-in-95 duration-150"
          >
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <h2 className="text-lg font-bold text-slate-900">Register New Dealership Branch</h2>
              <button
                type="button"
                onClick={() => setShowAddModal(false)}
                className="w-8 h-8 rounded-lg text-slate-400 hover:text-slate-600"
              >
                ✕
              </button>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-xs font-semibold text-slate-700">Branch Code *</label>
                <input
                  type="text"
                  required
                  placeholder="e.g. MDU-WST"
                  value={code}
                  onChange={(e) => setCode(e.target.value)}
                  className="w-full mt-1 px-3 py-2 border border-slate-200 rounded-xl text-xs font-mono uppercase focus:ring-2 focus:ring-amber-500/20 outline-none"
                />
              </div>
              <div>
                <label className="text-xs font-semibold text-slate-700">City *</label>
                <input
                  type="text"
                  required
                  value={city}
                  onChange={(e) => setCity(e.target.value)}
                  className="w-full mt-1 px-3 py-2 border border-slate-200 rounded-xl text-xs focus:ring-2 focus:ring-amber-500/20 outline-none"
                />
              </div>
            </div>

            <div>
              <label className="text-xs font-semibold text-slate-700">Branch Name *</label>
              <input
                type="text"
                required
                placeholder="e.g. Madurai West Showroom & Service"
                value={name}
                onChange={(e) => setName(e.target.value)}
                className="w-full mt-1 px-3 py-2 border border-slate-200 rounded-xl text-xs focus:ring-2 focus:ring-amber-500/20 outline-none"
              />
            </div>

            <div>
              <label className="text-xs font-semibold text-slate-700">Street Address</label>
              <textarea
                rows={2}
                value={address}
                onChange={(e) => setAddress(e.target.value)}
                placeholder="Full street location..."
                className="w-full mt-1 px-3 py-2 border border-slate-200 rounded-xl text-xs focus:ring-2 focus:ring-amber-500/20 outline-none"
              />
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-xs font-semibold text-slate-700">Contact Phone</label>
                <input
                  type="tel"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  className="w-full mt-1 px-3 py-2 border border-slate-200 rounded-xl text-xs font-mono outline-none"
                />
              </div>
              <div>
                <label className="text-xs font-semibold text-slate-700">Workshop Bays</label>
                <input
                  type="number"
                  min={1}
                  max={20}
                  value={bayCount}
                  onChange={(e) => setBayCount(Number(e.target.value))}
                  className="w-full mt-1 px-3 py-2 border border-slate-200 rounded-xl text-xs font-mono outline-none"
                />
              </div>
            </div>

            <div>
              <label className="text-xs font-semibold text-slate-700">Assigned Branch Manager</label>
              <input
                type="text"
                placeholder="Manager name"
                value={managerName}
                onChange={(e) => setManagerName(e.target.value)}
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
                Register Branch
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
}

