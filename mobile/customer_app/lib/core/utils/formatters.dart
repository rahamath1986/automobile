import 'package:intl/intl.dart';

final NumberFormat _rupeeFormat = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

final DateFormat _shortDate = DateFormat('dd MMM yyyy');
final DateFormat _dateTime = DateFormat('dd MMM yyyy, hh:mm a');
final DateFormat _monthYear = DateFormat('MMM yyyy');

String formatCurrency(num? value, {bool withDecimals = false}) {
  if (value == null) return '—';
  if (withDecimals) {
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2).format(value);
  }
  return _rupeeFormat.format(value);
}

String formatShortDate(DateTime? date) => date == null ? '—' : _shortDate.format(date);

String formatDateTime(DateTime? date) => date == null ? '—' : _dateTime.format(date);

String formatMonthYear(DateTime? date) => date == null ? '—' : _monthYear.format(date);

String formatEmiEstimate(num onRoadPrice, {double downPaymentPercent = 0.15, double annualRate = 10.5, int months = 36}) {
  final principal = onRoadPrice * (1 - downPaymentPercent);
  if (principal <= 0) return '—';
  final monthlyRate = annualRate / 12 / 100;
  final emi = principal * monthlyRate * _pow(1 + monthlyRate, months) / (_pow(1 + monthlyRate, months) - 1);
  return formatCurrency(emi);
}

double _pow(double base, int exponent) {
  var result = 1.0;
  for (var i = 0; i < exponent; i++) {
    result *= base;
  }
  return result;
}
