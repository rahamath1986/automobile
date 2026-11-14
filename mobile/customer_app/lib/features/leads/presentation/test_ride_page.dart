import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/status_chip.dart';
import '../../catalog/application/catalog_controllers.dart';
import '../../catalog/domain/entities/vehicle.dart';
import '../application/leads_controllers.dart';
import '../domain/entities/lead.dart';

const _timeSlots = [
  ('09:00 - 10:00', 9),
  ('10:00 - 11:00', 10),
  ('11:00 - 12:00', 11),
  ('12:00 - 13:00', 12),
  ('14:00 - 15:00', 14),
  ('15:00 - 16:00', 15),
  ('16:00 - 17:00', 16),
  ('17:00 - 18:00', 17),
];

class TestRidePage extends ConsumerStatefulWidget {
  const TestRidePage({
    super.key,
    required this.variantId,
    required this.branchId,
    required this.modelName,
    required this.variantName,
  });

  final String variantId;
  final String branchId;
  final String modelName;
  final String variantName;

  @override
  ConsumerState<TestRidePage> createState() => _TestRidePageState();
}

class _TestRidePageState extends ConsumerState<TestRidePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _licenseController = TextEditingController();

  String? _branchId;
  late DateTime _date;
  String _slot = _timeSlots.first.$1;
  bool _submitting = false;
  TestRide? _submitted;

  @override
  void initState() {
    super.initState();
    _branchId = widget.branchId.isEmpty ? null : widget.branchId;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _date = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 30)),
      helpText: 'Choose a test ride date',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final branches = ref.read(branchesProvider).value ?? const <DealershipBranch>[];
    final branchId = (_branchId != null && _branchId!.isNotEmpty)
        ? _branchId!
        : (widget.branchId.isNotEmpty
            ? widget.branchId
            : (branches.isNotEmpty ? branches.first.id : '22222222-2222-2222-2222-222222222222'));

    final slotHour = _timeSlots.firstWhere((slot) => slot.$1 == _slot).$2;
    final scheduledAt = DateTime(_date.year, _date.month, _date.day, slotHour);
    if (scheduledAt.isBefore(DateTime.now())) {
      _showError('Choose a future date and time for your test ride.');
      return;
    }

    setState(() => _submitting = true);

    try {
      final session = ref.read(authControllerProvider).value;
      final draft = TestRideDraft(
        branchId: branchId,
        variantId: widget.variantId,
        scheduledAt: scheduledAt,
        drivingLicenseNumber: _licenseController.text.trim().isEmpty ? null : _licenseController.text.trim(),
        firstName: session == null ? _firstNameController.text.trim() : null,
        lastName: session == null ? _lastNameController.text.trim() : null,
        phone: session == null ? _phoneController.text.trim() : null,
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      );

      final testRide = await ref.read(leadsRepositoryProvider).createTestRide(draft);
      ref.invalidate(myTestRidesProvider);
      if (!mounted) return;
      setState(() => _submitted = testRide);
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
    final branches = ref.watch(branchesProvider).value ?? const <DealershipBranch>[];
    final effectiveBranchId = _branchId ??
        (widget.branchId.isNotEmpty
            ? widget.branchId
            : (branches.isNotEmpty ? branches.first.id : '22222222-2222-2222-2222-222222222222'));
    final selectedBranch = branches.where((branch) => branch.id == effectiveBranchId).firstOrNull;

    if (_submitted != null) {
      return _TestRideSuccess(
        testRide: _submitted!,
        signedIn: session != null,
        branchName: selectedBranch?.name ?? _submitted!.branchName,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Book a test ride')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE8EDF5)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.speed_rounded, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.modelName.isEmpty ? 'Selected vehicle' : widget.modelName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.variantName,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Pick a slot',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 10),
              if (branches.isNotEmpty)
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: effectiveBranchId,
                  decoration: const InputDecoration(
                    labelText: 'Dealership branch',
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
                ),
              const SizedBox(height: 16),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Preferred date',
                    prefixIcon: Icon(Icons.calendar_month_rounded),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          formatShortDate(_date),
                          style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _timeSlots
                    .map(
                      (slot) {
                        final isSelected = _slot == slot.$1;
                        final primary = Theme.of(context).colorScheme.primary;
                        return ChoiceChip(
                          label: Text(
                            slot.$1,
                            style: TextStyle(
                              fontSize: 12,
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
                          onSelected: (_) => setState(() => _slot = slot.$1),
                        );
                      },
                    )
                    .toList(),
              ),
              const SizedBox(height: 22),
              if (session == null) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (value) => Validators.name(value, label: 'First name'),
                        decoration: const InputDecoration(labelText: 'First name'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Last name'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: Validators.phone,
                  decoration: const InputDecoration(
                    labelText: 'Mobile number',
                    prefixIcon: Icon(Icons.phone_iphone_rounded),
                    prefixText: '+91 ',
                  ),
                ),
              ] else
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE8EDF5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_outlined, size: 20, color: Color(0xFF64748B)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Booked for ${session.phone}. Bring your driving licence to the showroom.',
                          style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _licenseController,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                validator: null, // Driving licence is strictly optional
                decoration: const InputDecoration(
                  labelText: 'Driving licence (optional)',
                  hintText: 'KA01 20200000000',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                validator: Validators.email,
                decoration: const InputDecoration(
                  labelText: 'Email (optional)',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Test rides are confirmed by the dealership over a call. Please carry a valid driving licence.',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8), height: 1.4),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Request test ride'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TestRideSuccess extends StatelessWidget {
  const _TestRideSuccess({
    required this.testRide,
    required this.signedIn,
    required this.branchName,
  });

  final TestRide testRide;
  final bool signedIn;
  final String branchName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(color: Color(0xFFEDE9FE), shape: BoxShape.circle),
                child: const Icon(Icons.speed_rounded, color: Color(0xFF6D28D9), size: 32),
              ),
              const SizedBox(height: 20),
              const Text(
                'Test ride requested',
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: -0.6),
              ),
              const SizedBox(height: 10),
              Text(
                '${branchName.isEmpty ? 'The dealership' : branchName} will call you to confirm your slot.',
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE8EDF5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${testRide.modelName} ${testRide.variantName}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ),
                        StatusChip(status: testRide.status, compact: true),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.event_rounded, size: 18, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Text(
                          formatDateTime(testRide.scheduledAt),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    if (testRide.drivingLicenseNumber != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.badge_outlined, size: 18, color: Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          Text(
                            testRide.drivingLicenseNumber!,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              if (signedIn)
                FilledButton(
                  onPressed: () => context.go('/activity'),
                  child: const Text('View my test rides'),
                )
              else
                FilledButton(
                  onPressed: () {
                    context.go(Uri(path: '/login', queryParameters: {'redirect': '/activity'}).toString());
                  },
                  child: const Text('Sign in to track'),
                ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
