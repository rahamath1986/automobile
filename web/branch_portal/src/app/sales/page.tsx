'use client';

import React, { useState } from 'react';
import {
  Users,
  Plus,
  Phone,
  Mail,
  Calendar,
  CheckCircle2,
  ChevronRight,
  Filter,
  Search,
  MessageSquare,
  Sparkles
} from 'lucide-react';
import { DEMO_LEADS } from '@/lib/mock-data';
import { Lead, LeadStage } from '@/lib/types';

const STAGES: { id: LeadStage; label: string; color: string }[] = [
  { id: 'NEW', label: 'New Inquiries', color: 'bg-slate-100 text-slate-700 border-slate-300' },
  { id: 'CONTACTED', label: 'Contacted', color: 'bg-amber-50 text-amber-700 border-amber-300' },
  { id: 'TEST_RIDE_BOOKED', label: 'Test Ride Booked', color: 'bg-blue-50 text-blue-700 border-blue-300' },
  { id: 'QUOTATION_SHARED', label: 'Quote Shared', color: 'bg-purple-50 text-purple-700 border-purple-300' },
  { id: 'BOOKED', label: 'Booked / Won', color: 'bg-emerald-50 text-emerald-700 border-emerald-300' },
  { id: 'LOST', label: 'Lost / Dropped', color: 'bg-rose-50 text-rose-700 border-rose-300' },
];

