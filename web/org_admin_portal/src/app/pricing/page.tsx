'use client';

import React, { useState } from 'react';
import {
  BadgeDollarSign,
  ShieldAlert,
  Percent,
  Sliders,
  CheckCircle2,
  AlertCircle,
  FileEdit,
  Save
} from 'lucide-react';
import { DEMO_PRICING_RULES } from '@/lib/mock-data';
import { RegionalPricingRule } from '@/lib/types';

export default function PricingRulesPage() {
  const [rules, setRules] = useState<RegionalPricingRule[]>(DEMO_PRICING_RULES);
  const [editingRule, setEditingRule] = useState<RegionalPricingRule | null>(null);

  const handleSave = (updated: RegionalPricingRule) => {
    const onRoad = Math.round(
      updated.exShowroomBase +
      (updated.exShowroomBase * updated.rtoPercent / 100) +
      updated.insuranceFloor +
      updated.accessoriesPackagePrice +
      updated.handlingCap
    );

    setRules((prev) =>
      prev.map((r) => (r.id === updated.id ? { ...updated, effectiveOnRoadEstimate: onRoad } : r))
    );
    setEditingRule(null);
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 text-xs font-semibold uppercase tracking-wider text-amber-600">
            <span>Commercial Policies</span>
            <span>•</span>
            <span>Catalog Pricing & Discount Limits</span>
          </div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900 mt-1">
            Pricing Rules & Discount Governance
          </h1>
          <p className="text-sm text-slate-500">
            Configure regional on-road calculation components, statutory RTO slabs, and tiered staff discount approval limits.
          </p>
        </div>
      </div>

      {/* Discount Policy Matrix Banner */}
      <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-xs">
        <h2 className="text-sm font-bold text-slate-900 flex items-center gap-2">
          <ShieldAlert className="w-4 h-4 text-amber-600" />
          <span>Tiered Discount Approval Hierarchy (Anti-Margin Erosion)</span>
        </h2>
        <p className="text-xs text-slate-500 mt-1">
          Branch staff cannot quote beyond their role cap without escalation to the next supervisory tier.
        </p>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mt-4">
          <div className="p-4 rounded-xl border border-blue-200 bg-blue-50/50">
            <span className="text-[10px] font-bold uppercase tracking-wider text-blue-700 block">
              Tier 1: Sales Executive
            </span>
            <div className="text-xl font-bold text-slate-900 font-mono mt-1">Up to ₹2,000</div>
            <div className="text-xs text-slate-500 mt-1">Immediate self-authorization on spot closures.</div>
          </div>

          <div className="p-4 rounded-xl border border-purple-200 bg-purple-50/50">
            <span className="text-[10px] font-bold uppercase tracking-wider text-purple-700 block">
              Tier 2: Branch Manager
            </span>
            <div className="text-xl font-bold text-slate-900 font-mono mt-1">Up to ₹6,000</div>
            <div className="text-xs text-slate-500 mt-1">Requires branch manager digital sign-off.</div>
          </div>

          <div className="p-4 rounded-xl border border-amber-200 bg-amber-50/50">
            <span className="text-[10px] font-bold uppercase tracking-wider text-amber-700 block">
              Tier 3: Org Admin / Dealer Principal
            </span>
            <div className="text-xl font-bold text-slate-900 font-mono mt-1">Above ₹6,000 (No Limit)</div>
            <div className="text-xs text-slate-500 mt-1">Exclusive prerogative of head-office leadership.</div>
          </div>
        </div>
      </div>

      {/* Pricing Rules Table */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-xs overflow-hidden">
        <div className="px-6 py-4 border-b border-slate-200 flex items-center justify-between">
          <h2 className="text-sm font-bold text-slate-900">Vehicle Models On-Road Pricing Matrix</h2>
          <span className="text-xs text-slate-500 font-mono">{rules.length} Configured Models</span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-slate-50 border-b border-slate-200 text-slate-600 font-semibold uppercase tracking-wider text-[11px]">
              <tr>
                <th className="px-4 py-3.5">Model & Variant</th>
                <th className="px-4 py-3.5 text-right">Ex-Showroom</th>
                <th className="px-4 py-3.5 text-center">RTO Tax</th>
                <th className="px-4 py-3.5 text-right">Insurance Floor</th>
                <th className="px-4 py-3.5 text-right">Accessories</th>
                <th className="px-4 py-3.5 text-right">Handling</th>
                <th className="px-4 py-3.5 text-right">Effective On-Road</th>
                <th className="px-4 py-3.5 text-center">Max Staff Discount</th>
                <th className="px-4 py-3.5 text-right">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {rules.map((rule) => (
                <tr key={rule.id} className="hover:bg-slate-50/70 transition-colors">
                  <td className="px-4 py-3.5">
                    <div className="font-bold text-slate-900">{rule.modelName}</div>
                    <div className="text-[11px] text-slate-500">{rule.variantName}</div>
                  </td>
                  <td className="px-4 py-3.5 text-right font-mono font-semibold text-slate-900">
                    ₹{rule.exShowroomBase.toLocaleString('en-IN')}
                  </td>
                  <td className="px-4 py-3.5 text-center font-mono text-slate-700">
                    {rule.rtoPercent}%
                  </td>
                  <td className="px-4 py-3.5 text-right font-mono text-slate-700">
                    ₹{rule.insuranceFloor.toLocaleString('en-IN')}
                  </td>
                  <td className="px-4 py-3.5 text-right font-mono text-slate-700">
                    ₹{rule.accessoriesPackagePrice.toLocaleString('en-IN')}
                  </td>
                  <td className="px-4 py-3.5 text-right font-mono text-slate-700">
                    ₹{rule.handlingCap.toLocaleString('en-IN')}
                  </td>
                  <td className="px-4 py-3.5 text-right font-mono font-bold text-amber-600 text-sm">
                    ₹{rule.effectiveOnRoadEstimate.toLocaleString('en-IN')}
                  </td>
                  <td className="px-4 py-3.5 text-center font-mono text-slate-600 text-[11px]">
                    Sales: ₹{rule.maxSalesDiscount} / Mgr: ₹{rule.maxManagerDiscount}
                  </td>
                  <td className="px-4 py-3.5 text-right">
                    <button
                      onClick={() => setEditingRule(rule)}
                      className="text-amber-600 hover:text-amber-700 font-semibold inline-flex items-center gap-1"
                    >
                      <FileEdit className="w-3.5 h-3.5" />
                      <span>Edit</span>
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Edit Rule Modal */}
      {editingRule && (
        <div className="fixed inset-0 z-50 bg-slate-900/40 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-lg w-full p-6 shadow-xl border border-slate-200 space-y-4 animate-in fade-in zoom-in-95 duration-150">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <div>
                <span className="text-[10px] font-bold uppercase tracking-wider text-amber-600">
                  Update Price Formula
                </span>
                <h2 className="text-base font-bold text-slate-900 mt-0.5">
                  {editingRule.modelName} ({editingRule.variantName})
                </h2>
              </div>
              <button
                type="button"
                onClick={() => setEditingRule(null)}
                className="w-8 h-8 rounded-lg text-slate-400 hover:text-slate-600"
              >
                ✕
              </button>
            </div>

            <div className="grid grid-cols-2 gap-3 text-xs">
              <div>
                <label className="font-semibold text-slate-700">Ex-Showroom Price (₹)</label>
                <input
                  type="number"
                  value={editingRule.exShowroomBase}
                  onChange={(e) =>
                    setEditingRule({ ...editingRule, exShowroomBase: Number(e.target.value) })
                  }
                  className="w-full mt-1 px-3 py-2 border border-slate-200 rounded-xl font-mono outline-none"
                />
              </div>

              <div>
                <label className="font-semibold text-slate-700">RTO Tax Percentage (%)</label>
                <input
                  type="number"
                  step={0.5}
                  value={editingRule.rtoPercent}
                  onChange={(e) =>
                    setEditingRule({ ...editingRule, rtoPercent: Number(e.target.value) })
                  }
                  className="w-full mt-1 px-3 py-2 border border-slate-200 rounded-xl font-mono outline-none"
                />
              </div>

              <div>
                <label className="font-semibold text-slate-700">Insurance Floor (₹)</label>
                <input
                  type="number"
                  value={editingRule.insuranceFloor}
                  onChange={(e) =>
                    setEditingRule({ ...editingRule, insuranceFloor: Number(e.target.value) })
                  }
                  className="w-full mt-1 px-3 py-2 border border-slate-200 rounded-xl font-mono outline-none"
                />
              </div>

              <div>
                <label className="font-semibold text-slate-700">Accessories Kit (₹)</label>
                <input
                  type="number"
                  value={editingRule.accessoriesPackagePrice}
                  onChange={(e) =>
                    setEditingRule({ ...editingRule, accessoriesPackagePrice: Number(e.target.value) })
                  }
                  className="w-full mt-1 px-3 py-2 border border-slate-200 rounded-xl font-mono outline-none"
                />
              </div>

              <div>
                <label className="font-semibold text-slate-700">Handling Cap (₹)</label>
                <input
                  type="number"
                  value={editingRule.handlingCap}
                  onChange={(e) =>
                    setEditingRule({ ...editingRule, handlingCap: Number(e.target.value) })
                  }
                  className="w-full mt-1 px-3 py-2 border border-slate-200 rounded-xl font-mono outline-none"
                />
              </div>

              <div>
                <label className="font-semibold text-slate-700">Max Sales Discount (₹)</label>
                <input
                  type="number"
                  value={editingRule.maxSalesDiscount}
                  onChange={(e) =>
                    setEditingRule({ ...editingRule, maxSalesDiscount: Number(e.target.value) })
                  }
                  className="w-full mt-1 px-3 py-2 border border-slate-200 rounded-xl font-mono outline-none"
                />
              </div>
            </div>

            <div className="flex justify-end gap-2 pt-3 border-t border-slate-100">
              <button
                type="button"
                onClick={() => setEditingRule(null)}
                className="px-4 py-2 rounded-xl text-xs font-semibold text-slate-600 hover:bg-slate-100"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={() => handleSave(editingRule)}
                className="bg-amber-600 hover:bg-amber-500 text-white px-4 py-2 rounded-xl text-xs font-semibold shadow-xs flex items-center gap-1.5"
              >
                <Save className="w-3.5 h-3.5" />
                <span>Save Formula</span>
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

