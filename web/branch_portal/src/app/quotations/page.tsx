'use client';

import React, { useState, useMemo } from 'react';
import {
  Calculator,
  Printer,
  Share2,
  FileText,
  Percent,
  CheckCircle2,
  ShieldCheck,
  ChevronDown
} from 'lucide-react';
import { DEMO_QUOTATIONS } from '@/lib/mock-data';
import { Quotation } from '@/lib/types';

interface VehicleOption {
  model: string;
  variant: string;
  color: string;
  exShowroom: number;
  rto: number;
  insurance: number;
  accessories: number;
  handling: number;
}

const VEHICLE_CATALOG: VehicleOption[] = [
  {
    model: 'Yamaha YZF-R15 V4',
    variant: 'Racing Blue Special',
    color: 'Racing Blue',
    exShowroom: 187000,
    rto: 23500,
    insurance: 12200,
    accessories: 4500,
    handling: 1800,
  },
  {
    model: 'Yamaha YZF-R15 V4',
    variant: 'Metallic Grey',
    color: 'Metallic Grey',
    exShowroom: 182000,
    rto: 22800,
    insurance: 11900,
    accessories: 4500,
    handling: 1800,
  },
  {
    model: 'Yamaha RayZR 125 Fi Hybrid',
    variant: 'Disc Deluxe',
    color: 'Matte Red',
    exShowroom: 91430,
    rto: 11200,
    insurance: 6800,
    accessories: 3200,
    handling: 1500,
  },
  {
    model: 'Yamaha MT-15 V2',
    variant: 'MotoGP Edition',
    color: 'Metallic Black',
    exShowroom: 172000,
    rto: 21500,
    insurance: 11200,
    accessories: 3900,
    handling: 1800,
  },
  {
    model: 'Yamaha Aerox 155',
    variant: 'Version S with Smart Key',
    color: 'Silver Star',
    exShowroom: 150000,
    rto: 18900,
    insurance: 10100,
    accessories: 4200,
    handling: 1800,
  },
];

