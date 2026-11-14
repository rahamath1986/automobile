'use client';

import React from 'react';
import { useOrgAdmin } from '@/lib/auth-context';
import { ShieldCheck, Search, Bell, LogOut, ExternalLink } from 'lucide-react';

export function Header() {
  const { admin, logout } = useOrgAdmin();

  return (
    <header className="h-16 bg-white border-b border-slate-200 px-6 flex items-center justify-between sticky top-0 z-30 shadow-xs">
      {/* Left indicator */}
      <div className="flex items-center gap-3">
        <div className="flex items-center gap-2 bg-amber-50 border border-amber-200/80 px-3 py-1.5 rounded-lg text-xs">
          <ShieldCheck className="w-4 h-4 text-amber-600" />
          <span className="font-bold text-amber-900">Alagendra Group Headquarters</span>
          <span className="text-amber-700">• 3 Dealership Branches Active</span>
        </div>
      </div>

      {/* Right Actions */}
      <div className="flex items-center gap-3">
        <div className="hidden sm:flex items-center gap-2 bg-slate-50 border border-slate-200 rounded-lg px-3 py-1.5 text-xs text-slate-400 w-64">
          <Search className="w-3.5 h-3.5 text-slate-400" />
          <input
            type="text"
            placeholder="Search branches, staff, VIN..."
            className="bg-transparent border-none outline-none text-slate-700 placeholder:text-slate-400 w-full"
          />
        </div>

        <a
          href="http://localhost:3000"
          target="_blank"
          rel="noreferrer"
          title="Open Branch Operations Portal"
          className="hidden md:flex items-center gap-1.5 text-xs font-semibold text-slate-700 bg-slate-100 hover:bg-slate-200 px-3 py-1.5 rounded-lg transition-colors"
        >
          <span>Branch Portal</span>
          <ExternalLink className="w-3.5 h-3.5 text-slate-500" />
        </a>

        <button className="w-9 h-9 rounded-lg border border-slate-200 text-slate-600 hover:bg-slate-50 flex items-center justify-center relative">
          <Bell className="w-4 h-4" />
          <span className="w-2 h-2 rounded-full bg-amber-500 absolute top-2 right-2 ring-2 ring-white"></span>
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

