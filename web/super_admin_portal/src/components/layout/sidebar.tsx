'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { 
  LayoutDashboard, 
  Building2, 
  CreditCard, 
  Layers, 
  Activity, 
  ShieldCheck, 
  Cloud,
  ChevronRight,
  ExternalLink
} from 'lucide-react';

const navigation = [
  { name: 'Platform Overview', href: '/', icon: LayoutDashboard },
  { name: 'Dealership Tenants', href: '/tenants', icon: Building2, badge: '8' },
  { name: 'Subscription Plans', href: '/plans', icon: CreditCard },
  { name: 'Global OEM Catalog', href: '/oem-catalog', icon: Layers },
  { name: 'Platform Health', href: '/platform-health', icon: Activity, status: 'healthy' },
  { name: 'Audit & Compliance', href: '/audit-logs', icon: ShieldCheck },
];

export function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="w-64 bg-slate-900 border-r border-slate-800 flex flex-col shrink-0 text-slate-300">
      {/* Brand Header */}
      <div className="h-16 flex items-center gap-3 px-6 border-b border-slate-800 bg-slate-950">
        <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-purple-600 to-indigo-500 flex items-center justify-center text-white shadow-md shadow-purple-500/20">
          <Cloud className="w-5 h-5" />
        </div>
        <div>
          <div className="text-base font-bold text-white tracking-tight flex items-center gap-1.5">
            MotoSaaS <span className="text-[10px] uppercase font-semibold px-1.5 py-0.5 rounded bg-purple-500/20 text-purple-300 border border-purple-500/30">Super</span>
          </div>
          <div className="text-xs text-slate-400 font-medium">Platform Operations</div>
        </div>
      </div>

      {/* Navigation Links */}
      <nav className="flex-1 px-3 py-4 space-y-1">
        <div className="px-3 pb-2 text-[11px] font-semibold uppercase tracking-wider text-slate-400">
          Platform Governance
        </div>
        {navigation.map((item) => {
          const isActive = pathname === item.href;
          const Icon = item.icon;
          return (
            <Link
              key={item.name}
              href={item.href}
              className={`flex items-center justify-between px-3 py-2.5 rounded-lg text-sm font-medium transition-all duration-150 ${
                isActive
                  ? 'bg-purple-600 text-white shadow-md shadow-purple-600/30 font-semibold'
                  : 'text-slate-400 hover:text-white hover:bg-slate-800/80'
              }`}
            >
              <div className="flex items-center gap-3">
                <Icon className={`w-4 h-4 ${isActive ? 'text-white' : 'text-slate-400'}`} />
                <span>{item.name}</span>
              </div>
              {item.badge && (
                <span className="text-[11px] font-semibold px-2 py-0.5 rounded-full bg-slate-800 text-purple-300 border border-purple-500/20">
                  {item.badge}
                </span>
              )}
              {item.status === 'healthy' && (
                <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
              )}
            </Link>
          );
        })}

        <div className="pt-6 px-3 pb-2 text-[11px] font-semibold uppercase tracking-wider text-slate-400">
          Cross-Portal Jumps
        </div>
        <a
          href="http://localhost:3001"
          target="_blank"
          rel="noreferrer"
          className="flex items-center justify-between px-3 py-2 rounded-lg text-xs font-medium text-slate-400 hover:text-white hover:bg-slate-800/60"
        >
          <span>Dealer Org Admin (3001)</span>
          <ExternalLink className="w-3.5 h-3.5 text-slate-400" />
        </a>
        <a
          href="http://localhost:3000"
          target="_blank"
          rel="noreferrer"
          className="flex items-center justify-between px-3 py-2 rounded-lg text-xs font-medium text-slate-400 hover:text-white hover:bg-slate-800/60"
        >
          <span>Branch Portal (3000)</span>
          <ExternalLink className="w-3.5 h-3.5 text-slate-400" />
        </a>
      </nav>

      {/* Cloud Infrastructure Status Footer */}
      <div className="p-4 border-t border-slate-800 bg-slate-950/60 m-3 rounded-xl border">
        <div className="flex items-center gap-2 mb-1.5">
          <div className="w-2 h-2 rounded-full bg-emerald-500 animate-ping"></div>
          <span className="text-xs font-semibold text-white">Azure Cloud Central</span>
        </div>
        <p className="text-[11px] text-slate-400 leading-relaxed">
          PostgreSQL B1ms & Container Apps running active in East US. Zero-cost tier active.
        </p>
      </div>
    </aside>
  );
}
