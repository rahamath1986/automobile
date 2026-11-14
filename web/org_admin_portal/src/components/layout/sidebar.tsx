'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  LayoutDashboard,
  Building2,
  Users2,
  BadgeDollarSign,
  ArrowLeftRight,
  BarChart3,
  ShieldAlert,
  Crown
} from 'lucide-react';
import { useOrgAdmin } from '@/lib/auth-context';

const NAV_ITEMS = [
  { name: 'Executive Overview', href: '/', icon: LayoutDashboard },
  { name: 'Dealership Branches', href: '/branches', icon: Building2, badge: '3 Branches' },
  { name: 'Personnel & Roles', href: '/staff', icon: Users2, badge: '8 Active' },
  { name: 'Pricing & Discounts', href: '/pricing', icon: BadgeDollarSign },
  { name: 'Stock Transfers', href: '/transfers', icon: ArrowLeftRight, badge: 'Transit' },
  { name: 'Financial Audits', href: '/reports', icon: BarChart3 },
];

export function Sidebar() {
  const pathname = usePathname();
  const { admin } = useOrgAdmin();

  return (
    <aside className="w-64 bg-slate-900 text-white flex flex-col shrink-0 min-h-screen border-r border-slate-800">
      {/* Brand Header */}
      <div className="p-5 border-b border-slate-800 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-amber-500 to-amber-600 flex items-center justify-center font-bold text-lg text-slate-950 shadow-md">
            <Crown className="w-5 h-5 text-slate-950" />
          </div>
          <div>
            <div className="font-bold text-sm tracking-wide text-white flex items-center gap-1.5">
              MotoSaaS
              <span className="text-[10px] font-extrabold bg-amber-400/20 text-amber-300 px-1.5 py-0.5 rounded border border-amber-400/30">
                ORG ADMIN
              </span>
            </div>
            <div className="text-[11px] text-slate-400 truncate max-w-[140px]">
              {admin.tenantName}
            </div>
          </div>
        </div>
      </div>

      {/* Tenancy Badge */}
      <div className="px-4 py-2.5 bg-slate-850 border-b border-slate-800 flex items-center justify-between text-xs">
        <span className="text-slate-400">Tenant Code:</span>
        <span className="font-mono font-bold text-amber-400 bg-amber-950/60 px-2 py-0.5 rounded border border-amber-800/50 text-[11px]">
          {admin.tenantCode}
        </span>
      </div>

      {/* Navigation Links */}
      <nav className="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
        <div className="px-3 pb-2 text-[11px] font-semibold uppercase tracking-wider text-slate-400">
          Governance & Administration
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
                  ? 'bg-amber-600 text-white shadow-sm'
                  : 'text-slate-300 hover:bg-slate-800 hover:text-white'
              }`}
            >
              <div className="flex items-center gap-3">
                <Icon className={`w-4 h-4 ${isActive ? 'text-white' : 'text-slate-400'}`} />
                <span>{item.name}</span>
              </div>
              {item.badge && (
                <span
                  className={`text-[10px] font-semibold px-2 py-0.5 rounded-full ${
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

      {/* Admin Profile Footer */}
      <div className="p-4 border-t border-slate-800 bg-slate-900/80">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-full bg-gradient-to-tr from-amber-500 to-amber-700 flex items-center justify-center font-bold text-sm text-slate-950 shrink-0">
            {admin.name.charAt(0)}
          </div>
          <div className="truncate flex-1">
            <div className="text-xs font-semibold text-white truncate">{admin.name}</div>
            <div className="text-[11px] text-amber-400 font-medium truncate">Dealer Principal</div>
          </div>
        </div>
      </div>
    </aside>
  );
}

