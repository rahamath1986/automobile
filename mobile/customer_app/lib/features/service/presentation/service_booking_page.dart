import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/login_required.dart';
import '../../catalog/application/catalog_controllers.dart';
import '../../catalog/domain/entities/vehicle.dart';
import '../application/service_controllers.dart';
import '../domain/entities/service_entities.dart';

const _serviceTypes = [
  ('PERIODIC', 'Periodic service', Icons.autorenew_rounded),
  ('PAID_GENERAL', 'General service', Icons.build_rounded),
  ('REPAIR', 'Repair', Icons.handyman_rounded),
  ('ACCIDENT', 'Accident repair', Icons.car_crash_rounded),
  ('BATTERY', 'Battery check', Icons.battery_charging_full_rounded),
  ('FREE_SERVICE', 'Free service', Icons.card_giftcard_rounded),
];

const _slots = [
  '09:00 - 10:00',
  '10:00 - 11:00',
  '11:00 - 12:00',
  '12:00 - 13:00',
  '14:00 - 15:00',
  '15:00 - 16:00',
  '16:00 - 17:00',
  '17:00 - 18:00',
];

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
  String _slot = _slots.first;
  late DateTime _date;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _vehicleId = widget.initialVehicleId;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _date = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
  }

  @override
  void dispose() {
    _complaintsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 90)),
      helpText: 'Choose a service date',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit(List<CustomerVehicle> vehicles) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final vehicleId = _vehicleId ?? (vehicles.isEmpty ? null : vehicles.first.id);
    if (vehicleId == null) {
      _showError('Select the vehicle to be serviced.');
      return;
    }
    if (_branchId == null || _branchId!.isEmpty) {
      _showError('Select a service branch.');
      return;
    }

    setState(() => _submitting = true);

    try {
      final booking = await ref.read(serviceRepositoryProvider).createBooking(
            ServiceBookingDraft(
              customerVehicleId: vehicleId,
              branchId: _branchId!,
              serviceType: _serviceType,
              scheduledDate: _date,
              timeSlot: _slot,
              customerComplaints:
                  _complaintsController.text.trim().isEmpty ? null : _complaintsController.text.trim(),
            ),
          );

      ref.invalidate(myServiceBookingsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Service appointment booked.')));
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
        appBar: AppBar(title: const Text('Book a service')),
        body: const LoginRequired(
          title: 'Sign in to book service',
          message: 'Service bookings are linked to your owned vehicles.',
          icon: Icons.build_circle_outlined,
          redirect: '/service/book',
        ),
      );
    }

    final vehiclesState = ref.watch(myVehiclesProvider);
    final branches = ref.watch(branchesProvider).value ?? const <DealershipBranch>[];
    final effectiveBranchId = _branchId ?? (branches.isEmpty ? null : branches.first.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Book a service')),
      body: vehiclesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(myVehiclesProvider),
        ),
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return EmptyState(
              icon: Icons.garage_outlined,
              title: 'No owned vehicles',
              message: 'A vehicle appears here after delivery. Contact the dealership if it is missing.',
              action: OutlinedButton(
                onPressed: () => context.go('/garage'),
                child: const Text('Back to garage'),
              ),
            );
          }

          final effectiveVehicleId = _vehicleId == null
              ? vehicles.first.id
              : (vehicles.any((vehicle) => vehicle.id == _vehicleId) ? _vehicleId : vehicles.first.id);

          return SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  const SectionHeader(
                    title: 'Vehicle & branch',
                    subtitle: 'We will confirm your slot over a call if needed',
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: effectiveVehicleId,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle',
                      prefixIcon: Icon(Icons.two_wheeler_rounded),
                    ),
                    items: vehicles
                        .map(
                          (vehicle) => DropdownMenuItem(
                            value: vehicle.id,
                            child: Text(
                              '${vehicle.modelName} · ${vehicle.registrationNumber}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _vehicleId = value),
                  ),
                  const SizedBox(height: 14),
                  if (branches.isNotEmpty)
                    DropdownButtonFormField<String>(
                      initialValue: effectiveBranchId,
                      decoration: const InputDecoration(
                        labelText: 'Service branch',
                        prefixIcon: Icon(Icons.storefront_rounded),
                      ),
                      items: branches
                          .map(
                            (branch) => DropdownMenuItem(
                              value: branch.id,
                              child: Text(
                                branch.city.isEmpty ? branch.name : '${branch.name} · ${branch.city}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _branchId = value),
                    )
                  else
                    TextFormField(
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Service branch',
                        hintText: 'Branches are unavailable right now',
                        prefixIcon: Icon(Icons.storefront_rounded),
                      ),
                    ),
                  const SizedBox(height: 24),
                  const SectionHeader(title: 'What do you need?'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _serviceTypes
                        .map(
                          (type) {
                            final isSelected = _serviceType == type.$1;
                            final primary = Theme.of(context).colorScheme.primary;
                            return ChoiceChip(
                              avatar: Icon(
                                type.$3,
                                size: 16,
                                color: isSelected ? Colors.white : const Color(0xFF0F172A),
                              ),
                              label: Text(
                                type.$2,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: primary,
                              backgroundColor: Colors.white,
                              checkmarkColor: Colors.white,
                              showCheckmark: false,
                              side: BorderSide(
                                color: isSelected ? primary : const Color(0xFFDCE5F0),
                              ),
                              onSelected: (_) => setState(() => _serviceType = type.$1),
                            );
                          },
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  const SectionHeader(title: 'When should we expect you?'),
                  const SizedBox(height: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Service date',
                        prefixIcon: Icon(Icons.calendar_month_rounded),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              formatShortDate(_date),
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _slot,
                    decoration: const InputDecoration(
                      labelText: 'Time slot',
                      prefixIcon: Icon(Icons.schedule_rounded),
                    ),
                    items: _slots
                        .map((slot) => DropdownMenuItem(value: slot, child: Text(slot)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _slot = value);
                    },
                  ),
                  const SizedBox(height: 24),
                  const SectionHeader(title: 'Tell the technician'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _complaintsController,
                    maxLines: 4,
                    maxLength: 1000,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Symptoms or requests (optional)',
                      hintText: 'Noise from the engine, brake feel, first service…',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _submitting ? null : () => _submit(vehicles),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Confirm appointment'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
