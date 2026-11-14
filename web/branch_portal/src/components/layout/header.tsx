'use client';

import React from 'react';
import { useAuth } from '@/lib/auth-context';
import { Building2, Bell, Search, ShieldCheck, LogOut } from 'lucide-react';

export function Header() {
  const { user, activeBranch, availableBranches, setActiveBranch, logout } = useAuth();

  return (
    <header className="h-16 bg-white border-b border-slate-200 px-6 flex items-center justify-between sticky top-0 z-30 shadow-xs">
      {/* Branch selector dropdown */}
      <div className="flex items-center gap-4">
        <div className="flex items-center gap-2 bg-slate-50 border border-slate-200 px-3 py-1.5 rounded-lg text-xs">
          <Building2 className="w-4 h-4 text-blue-600" />
          <span className="font-semibold text-slate-700">Branch:</span>
          <select
            value={activeBranch?.id}
            onChange={(e) => {
              const b = availableBranches.find((br) => br.id === e.target.value);
              if (b) setActiveBranch(b);
            }}
            className="bg-transparent font-medium text-slate-900 border-none focus:outline-none cursor-pointer"
          >
            {availableBranches.map((branch) => (
              <option key={branch.id} value={branch.id}>
                {branch.name} ({branch.code})
              </option>
            ))}
          </select>
        </div>

        <div className="hidden md:flex items-center gap-2 text-xs text-slate-500 font-mono">
          <ShieldCheck className="w-3.5 h-3.5 text-emerald-600" />
          <span>Tenant: {user?.tenantCode}</span>
        </div>
      </div>

      {/* Right Actions */}
      <div className="flex items-center gap-3">
        <div className="hidden sm:flex items-center gap-2 bg-slate-50 border border-slate-200 rounded-lg px-3 py-1.5 text-xs text-slate-400 w-64">
          <Search className="w-3.5 h-3.5 text-slate-400" />
          <input
            type="text"
            placeholder="Search leads, VIN, customer..."
            className="bg-transparent border-none outline-none text-slate-700 placeholder:text-slate-400 w-full"
          />
        </div>

        <button className="w-9 h-9 rounded-lg border border-slate-200 text-slate-600 hover:bg-slate-50 flex items-center justify-center relative">
          <Bell className="w-4 h-4" />
          <span className="w-2 h-2 rounded-full bg-blue-600 absolute top-2 right-2 ring-2 ring-white"></span>
        </button>

        <button
          onClick={logout}
          title="Sign out"
          className="w-9 h-9 rounded-lg border border-slate-200 text-slate-600 hover:bg-rose-50 hover:text-rose-600 flex items-center justify-center transition-colors"
        >
          <LogOut className="w-4 h-4" />
        </button>
      </div>
    </header>
  );
}