export default function QuotationsPage() {
  const [selectedVehicle, setSelectedVehicle] = useState<VehicleOption>(VEHICLE_CATALOG[0]);
  const [customerName, setCustomerName] = useState('Karthik Subramanian');
  const [customerPhone, setCustomerPhone] = useState('+91 98420 54321');
  const [discount, setDiscount] = useState<number>(3000);

  // EMI Sliders
  const [downPayment, setDownPayment] = useState<number>(50000);
  const [interestRate, setInterestRate] = useState<number>(10.0);
  const [tenureYears, setTenureYears] = useState<number>(3); // 1 to 7

  const [generatedQuotations, setGeneratedQuotations] = useState<Quotation[]>(DEMO_QUOTATIONS);
  const [activeQuoteModal, setActiveQuoteModal] = useState<Quotation | null>(null);

  // Computed Pricing
  const onRoadPrice = useMemo(() => {
    return (
      selectedVehicle.exShowroom +
      selectedVehicle.rto +
      selectedVehicle.insurance +
      selectedVehicle.accessories +
      selectedVehicle.handling -
      discount
    );
  }, [selectedVehicle, discount]);

  // Computed EMI
  const loanPrincipal = Math.max(0, onRoadPrice - downPayment);
  const tenureMonths = tenureYears * 12;

  const monthlyEmi = useMemo(() => {
    if (loanPrincipal <= 0) return 0;
    const r = interestRate / 12 / 100;
    const n = tenureMonths;
    return Math.round((loanPrincipal * r * Math.pow(1 + r, n)) / (Math.pow(1 + r, n) - 1));
  }, [loanPrincipal, interestRate, tenureMonths]);

  const totalPayable = monthlyEmi * tenureMonths;
  const totalInterest = Math.max(0, totalPayable - loanPrincipal);

  const handleGenerateQuote = () => {
    const quoteNum = `QT-2026-0${840 + generatedQuotations.length + 1}`;
    const newQuote: Quotation = {
      id: 'q-' + Date.now(),
      quotationNumber: quoteNum,
      customerName,
      customerPhone,
      modelName: selectedVehicle.model,
      variantName: selectedVehicle.variant,
      colorName: selectedVehicle.color,
      exShowroom: selectedVehicle.exShowroom,
      rtoCharges: selectedVehicle.rto,
      insuranceCharges: selectedVehicle.insurance,
      accessoriesAmount: selectedVehicle.accessories,
      handlingCharges: selectedVehicle.handling,
      discountAmount: discount,
      onRoadPrice,
      downPayment,
      loanAmount: loanPrincipal,
      interestRate,
      tenureMonths,
      monthlyEmi,
      status: 'CONFIRMED',
      createdAt: new Date().toISOString(),
    };

    setGeneratedQuotations([newQuote, ...generatedQuotations]);
    setActiveQuoteModal(newQuote);
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 text-xs font-semibold uppercase tracking-wider text-blue-600">
            <span>Branch Finance</span>
            <span>•</span>
            <span>Dynamic Quotation Studio</span>
          </div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900 mt-1">
            Quotation & EMI Calculator
          </h1>
          <p className="text-sm text-slate-500">
            Generate itemized on-road estimates and tailor monthly EMI financing plans.
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column: Vehicle & Breakdown */}
        <div className="lg:col-span-2 space-y-6">
          {/* Vehicle Selection Card */}
          <div className="bg-white p-6 rounded-2xl border border-slate-200/80 shadow-xs space-y-4">
            <h2 className="text-base font-bold text-slate-900 flex items-center gap-2">
              <span className="w-6 h-6 rounded-full bg-blue-600 text-white text-xs flex items-center justify-center font-bold">1</span>
              Select Model & Variant
            </h2>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="text-xs font-semibold text-slate-700">Vehicle</label>
                <select
                  value={selectedVehicle.model + ' - ' + selectedVehicle.variant}
                  onChange={(e) => {
                    const found = VEHICLE_CATALOG.find(
                      (v) => v.model + ' - ' + v.variant === e.target.value
                    );
                    if (found) setSelectedVehicle(found);
                  }}
                  className="w-full mt-1.5 px-3 py-2.5 border border-slate-200 rounded-xl text-xs font-medium focus:ring-2 focus:ring-blue-500/20 outline-none bg-white"
                >
                  {VEHICLE_CATALOG.map((v, i) => (
                    <option key={i} value={v.model + ' - ' + v.variant}>
                      {v.model} ({v.variant} - {v.color})
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="text-xs font-semibold text-slate-700">Customer Full Name</label>
                <input
                  type="text"
                  value={customerName}
                  onChange={(e) => setCustomerName(e.target.value)}
                  className="w-full mt-1.5 px-3 py-2.5 border border-slate-200 rounded-xl text-xs font-medium focus:ring-2 focus:ring-blue-500/20 outline-none"
                />
              </div>
            </div>

            {/* Price Breakdown Table */}
            <div className="rounded-xl border border-slate-200 bg-slate-50/70 p-4 space-y-2.5">
              <div className="flex justify-between text-xs text-slate-600">
                <span>Ex-Showroom Price</span>
                <span className="font-semibold text-slate-900 font-mono">₹{selectedVehicle.exShowroom.toLocaleString('en-IN')}</span>
              </div>
              <div className="flex justify-between text-xs text-slate-600">
                <span>RTO Registration & Road Tax</span>
                <span className="font-semibold text-slate-900 font-mono">₹{selectedVehicle.rto.toLocaleString('en-IN')}</span>
              </div>
              <div className="flex justify-between text-xs text-slate-600">
                <span>Comprehensive Insurance (1+4 Yr)</span>
                <span className="font-semibold text-slate-900 font-mono">₹{selectedVehicle.insurance.toLocaleString('en-IN')}</span>
              </div>
              <div className="flex justify-between text-xs text-slate-600">
                <span>Essential Accessories Kit</span>
                <span className="font-semibold text-slate-900 font-mono">₹{selectedVehicle.accessories.toLocaleString('en-IN')}</span>
              </div>
              <div className="flex justify-between text-xs text-slate-600">
                <span>Handling & Logistics</span>
                <span className="font-semibold text-slate-900 font-mono">₹{selectedVehicle.handling.toLocaleString('en-IN')}</span>
              </div>
              <div className="flex justify-between text-xs text-emerald-600 pt-2 border-t border-slate-200">
                <span>Dealership Promotional Discount</span>
                <span className="font-semibold font-mono">- ₹{discount.toLocaleString('en-IN')}</span>
              </div>
              <div className="flex justify-between text-sm font-bold text-slate-900 pt-2 border-t-2 border-slate-300">
                <span>Final On-Road Estimate</span>
                <span className="text-blue-600 font-extrabold font-mono text-base">
                  ₹{onRoadPrice.toLocaleString('en-IN')}
                </span>
              </div>
            </div>
          </div>

          {/* EMI Studio Sliders matching the user reference */}
          <div className="bg-white p-6 rounded-2xl border border-slate-200/80 shadow-xs space-y-6">
            <h2 className="text-base font-bold text-slate-900 flex items-center gap-2">
              <span className="w-6 h-6 rounded-full bg-blue-600 text-white text-xs flex items-center justify-center font-bold">2</span>
              Interactive EMI Financing Studio
            </h2>

            {/* Slider 1: Loan Amount */}
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-slate-700">Loan Principal</span>
                <span className="bg-[#1B365D] text-white text-xs font-bold px-3 py-1 rounded-lg font-mono">
                  ₹ {(loanPrincipal / 1000).toFixed(0)} Thousands
                </span>
              </div>
              <input
                type="range"
                min={10000}
                max={onRoadPrice}
                step={5000}
                value={loanPrincipal}
                onChange={(e) => setDownPayment(Math.max(0, onRoadPrice - Number(e.target.value)))}
                className="w-full accent-blue-600 cursor-pointer"
              />
              <div className="flex justify-between text-[11px] text-slate-400">
                <span>₹10 Thousand</span>
                <span>₹{(onRoadPrice / 100000).toFixed(2)} Lakh</span>
              </div>
            </div>

            {/* Slider 2: Rate of interest */}
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-slate-700">Rate of interest</span>
                <span className="bg-[#1B365D] text-white text-xs font-bold px-3 py-1 rounded-lg font-mono">
                  {interestRate.toFixed(1)} Percentage %
                </span>
              </div>
              <input
                type="range"
                min={7}
                max={22}
                step={0.5}
                value={interestRate}
                onChange={(e) => setInterestRate(Number(e.target.value))}
                className="w-full accent-blue-600 cursor-pointer"
              />
              <div className="flex justify-between text-[11px] text-slate-400">
                <span>7%</span>
                <span>22%</span>
              </div>
            </div>

            {/* Slider 3: Tenure */}
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-slate-700">Tenure</span>
                <span className="bg-[#1B365D] text-white text-xs font-bold px-3 py-1 rounded-lg font-mono">
                  {tenureYears} Years ({tenureMonths} mo)
                </span>
              </div>
              <input
                type="range"
                min={1}
                max={7}
                step={1}
                value={tenureYears}
                onChange={(e) => setTenureYears(Number(e.target.value))}
                className="w-full accent-blue-600 cursor-pointer"
              />
              <div className="flex justify-between text-[11px] text-slate-400">
                <span>1 Year</span>
                <span>7 Years</span>
              </div>
            </div>
          </div>
        </div>

        {/* Right Column: Live EMI Output Card */}
        <div className="space-y-6">
          <div className="bg-gradient-to-br from-slate-900 to-blue-950 text-white p-6 rounded-2xl border border-slate-800 shadow-lg space-y-6 sticky top-20">
            <div>
              <span className="text-[10px] font-bold uppercase tracking-wider text-blue-400">
                Finance Calculation
              </span>
              <div className="text-xs text-slate-300 mt-1">Your Estimated Monthly EMI</div>
              <div className="text-4xl font-extrabold text-white mt-1 font-mono tracking-tight">
                ₹{monthlyEmi.toLocaleString('en-IN')}
                <span className="text-sm font-normal text-slate-400 ml-1">/mo</span>
              </div>
            </div>

            <div className="space-y-2.5 pt-4 border-t border-slate-800 text-xs text-slate-300">
              <div className="flex justify-between">
                <span>Down Payment</span>
                <span className="font-semibold text-white font-mono">₹{downPayment.toLocaleString('en-IN')}</span>
              </div>
              <div className="flex justify-between">
                <span>Loan Principal</span>
                <span className="font-semibold text-white font-mono">₹{loanPrincipal.toLocaleString('en-IN')}</span>
              </div>
              <div className="flex justify-between">
                <span>Total Interest Payable</span>
                <span className="font-semibold text-amber-400 font-mono">₹{totalInterest.toLocaleString('en-IN')}</span>
              </div>
              <div className="flex justify-between pt-2 border-t border-slate-800 text-sm font-bold text-white">
                <span>Total Repayment</span>
                <span className="font-mono">₹{totalPayable.toLocaleString('en-IN')}</span>
              </div>
            </div>

            <button
              onClick={handleGenerateQuote}
              className="w-full bg-blue-600 hover:bg-blue-500 text-white font-bold py-3 rounded-xl text-xs shadow-md transition-colors flex items-center justify-center gap-2"
            >
              <FileText className="w-4 h-4" />
              <span>Issue Official Quotation</span>
            </button>
          </div>

          {/* Recent Quotes List */}
          <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs space-y-3">
            <h3 className="text-xs font-bold uppercase tracking-wider text-slate-500">
              Recent Quotations Issued
            </h3>
            <div className="space-y-2">
              {generatedQuotations.map((q) => (
                <div
                  key={q.id}
                  onClick={() => setActiveQuoteModal(q)}
                  className="p-3 rounded-xl border border-slate-100 hover:border-blue-300 hover:bg-blue-50/30 cursor-pointer transition-all flex items-center justify-between text-xs"
                >
                  <div>
                    <div className="font-mono font-bold text-blue-600">{q.quotationNumber}</div>
                    <div className="font-semibold text-slate-800">{q.customerName}</div>
                    <div className="text-[11px] text-slate-400">{q.modelName}</div>
                  </div>
                  <div className="text-right">
                    <div className="font-bold text-slate-900 font-mono">₹{q.onRoadPrice.toLocaleString('en-IN')}</div>
                    <div className="text-[10px] text-emerald-600 font-medium">EMI: ₹{q.monthlyEmi}/mo</div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Generated Quote Modal */}
      {activeQuoteModal && (
        <div className="fixed inset-0 z-50 bg-slate-900/40 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-lg w-full p-6 shadow-xl border border-slate-200 space-y-5 animate-in fade-in zoom-in-95 duration-150">
            <div className="flex items-start justify-between border-b border-slate-100 pb-4">
              <div>
                <span className="text-[10px] font-bold uppercase tracking-wider bg-emerald-50 text-emerald-700 px-2 py-0.5 rounded">
                  Official Quotation
                </span>
                <h2 className="text-xl font-bold font-mono text-slate-900 mt-1">
                  {activeQuoteModal.quotationNumber}
                </h2>
                <div className="text-xs text-slate-500">
                  Customer: <span className="font-semibold text-slate-800">{activeQuoteModal.customerName}</span> ({activeQuoteModal.customerPhone})
                </div>
              </div>
              <button
                onClick={() => setActiveQuoteModal(null)}
                className="w-8 h-8 rounded-lg text-slate-400 hover:text-slate-600 flex items-center justify-center"
              >
                ✕
              </button>
            </div>

            <div className="space-y-2 text-xs">
              <div className="p-3 bg-slate-50 rounded-xl space-y-1">
                <div className="font-bold text-slate-800">{activeQuoteModal.modelName}</div>
                <div className="text-slate-500">
                  {activeQuoteModal.variantName} • Color: {activeQuoteModal.colorName}
                </div>
              </div>

              <div className="divide-y divide-slate-100 py-1">
                <div className="py-1.5 flex justify-between">
                  <span>Ex-Showroom Price</span>
                  <span className="font-mono">₹{activeQuoteModal.exShowroom.toLocaleString('en-IN')}</span>
                </div>
                <div className="py-1.5 flex justify-between">
                  <span>RTO + Insurance + Accessories</span>
                  <span className="font-mono">
                    ₹{(activeQuoteModal.rtoCharges + activeQuoteModal.insuranceCharges + activeQuoteModal.accessoriesAmount).toLocaleString('en-IN')}
                  </span>
                </div>
                <div className="py-1.5 flex justify-between text-emerald-600">
                  <span>Discount Applied</span>
                  <span className="font-mono">- ₹{activeQuoteModal.discountAmount.toLocaleString('en-IN')}</span>
                </div>
                <div className="py-2 flex justify-between font-bold text-slate-900 text-sm">
                  <span>Total On-Road Value</span>
                  <span className="font-mono text-blue-600">₹{activeQuoteModal.onRoadPrice.toLocaleString('en-IN')}</span>
                </div>
              </div>

              <div className="p-3 bg-blue-50/50 rounded-xl border border-blue-200/60 flex justify-between items-center">
                <div>
                  <div className="font-bold text-blue-900">Estimated EMI</div>
                  <div className="text-[11px] text-blue-700">
                    ₹{activeQuoteModal.monthlyEmi}/mo for {activeQuoteModal.tenureMonths} months @ {activeQuoteModal.interestRate}% APR
                  </div>
                </div>
                <div className="text-right font-mono font-bold text-blue-900 text-sm">
                  ₹{activeQuoteModal.monthlyEmi}/mo
                </div>
              </div>
            </div>

            <div className="flex justify-end gap-2 pt-2 border-t border-slate-100">
              <button
                onClick={() => window.print()}
                className="bg-slate-100 hover:bg-slate-200 text-slate-700 px-4 py-2 rounded-xl text-xs font-semibold flex items-center gap-1.5"
              >
                <Printer className="w-3.5 h-3.5" />
                <span>Print Quotation</span>
              </button>
              <button
                onClick={() => setActiveQuoteModal(null)}
                className="bg-blue-600 hover:bg-blue-500 text-white px-4 py-2 rounded-xl text-xs font-semibold"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

