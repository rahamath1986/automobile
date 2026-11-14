'use client';

import React, { useState } from 'react';
import { 
  Layers, 
  Search, 
  Plus, 
  RefreshCw, 
  Check, 
  Fuel, 
  Gauge, 
  Zap, 
  Building2, 
  Sparkles,
  ExternalLink,
  ChevronRight
} from 'lucide-react';
import { OEM_BRANDS, GLOBAL_VEHICLE_MODELS } from '@/lib/mock-data';
import { GlobalVehicleModel, OemBrand } from '@/lib/types';

export default function OemCatalogPage() {
  const [selectedOem, setSelectedOem] = useState<string>('ALL');
  const [categoryFilter, setCategoryFilter] = useState<string>('ALL');
  const [searchQuery, setSearchQuery] = useState('');
  const [syncSuccess, setSyncSuccess] = useState<string | null>(null);
  const [models, setModels] = useState<GlobalVehicleModel[]>(GLOBAL_VEHICLE_MODELS);

  const filteredModels = models.filter((m) => {
    const matchOem = selectedOem === 'ALL' || m.oemCode === selectedOem;
    const matchCat = categoryFilter === 'ALL' || m.category === categoryFilter;
    const matchSearch =
      m.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      m.oemName.toLowerCase().includes(searchQuery.toLowerCase());
    return matchOem && matchCat && matchSearch;
  });

  const handleSyncToTenants = (modelName: string) => {
    setSyncSuccess(`Triggered global catalog push for "${modelName}" to all active dealer tenant catalogs!`);
    setTimeout(() => setSyncSuccess(null), 4000);
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white tracking-tight flex items-center gap-2">
            <Layers className="w-6 h-6 text-purple-400" />
            Global OEM Master Vehicle Catalog
          </h1>
          <p className="text-sm text-slate-400 mt-1">
            Central repository of OEM 2-wheelers, multi-angle imagery, engine specs, and baseline ex-showroom pricing synchronized to tenant dealerships.
          </p>
        </div>

        <button
          onClick={() => handleSyncToTenants('All OEM Lineup')}
          className="flex items-center gap-2 bg-gradient-to-r from-purple-600 to-indigo-600 hover:from-purple-500 hover:to-indigo-500 text-white font-semibold px-4 py-2.5 rounded-xl shadow-lg shadow-purple-600/20 text-sm transition-all"
        >
          <RefreshCw className="w-4 h-4" />
          Sync All to Dealers
        </button>
      </div>

      {syncSuccess && (
        <div className="p-4 rounded-xl bg-emerald-500/10 border border-emerald-500/30 text-emerald-300 text-sm flex items-center gap-2.5 animate-fadeIn">
          <Check className="w-4 h-4 text-emerald-400" />
          {syncSuccess}
        </div>
      )}

      {/* OEM Franchise Brand Selector Banner */}
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3">
        <button
          onClick={() => setSelectedOem('ALL')}
          className={`p-3 rounded-xl border text-left transition-all ${
            selectedOem === 'ALL'
              ? 'bg-purple-600/20 border-purple-500 text-white shadow-md shadow-purple-600/10'
              : 'bg-slate-900 border-slate-800 text-slate-400 hover:border-slate-700 hover:text-white'
          }`}
        >
          <div className="text-xs font-semibold uppercase tracking-wider text-purple-400">All Brands</div>
          <div className="text-lg font-bold text-white mt-0.5">{models.length} Models</div>
          <div className="text-[11px] text-slate-400">8 Franchises</div>
        </button>

        {OEM_BRANDS.map((b) => (
          <button
            key={b.id}
            onClick={() => setSelectedOem(b.code)}
            className={`p-3 rounded-xl border text-left transition-all ${
              selectedOem === b.code
                ? 'bg-purple-600/20 border-purple-500 text-white shadow-md shadow-purple-600/10'
                : 'bg-slate-900 border-slate-800 text-slate-400 hover:border-slate-700 hover:text-white'
            }`}
          >
            <div className="text-xs font-semibold uppercase tracking-wider text-slate-400">{b.name}</div>
            <div className="text-lg font-bold text-white mt-0.5">{b.totalModels} Models</div>
            <div className="text-[11px] text-slate-400">{b.franchisedTenantsCount} Dealerships</div>
          </button>
        ))}
      </div>

      {/* Filter and Search Bar */}
      <div className="flex flex-col sm:flex-row gap-3 items-center justify-between bg-slate-900 p-4 rounded-xl border border-slate-800">
        <div className="relative w-full sm:w-80">
          <Search className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
          <input
            type="text"
            placeholder="Search by model or brand..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full bg-slate-950 border border-slate-800 rounded-lg pl-10 pr-4 py-2 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-purple-500"
          />
        </div>

        <div className="flex items-center gap-2 w-full sm:w-auto overflow-x-auto pb-1 sm:pb-0">
          {['ALL', 'Motorcycle', 'Scooter', 'ElectricVehicle'].map((cat) => (
            <button
              key={cat}
              onClick={() => setCategoryFilter(cat)}
              className={`px-3 py-1.5 rounded-lg text-xs font-semibold whitespace-nowrap transition-all ${
                categoryFilter === cat
                  ? 'bg-purple-600 text-white shadow'
                  : 'bg-slate-950 text-slate-400 hover:text-white border border-slate-800'
              }`}
            >
              {cat === 'ALL' ? 'All Types' : cat === 'ElectricVehicle' ? 'Electric EV' : cat}
            </button>
          ))}
        </div>
      </div>

      {/* Model Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {filteredModels.map((m) => (
          <div
            key={m.id}
            className="bg-slate-900 rounded-2xl border border-slate-800 overflow-hidden hover:border-slate-700 transition-all flex flex-col group"
          >
            {/* Image Viewport */}
            <div className="h-44 bg-gradient-to-b from-slate-950 to-slate-900 p-4 flex items-center justify-center relative overflow-hidden">
              <span className="absolute top-3 left-3 text-[11px] font-bold px-2 py-0.5 rounded-md bg-slate-900/90 text-purple-300 border border-purple-500/30">
                {m.oemName}
              </span>
              <span className="absolute top-3 right-3 text-[11px] font-semibold px-2 py-0.5 rounded-md bg-slate-800/90 text-slate-300 border border-slate-700">
                {m.fuelType}
              </span>
              <img
                src={m.imageUrl}
                alt={m.name}
                className="max-h-36 max-w-[85%] object-contain group-hover:scale-105 transition-transform duration-300 drop-shadow-xl"
                onError={(e) => {
                  (e.target as HTMLImageElement).src = 'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?w=600';
                }}
              />
            </div>

            {/* Content Details */}
            <div className="p-5 flex-1 flex flex-col">
              <div className="flex items-start justify-between gap-2">
                <div>
                  <h3 className="text-lg font-bold text-white group-hover:text-purple-300 transition-colors">
                    {m.name}
                  </h3>
                  <div className="text-xs text-slate-400 font-mono mt-0.5">{m.code}</div>
                </div>
                <div className="text-right">
                  <div className="text-base font-extrabold text-white">
                    ₹{(m.baseExShowroomPrice / 100000).toFixed(2)} Lakh
                  </div>
                  <div className="text-[10px] text-slate-400 uppercase font-medium">Ex-Showroom Base</div>
                </div>
              </div>

              {/* Engine / Specs Pill Row */}
              <div className="grid grid-cols-3 gap-2 my-4 pt-3 border-t border-slate-800/80">
                <div className="bg-slate-950/70 p-2 rounded-lg border border-slate-800 text-center">
                  <div className="text-[10px] text-slate-400 uppercase font-semibold">Engine</div>
                  <div className="text-xs font-bold text-slate-200 mt-0.5">
                    {m.engineCc ? `${m.engineCc} cc` : 'EV Motor'}
                  </div>
                </div>
                <div className="bg-slate-950/70 p-2 rounded-lg border border-slate-800 text-center">
                  <div className="text-[10px] text-slate-400 uppercase font-semibold">Power</div>
                  <div className="text-xs font-bold text-slate-200 mt-0.5">{m.powerBhp || 'N/A'}</div>
                </div>
                <div className="bg-slate-950/70 p-2 rounded-lg border border-slate-800 text-center">
                  <div className="text-[10px] text-slate-400 uppercase font-semibold">Mileage</div>
                  <div className="text-xs font-bold text-slate-200 mt-0.5">
                    {m.mileageKmpl ? `${m.mileageKmpl} km/l` : '100 km/chg'}
                  </div>
                </div>
              </div>

              {/* Synced Dealers Footer */}
              <div className="mt-auto pt-3 border-t border-slate-800/80 flex items-center justify-between text-xs">
                <span className="text-slate-400 flex items-center gap-1.5">
                  <Building2 className="w-3.5 h-3.5 text-purple-400" />
                  Synced to <strong className="text-slate-200">{m.syncedTenantsCount}</strong> dealers
                </span>

                <button
                  onClick={() => handleSyncToTenants(m.name)}
                  className="flex items-center gap-1 text-purple-400 hover:text-purple-300 font-semibold transition-colors"
                >
                  <RefreshCw className="w-3 h-3" />
                  Push Update
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
