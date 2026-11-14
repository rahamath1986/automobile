'use client';

import React, { useState } from 'react';
import { 
  CreditCard, 
  Check, 
  X, 
  Plus, 
  Edit3, 
  ShieldCheck, 
  Sparkles, 
  Building2, 
  Users, 
  Box,
  Layers,
  ArrowRight
} from 'lucide-react';
import { SUBSCRIPTION_PLANS } from '@/lib/mock-data';
import { SubscriptionPlanDef, SubscriptionTier } from '@/lib/types';

export default function SubscriptionPlansPage() {
  const [plans, setPlans] = useState<SubscriptionPlanDef[]>(SUBSCRIPTION_PLANS);
  const [editingPlan, setEditingPlan] = useState<SubscriptionPlanDef | null>(null);
  const [billingCycle, setBillingCycle] = useState<'Monthly' | 'Annual'>('Monthly');

  const handleSavePlan = (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingPlan) return;
    setPlans(prev => prev.map(p => p.id === editingPlan.id ? editingPlan : p));
    setEditingPlan(null);
  };

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white tracking-tight flex items-center gap-2">
            <CreditCard className="w-6 h-6 text-purple-400" />
            Subscription Tiers & Feature Entitlements
          </h1>
          <p className="text-sm text-slate-400 mt-1">
            Configure dealership SaaS pricing, branch quotas, physical inventory limits, and feature toggles.
          </p>
        </div>

        {/* Monthly vs Annual Toggle */}
        <div className="flex items-center gap-2 bg-slate-900 p-1 rounded-xl border border-slate-800 self-start sm:self-auto">
          <button
            onClick={() => setBillingCycle('Monthly')}
            className={`px-4 py-1.5 rounded-lg text-xs font-semibold transition-all ${
              billingCycle === 'Monthly' 
                ? 'bg-purple-600 text-white shadow' 
                : 'text-slate-400 hover:text-white'
            }`}
          >
            Monthly Billing
          </button>
          <button
            onClick={() => setBillingCycle('Annual')}
            className={`px-4 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5 transition-all ${
              billingCycle === 'Annual' 
                ? 'bg-purple-600 text-white shadow' 
                : 'text-slate-400 hover:text-white'
            }`}
          >
            Annual Billing
            <span className="text-[10px] px-1.5 py-0.2 rounded-full bg-emerald-500/20 text-emerald-300 font-bold">Save 17%</span>
          </button>
        </div>
      </div>

      {/* Plan Pricing Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {plans.map((plan) => {
          const isEnterprise = plan.code === 'ENTERPRISE';
          const price = billingCycle === 'Monthly' ? plan.monthlyPrice : Math.round(plan.annualPrice / 12);

          return (
            <div 
              key={plan.id}
              className={`rounded-2xl p-6 border flex flex-col justify-between relative transition-all duration-200 ${
                plan.isPopular 
                  ? 'bg-gradient-to-b from-purple-950/40 via-slate-900 to-slate-900 border-purple-500/60 shadow-xl shadow-purple-950/40' 
                  : 'bg-slate-900/90 border-slate-800 shadow-lg'
              }`}
            >
              {plan.isPopular && (
                <div className="absolute -top-3 left-1/2 -translate-x-1/2 px-3 py-1 rounded-full bg-gradient-to-r from-purple-600 to-indigo-500 text-[11px] font-bold text-white shadow-md flex items-center gap-1">
                  <Sparkles className="w-3 h-3" />
                  MOST POPULAR DEALER TIER
                </div>
              )}

              <div>
                <div className="flex items-center justify-between mb-3">
                  <span className="text-xs font-bold uppercase tracking-wider text-purple-400">
                    {plan.code}
                  </span>
                  <span className="text-xs text-slate-400 font-medium">
                    {plan.activeTenantsCount} Active Dealers
                  </span>
                </div>

                <h3 className="text-xl font-bold text-white">{plan.name}</h3>
                <p className="text-xs text-slate-400 mt-2 min-h-[36px]">{plan.description}</p>

                {/* Price Display */}
                <div className="mt-5 pb-5 border-b border-slate-800">
                  <div className="flex items-baseline gap-1">
                    <span className="text-3xl font-extrabold text-white">
                      ₹{price.toLocaleString('en-IN')}
                    </span>
                    <span className="text-xs text-slate-400 font-medium">
                      / month / org
                    </span>
                  </div>
                  {billingCycle === 'Annual' && (
                    <div className="text-[11px] text-emerald-400 mt-1 font-medium">
                      Billed annually at ₹{plan.annualPrice.toLocaleString('en-IN')}
                    </div>
                  )}
                </div>

                {/* Capacity Limits */}
                <div className="py-4 space-y-2.5 border-b border-slate-800 text-xs">
                  <div className="flex items-center justify-between text-slate-300">
                    <span className="flex items-center gap-2 text-slate-400">
                      <Building2 className="w-3.5 h-3.5" /> Max Branches:
                    </span>
                    <span className="font-bold text-white">
                      {plan.maxBranches > 100 ? 'Unlimited' : `${plan.maxBranches} Branches`}
                    </span>
                  </div>
                  <div className="flex items-center justify-between text-slate-300">
                    <span className="flex items-center gap-2 text-slate-400">
                      <Users className="w-3.5 h-3.5" /> Max Staff Accounts:
                    </span>
                    <span className="font-bold text-white">
                      {plan.maxStaff > 100 ? 'Unlimited' : `${plan.maxStaff} Users`}
                    </span>
                  </div>
                  <div className="flex items-center justify-between text-slate-300">
                    <span className="flex items-center gap-2 text-slate-400">
                      <Box className="w-3.5 h-3.5" /> Active Inventory Units:
                    </span>
                    <span className="font-bold text-white">
                      {plan.maxInventory > 100 ? 'Unlimited' : `${plan.maxInventory} Vehicles`}
                    </span>
                  </div>
                </div>

                {/* Feature Checklist */}
                <div className="pt-4 space-y-2 text-xs">
                  <FeatureRow label="3D & 360° Showroom Visualizer" enabled={plan.features.showroom3D} />
                  <FeatureRow label="After-Sales Service & Digital Job Cards" enabled={plan.features.afterSalesService} />
                  <FeatureRow label="Dynamic Quotation & EMI Studio" enabled={plan.features.emiCalculator} />
                  <FeatureRow label="Financier Schemes & Online Approval" enabled={plan.features.financierSchemes} />
                  <FeatureRow label="Inter-Branch Stock Transfers" enabled={plan.features.multiBranchTransfer} />
                  <FeatureRow label="Accounting Ledger & GST Export" enabled={plan.features.accountingExport} />
                  <FeatureRow label="Advanced BI & Executive Analytics" enabled={plan.features.advancedAnalytics} />
                  <FeatureRow label="Custom White-Label Domain & Branding" enabled={plan.features.customBranding} />
                  <FeatureRow label="WhatsApp Automated Customer Alerts" enabled={plan.features.whatsappIntegration} />
                  <FeatureRow label="Dedicated Support SLA" enabled={plan.features.prioritySLA} />
                </div>
              </div>

              {/* Action Button */}
              <div className="mt-6 pt-4 border-t border-slate-800">
                <button
                  onClick={() => setEditingPlan(plan)}
                  className="w-full py-2.5 px-4 rounded-xl text-xs font-semibold bg-slate-800 hover:bg-slate-700 text-white flex items-center justify-center gap-2 border border-slate-700 transition-colors"
                >
                  <Edit3 className="w-3.5 h-3.5 text-purple-400" />
                  Edit Plan Limits & Features
                </button>
              </div>
            </div>
          );
        })}
      </div>

      {/* Edit Plan Modal */}
      {editingPlan && (
        <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl w-full max-w-lg overflow-hidden shadow-2xl">
            <div className="px-6 py-4 border-b border-slate-800 flex items-center justify-between">
              <div>
                <h3 className="text-base font-bold text-white">Edit {editingPlan.name}</h3>
                <p className="text-xs text-slate-400 mt-0.5">Tier Code: {editingPlan.code}</p>
              </div>
              <button 
                onClick={() => setEditingPlan(null)}
                className="text-slate-400 hover:text-white p-1 rounded-lg"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSavePlan} className="p-6 space-y-4 max-h-[75vh] overflow-y-auto">
              <div>
                <label className="block text-xs font-medium text-slate-300 mb-1">Plan Display Name</label>
                <input
                  type="text"
                  value={editingPlan.name}
                  onChange={e => setEditingPlan({...editingPlan, name: e.target.value})}
                  className="w-full px-3 py-2 bg-slate-950 border border-slate-800 rounded-lg text-sm text-white"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-medium text-slate-300 mb-1">Monthly Price (₹)</label>
                  <input
                    type="number"
                    value={editingPlan.monthlyPrice}
                    onChange={e => setEditingPlan({...editingPlan, monthlyPrice: Number(e.target.value)})}
                    className="w-full px-3 py-2 bg-slate-950 border border-slate-800 rounded-lg text-sm text-white"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-300 mb-1">Annual Price (₹)</label>
                  <input
                    type="number"
                    value={editingPlan.annualPrice}
                    onChange={e => setEditingPlan({...editingPlan, annualPrice: Number(e.target.value)})}
                    className="w-full px-3 py-2 bg-slate-950 border border-slate-800 rounded-lg text-sm text-white"
                  />
                </div>
              </div>

              <div className="grid grid-cols-3 gap-3">
                <div>
                  <label className="block text-xs font-medium text-slate-300 mb-1">Max Branches</label>
                  <input
                    type="number"
                    value={editingPlan.maxBranches}
                    onChange={e => setEditingPlan({...editingPlan, maxBranches: Number(e.target.value)})}
                    className="w-full px-3 py-2 bg-slate-950 border border-slate-800 rounded-lg text-sm text-white"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-300 mb-1">Max Staff</label>
                  <input
                    type="number"
                    value={editingPlan.maxStaff}
                    onChange={e => setEditingPlan({...editingPlan, maxStaff: Number(e.target.value)})}
                    className="w-full px-3 py-2 bg-slate-950 border border-slate-800 rounded-lg text-sm text-white"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-300 mb-1">Max Inventory</label>
                  <input
                    type="number"
                    value={editingPlan.maxInventory}
                    onChange={e => setEditingPlan({...editingPlan, maxInventory: Number(e.target.value)})}
                    className="w-full px-3 py-2 bg-slate-950 border border-slate-800 rounded-lg text-sm text-white"
                  />
                </div>
              </div>

              <div className="pt-2">
                <label className="block text-xs font-medium text-slate-300 mb-2">Feature Toggles</label>
                <div className="grid grid-cols-2 gap-2 text-xs">
                  {Object.entries(editingPlan.features).map(([key, val]) => (
                    <label key={key} className="flex items-center gap-2 p-2 bg-slate-950 border border-slate-800 rounded-lg text-slate-300 cursor-pointer hover:bg-slate-800/50">
                      <input
                        type="checkbox"
                        checked={val}
                        onChange={e => setEditingPlan({
                          ...editingPlan,
                          features: { ...editingPlan.features, [key]: e.target.checked }
                        })}
                        className="rounded border-slate-700 text-purple-600 focus:ring-purple-500 bg-slate-900"
                      />
                      <span className="capitalize">{key.replace(/([A-Z])/g, ' $1')}</span>
                    </label>
                  ))}
                </div>
              </div>

              <div className="pt-4 border-t border-slate-800 flex justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setEditingPlan(null)}
                  className="px-4 py-2 rounded-lg text-xs font-semibold text-slate-400 hover:text-white"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 rounded-lg text-xs font-semibold bg-purple-600 hover:bg-purple-500 text-white shadow-md shadow-purple-600/30"
                >
                  Save Plan Changes
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

function FeatureRow({ label, enabled }: { label: string; enabled: boolean }) {
  return (
    <div className="flex items-center gap-2 text-slate-300">
      {enabled ? (
        <div className="w-4 h-4 rounded-full bg-emerald-500/20 text-emerald-400 flex items-center justify-center shrink-0">
          <Check className="w-2.5 h-2.5 stroke-[3]" />
        </div>
      ) : (
        <div className="w-4 h-4 rounded-full bg-slate-800 text-slate-600 flex items-center justify-center shrink-0">
          <X className="w-2.5 h-2.5" />
        </div>
      )}
      <span className={enabled ? 'text-slate-200' : 'text-slate-500 line-through'}>{label}</span>
    </div>
  );
}
