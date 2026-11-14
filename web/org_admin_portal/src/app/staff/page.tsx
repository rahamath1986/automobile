'use client';

import React, { useState } from 'react';
import {
  Users2,
  Plus,
  Search,
  ShieldCheck,
  CheckCircle2,
  Mail,
  Phone,
  Building2,
  UserCheck,
  Lock
} from 'lucide-react';
import { DEMO_STAFF_MEMBERS, DEMO_BRANCHES } from '@/lib/mock-data';
import { StaffMember, StaffRole } from '@/lib/types';

const ROLES: { id: StaffRole; label: string; badge: string }[] = [
  { id: 'OrgAdmin', label: 'Org Admin (Principal)', badge: 'bg-amber-100 text-amber-800' },
  { id: 'BranchManager', label: 'Branch Manager', badge: 'bg-purple-100 text-purple-800' },
  { id: 'SalesExecutive', label: 'Sales Executive', badge: 'bg-blue-100 text-blue-800' },
  { id: 'ServiceAdvisor', label: 'Service Advisor', badge: 'bg-indigo-100 text-indigo-800' },
  { id: 'Technician', label: 'Technician', badge: 'bg-emerald-100 text-emerald-800' },
  { id: 'Cashier', label: 'Cashier / Billing', badge: 'bg-rose-100 text-rose-800' },
];

