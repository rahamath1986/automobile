import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';

class EmiCalculatorWidget extends StatefulWidget {
  const EmiCalculatorWidget({
    super.key,
    this.initialPrice,
    this.modelName,
    this.variantName,
    this.onApply,
  });

  final double? initialPrice;
  final String? modelName;
  final String? variantName;
  final void Function(double loanAmount, double rate, int tenureYears, double monthlyEmi)? onApply;

  static void show(
    BuildContext context, {
    double? initialPrice,
    String? modelName,
    String? variantName,
    void Function(double loanAmount, double rate, int tenureYears, double monthlyEmi)? onApply,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: EmiCalculatorWidget(
            initialPrice: initialPrice,
            modelName: modelName,
            variantName: variantName,
            onApply: onApply,
          ),
        ),
      ),
    );
  }

  @override
  State<EmiCalculatorWidget> createState() => _EmiCalculatorWidgetState();
}

class _EmiCalculatorWidgetState extends State<EmiCalculatorWidget> {
  late double _loanAmount;
  double _interestRate = 9.0;
  int _tenureYears = 2;

  double get _minLoan => 10000;
  double get _maxLoan {
    final base = widget.initialPrice ?? 200000;
    return max(200000.0, ((base * 1.2) / 10000).ceil() * 10000.0);
  }

  @override
  void initState() {
    super.initState();
    final base = widget.initialPrice ?? 150000;
    // Default to ~80% of vehicle price or ₹1,00,000 clamped to range
    final defaultLoan = (base * 0.8 / 5000).round() * 5000.0;
    _loanAmount = defaultLoan.clamp(_minLoan, _maxLoan);
  }

  double get _monthlyEmi {
    final p = _loanAmount;
    final r = (_interestRate / 12) / 100;
    final n = _tenureYears * 12;

    if (r <= 0) return p / n;
    final powFactor = pow(1 + r, n);
    return (p * r * powFactor) / (powFactor - 1);
  }

  double get _totalPayable => _monthlyEmi * (_tenureYears * 12);
  double get _totalInterest => _totalPayable - _loanAmount;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    const badgeColor = Color(0xFF1E3A8A); // Deep blue pill from user design

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 42,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Center(
            child: Text(
              'EMI Calculator',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (widget.modelName != null) ...[
            const SizedBox(height: 4),
            Center(
              child: Text(
                '${widget.modelName} ${widget.variantName ?? ''}'.trim(),
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ),
          ],
          const SizedBox(height: 28),

          // 1. Loan Amount Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Loan Amount',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '₹ ${_loanAmount.round()} Thousands',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: badgeColor,
              thumbColor: badgeColor,
              inactiveTrackColor: const Color(0xFFE2E8F0),
              trackHeight: 3.5,
            ),
            child: Slider(
              value: _loanAmount,
              min: _minLoan,
              max: _maxLoan,
              divisions: ((_maxLoan - _minLoan) / 5000).round(),
              onChanged: (val) => setState(() => _loanAmount = val),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatAmountLabel(_minLoan),
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              Text(
                _formatAmountLabel(_maxLoan),
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 2. Rate of Interest Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Rate of interest',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_interestRate.toStringAsFixed(_interestRate % 1 == 0 ? 0 : 1)} Percentage %',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: badgeColor,
              thumbColor: badgeColor,
              inactiveTrackColor: const Color(0xFFE2E8F0),
              trackHeight: 3.5,
            ),
            child: Slider(
              value: _interestRate,
              min: 7.0,
              max: 22.0,
              divisions: 30,
              onChanged: (val) => setState(() => _interestRate = val),
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('7%', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              Text('22%', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 24),

          // 3. Tenure Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tenure',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_tenureYears ${_tenureYears == 1 ? 'Year' : 'Years'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: badgeColor,
              thumbColor: badgeColor,
              inactiveTrackColor: const Color(0xFFE2E8F0),
              trackHeight: 3.5,
            ),
            child: Slider(
              value: _tenureYears.toDouble(),
              min: 1.0,
              max: 7.0,
              divisions: 6,
              onChanged: (val) => setState(() => _tenureYears = val.round()),
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1 Year', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              Text('7 Years', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 30),

          // Monthly EMI Result matching user design
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Monthly EMI',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      formatCurrency(_monthlyEmi),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                _summaryRow('Principal Amount', formatCurrency(_loanAmount)),
                const SizedBox(height: 6),
                _summaryRow('Total Interest', formatCurrency(_totalInterest)),
                const SizedBox(height: 6),
                _summaryRow('Total Amount Payable', formatCurrency(_totalPayable), isBold: true),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onApply?.call(_loanAmount, _interestRate, _tenureYears, _monthlyEmi);
              },
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Apply for Loan with this EMI',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isBold ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: isBold ? const Color(0xFF0F172A) : const Color(0xFF0F172A),
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  static String _formatAmountLabel(double amount) {
    if (amount >= 100000) {
      final lakhs = amount / 100000;
      return '${lakhs.toStringAsFixed(lakhs % 1 == 0 ? 0 : 1)} Lakh';
    }
    final thousands = (amount / 1000).round();
    return '$thousands Thousand';
  }
}

