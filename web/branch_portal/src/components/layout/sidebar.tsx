'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  LayoutDashboard,
  Users,
  Calculator,
  Bike,
  Wrench,
  Receipt,
  FileText,
  Building2,
  ChevronRight
} from 'lucide-react';
import { useAuth } from '@/lib/auth-context';

const NAV_ITEMS = [
  { name: 'Dashboard', href: '/', icon: LayoutDashboard },
  { name: 'Sales & CRM', href: '/sales', icon: Users, badge: '5' },
  { name: 'Quotation Studio', href: '/quotations', icon: Calculator },
  { name: 'Chassis & VIN', href: '/inventory', icon: Bike, badge: 'Stock' },
  { name: 'Service Workshop', href: '/service', icon: Wrench, badge: 'Bays' },
  { name: 'Cashier & Billing', href: '/billing', icon: Receipt },
];

export function Sidebar() {
  const pathname = usePathname();
  const { user, activeBranch } = useAuth();

  return (
    <aside className="w-64 bg-slate-900 text-white flex flex-col shrink-0 min-h-screen border-r border-slate-800">
      {/* Brand Header */}
      <div className="p-5 border-b border-slate-800 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-xl bg-blue-600 flex items-center justify-center font-bold text-lg tracking-wider shadow-lg shadow-blue-500/20">
            M
          </div>
          <div>
            <div className="font-bold text-sm tracking-wide text-white flex items-center gap-1.5">
              MotoSaaS
              <span className="text-[10px] font-semibold bg-blue-500/20 text-blue-300 px-1.5 py-0.5 rounded border border-blue-400/30">
                PORTAL
              </span>
            </div>
            <div className="text-[11px] text-slate-400 truncate max-w-[140px]">
              {user?.tenantName || 'Alagendra Yamaha'}
            </div>
          </div>
        </div>
      </div>

      {/* Branch Context Pill */}
      <div className="px-4 py-3 bg-slate-850 border-b border-slate-800">
        <div className="flex items-center gap-2 text-xs text-slate-300">
          <Building2 className="w-4 h-4 text-blue-400 shrink-0" />
          <div className="truncate">
            <span className="font-medium text-white">{activeBranch?.name}</span>
            <div className="text-[10px] text-slate-400 font-mono">{activeBranch?.code}</div>
          </div>
        </div>
      </div>

      {/* Navigation Links */}
      <nav className="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
        <div className="px-3 pb-2 text-[11px] font-semibold uppercase tracking-wider text-slate-400">
          Operations
        </div>
        {NAV_ITEMS.map((item) => {
          const isActive = pathname === item.href;
          const Icon = item.icon;
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center justify-between px-3.5 py-2.5 rounded-lg text-sm font-medium transition-colors ${
                isActive
                  ? 'bg-blue-600 text-white shadow-sm'
                  : 'text-slate-300 hover:bg-slate-800 hover:text-white'
              }`}
            >
              <div className="flex items-center gap-3">
                <Icon className={`w-4 h-4 ${isActive ? 'text-white' : 'text-slate-400'}`} />
                <span>{item.name}</span>
              </div>
              {item.badge && (
                <span
                  className={`text-[11px] font-semibold px-2 py-0.5 rounded-full ${
                    isActive
                      ? 'bg-white/20 text-white'
                      : 'bg-slate-800 text-slate-300 border border-slate-700'
                  }`}
                >
                  {item.badge}
                </span>
              )}
            </Link>
          );
        })}
      </nav>

      {/* Staff Profile Footer */}
      <div className="p-4 border-t border-slate-800 bg-slate-900/80">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-full bg-gradient-to-tr from-blue-500 to-indigo-600 flex items-center justify-center font-bold text-sm text-white shrink-0">
            {user?.name ? user.name.charAt(0) : 'S'}
          </div>
          <div className="truncate flex-1">
            <div className="text-xs font-semibold text-white truncate">{user?.name}</div>
            <div className="text-[11px] text-blue-400 font-medium truncate">{user?.role}</div>
          </div>
        </div>
      </div>
    </aside>
  );
}