export default function StaffRosterPage() {
  const [members, setMembers] = useState<StaffMember[]>(DEMO_STAFF_MEMBERS);
  const [showAddModal, setShowAddModal] = useState(false);
  const [selectedBranchFilter, setSelectedBranchFilter] = useState<string>('ALL');
  const [search, setSearch] = useState('');

  // Form state
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('+91 ');
  const [role, setRole] = useState<StaffRole>('SalesExecutive');
  const [branchId, setBranchId] = useState(DEMO_BRANCHES[0].id);

  const handleAddStaff = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name || !email) return;

    const b = DEMO_BRANCHES.find((item) => item.id === branchId) || DEMO_BRANCHES[0];
    const newStaff: StaffMember = {
      id: 'staff-' + Date.now(),
      name,
      email,
      phone,
      role,
      branchId: b.id,
      branchName: b.name,
      isActive: true,
      joinedDate: new Date().toISOString().split('T')[0],
      monthlyTargetUnits: role === 'SalesExecutive' ? 12 : undefined,
      currentUnitsSold: 0,
    };

    setMembers([newStaff, ...members]);
    setShowAddModal(false);
    setName('');
    setEmail('');
    setPhone('+91 ');
  };

  const filtered = members.filter((m) => {
    const matchesSearch =
      m.name.toLowerCase().includes(search.toLowerCase()) ||
      m.email.toLowerCase().includes(search.toLowerCase()) ||
      m.phone.includes(search) ||
      m.role.toLowerCase().includes(search.toLowerCase());

    const matchesBranch = selectedBranchFilter === 'ALL' || m.branchId === selectedBranchFilter;
    return matchesSearch && matchesBranch;
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 text-xs font-semibold uppercase tracking-wider text-amber-600">
            <span>Governance</span>
            <span>•</span>
            <span>Personnel & Role-Based Access Control</span>
          </div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900 mt-1">
            Staff Roster & Permissions
          </h1>
          <p className="text-sm text-slate-500">
            Control dealership branch access, role privileges, sales quotas, and credential status.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <button
            onClick={() => setShowAddModal(true)}
            className="bg-amber-600 hover:bg-amber-500 text-white px-4 py-2 rounded-xl text-xs font-semibold shadow-sm transition-colors flex items-center gap-2"
          >
            <Plus className="w-4 h-4" />
            <span>Invite Personnel</span>
          </button>
        </div>
      </div>

      {/* Filters Bar */}
      <div className="flex flex-col sm:flex-row items-center justify-between gap-4 bg-white p-4 rounded-2xl border border-slate-200/80 shadow-xs">
        <div className="flex items-center gap-3 w-full sm:w-auto">
          <div className="relative flex-1 sm:w-64">
            <Search className="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search staff, email, phone..."
              className="pl-9 pr-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-medium focus:outline-none focus:ring-2 focus:ring-amber-500/20 w-full"
            />
          </div>

          <select
            value={selectedBranchFilter}
            onChange={(e) => setSelectedBranchFilter(e.target.value)}
            className="px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-medium focus:outline-none cursor-pointer"
          >
            <option value="ALL">All Dealership Branches</option>
            {DEMO_BRANCHES.map((b) => (
              <option key={b.id} value={b.id}>
                {b.name}
              </option>
            ))}
          </select>
        </div>

        <div className="text-xs text-slate-500 font-mono">
          Showing {filtered.length} of {members.length} team members
        </div>
      </div>

      {/* Staff Table */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-xs overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-slate-50 border-b border-slate-200 text-slate-600 font-semibold uppercase tracking-wider text-[11px]">
              <tr>
                <th className="px-5 py-3.5">Staff Member</th>
                <th className="px-5 py-3.5">RBAC Role</th>
                <th className="px-5 py-3.5">Branch Location</th>
                <th className="px-5 py-3.5">Contact Details</th>
                <th className="px-5 py-3.5 text-center">Sales Target</th>
                <th className="px-5 py-3.5 text-center">Status</th>
                <th className="px-5 py-3.5 text-right">Joined</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {filtered.map((m) => {
                const roleConfig = ROLES.find((r) => r.id === m.role);
                return (
                  <tr key={m.id} className="hover:bg-slate-50/70 transition-colors">
                    <td className="px-5 py-3.5">
                      <div className="font-bold text-slate-900">{m.name}</div>
                      <div className="text-[11px] text-slate-400 font-mono">{m.email}</div>
                    </td>
                    <td className="px-5 py-3.5">
                      <span
                        className={`text-[10px] font-bold px-2.5 py-1 rounded-full ${roleConfig?.badge || 'bg-slate-100 text-slate-700'}`}
                      >
                        {roleConfig?.label || m.role}
                      </span>
                    </td>
                    <td className="px-5 py-3.5 font-medium text-slate-700">
                      {m.branchName}
                    </td>
                    <td className="px-5 py-3.5 font-mono text-slate-600 text-[11px]">
                      {m.phone}
                    </td>
                    <td className="px-5 py-3.5 text-center">
                      {m.monthlyTargetUnits ? (
                        <span className="font-mono font-bold text-slate-900">
                          {m.currentUnitsSold} / {m.monthlyTargetUnits}
                        </span>
                      ) : (
                        <span className="text-slate-400">—</span>
                      )}
                    </td>
                    <td className="px-5 py-3.5 text-center">
                      <span className="inline-flex items-center gap-1 text-[11px] font-semibold text-emerald-600">
                        <UserCheck className="w-3.5 h-3.5" />
                        <span>Active</span>
                      </span>
                    </td>
                    <td className="px-5 py-3.5 text-right font-mono text-slate-500 text-[11px]">
                      {m.joinedDate}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* Invite Modal */}
      {showAddModal && (
        <div className="fixed inset-0 z-50 bg-slate-900/40 backdrop-blur-xs flex items-center justify-center p-4">
          <form
            onSubmit={handleAddStaff}
            className="bg-white rounded-2xl max-w-md w-full p-6 shadow-xl border border-slate-200 space-y-4 animate-in fade-in zoom-in-95 duration-150"
          >
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <h2 className="text-lg font-bold text-slate-900">Invite Dealership Staff</h2>
              <button
                type="button"
                onClick={() => setShowAddModal(false)}
                className="w-8 h-8 rounded-lg text-slate-400 hover:text-slate-600"
              >
                ✕
              </button>
            </div>

            <div>
              <label className="text-xs font-semibold text-slate-700">Full Name *</label>
              <input
                type="text"
                required
                placeholder="e.g. Anandha Kumar"
                value={name}
                onChange={(e) => setName(e.target.value)}
                className="w-full mt-1 px-3 py-2 border border-slate-200 rounded-xl text-xs focus:ring-2 focus:ring-amber-500/20 outline-none"
              />
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-xs font-semibold text-slate-700">Email Address *</label>
                <input
                  type="email"
                  required
                  placeholder="name@alagendra.demo"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full mt-1 px-3 py-2 border border-slate-200 rounded-xl text-xs outline-none"
                />
              </div>
              <div>
                <label className="text-xs font-semibold text-slate-700">Phone</label>
                <input
                  type="tel"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  className="w-full mt-1 px-3 py-2 border border-slate-200 rounded-xl text-xs font-mono outline-none"
                />
              </div>
            </div>

            <div>
              <label className="text-xs font-semibold text-slate-700">Role Privilege *</label>
              <select
                value={role}
                onChange={(e) => setRole(e.target.value as StaffRole)}
                className="w-full mt-1 px-3 py-2 border border-slate-200 rounded-xl text-xs bg-white outline-none cursor-pointer"
              >
                {ROLES.map((r) => (
                  <option key={r.id} value={r.id}>
                    {r.label}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="text-xs font-semibold text-slate-700">Branch Assignment *</label>
              <select
                value={branchId}
                onChange={(e) => setBranchId(e.target.value)}
                className="w-full mt-1 px-3 py-2 border border-slate-200 rounded-xl text-xs bg-white outline-none cursor-pointer"
              >
                {DEMO_BRANCHES.map((b) => (
                  <option key={b.id} value={b.id}>
                    {b.name} ({b.code})
                  </option>
                ))}
              </select>
            </div>

            <div className="p-3 bg-amber-50/70 rounded-xl border border-amber-200/60 text-xs text-amber-800 flex items-center gap-2">
              <Lock className="w-4 h-4 text-amber-600 shrink-0" />
              <span>Initial login password will default to <strong>123456</strong> or <strong>Demo@123</strong>.</span>
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
                Create Account
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
}