export default function SalesCrmPage() {
  const [leads, setLeads] = useState<Lead[]>(DEMO_LEADS);
  const [selectedLead, setSelectedLead] = useState<Lead | null>(null);
  const [showAddModal, setShowAddModal] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  // New lead form state
  const [newCustomerName, setNewCustomerName] = useState('');
  const [newPhone, setNewPhone] = useState('');
  const [newModel, setNewModel] = useState('Yamaha YZF-R15 V4');
  const [newNotes, setNewNotes] = useState('');

  const handleAddLead = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newCustomerName || !newPhone) return;

    const newLead: Lead = {
      id: 'lead-' + (leads.length + 1),
      customerName: newCustomerName,
      phone: newPhone,
      preferredModel: newModel,
      stage: 'NEW',
      source: 'WALK_IN',
      notes: newNotes,
      assignedStaffName: 'Alex Pandian',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    setLeads([newLead, ...leads]);
    setShowAddModal(false);
    setNewCustomerName('');
    setNewPhone('');
    setNewNotes('');
  };

  const handleAdvanceStage = (leadId: string, nextStage: LeadStage) => {
    setLeads((prev) =>
      prev.map((l) => (l.id === leadId ? { ...l, stage: nextStage, updatedAt: new Date().toISOString() } : l))
    );
    if (selectedLead && selectedLead.id === leadId) {
      setSelectedLead((prev) => (prev ? { ...prev, stage: nextStage } : null));
    }
  };

  const filteredLeads = leads.filter(
    (l) =>
      l.customerName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      l.phone.includes(searchQuery) ||
      l.preferredModel.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 text-xs font-semibold uppercase tracking-wider text-blue-600">
            <span>Branch CRM</span>
            <span>•</span>
            <span>Lead Pipeline</span>
          </div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900 mt-1">
            Sales & Inquiries Board
          </h1>
          <p className="text-sm text-slate-500">
            Track customer conversations, test ride milestones, and booking conversions.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <div className="relative">
            <Search className="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search leads..."
              className="pl-9 pr-3 py-2 bg-white border border-slate-200 rounded-xl text-xs font-medium focus:outline-none focus:ring-2 focus:ring-blue-500/20 w-48 sm:w-60"
            />
          </div>

          <button
            onClick={() => setShowAddModal(true)}
            className="bg-blue-600 hover:bg-blue-500 text-white px-4 py-2 rounded-xl text-xs font-semibold shadow-sm transition-colors flex items-center gap-2"
          >
            <Plus className="w-4 h-4" />
            <span>Add Walk-In Lead</span>
          </button>
        </div>
      </div>

      {/* Kanban Pipeline Columns */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5 gap-4 overflow-x-auto pb-4">
        {STAGES.slice(0, 5).map((stage) => {
          const stageLeads = filteredLeads.filter((l) => l.stage === stage.id);
          return (
            <div key={stage.id} className="bg-slate-100/70 rounded-2xl p-3 flex flex-col min-w-[240px]">
              {/* Column Header */}
              <div className="flex items-center justify-between px-2 py-1.5 mb-2">
                <span className="text-xs font-bold text-slate-700 tracking-tight">
                  {stage.label}
                </span>
                <span className="text-[11px] font-bold bg-white text-slate-600 px-2 py-0.5 rounded-full border border-slate-200 shadow-2xs">
                  {stageLeads.length}
                </span>
              </div>

              {/* Cards Container */}
              <div className="space-y-2.5 flex-1 overflow-y-auto max-h-[calc(100vh-280px)]">
                {stageLeads.length === 0 ? (
                  <div className="h-28 rounded-xl border-2 border-dashed border-slate-200 flex items-center justify-center text-xs text-slate-400">
                    No leads in this stage
                  </div>
                ) : (
                  stageLeads.map((lead) => (
                    <div
                      key={lead.id}
                      onClick={() => setSelectedLead(lead)}
                      className="bg-white p-4 rounded-xl border border-slate-200 shadow-xs hover:border-blue-400 hover:shadow-sm cursor-pointer transition-all space-y-2.5"
                    >
                      <div className="flex items-start justify-between gap-2">
                        <h3 className="text-xs font-bold text-slate-900 leading-snug">
                          {lead.customerName}
                        </h3>
                        <span className="text-[9px] font-bold uppercase tracking-wider bg-slate-100 text-slate-600 px-1.5 py-0.5 rounded">
                          {lead.source}
                        </span>
                      </div>

                      <div className="text-[11px] text-blue-600 font-medium">
                        {lead.preferredModel}
                      </div>

                      <div className="text-[11px] font-mono text-slate-500 flex items-center gap-1">
                        <Phone className="w-3 h-3 text-slate-400" />
                        <span>{lead.phone}</span>
                      </div>

                      {lead.notes && (
                        <p className="text-[11px] text-slate-500 line-clamp-2 italic bg-slate-50 p-1.5 rounded">
                          "{lead.notes}"
                        </p>
                      )}

                      <div className="pt-2 border-t border-slate-100 flex items-center justify-between text-[10px] text-slate-400">
                        <span>Staff: {lead.assignedStaffName || 'Unassigned'}</span>
                        <ChevronRight className="w-3.5 h-3.5 text-slate-400" />
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>
          );
        })}
      </div>

      {/* Lead Details Drawer / Modal */}
      {selectedLead && (
        <div className="fixed inset-0 z-50 bg-slate-900/40 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-lg w-full p-6 shadow-xl border border-slate-200 space-y-5 animate-in fade-in zoom-in-95 duration-150">
            <div className="flex items-start justify-between">
              <div>
                <span className="text-[10px] font-bold uppercase tracking-wider bg-blue-50 text-blue-700 px-2 py-0.5 rounded">
                  Lead #{selectedLead.id}
                </span>
                <h2 className="text-xl font-bold text-slate-900 mt-1">
                  {selectedLead.customerName}
                </h2>
                <div className="text-xs text-slate-500 mt-0.5 flex items-center gap-3">
                  <span className="flex items-center gap-1 font-mono">
                    <Phone className="w-3 h-3" /> {selectedLead.phone}
                  </span>
                  <span>Source: {selectedLead.source}</span>
                </div>
              </div>
              <button
                onClick={() => setSelectedLead(null)}
                className="w-8 h-8 rounded-lg text-slate-400 hover:text-slate-600 hover:bg-slate-100 flex items-center justify-center"
              >
                ✕
              </button>
            </div>

            <div className="p-3.5 rounded-xl bg-slate-50 border border-slate-200/70 space-y-1">
              <div className="text-xs font-semibold text-slate-700">Vehicle of Interest</div>
              <div className="text-sm font-bold text-blue-600">
                {selectedLead.preferredModel}
              </div>
              {selectedLead.preferredVariant && (
                <div className="text-xs text-slate-500">
                  Variant: {selectedLead.preferredVariant} ({selectedLead.preferredColor || 'Standard'})
                </div>
              )}
            </div>

            {selectedLead.notes && (
              <div className="space-y-1">
                <div className="text-xs font-semibold text-slate-700">Staff Notes</div>
                <div className="text-xs text-slate-600 p-3 bg-amber-50/50 rounded-xl border border-amber-200/60">
                  {selectedLead.notes}
                </div>
              </div>
            )}

            {/* Advance Stage Control */}
            <div className="space-y-2 pt-2 border-t border-slate-100">
              <div className="text-xs font-semibold text-slate-700">Progress Stage</div>
              <div className="flex flex-wrap gap-2">
                {STAGES.map((s) => (
                  <button
                    key={s.id}
                    onClick={() => handleAdvanceStage(selectedLead.id, s.id)}
                    className={`text-xs px-3 py-1.5 rounded-lg font-semibold transition-all ${
                      selectedLead.stage === s.id
                        ? 'bg-blue-600 text-white shadow-xs'
                        : 'bg-slate-100 hover:bg-slate-200 text-slate-700'
                    }`}
                  >
                    {s.label}
                  </button>
                ))}
              </div>
            </div>

            <div className="flex justify-end pt-3">
              <button
                onClick={() => setSelectedLead(null)}
                className="bg-slate-900 hover:bg-slate-850 text-white px-4 py-2 rounded-xl text-xs font-semibold"
              >
                Done
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Add Lead Modal */}
      {showAddModal && (
        <div className="fixed inset-0 z-50 bg-slate-900/40 backdrop-blur-xs flex items-center justify-center p-4">
          <form
            onSubmit={handleAddLead}
            className="bg-white rounded-2xl max-w-md w-full p-6 shadow-xl border border-slate-200 space-y-4 animate-in fade-in zoom-in-95 duration-150"
          >
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-bold text-slate-900">Add Walk-In Lead</h2>
              <button
                type="button"
                onClick={() => setShowAddModal(false)}
                className="w-8 h-8 rounded-lg text-slate-400 hover:text-slate-600"
              >
                ✕
              </button>
            </div>

            <div>
              <label className="text-xs font-semibold text-slate-700">Customer Full Name *</label>
              <input
                type="text"
                required
                value={newCustomerName}
                onChange={(e) => setNewCustomerName(e.target.value)}
                placeholder="e.g. Anandha Kumar"
                className="w-full mt-1 px-3 py-2 border border-slate-200 rounded-xl text-xs focus:ring-2 focus:ring-blue-500/20 outline-none"
              />
            </div>

            <div>
              <label className="text-xs font-semibold text-slate-700">Mobile Phone Number *</label>
              <input
                type="tel"
                required
                value={newPhone}
                onChange={(e) => setNewPhone(e.target.value)}
                placeholder="+91 98420 XXXXX"
                className="w-full mt-1 px-3 py-2 border border-slate-200 rounded-xl text-xs focus:ring-2 focus:ring-blue-500/20 outline-none font-mono"
              />
            </div>

            <div>
              <label className="text-xs font-semibold text-slate-700">Vehicle Model</label>
              <select
                value={newModel}
                onChange={(e) => setNewModel(e.target.value)}
                className="w-full mt-1 px-3 py-2 border border-slate-200 rounded-xl text-xs focus:ring-2 focus:ring-blue-500/20 outline-none bg-white"
              >
                <option value="Yamaha YZF-R15 V4">Yamaha YZF-R15 V4</option>
                <option value="Yamaha RayZR 125 Fi Hybrid">Yamaha RayZR 125 Fi Hybrid</option>
                <option value="Yamaha MT-15 V2">Yamaha MT-15 V2</option>
                <option value="Yamaha Aerox 155">Yamaha Aerox 155</option>
                <option value="Yamaha FZ-S Fi V4">Yamaha FZ-S Fi V4</option>
              </select>
            </div>

            <div>
              <label className="text-xs font-semibold text-slate-700">Notes / Remarks</label>
              <textarea
                rows={3}
                value={newNotes}
                onChange={(e) => setNewNotes(e.target.value)}
                placeholder="Mention down payment readiness, exchange vehicle, or preferred test ride time..."
                className="w-full mt-1 px-3 py-2 border border-slate-200 rounded-xl text-xs focus:ring-2 focus:ring-blue-500/20 outline-none"
              />
            </div>

            <div className="flex justify-end gap-2 pt-2">
              <button
                type="button"
                onClick={() => setShowAddModal(false)}
                className="px-4 py-2 rounded-xl text-xs font-semibold text-slate-600 hover:bg-slate-100"
              >
                Cancel
              </button>
              <button
                type="submit"
                className="bg-blue-600 hover:bg-blue-500 text-white px-4 py-2 rounded-xl text-xs font-semibold shadow-xs"
              >
                Create Lead
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
}

