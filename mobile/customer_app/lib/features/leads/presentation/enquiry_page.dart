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

class EnquiryPage extends ConsumerStatefulWidget {
  const EnquiryPage({
    super.key,
    required this.variantId,
    required this.branchId,
    required this.modelName,
    required this.variantName,
    this.colorId,
  });

  final String variantId;
  final String branchId;
  final String? colorId;
  final String modelName;
  final String variantName;

  @override
  ConsumerState<EnquiryPage> createState() => _EnquiryPageState();
}

class _EnquiryPageState extends ConsumerState<EnquiryPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();

  String? _branchId;
  DateTime? _expectedPurchaseDate;
  bool _submitting = false;
  Enquiry? _submitted;

  @override
  void initState() {
    super.initState();
    _branchId = widget.branchId.isEmpty ? null : widget.branchId;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedPurchaseDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'When do you plan to buy?',
    );
    if (picked != null) setState(() => _expectedPurchaseDate = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final branches = ref.read(branchesProvider).value ?? const <DealershipBranch>[];
    final branchId = (_branchId != null && _branchId!.isNotEmpty)
        ? _branchId!
        : (widget.branchId.isNotEmpty
            ? widget.branchId
            : (branches.isNotEmpty ? branches.first.id : '22222222-2222-2222-2222-222222222222'));

    setState(() => _submitting = true);

    try {
      final draft = EnquiryDraft(
        branchId: branchId,
        variantId: widget.variantId,
        colorId: widget.colorId,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        expectedPurchaseDate: _expectedPurchaseDate,
        firstName: ref.read(authControllerProvider).value == null
            ? _firstNameController.text.trim()
            : null,
        lastName: ref.read(authControllerProvider).value == null
            ? _lastNameController.text.trim()
            : null,
        phone: ref.read(authControllerProvider).value == null ? _phoneController.text.trim() : null,
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      );

      final enquiry = await ref.read(leadsRepositoryProvider).createEnquiry(draft);
      ref.invalidate(myEnquiriesProvider);
      if (!mounted) return;
      setState(() => _submitted = enquiry);
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
      return _EnquirySuccess(
        enquiry: _submitted!,
        signedIn: session != null,
        branchName: selectedBranch?.name ?? _submitted!.branchName,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Send an enquiry')),
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
                      child: Icon(
                        Icons.two_wheeler_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
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
                'Where should we follow up?',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 10),
              if (branches.isNotEmpty)
                DropdownButtonFormField<String>(
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
                )
              else
                TextFormField(
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Dealership branch',
                    hintText: 'Choose a branch from the model page',
                    prefixIcon: Icon(Icons.storefront_rounded),
                  ),
                ),
              const SizedBox(height: 16),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Expected purchase date (optional)',
                    prefixIcon: Icon(Icons.event_rounded),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _expectedPurchaseDate == null
                              ? 'Planning later'
                              : formatShortDate(_expectedPurchaseDate),
                          style: TextStyle(
                            color: _expectedPurchaseDate == null
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (_expectedPurchaseDate != null)
                        IconButton(
                          onPressed: () => setState(() => _expectedPurchaseDate = null),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          visualDensity: VisualDensity.compact,
                        )
                      else
                        const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                          'We will contact you on ${session.phone}.',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: Validators.email,
                decoration: const InputDecoration(
                  labelText: 'Email (optional)',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Anything we should know? (optional)',
                  hintText: 'Preferred colour, accessories, exchange, finance…',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your enquiry is shared only with this dealership. It is not a booking or a price commitment.',
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
                    : const Text('Send enquiry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnquirySuccess extends StatelessWidget {
  const _EnquirySuccess({
    required this.enquiry,
    required this.signedIn,
    required this.branchName,
  });

  final Enquiry enquiry;
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
                decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Color(0xFF166534), size: 32),
              ),
              const SizedBox(height: 20),
              const Text(
                'Enquiry sent!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.6),
              ),
              const SizedBox(height: 10),
              Text(
                'A sales executive from ${branchName.isEmpty ? 'the dealership' : branchName} will call you to confirm availability and next steps.',
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
                            '${enquiry.modelName} ${enquiry.variantName}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ),
                        StatusChip(status: enquiry.status, compact: true),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Reference ${enquiry.id.split('-').first.toUpperCase()}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    if (enquiry.colorName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Colour: ${enquiry.colorName}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ),
                  ],
                ),
              ),
              if (!signedIn) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF1D4ED8)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Sign in with the same mobile number to track this enquiry in the app.',
                          style: TextStyle(fontSize: 12.5, color: Color(0xFF1E40AF), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              if (signedIn)
                FilledButton(
                  onPressed: () {
                    context.go('/activity');
                  },
                  child: const Text('View my activity'),
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
