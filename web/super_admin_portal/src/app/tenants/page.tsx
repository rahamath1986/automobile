'use client';

import React, { useState } from 'react';
import { 
  Building2, 
  Plus, 
  Search, 
  Filter, 
  MoreVertical, 
  CheckCircle2, 
  AlertCircle, 
  X, 
  ArrowRight, 
  ShieldCheck, 
  ExternalLink,
  Layers,
  Sparkles,
  RefreshCw,
  Mail,
  Phone,
  Calendar,
  Lock
} from 'lucide-react';
import { INITIAL_TENANTS, SUBSCRIPTION_PLANS, OEM_BRANDS } from '@/lib/mock-data';
import { TenantSummary, SubscriptionTier, TenantStatus } from '@/lib/types';

export default function TenantsPage() {
  const [tenants, setTenants] = useState<TenantSummary[]>(INITIAL_TENANTS);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('All');
  const [oemFilter, setOemFilter] = useState<string>('All');
  const [selectedTenant, setSelectedTenant] = useState<TenantSummary | null>(null);
  
  // Onboarding Wizard Modal State
  const [showWizard, setShowWizard] = useState(false);
  const [step, setStep] = useState(1);
  const [wizardForm, setWizardForm] = useState({
    code: '',
    legalName: '',
    tradeName: '',
    taxId: '',
    primaryOem: 'Yamaha',
    primaryColor: '#002C6C',
    secondaryColor: '#E60012',
    subscriptionPlan: 'PROFESSIONAL' as SubscriptionTier,
    billingCycle: 'Monthly' as 'Monthly' | 'Annual',
    contactEmail: '',
    contactPhone: '',
    adminName: '',
    adminEmail: '',
  });

  const filteredTenants = tenants.filter((tenant) => {
    const matchesSearch = 
      tenant.code.toLowerCase().includes(searchQuery.toLowerCase()) ||
      tenant.tradeName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      tenant.legalName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      tenant.contactEmail.toLowerCase().includes(searchQuery.toLowerCase());
    
    const matchesStatus = statusFilter === 'All' || tenant.status === statusFilter;
    const matchesOem = oemFilter === 'All' || tenant.primaryOem === oemFilter;

    return matchesSearch && matchesStatus && matchesOem;
  });

  const handleToggleStatus = (tenantId: string) => {
    setTenants(prev => prev.map(t => {
      if (t.id === tenantId) {
        const nextStatus: TenantStatus = t.status === 'Active' ? 'Suspended' : 'Active';
        return { ...t, status: nextStatus };
      }
      return t;
    }));
  };

  const handleCompleteWizard = (e: React.FormEvent) => {
    e.preventDefault();
    const newTenant: TenantSummary = {
      id: `t-${wizardForm.code.toLowerCase()}`,
      code: wizardForm.code.toUpperCase(),
      legalName: wizardForm.legalName,
      tradeName: wizardForm.tradeName,
      taxId: wizardForm.taxId,
      primaryOem: wizardForm.primaryOem,
      oemBrands: [wizardForm.primaryOem],
      status: 'Active',
      subscriptionPlan: wizardForm.subscriptionPlan,
      branchesCount: 1,
      maxBranches: wizardForm.subscriptionPlan === 'ENTERPRISE' ? 999 : wizardForm.subscriptionPlan === 'PROFESSIONAL' ? 5 : 1,
      staffCount: 3,
      maxStaff: wizardForm.subscriptionPlan === 'ENTERPRISE' ? 999 : wizardForm.subscriptionPlan === 'PROFESSIONAL' ? 25 : 5,
      inventoryUnits: 15,
      maxInventory: wizardForm.subscriptionPlan === 'ENTERPRISE' ? 999 : wizardForm.subscriptionPlan === 'PROFESSIONAL' ? 250 : 50,
      mrr: wizardForm.subscriptionPlan === 'ENTERPRISE' ? 39999 : wizardForm.subscriptionPlan === 'PROFESSIONAL' ? 14999 : 4999,
      billingCycle: wizardForm.billingCycle,
      createdAt: new Date().toISOString().split('T')[0],
      contactEmail: wizardForm.contactEmail,
      contactPhone: wizardForm.contactPhone,
      primaryColor: wizardForm.primaryColor,
      secondaryColor: wizardForm.secondaryColor,
    };

    setTenants([newTenant, ...tenants]);
    setShowWizard(false);
    setStep(1);
    setWizardForm({
      code: '',
      legalName: '',
      tradeName: '',
      taxId: '',
      primaryOem: 'Yamaha',
      primaryColor: '#002C6C',
      secondaryColor: '#E60012',
      subscriptionPlan: 'PROFESSIONAL',
      billingCycle: 'Monthly',
      contactEmail: '',
      contactPhone: '',
      adminName: '',
      adminEmail: '',
    });
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-2 border-b border-slate-200">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900">
            Dealership Tenants & Franchisees
          </h1>
          <p className="text-sm text-slate-500 mt-0.5">
            Onboard new 2-wheeler automotive groups, govern subscription quotas, and manage tenant lifecycles.
          </p>
        </div>

        <button
          onClick={() => { setShowWizard(true); setStep(1); }}
          className="inline-flex items-center gap-2 px-4 py-2 bg-purple-600 hover:bg-purple-700 text-white text-sm font-semibold rounded-lg shadow-sm shadow-purple-500/20 transition-colors"
        >
          <Plus className="w-4 h-4" />
          <span>Onboard New Dealership</span>
        </button>
      </div>

      {/* Filters and Search Bar */}
      <div className="bg-white p-4 rounded-xl border border-slate-200/80 shadow-xs flex flex-col md:flex-row items-center justify-between gap-4">
        <div className="relative w-full md:w-96">
          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search by code, trade name, legal entity..."
            className="w-full pl-10 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-lg text-sm text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-purple-500/20 focus:border-purple-500 transition-all"
          />
        </div>

        <div className="flex items-center gap-3 w-full md:w-auto flex-wrap">
          <div className="flex items-center gap-2 text-xs font-semibold text-slate-500">
            <Filter className="w-3.5 h-3.5" />
            <span>Status:</span>
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="bg-slate-50 border border-slate-200 rounded-lg px-2.5 py-1.5 text-xs text-slate-800 font-medium focus:outline-none focus:border-purple-500"
            >
              <option value="All">All Statuses ({tenants.length})</option>
              <option value="Active">Active</option>
              <option value="Trial">Trial</option>
              <option value="Suspended">Suspended</option>
            </select>
          </div>

          <div className="flex items-center gap-2 text-xs font-semibold text-slate-500">
            <span>OEM:</span>
            <select
              value={oemFilter}
              onChange={(e) => setOemFilter(e.target.value)}
              className="bg-slate-50 border border-slate-200 rounded-lg px-2.5 py-1.5 text-xs text-slate-800 font-medium focus:outline-none focus:border-purple-500"
            >
              <option value="All">All OEMs</option>
              {OEM_BRANDS.map(oem => (
                <option key={oem.code} value={oem.name.split(' ')[0]}>
                  {oem.name.split(' ')[0]}
                </option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* Tenants Table */}
      <div className="bg-white rounded-xl border border-slate-200/80 shadow-xs overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-slate-50/80 border-b border-slate-200/80 uppercase tracking-wider text-[11px] text-slate-500 font-semibold">
              <tr>
                <th className="py-3.5 px-4">Dealership Entity</th>
                <th className="py-3.5 px-4">OEM Franchise</th>
                <th className="py-3.5 px-4">Plan & MRR</th>
                <th className="py-3.5 px-4">Branches & Quota</th>
                <th className="py-3.5 px-4">Staff / Inventory</th>
                <th className="py-3.5 px-4">Status</th>
                <th className="py-3.5 px-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {filteredTenants.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-8 text-center text-slate-500">
                    No dealerships found matching the current search & filters.
                  </td>
                </tr>
              ) : (
                filteredTenants.map((t) => (
                  <tr key={t.id} className="hover:bg-slate-50/60 transition-colors">
                    {/* Entity */}
                    <td className="py-3 px-4">
                      <div className="flex items-center gap-3">
                        <div 
                          className="w-9 h-9 rounded-lg flex items-center justify-center font-bold text-xs text-white shrink-0 shadow-xs"
                          style={{ backgroundColor: t.primaryColor }}
                        >
                          {t.code.slice(0, 2)}
                        </div>
                        <div>
                          <div className="font-bold text-slate-900 flex items-center gap-1.5">
                            <span>{t.tradeName}</span>
                            <span className="font-mono text-[10px] px-1.5 py-0.2 bg-slate-100 text-slate-600 rounded">
                              {t.code}
                            </span>
                          </div>
                          <div className="text-[11px] text-slate-500 mt-0.5">
                            {t.legalName} • GSTIN: {t.taxId}
                          </div>
                        </div>
                      </div>
                    </td>

                    {/* OEM */}
                    <td className="py-3 px-4 font-semibold text-slate-800">
                      <span className="px-2 py-0.5 rounded-full bg-slate-100 text-slate-700 text-[11px]">
                        {t.primaryOem}
                      </span>
                    </td>

                    {/* Plan */}
                    <td className="py-3 px-4">
                      <div className="font-bold text-purple-700">
                        {t.subscriptionPlan}
                      </div>
                      <div className="text-[11px] text-slate-500">
                        ₹{t.mrr.toLocaleString()} / mo ({t.billingCycle})
                      </div>
                    </td>

                    {/* Branches */}
                    <td className="py-3 px-4">
                      <div className="font-semibold text-slate-800">
                        {t.branchesCount} / {t.maxBranches === 999 ? '∞' : t.maxBranches} Branches
                      </div>
                      <div className="w-24 bg-slate-100 h-1.5 rounded-full mt-1 overflow-hidden">
                        <div 
                          className="bg-purple-600 h-full rounded-full" 
                          style={{ width: `${Math.min(100, (t.branchesCount / (t.maxBranches === 999 ? 10 : t.maxBranches)) * 100)}%` }}
                        />
                      </div>
                    </td>

                    {/* Staff & Inventory */}
                    <td className="py-3 px-4 text-slate-600">
                      <div>{t.staffCount} staff members</div>
                      <div className="text-[11px] text-slate-400">{t.inventoryUnits} live units</div>
                    </td>

                    {/* Status */}
                    <td className="py-3 px-4">
                      <span className={`px-2.5 py-0.5 rounded-md text-[11px] font-bold ${
                        t.status === 'Active'
                          ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                          : t.status === 'Trial'
                          ? 'bg-amber-50 text-amber-700 border border-amber-200'
                          : 'bg-rose-50 text-rose-700 border border-rose-200'
                      }`}>
                        {t.status}
                      </span>
                    </td>

                    {/* Actions */}
                    <td className="py-3 px-4 text-right">
                      <div className="flex items-center justify-end gap-1.5">
                        <button
                          onClick={() => setSelectedTenant(t)}
                          className="px-2.5 py-1 text-slate-600 hover:text-slate-900 hover:bg-slate-100 rounded text-xs font-semibold"
                        >
                          Details
                        </button>
                        <button
                          onClick={() => handleToggleStatus(t.id)}
                          className={`px-2.5 py-1 rounded text-xs font-semibold border ${
                            t.status === 'Active'
                              ? 'text-rose-600 border-rose-200 hover:bg-rose-50'
                              : 'text-emerald-600 border-emerald-200 hover:bg-emerald-50'
                          }`}
                        >
                          {t.status === 'Active' ? 'Suspend' : 'Activate'}
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Tenant Details Drawer / Modal */}
      {selectedTenant && (
        <div className="fixed inset-0 bg-slate-900/50 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl max-w-lg w-full p-6 shadow-2xl border border-slate-200 space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <div className="flex items-center gap-3">
                <div 
                  className="w-10 h-10 rounded-xl flex items-center justify-center font-bold text-white shadow-xs"
                  style={{ backgroundColor: selectedTenant.primaryColor }}
                >
                  {selectedTenant.code.slice(0, 2)}
                </div>
                <div>
                  <h3 className="font-bold text-slate-900">{selectedTenant.tradeName}</h3>
                  <p className="text-xs text-slate-500 font-mono">{selectedTenant.code}</p>
                </div>
              </div>
              <button onClick={() => setSelectedTenant(null)} className="text-slate-400 hover:text-slate-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-3 text-xs">
              <div className="p-3 bg-slate-50 rounded-lg space-y-1.5 border border-slate-100">
                <div className="flex justify-between">
                  <span className="text-slate-500">Legal Entity Name:</span>
                  <span className="font-semibold text-slate-800">{selectedTenant.legalName}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-500">GSTIN Tax ID:</span>
                  <span className="font-mono font-semibold text-slate-800">{selectedTenant.taxId}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-500">Primary Contact Email:</span>
                  <span className="font-semibold text-slate-800">{selectedTenant.contactEmail}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-500">Phone:</span>
                  <span className="font-semibold text-slate-800">{selectedTenant.contactPhone}</span>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div className="p-3 bg-purple-50/60 border border-purple-100 rounded-lg">
                  <span className="text-slate-500 text-[11px]">Subscription Plan</span>
                  <div className="font-bold text-purple-900 text-sm">{selectedTenant.subscriptionPlan}</div>
                  <div className="text-[11px] text-purple-700">₹{selectedTenant.mrr.toLocaleString()} / mo</div>
                </div>
                <div className="p-3 bg-slate-50 border border-slate-100 rounded-lg">
                  <span className="text-slate-500 text-[11px]">Primary OEM</span>
                  <div className="font-bold text-slate-800 text-sm">{selectedTenant.primaryOem}</div>
                  <div className="text-[11px] text-slate-500">Franchised Partner</div>
                </div>
              </div>

              <div className="p-3 bg-slate-50 rounded-lg border border-slate-100 space-y-2">
                <div className="font-bold text-slate-800">Resource Headroom</div>
                <div className="flex justify-between text-[11px]">
                  <span>Branches Allocated:</span>
                  <span className="font-semibold">{selectedTenant.branchesCount} / {selectedTenant.maxBranches === 999 ? 'Unlimited' : selectedTenant.maxBranches}</span>
                </div>
                <div className="flex justify-between text-[11px]">
                  <span>Staff Headcount:</span>
                  <span className="font-semibold">{selectedTenant.staffCount} / {selectedTenant.maxStaff === 999 ? 'Unlimited' : selectedTenant.maxStaff}</span>
                </div>
                <div className="flex justify-between text-[11px]">
                  <span>Live Inventory Units:</span>
                  <span className="font-semibold">{selectedTenant.inventoryUnits} units</span>
                </div>
              </div>
            </div>

            <div className="pt-3 border-t border-slate-100 flex items-center justify-end gap-2">
              <button
                onClick={() => setSelectedTenant(null)}
                className="px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-lg text-xs font-semibold"
              >
                Close
              </button>
              <button
                onClick={() => {
                  handleToggleStatus(selectedTenant.id);
                  setSelectedTenant(null);
                }}
                className={`px-4 py-2 rounded-lg text-xs font-semibold text-white ${
                  selectedTenant.status === 'Active' ? 'bg-rose-600 hover:bg-rose-700' : 'bg-emerald-600 hover:bg-emerald-700'
                }`}
              >
                {selectedTenant.status === 'Active' ? 'Suspend Tenant Access' : 'Activate Tenant'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 4-Step Dealership Onboarding Wizard Modal */}
      {showWizard && (
        <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl max-w-2xl w-full p-6 shadow-2xl border border-slate-200 space-y-5">
            {/* Wizard Header */}
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <div>
                <h3 className="text-lg font-bold text-slate-900">
                  Dealership Onboarding Wizard
                </h3>
                <p className="text-xs text-slate-500">
                  Step {step} of 4: {
                    step === 1 ? 'Legal & Trade Identity' :
                    step === 2 ? 'OEM Brand & Theme' :
                    step === 3 ? 'Subscription & Quotas' :
                    'Admin Credentials & Review'
                  }
                </p>
              </div>
              <button 
                onClick={() => setShowWizard(false)}
                className="text-slate-400 hover:text-slate-600"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Stepper Dots */}
            <div className="flex items-center justify-between px-6">
              {[1, 2, 3, 4].map((s) => (
                <div key={s} className="flex items-center gap-2">
                  <div className={`w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold ${
                    step === s 
                      ? 'bg-purple-600 text-white ring-4 ring-purple-100' 
                      : step > s 
                      ? 'bg-emerald-500 text-white' 
                      : 'bg-slate-100 text-slate-400'
                  }`}>
                    {step > s ? '✓' : s}
                  </div>
                  {s < 4 && <div className={`w-16 h-0.5 ${step > s ? 'bg-emerald-500' : 'bg-slate-200'}`} />}
                </div>
              ))}
            </div>

            {/* Step 1: Legal & Trade */}
            {step === 1 && (
              <div className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-semibold text-slate-700 mb-1">
                      Unique Dealer Code *
                    </label>
                    <input
                      type="text"
                      required
                      placeholder="e.g. HERO_SOUTH"
                      value={wizardForm.code}
                      onChange={(e) => setWizardForm({ ...wizardForm, code: e.target.value.toUpperCase().replace(/\s+/g, '_') })}
                      className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs font-mono font-bold uppercase focus:ring-2 focus:ring-purple-500/20 focus:border-purple-500"
                    />
                    <span className="text-[10px] text-slate-400">Used as X-Dealer-Code header and subdomain.</span>
                  </div>

                  <div>
                    <label className="block text-xs font-semibold text-slate-700 mb-1">
                      GSTIN Tax ID *
                    </label>
                    <input
                      type="text"
                      required
                      placeholder="33AAAAA0000A1Z5"
                      value={wizardForm.taxId}
                      onChange={(e) => setWizardForm({ ...wizardForm, taxId: e.target.value.toUpperCase() })}
                      className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs font-mono focus:ring-2 focus:ring-purple-500/20 focus:border-purple-500"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Trade Name (Customer-Facing Store Name) *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. South Star Hero Super Store"
                    value={wizardForm.tradeName}
                    onChange={(e) => setWizardForm({ ...wizardForm, tradeName: e.target.value })}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs font-medium focus:ring-2 focus:ring-purple-500/20 focus:border-purple-500"
                  />
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Legal Registered Company Name *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. South Star Two Wheelers Private Limited"
                    value={wizardForm.legalName}
                    onChange={(e) => setWizardForm({ ...wizardForm, legalName: e.target.value })}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs font-medium focus:ring-2 focus:ring-purple-500/20 focus:border-purple-500"
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-semibold text-slate-700 mb-1">
                      Contact Email *
                    </label>
                    <input
                      type="email"
                      required
                      placeholder="admin@dealership.com"
                      value={wizardForm.contactEmail}
                      onChange={(e) => setWizardForm({ ...wizardForm, contactEmail: e.target.value })}
                      className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs focus:ring-2 focus:ring-purple-500/20 focus:border-purple-500"
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-semibold text-slate-700 mb-1">
                      Contact Phone *
                    </label>
                    <input
                      type="tel"
                      required
                      placeholder="+91 98400 12345"
                      value={wizardForm.contactPhone}
                      onChange={(e) => setWizardForm({ ...wizardForm, contactPhone: e.target.value })}
                      className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs focus:ring-2 focus:ring-purple-500/20 focus:border-purple-500"
                    />
                  </div>
                </div>
              </div>
            )}

            {/* Step 2: OEM Brand & Theme */}
            {step === 2 && (
              <div className="space-y-4">
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1.5">
                    Primary OEM Franchise *
                  </label>
                  <div className="grid grid-cols-3 gap-2.5">
                    {OEM_BRANDS.map((oem) => (
                      <button
                        type="button"
                        key={oem.code}
                        onClick={() => setWizardForm({ ...wizardForm, primaryOem: oem.name.split(' ')[0] })}
                        className={`p-3 rounded-xl border text-left transition-all ${
                          wizardForm.primaryOem === oem.name.split(' ')[0]
                            ? 'border-purple-600 bg-purple-50/70 ring-2 ring-purple-600/20'
                            : 'border-slate-200 hover:border-slate-300 bg-white'
                        }`}
                      >
                        <div className="font-bold text-xs text-slate-900">{oem.name.split(' ')[0]}</div>
                        <div className="text-[10px] text-slate-500">{oem.totalModels} global models</div>
                      </button>
                    ))}
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4 pt-2">
                  <div>
                    <label className="block text-xs font-semibold text-slate-700 mb-1">
                      Primary Brand Color
                    </label>
                    <div className="flex items-center gap-2">
                      <input
                        type="color"
                        value={wizardForm.primaryColor}
                        onChange={(e) => setWizardForm({ ...wizardForm, primaryColor: e.target.value })}
                        className="w-10 h-10 rounded border border-slate-200 cursor-pointer"
                      />
                      <input
                        type="text"
                        value={wizardForm.primaryColor}
                        onChange={(e) => setWizardForm({ ...wizardForm, primaryColor: e.target.value })}
                        className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs font-mono"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-xs font-semibold text-slate-700 mb-1">
                      Secondary Brand Accent
                    </label>
                    <div className="flex items-center gap-2">
                      <input
                        type="color"
                        value={wizardForm.secondaryColor}
                        onChange={(e) => setWizardForm({ ...wizardForm, secondaryColor: e.target.value })}
                        className="w-10 h-10 rounded border border-slate-200 cursor-pointer"
                      />
                      <input
                        type="text"
                        value={wizardForm.secondaryColor}
                        onChange={(e) => setWizardForm({ ...wizardForm, secondaryColor: e.target.value })}
                        className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs font-mono"
                      />
                    </div>
                  </div>
                </div>

                <div className="p-3 bg-slate-50 rounded-lg border border-slate-200 flex items-center justify-between text-xs">
                  <div>
                    <div className="font-semibold text-slate-800">Auto-Sync OEM Master Catalog</div>
                    <div className="text-slate-500 text-[11px]">Automatically load manufacturer models and high-res photos into dealer catalog.</div>
                  </div>
                  <input type="checkbox" defaultChecked className="w-4 h-4 text-purple-600 rounded" />
                </div>
              </div>
            )}

            {/* Step 3: Subscription & Quota */}
            {step === 3 && (
              <div className="space-y-4">
                <label className="block text-xs font-semibold text-slate-700">
                  Select Subscription Tier *
                </label>
                <div className="grid grid-cols-3 gap-3">
                  {SUBSCRIPTION_PLANS.map((plan) => (
                    <button
                      type="button"
                      key={plan.id}
                      onClick={() => setWizardForm({ ...wizardForm, subscriptionPlan: plan.code })}
                      className={`p-3.5 rounded-xl border text-left transition-all relative ${
                        wizardForm.subscriptionPlan === plan.code
                          ? 'border-purple-600 bg-purple-50/70 ring-2 ring-purple-600/20'
                          : 'border-slate-200 hover:border-slate-300 bg-white'
                      }`}
                    >
                      {plan.isPopular && (
                        <span className="absolute -top-2 right-2 px-1.5 py-0.2 bg-purple-600 text-white text-[9px] font-bold rounded">
                          POPULAR
                        </span>
                      )}
                      <div className="font-bold text-xs text-slate-900">{plan.name}</div>
                      <div className="font-extrabold text-sm text-purple-700 mt-1">
                        ₹{plan.monthlyPrice.toLocaleString()}<span className="text-[10px] text-slate-500 font-normal">/mo</span>
                      </div>
                      <div className="text-[10px] text-slate-500 mt-2 space-y-0.5">
                        <div>• Up to {plan.maxBranches === 999 ? 'Unlimited' : plan.maxBranches} Branches</div>
                        <div>• {plan.maxStaff === 999 ? 'Unlimited' : plan.maxStaff} Staff users</div>
                        <div>• {plan.maxInventory === 999 ? 'Unlimited' : plan.maxInventory} Inventory</div>
                      </div>
                    </button>
                  ))}
                </div>

                <div className="pt-2">
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Billing Cycle
                  </label>
                  <div className="flex gap-4">
                    <label className="flex items-center gap-2 text-xs font-medium text-slate-700 cursor-pointer">
                      <input 
                        type="radio" 
                        name="cycle" 
                        checked={wizardForm.billingCycle === 'Monthly'} 
                        onChange={() => setWizardForm({ ...wizardForm, billingCycle: 'Monthly' })} 
                      />
                      <span>Monthly Billed</span>
                    </label>
                    <label className="flex items-center gap-2 text-xs font-medium text-slate-700 cursor-pointer">
                      <input 
                        type="radio" 
                        name="cycle" 
                        checked={wizardForm.billingCycle === 'Annual'} 
                        onChange={() => setWizardForm({ ...wizardForm, billingCycle: 'Annual' })} 
                      />
                      <span>Annual (10% Discount Applied)</span>
                    </label>
                  </div>
                </div>
              </div>
            )}

            {/* Step 4: Admin Credentials & Review */}
            {step === 4 && (
              <div className="space-y-4">
                <div className="p-3.5 bg-slate-50 border border-slate-200 rounded-xl space-y-2 text-xs">
                  <div className="font-bold text-slate-900 text-sm">Review Dealership Setup</div>
                  <div className="grid grid-cols-2 gap-2 text-[11px]">
                    <div><strong className="text-slate-600">Code:</strong> {wizardForm.code || 'HERO_SOUTH'}</div>
                    <div><strong className="text-slate-600">Trade:</strong> {wizardForm.tradeName || 'New Dealership'}</div>
                    <div><strong className="text-slate-600">OEM:</strong> {wizardForm.primaryOem}</div>
                    <div><strong className="text-slate-600">Tier:</strong> {wizardForm.subscriptionPlan}</div>
                  </div>
                </div>

                <div className="space-y-3 pt-1">
                  <div className="font-semibold text-xs text-slate-800 flex items-center gap-1.5">
                    <Lock className="w-3.5 h-3.5 text-purple-600" />
                    <span>Initial Org Admin Account</span>
                  </div>

                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <label className="block text-xs text-slate-600 mb-1">Admin Name</label>
                      <input
                        type="text"
                        placeholder="e.g. Ramesh Kumar"
                        value={wizardForm.adminName}
                        onChange={(e) => setWizardForm({ ...wizardForm, adminName: e.target.value })}
                        className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs"
                      />
                    </div>
                    <div>
                      <label className="block text-xs text-slate-600 mb-1">Admin Email (Login)</label>
                      <input
                        type="email"
                        placeholder="admin@dealership.com"
                        value={wizardForm.adminEmail}
                        onChange={(e) => setWizardForm({ ...wizardForm, adminEmail: e.target.value })}
                        className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs"
                      />
                    </div>
                  </div>

                  <div className="p-3 bg-purple-50/70 border border-purple-200 rounded-lg text-[11px] text-purple-900 flex items-center gap-2">
                    <CheckCircle2 className="w-4 h-4 text-purple-600 shrink-0" />
                    <span>Auto-provisions password reset token and welcome email with direct access link.</span>
                  </div>
                </div>
              </div>
            )}

            {/* Stepper Controls */}
            <div className="pt-4 border-t border-slate-100 flex items-center justify-between">
              {step > 1 ? (
                <button
                  type="button"
                  onClick={() => setStep(step - 1)}
                  className="px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-lg text-xs font-semibold"
                >
                  Back
                </button>
              ) : <div />}

              {step < 4 ? (
                <button
                  type="button"
                  onClick={() => setStep(step + 1)}
                  className="inline-flex items-center gap-1.5 px-4 py-2 bg-purple-600 hover:bg-purple-700 text-white text-xs font-semibold rounded-lg shadow-sm"
                >
                  <span>Continue</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </button>
              ) : (
                <button
                  type="button"
                  onClick={handleCompleteWizard}
                  className="inline-flex items-center gap-1.5 px-5 py-2 bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold rounded-lg shadow-sm"
                >
                  <span>Provision & Launch Dealership</span>
                  <CheckCircle2 className="w-4 h-4" />
                </button>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
