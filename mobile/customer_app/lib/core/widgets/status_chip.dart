import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.compact = false});

  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    final (background, foreground) = switch (normalized) {
      'NEW' || 'BOOKED' || 'SCHEDULED' => (const Color(0xFFE0F2FE), const Color(0xFF0369A1)),
      'CONTACTED' || 'TESTRIDE' || 'TEST_RIDE' || 'CONFIRMED' => (
          const Color(0xFFEDE9FE),
          const Color(0xFF6D28D9),
        ),
      'QUOTED' || 'ESTIMATED' || 'OPEN' => (const Color(0xFFFEF3C7), const Color(0xFF92400E)),
      'APPROVED' => (const Color(0xFFDCFCE7), const Color(0xFF166534)),
      'WORKINPROGRESS' || 'WORK_IN_PROGRESS' => (const Color(0xFFFFEDD5), const Color(0xFF9A3412)),
      'QUALITYCHECKPENDING' || 'QUALITY_CHECK_PENDING' => (
          const Color(0xFFE0F2FE),
          const Color(0xFF075985),
        ),
      'QUALITYCHECKPASSED' || 'QUALITY_CHECK_PASSED' => (
          const Color(0xFFDCFCE7),
          const Color(0xFF166534),
        ),
      'COMPLETED' || 'DELIVERED' || 'CLOSED' || 'BILLED' => (
          const Color(0xFFDCFCE7),
          const Color(0xFF166534),
        ),
      'LOST' || 'CANCELLED' || 'NOSHOW' || 'NO_SHOW' => (
          const Color(0xFFFEE2E2),
          const Color(0xFFB91C1C),
        ),
      _ => (const Color(0xFFF1F5F9), const Color(0xFF475569)),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 4 : 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _label(normalized),
        style: TextStyle(
          color: foreground,
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  String _label(String value) {
    if (value.isEmpty) return 'Unknown';
    final cleaned = value.replaceAll('_', ' ').toLowerCase();
    return cleaned
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}
