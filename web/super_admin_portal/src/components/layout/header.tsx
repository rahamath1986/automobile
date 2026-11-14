'use client';

import React, { useState } from 'react';
import { 
  Bell, 
  Search, 
  ShieldAlert, 
  CheckCircle2, 
  ChevronDown, 
  Server,
  Sparkles,
  Building
} from 'lucide-react';
import { CURRENT_SUPER_ADMIN } from '@/lib/mock-data';

export function Header() {
  const [showNotifications, setShowNotifications] = useState(false);

  return (
    <header className="h-16 bg-white border-b border-slate-200 px-6 flex items-center justify-between sticky top-0 z-30 shadow-xs">
      {/* Global Search Bar */}
      <div className="flex items-center gap-4 flex-1 max-w-xl">
        <div className="relative w-full">
          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Search tenant code (ALAGENDRA, HONDA_NORTH), OEM models, audit logs..."
            className="w-full pl-10 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-lg text-sm text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-purple-500/20 focus:border-purple-500 transition-all"
          />
        </div>
      </div>

      {/* Right Controls */}
      <div className="flex items-center gap-4">
        {/* Environment Pill */}
        <div className="hidden md:flex items-center gap-2 px-3 py-1.5 rounded-full bg-purple-50 border border-purple-200 text-xs font-semibold text-purple-800">
          <Server className="w-3.5 h-3.5 text-purple-600" />
          <span>Azure Production (East US)</span>
          <span className="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
        </div>

        {/* Notifications */}
        <div className="relative">
          <button
            onClick={() => setShowNotifications(!showNotifications)}
            className="p-2 text-slate-500 hover:text-slate-800 hover:bg-slate-100 rounded-lg relative transition-colors"
            title="System Notifications"
          >
            <Bell className="w-4 h-4" />
            <span className="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-purple-600 ring-2 ring-white"></span>
          </button>

          {showNotifications && (
            <div className="absolute right-0 mt-2 w-80 bg-white rounded-xl shadow-xl border border-slate-200 p-4 z-50">
              <div className="flex items-center justify-between pb-3 border-b border-slate-100">
                <span className="text-xs font-bold text-slate-900 uppercase tracking-wider">Platform Alerts</span>
                <span className="text-[11px] font-semibold text-purple-600">2 unread</span>
              </div>
              <div className="space-y-3 pt-3">
                <div className="flex items-start gap-3 text-xs">
                  <div className="p-1 rounded-md bg-amber-50 text-amber-600 border border-amber-200 shrink-0">
                    <ShieldAlert className="w-3.5 h-3.5" />
                  </div>
                  <div>
                    <div className="font-semibold text-slate-900">Tenant Suspended: ECO_SPEED</div>
                    <div className="text-slate-500 text-[11px]">Invoice past due 45 days. Auto-restricted write ops.</div>
                    <div className="text-[10px] text-slate-400 mt-0.5">2 hours ago</div>
                  </div>
                </div>
                <div className="flex items-start gap-3 text-xs">
                  <div className="p-1 rounded-md bg-emerald-50 text-emerald-600 border border-emerald-200 shrink-0">
                    <CheckCircle2 className="w-3.5 h-3.5" />
                  </div>
                  <div>
                    <div className="font-semibold text-slate-900">Trial Dealership Activated</div>
                    <div className="text-slate-500 text-[11px]">Madras Cruiser (CHENNAI_RE) trial extended +14d.</div>
                    <div className="text-[10px] text-slate-400 mt-0.5">5 hours ago</div>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* User Profile */}
        <div className="flex items-center gap-3 pl-2 border-l border-slate-200">
          <div className="w-8 h-8 rounded-full bg-gradient-to-tr from-purple-700 to-indigo-600 text-white font-bold text-xs flex items-center justify-center shadow-sm">
            SA
          </div>
          <div className="hidden lg:block text-left">
            <div className="text-xs font-bold text-slate-900 leading-tight">
              {CURRENT_SUPER_ADMIN.name}
            </div>
            <div className="text-[11px] text-purple-700 font-semibold leading-tight">
              {CURRENT_SUPER_ADMIN.role}
            </div>
          </div>
        </div>
      </div>
    </header>
  );
}
