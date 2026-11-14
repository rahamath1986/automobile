'use client';

import React, { useState } from 'react';
import {
  Receipt,
  Plus,
  Search,
  CheckCircle2,
  Printer,
  CreditCard,
  Banknote,
  Smartphone,
  Building
} from 'lucide-react';
import { DEMO_PAYMENTS } from '@/lib/mock-data';
import { PaymentReceipt, PaymentMethod } from '@/lib/types';

export default function BillingCashierPage() {
  const [payments, setPayments] = useState<PaymentReceipt[]>(DEMO_PAYMENTS);
  const [showNewModal, setShowNewModal] = useState(false);
  const [activeReceiptModal, setActiveReceiptModal] = useState<PaymentReceipt | null>(null);

  // New payment form state
  const [customerName, setCustomerName] = useState('');
  const [amount, setAmount] = useState<number>(5000);
  const [paymentMethod, setPaymentMethod] = useState<PaymentMethod>('UPI');
  const [referenceType, setReferenceType] = useState<'VEHICLE_BOOKING' | 'SERVICE_INVOICE'>('VEHICLE_BOOKING');
  const [referenceId, setReferenceId] = useState('');
  const [transactionRef, setTransactionRef] = useState('');
  const [notes, setNotes] = useState('');

  const totalCollected = payments.reduce((sum, p) => sum + p.amount, 0);
  const totalUpi = payments.filter((p) => p.paymentMethod === 'UPI').reduce((sum, p) => sum + p.amount, 0);
  const totalCash = payments.filter((p) => p.paymentMethod === 'CASH').reduce((sum, p) => sum + p.amount, 0);
  const totalFinance = payments.filter((p) => p.paymentMethod === 'FINANCE_DISBURSEMENT').reduce((sum, p) => sum + p.amount, 0);

  const handleRecordPayment = (e: React.FormEvent) => {
    e.preventDefault();
    if (!customerName || amount <= 0) return;

    const receiptNum = `RCP-2026-0${910 + payments.length + 1}`;
    const newReceipt: PaymentReceipt = {
      id: 'rcpt-' + Date.now(),
      receiptNumber: receiptNum,
      customerName,
      referenceType,
      referenceId: referenceId || 'REF-' + Date.now().toString().slice(-4),
      amount,
      paymentMethod,
      transactionRef: transactionRef || undefined,
      collectedBy: 'Mohan Kumar',
      createdAt: new Date().toISOString(),
      notes: notes || undefined,
    };

    setPayments([newReceipt, ...payments]);
    setShowNewModal(false);
    setActiveReceiptModal(newReceipt);
    setCustomerName('');
    setReferenceId('');
    setTransactionRef('');
    setNotes('');
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 text-xs font-semibold uppercase tracking-wider text-blue-600">
            <span>Branch Finance</span>
            <span>•</span>
            <span>Cashier Register & Settlement</span>
          </div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900 mt-1">
            Cashier & Payment Receipts
          </h1>
          <p className="text-sm text-slate-500">
            Record customer token deposits, balance settlements, workshop invoices, and financier disbursements.
          </p>
        </div>

        <button
          onClick={() => setShowNewModal(true)}
          className="bg-blue-600 hover:bg-blue-500 text-white px-4 py-2 rounded-xl text-xs font-semibold shadow-sm transition-colors flex items-center gap-2 self-start sm:self-auto"
        >
          <Plus className="w-4 h-4" />
          <span>Collect Payment</span>
        </button>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-4 gap-4">
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs">
          <div className="text-xs font-semibold uppercase tracking-wider text-slate-500">
            Total Reconciled Today
          </div>
          <div className="text-2xl font-bold text-slate-900 mt-2 font-mono">
            ₹{totalCollected.toLocaleString('en-IN')}
          </div>
          <div className="text-xs text-emerald-600 mt-1 font-medium flex items-center gap-1">
            <CheckCircle2 className="w-3.5 h-3.5" />
            <span>Shift balanced</span>
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs">
          <div className="text-xs font-semibold uppercase tracking-wider text-slate-500 flex items-center justify-between">
            <span>UPI QR / Digital</span>
            <Smartphone className="w-4 h-4 text-blue-600" />
          </div>
          <div className="text-xl font-bold text-slate-900 mt-2 font-mono">
            ₹{totalUpi.toLocaleString('en-IN')}
          </div>
          <div className="text-xs text-slate-400 mt-1">Direct Bank Credit</div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs">
          <div className="text-xs font-semibold uppercase tracking-wider text-slate-500 flex items-center justify-between">
            <span>Physical Cash In Till</span>
            <Banknote className="w-4 h-4 text-emerald-600" />
          </div>
          <div className="text-xl font-bold text-slate-900 mt-2 font-mono">
            ₹{totalCash.toLocaleString('en-IN')}
          </div>
          <div className="text-xs text-slate-400 mt-1">Ready for vault lock</div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs">
          <div className="text-xs font-semibold uppercase tracking-wider text-slate-500 flex items-center justify-between">
            <span>Financier Disbursals</span>
            <Building className="w-4 h-4 text-purple-600" />
          </div>
          <div className="text-xl font-bold text-slate-900 mt-2 font-mono">
            ₹{totalFinance.toLocaleString('en-IN')}
          </div>
          <div className="text-xs text-slate-400 mt-1">TVS Credit, HDFC, L&T</div>
        </div>
      </div>

      {/* Receipts Table */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-xs overflow-hidden">
        <div className="px-6 py-4 border-b border-slate-200 flex items-center justify-between">
          <h2 className="text-sm font-bold text-slate-900">Payment Collection Ledger</h2>
          <span className="text-xs text-slate-500 font-mono">{payments.length} Transactions</span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-slate-50 border-b border-slate-200 text-slate-600 font-semibold uppercase tracking-wider text-[11px]">
              <tr>
                <th className="px-5 py-3.5">Receipt #</th>
                <th className="px-5 py-3.5">Customer</th>
                <th className="px-5 py-3.5">Type & Reference</th>
                <th className="px-5 py-3.5">Payment Method</th>
                <th className="px-5 py-3.5">Txn ID / Financier</th>
                <th className="px-5 py-3.5 text-right">Amount Paid</th>
                <th className="px-5 py-3.5 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {payments.map((p) => (
                <tr key={p.id} className="hover:bg-slate-50/70 transition-colors">
                  <td className="px-5 py-3.5 font-mono font-bold text-blue-600">
                    {p.receiptNumber}
                  </td>
                  <td className="px-5 py-3.5 font-semibold text-slate-800">
                    {p.customerName}
                  </td>
                  <td className="px-5 py-3.5">
                    <span className="text-[10px] font-bold uppercase tracking-wider bg-slate-100 text-slate-700 px-2 py-0.5 rounded">
                      {p.referenceType.replace(/_/g, ' ')}
                    </span>
                    <span className="font-mono text-slate-500 ml-1.5 text-[11px]">{p.referenceId}</span>
                  </td>
                  <td className="px-5 py-3.5 font-medium text-slate-700">
                    {p.paymentMethod.replace(/_/g, ' ')}
                  </td>
                  <td className="px-5 py-3.5 font-mono text-slate-500 text-[11px]">
                    {p.financierName || p.transactionRef || '—'}
                  </td>
                  <td className="px-5 py-3.5 text-right font-mono font-bold text-slate-900 text-sm">
                    ₹{p.amount.toLocaleString('en-IN')}
                  </td>
                  <td className="px-5 py-3.5 text-right">
                    <button
                      onClick={() => setActiveReceiptModal(p)}
                      className="text-blue-600 hover:text-blue-700 font-semibold inline-flex items-center gap-1"
                    >
                      <Printer className="w-3.5 h-3.5" />
                      <span>Receipt</span>
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Collect Payment Modal */}
      {showNewModal && (
        <div className="fixed inset-0 z-50 bg-slate-900/40 backdrop-blur-xs flex items-center justify-center p-4">
          <form
            onSubmit={handleRecordPayment}
            className="bg-white rounded-2xl max-w-md w-full p-6 shadow-xl border border-slate-200 space-y-4 animate-in fade-in zoom-in-95 duration-150"
          >
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <h2 className="text-lg font-bold text-slate-900">Record Payment Tender</h2>
              <button
                type="button"
                onClick={() => setShowNewModal(false)}
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
                value={customerName}
                onChange={(e) => setCustomerName(e.target.value)}
                placeholder="e.g. Anandha Kumar"
                className="w-full mt-1 px-3 py-2 border border-slate-200 rounded-xl text-xs focus:ring-2 focus:ring-blue-500/20 outline-none"
              />
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-xs font-semibold text-slate-700">Payment Tender</label>
                <select
                  value={paymentMethod}
                  onChange={(e) => setPaymentMethod(e.target.value as PaymentMethod)}
                  className="w-full mt-1 px-3 py-2 border border-slate-200 rounded-xl text-xs bg-white outline-none"
                >
                  <option value="UPI">UPI / QR Code</option>
                  <option value="CASH">Physical Cash</option>
                  <option value="CREDIT_DEBIT_CARD">Debit / Credit Card</option>
                  <option value="NET_BANKING">Bank NEFT / RTGS</option>
                  <option value="FINANCE_DISBURSEMENT">Finance Loan Disbursal</option>
                </select>
              </div>

              <div>
                <label className="text-xs font-semibold text-slate-700">Amount (₹) *</label>
                <input
                  type="number"
                  required
                  min={1}
                  value={amount}
                  onChange={(e) => setAmount(Number(e.target.value))}
                  className="w-full mt-1 px-3 py-2 border border-slate-200 rounded-xl text-xs font-mono font-bold text-slate-900 outline-none"
                />
              </div>
            </div>

            <div>
              <label className="text-xs font-semibold text-slate-700">Reference Type</label>
              <select
                value={referenceType}
                onChange={(e) => setReferenceType(e.target.value as any)}
                className="w-full mt-1 px-3 py-2 border border-slate-200 rounded-xl text-xs bg-white outline-none"
              >
                <option value="VEHICLE_BOOKING">Vehicle Booking Deposit / Balance</option>
                <option value="SERVICE_INVOICE">Service Workshop Invoice</option>
              </select>
            </div>

            <div>
              <label className="text-xs font-semibold text-slate-700">Booking / Job Card Number</label>
              <input
                type="text"
                value={referenceId}
                onChange={(e) => setReferenceId(e.target.value)}
                placeholder="e.g. BK-9941 or JC-2026-0412"
                className="w-full mt-1 px-3 py-2 border border-slate-200 rounded-xl text-xs font-mono outline-none"
              />
            </div>

            <div>
              <label className="text-xs font-semibold text-slate-700">Bank Txn ID / UPI Ref</label>
              <input
                type="text"
                value={transactionRef}
                onChange={(e) => setTransactionRef(e.target.value)}
                placeholder="e.g. UPI/432098114921 or Chq #009121"
                className="w-full mt-1 px-3 py-2 border border-slate-200 rounded-xl text-xs font-mono outline-none"
              />
            </div>

            <div className="flex justify-end gap-2 pt-2 border-t border-slate-100">
              <button
                type="button"
                onClick={() => setShowNewModal(false)}
                className="px-4 py-2 rounded-xl text-xs font-semibold text-slate-600 hover:bg-slate-100"
              >
                Cancel
              </button>
              <button
                type="submit"
                className="bg-blue-600 hover:bg-blue-500 text-white px-4 py-2 rounded-xl text-xs font-semibold shadow-xs"
              >
                Issue Receipt
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Printable Receipt Modal */}
      {activeReceiptModal && (
        <div className="fixed inset-0 z-50 bg-slate-900/40 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-sm w-full p-6 shadow-xl border border-slate-200 space-y-4 animate-in fade-in zoom-in-95 duration-150">
            <div className="text-center pb-3 border-b border-dashed border-slate-300">
              <div className="font-extrabold text-sm tracking-wide text-slate-900">ALAGENDRA AUTOMOBILES</div>
              <div className="text-[11px] text-slate-500">Authorised Yamaha Dealership</div>
              <div className="text-[10px] text-slate-400">Madurai Central Flagship • GSTIN: 33AAAAA0000A1Z5</div>
            </div>

            <div className="space-y-1.5 text-xs">
              <div className="flex justify-between">
                <span className="text-slate-500">Receipt No:</span>
                <span className="font-mono font-bold text-slate-800">{activeReceiptModal.receiptNumber}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">Date & Time:</span>
                <span className="font-mono text-slate-700">{new Date(activeReceiptModal.createdAt).toLocaleDateString()}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">Customer:</span>
                <span className="font-bold text-slate-900">{activeReceiptModal.customerName}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">Against Ref:</span>
                <span className="font-mono text-blue-600">{activeReceiptModal.referenceId}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">Tender:</span>
                <span className="font-medium text-slate-700">{activeReceiptModal.paymentMethod.replace(/_/g, ' ')}</span>
              </div>
              <div className="pt-2 border-t border-dashed border-slate-300 flex justify-between items-center text-sm font-bold text-slate-900">
                <span>Amount Received:</span>
                <span className="font-mono text-base text-blue-600">₹{activeReceiptModal.amount.toLocaleString('en-IN')}</span>
              </div>
            </div>

            <div className="text-[10px] text-center text-slate-400 italic pt-2">
              Payment verified & cashier signed by {activeReceiptModal.collectedBy}
            </div>

            <div className="flex justify-end gap-2 pt-2 border-t border-slate-100">
              <button
                onClick={() => window.print()}
                className="bg-slate-100 hover:bg-slate-200 text-slate-700 px-3 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1"
              >
                <Printer className="w-3.5 h-3.5" />
                <span>Print</span>
              </button>
              <button
                onClick={() => setActiveReceiptModal(null)}
                className="bg-blue-600 hover:bg-blue-500 text-white px-3 py-1.5 rounded-lg text-xs font-semibold"
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

