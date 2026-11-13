import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/login_required.dart';
import '../application/profile_controller.dart';
import '../domain/entities/customer_profile.dart';

class EditProfilePage extends ConsumerWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).value;
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit profile')),
        body: const LoginRequired(
          title: 'Sign in to edit your profile',
          message: 'Your profile is linked to your mobile number.',
          icon: Icons.person_outline_rounded,
          redirect: '/profile/edit',
        ),
      );
    }

    final profileState = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.read(profileControllerProvider.notifier).refresh(),
        ),
        data: (profile) => profile == null
            ? const Center(child: Text('Profile unavailable.'))
            : _EditProfileForm(profile: profile),
      ),
    );
  }
}

class _EditProfileForm extends ConsumerStatefulWidget {
  const _EditProfileForm({required this.profile});

  final CustomerProfile profile;

  @override
  ConsumerState<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<_EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _postalCode;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _firstName = TextEditingController(text: profile.firstName);
    _lastName = TextEditingController(text: profile.lastName ?? '');
    _email = TextEditingController(text: profile.email ?? '');
    _address = TextEditingController(text: profile.addressLine1 ?? '');
    _city = TextEditingController(text: profile.city ?? '');
    _state = TextEditingController(text: profile.state ?? '');
    _postalCode = TextEditingController(text: profile.postalCode ?? '');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _address.dispose();
    _city.dispose();
    _state.dispose();
    _postalCode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(profileControllerProvider.notifier).save(
            ProfileUpdateDraft(
              firstName: _firstName.text.trim(),
              lastName: _lastName.text.trim(),
              email: _email.text.trim(),
              addressLine1: _address.text.trim(),
              city: _city.text.trim(),
              state: _state.text.trim(),
              postalCode: _postalCode.text.trim(),
            ),
          );

      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Profile updated.')));

      if (mounted) context.pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      _showError(error.message);
    } catch (error) {
      if (!mounted) return;
      _showError(error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const SectionHeader(
              title: 'Personal details',
              subtitle: 'This is how the dealership will address you',
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstName,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: (value) => Validators.name(value, label: 'First name'),
                    decoration: const InputDecoration(labelText: 'First name'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lastName,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Last name'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              initialValue: widget.profile.phone,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Mobile number',
                prefixIcon: Icon(Icons.phone_iphone_rounded),
                helperText: 'Contact the dealership to change your registered mobile number.',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: Validators.email,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
            ),
            const SizedBox(height: 26),
            const SectionHeader(
              title: 'Delivery address',
              subtitle: 'Used for invoices, registration and pickup',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _address,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Address line 1'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _city,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'City'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _state,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'State'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _postalCode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              validator: Validators.postalCode,
              onFieldSubmitted: (_) => _save(),
              decoration: const InputDecoration(labelText: 'Postal code'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}
