import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/login_required.dart';
import '../../../core/widgets/remote_image.dart';
import '../../catalog/application/catalog_controllers.dart';
import '../../catalog/domain/entities/vehicle.dart';
import '../application/service_controllers.dart';
import '../domain/entities/service_entities.dart';

const _serviceCards = [
  ('PAID_GENERAL', 'General\nService', Icons.handyman_rounded),
  ('PERIODIC', 'Periodic\nService', Icons.book_rounded),
  ('REPAIR', 'Repair\nService', Icons.settings_rounded),
];

const _slots = [
  '09:00 - 10:00 AM',
  '10:00 - 11:00 AM',
  '11:00 - 12:00 PM',
  '02:00 - 03:00 PM',
  '04:00 - 05:00 PM',
];

/// Screen 9: Book Service (Logged In)
class ServiceBookingPage extends ConsumerStatefulWidget {
  const ServiceBookingPage({super.key, this.initialVehicleId});

  final String? initialVehicleId;

  @override
  ConsumerState<ServiceBookingPage> createState() => _ServiceBookingPageState();
}

class _ServiceBookingPageState extends ConsumerState<ServiceBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _complaintsController = TextEditingController();

  String? _vehicleId;
  String? _branchId;
  String _serviceType = 'PERIODIC';
  String _slot = _slots[1]; // 10:00 - 11:00 AM
  late DateTime _selectedDate;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _vehicleId = widget.initialVehicleId;
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _complaintsController.dispose();
    super.dispose();
  }

  Future<void> _submit(List<CustomerVehicle> vehicles, List<DealershipBranch> branches) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final vehicleId = _vehicleId ?? (vehicles.isEmpty ? null : vehicles.first.id);
    if (vehicleId == null) {
      _showError('Select the vehicle to be serviced.');
      return;
    }

    final branchId = _branchId ?? (branches.isNotEmpty ? branches.first.id : '22222222-2222-2222-2222-222222222222');

    setState(() => _submitting = true);

    try {
      final booking = await ref.read(serviceRepositoryProvider).createBooking(
            ServiceBookingDraft(
              customerVehicleId: vehicleId,
              branchId: branchId,
              serviceType: _serviceType,
              scheduledDate: _selectedDate,
              timeSlot: _slot,
              customerComplaints:
                  _complaintsController.text.trim().isEmpty ? null : _complaintsController.text.trim(),
            ),
          );

      ref.invalidate(myServiceBookingsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Service appointment booked successfully.')));
      context.pushReplacement('/service/track/${booking.id}');
    } on ApiException catch (error) {
      if (!mounted) return;
      _showError(error.message);
    } catch (error) {
      if (!mounted) return;
      _showError(error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).value;
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book Service')),
        body: const LoginRequired(
          title: 'Sign in to book service',
          message: 'Service bookings are linked to your registered two-wheelers.',
          icon: Icons.build_circle_outlined,
          redirect: '/service/book',
        ),
      );
    }

    final vehiclesState = ref.watch(myVehiclesProvider);
    final branches = ref.watch(branchesProvider).value ?? const <DealershipBranch>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Book Service', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: vehiclesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(myVehiclesProvider),
        ),
        data: (vehicles) {
          final effectiveVehicles = vehicles.isNotEmpty ? vehicles : sampleVehiclesData;
          final effectiveVehicle = effectiveVehicles.firstWhere(
            (v) => v.id == _vehicleId,
            orElse: () => effectiveVehicles.first,
          );

          return SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  // 1. Vehicle Selector Card (Screen 9)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 52,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: RemoteImage(
                            url: effectiveVehicle.heroImageUrl,
                            fallbackAsset: RemoteImage.resolveVehicleAsset(effectiveVehicle.modelName),
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                effectiveVehicle.modelName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                effectiveVehicle.registrationNumber,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (effectiveVehicles.length > 1)
                          PopupMenuButton<String>(
                            tooltip: 'Switch vehicle',
                            icon: const Icon(Icons.swap_horiz_rounded, color: Color(0xFFDC2626)),
                            onSelected: (id) => setState(() => _vehicleId = id),
                            itemBuilder: (context) => effectiveVehicles
                                .map((v) => PopupMenuItem(
                                      value: v.id,
                                      child: Text('${v.modelName} (${v.registrationNumber})'),
                                    ))
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Service Options (3 Cards matching Screen 9)
                  Row(
                    children: _serviceCards.map((card) {
                      final isSelected = _serviceType == card.$1;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _serviceType = card.$1),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFEF2F2) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? const Color(0xFFDC2626) : const Color(0xFFE2E8F0),
                                width: isSelected ? 1.8 : 1.0,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFFEE2E2) : const Color(0xFFF8FAFC),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    card.$3,
                                    size: 22,
                                    color: isSelected ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  card.$2,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // 3. Select Date (Horizontal Strip matching Screen 9)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Date',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        formatMonthYear(_selectedDate),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildHorizontalCalendarStrip(),
                  const SizedBox(height: 20),

                  // 4. Preferred Time Slot
                  const Text(
                    'Preferred Time Slot',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _slots.map((slot) {
                      final active = _slot == slot;
                      return ChoiceChip(
                        label: Text(slot),
                        selected: active,
                        selectedColor: const Color(0xFFDC2626),
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: active ? Colors.white : const Color(0xFF0F172A),
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12.5,
                        ),
                        checkmarkColor: Colors.white,
                        showCheckmark: false,
                        side: BorderSide(
                          color: active ? const Color(0xFFDC2626) : const Color(0xFFE2E8F0),
                        ),
                        onSelected: (_) => setState(() => _slot = slot),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // 5. Dealership Workshop Location
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.storefront_rounded, color: Color(0xFFDC2626), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kotchadai Workshop, Madurai',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Theni Main Road, Kotchadai · Dedicated 2-Wheeler Service Bay',
                                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 6. Solid Red Book Service Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _submitting ? null : () => _submit(effectiveVehicles, branches),
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Text(
                              'Book Service',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalCalendarStrip() {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.add(Duration(days: i)));

    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final date = days[index];
          final isSelected = date.year == _selectedDate.year &&
              date.month == _selectedDate.month &&
              date.day == _selectedDate.day;
          final weekday = _weekdayShort(date.weekday);

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 54,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFDC2626) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? const Color(0xFFDC2626) : const Color(0xFFE2E8F0),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    weekday,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _weekdayShort(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }
}
