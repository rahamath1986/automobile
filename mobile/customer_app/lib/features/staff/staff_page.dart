import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/token_store.dart';

class StaffPage extends StatefulWidget {
  const StaffPage({super.key});

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  final _tokens = TokenStore(staff: true);
  late final _api = ApiClient(tokenStore: _tokens);
  final _dealer = TextEditingController(text: AppConfig.dealerCode);
  final _username = TextEditingController(text: 'manager.priya');
  final _password = TextEditingController(text: 'Demo@123');
  String? _section;
  List<Map<String, dynamic>> _rows = [];
  bool _busy = true;
  String? _error;
  String? _receipt;
  String? _paymentFingerprint;
  String? _paymentRequestId;

  Map<String, dynamic> get _profile => _tokens.session ?? {};
  List<dynamic> get _roles => _profile['roles'] as List? ?? [];
  bool hasRole(String role) => _roles.contains(role);
  bool get _manager => hasRole('BranchManager');
  bool get _advisor => _manager || hasRole('ServiceAdvisor');

  @override
  void initState() {
    super.initState();
    _tokens.load().whenComplete(() {
      if (mounted) setState(() => _busy = false);
    });
  }

  @override
  void dispose() {
    _dealer.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _login() => _run(() async {
    final data =
        await _api.post(
              '/auth/staff/login',
              body: {
                'dealerCode': _dealer.text.trim().isEmpty
                    ? AppConfig.dealerCode
                    : _dealer.text.trim(),
                'usernameOrEmail': _username.text.trim(),
                'password': _password.text,
              },
            )
            as Map<String, dynamic>;
    await _tokens.save(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      session: data['user'] as Map<String, dynamic>,
    );
    if (mounted) _password.clear();
  });

  List<Map<String, dynamic>> _list(dynamic value) {
    final rows = value is Map ? value['items'] : value;
    return (rows as List? ?? []).cast<Map<String, dynamic>>();
  }

  static const _routes = {
    'Leads': '/staff/sales/leads',
    'Test rides': '/staff/sales/test-rides',
    'Appointments': '/service/bookings',
    'Job cards': '/service/job-cards',
  };

  Future<void> _load(String section) async {
    _section = section;
    _rows = [];
    if (section != 'Payments') {
      _rows = _list(await _api.get(_routes[section]!));
    }
  }

  Future<List<String>?> _fields(String title, List<String> labels) async {
    final values = List.filled(labels.length, '');
    return showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < labels.length; i++)
                TextField(
                  decoration: InputDecoration(labelText: labels[i]),
                  onChanged: (value) => values[i] = value.trim(),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, values),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _change(String path, Object? body, {bool post = false}) =>
      _run(() async {
        if (post) {
          await _api.post(path, body: body);
        } else {
          await _api.put(path, body: body);
        }
        await _load(_section!);
      });

  Future<void> _payment() async {
    final values = await _fields('Record received payment', [
      'Booking ID',
      'Amount',
      'Mode (Cash, UPI, Card, NetBanking, Financier, BankTransfer)',
      'Transaction reference',
    ]);
    if (!mounted || values == null) return;
    await _run(() async {
      const modes = [
        'cash',
        'upi',
        'card',
        'netbanking',
        'financier',
        'banktransfer',
      ];
      final mode = modes.indexOf(values[2].toLowerCase());
      final amount = double.tryParse(values[1]);
      if (mode < 0 ||
          amount == null ||
          !amount.isFinite ||
          amount <= 0 ||
          values[0].isEmpty) {
        throw const FormatException(
          'Enter a booking ID, positive amount and payment mode.',
        );
      }
      final body = {
        'bookingId': values[0],
        'amount': amount,
        'mode': mode,
        'transactionRef': values[3],
      };
      final fingerprint = body.toString();
      if (_paymentFingerprint != fingerprint) {
        _paymentFingerprint = fingerprint;
        final random = Random.secure();
        String hex(int length) => List.generate(
          length,
          (_) => random.nextInt(16).toRadixString(16),
        ).join();
        _paymentRequestId =
            '${hex(8)}-${hex(4)}-4${hex(3)}-8${hex(3)}-${hex(12)}';
      }
      final result =
          await _api.post(
                '/billing/payments',
                body: {...body, 'requestId': _paymentRequestId},
              )
              as Map;
      _receipt = '${result['receiptNumber']} · ₹${result['amount']}';
      _paymentFingerprint = null;
      _paymentRequestId = null;
    });
  }

  Future<void> _rowAction(Map<String, dynamic> row) async {
    final id = row['id'];
    final path = '/service/job-cards/$id';
    switch (_section) {
      case 'Leads':
        final action = await showDialog<String>(
          context: context,
          builder: (context) => SimpleDialog(
            title: Text(row['customerName'].toString()),
            children: [
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, 'contact'),
                child: const Text('Log customer contact'),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, 'schedule'),
                child: const Text('Schedule test ride'),
              ),
            ],
          ),
        );
        if (!mounted || action == null) return;
        if (action == 'schedule') {
          final now = DateTime.now();
          final day = await showDatePicker(
            context: context,
            initialDate: now,
            firstDate: now,
            lastDate: now.add(const Duration(days: 60)),
          );
          if (!mounted || day == null) return;
          final time = await showTimePicker(
            context: context,
            initialTime: const TimeOfDay(hour: 10, minute: 0),
          );
          if (!mounted || time == null) return;
          final scheduled = DateTime(
            day.year,
            day.month,
            day.day,
            time.hour,
            time.minute,
          );
          await _change('/sales/test-rides', {
            'enquiryId': id,
            'branchId': row['branchId'],
            'variantId': row['variantId'],
            'firstName': row['customerName'],
            'phone': row['phone'],
            'scheduledAt': scheduled.toUtc().toIso8601String(),
          }, post: true);
          return;
        }
        final values = await _fields('Log customer contact', ['Notes']);
        if (mounted && values != null) {
          await _change('/staff/sales/leads/$id/follow-ups', {
            'notes': values[0],
          }, post: true);
        }
      case 'Test rides':
        if (row['status'] != 'Scheduled') return;
        final values = await _fields('Complete test ride', [
          'Verified driving licence number',
          'Feedback',
        ]);
        if (mounted && values != null && values[0].isNotEmpty) {
          await _change('/staff/sales/test-rides/$id/complete', {
            'drivingLicenseVerified': true,
            'drivingLicenseNumber': values[0],
            'feedbackNotes': values[1],
          }, post: true);
        }
      case 'Appointments':
        final values = await _fields('Check in vehicle', [
          'Odometer reading',
          'Fuel percentage',
        ]);
        if (mounted && values != null) {
          await _change('/service/job-cards', {
            'serviceBookingId': id,
            'odometerReading': int.tryParse(values[0]),
            'fuelLevelPercent': int.tryParse(values[1]),
          }, post: true);
        }
      case 'Job cards':
        await _jobAction(path, row['status']?.toString());
    }
  }

  Future<void> _jobAction(String path, String? status) async {
    if (status == 'Open' && _advisor) {
      final values = await _fields('Create estimate', [
        'Labour description',
        'Labour cost',
        'Spare part (optional)',
        'Spare part cost',
      ]);
      if (mounted && values != null) {
        await _change('$path/estimate', {
          'items': [
            {
              'type': 0,
              'description': values[0],
              'quantity': 1,
              'unitPrice': double.tryParse(values[1]),
            },
            if (values[2].isNotEmpty)
              {
                'type': 1,
                'description': values[2],
                'quantity': 1,
                'unitPrice': double.tryParse(values[3]),
              },
          ],
        });
      }
    } else if (status == 'Approved' && _advisor) {
      try {
        final technicians = _list(await _api.get('/service/technicians'));
        if (!mounted) return;
        final id = await showDialog<String>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('Assign technician'),
            children: [
              if (technicians.isEmpty)
                const SimpleDialogOption(
                  child: Text('No technicians in this branch'),
                ),
              for (final tech in technicians)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, tech['id']),
                  child: Text(tech['fullName'].toString()),
                ),
            ],
          ),
        );
        if (mounted && id != null) {
          await _change('$path/assign', {'technicianId': id});
        }
      } catch (error) {
        if (mounted) setState(() => _error = error.toString());
      }
    } else if (status == 'WorkInProgress' && hasRole('Technician')) {
      final values = await _fields('Submit inspection', [
        'Inspection item',
        'Pass or fail',
        'Notes',
      ]);
      if (!mounted || values == null) return;
      final result = values[1].toLowerCase();
      if (result != 'pass' && result != 'fail') {
        setState(
          () => _error = 'Enter pass or fail for the inspection result.',
        );
        return;
      }
      await _change('$path/progress', {
        'checklist': [
          {'item': values[0], 'passed': result == 'pass', 'notes': values[2]},
        ],
      });
    } else if (status == 'QualityCheckPending' && _advisor) {
      final passed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Quality check'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Return for rework'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Pass'),
            ),
          ],
        ),
      );
      if (mounted && passed != null) {
        await _change('$path/qc', {'passed': passed});
      }
    } else if (status == 'QualityCheckPassed' && _manager) {
      await _change('$path/invoice', null, post: true);
    } else if (status == 'Billed' && _advisor) {
      await _change('$path/close', null, post: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = _tokens.hasToken;
    final sales =
        _manager || hasRole('SalesExecutive') || hasRole('SalesManager');
    final sections = [
      if (sales) ...['Leads', 'Test rides'],
      if (_advisor) 'Appointments',
      if (_advisor || hasRole('Technician')) 'Job cards',
      if (_manager || hasRole('Cashier')) 'Payments',
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dealer workspace'),
        actions: [
          if (signedIn)
            TextButton(
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                      await _tokens.clear();
                      _section = null;
                      _rows = [];
                      _receipt = null;
                      _paymentFingerprint = null;
                      _paymentRequestId = null;
                    }),
              child: const Text('Sign out'),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (_busy) const LinearProgressIndicator(),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (!signedIn) ...[
                Center(
                  child: Image.asset('assets/images/motosaas_logo.png', height: 48, fit: BoxFit.contain),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Quick-fill demo staff account:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.manage_accounts_rounded, size: 16),
                      label: const Text('Branch Manager'),
                      onPressed: () => setState(() {
                        _dealer.text = AppConfig.dealerCode;
                        _username.text = 'manager.priya';
                        _password.text = 'Demo@123';
                      }),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.support_agent_rounded, size: 16),
                      label: const Text('Sales'),
                      onPressed: () => setState(() {
                        _dealer.text = AppConfig.dealerCode;
                        _username.text = 'sales.arjun';
                        _password.text = 'Demo@123';
                      }),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.build_circle_outlined, size: 16),
                      label: const Text('Advisor'),
                      onPressed: () => setState(() {
                        _dealer.text = AppConfig.dealerCode;
                        _username.text = 'advisor.kiran';
                        _password.text = 'Demo@123';
                      }),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.handyman_outlined, size: 16),
                      label: const Text('Technician'),
                      onPressed: () => setState(() {
                        _dealer.text = AppConfig.dealerCode;
                        _username.text = 'tech.suresh';
                        _password.text = 'Demo@123';
                      }),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.point_of_sale_rounded, size: 16),
                      label: const Text('Cashier'),
                      onPressed: () => setState(() {
                        _dealer.text = AppConfig.dealerCode;
                        _username.text = 'cashier.meena';
                        _password.text = 'Demo@123';
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _dealer,
                  decoration: const InputDecoration(
                    labelText: 'Dealer code',
                    hintText: AppConfig.dealerCode,
                  ),
                ),
                TextField(
                  controller: _username,
                  decoration: const InputDecoration(
                    labelText: 'Username or email',
                    hintText: kDebugMode ? 'manager.priya' : null,
                    helperText: kDebugMode
                        ? 'Also: advisor.kiran, sales.arjun, tech.suresh'
                        : null,
                    helperMaxLines: 2,
                  ),
                ),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    hintText: kDebugMode ? 'Demo@123' : null,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _login,
                  child: const Text('Sign in'),
                ),
              ] else ...[
                Text(
                  _profile['fullName']?.toString() ?? 'Staff',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(_roles.join(' · ')),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final section in sections)
                      ChoiceChip(
                        label: Text(
                          section,
                          style: TextStyle(
                            color: _section == section ? Colors.white : const Color(0xFF0F172A),
                            fontWeight: _section == section ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        selected: _section == section,
                        selectedColor: Theme.of(context).colorScheme.primary,
                        backgroundColor: Colors.white,
                        checkmarkColor: Colors.white,
                        showCheckmark: false,
                        side: BorderSide(
                          color: _section == section
                              ? Theme.of(context).colorScheme.primary
                              : const Color(0xFFDCE5F0),
                        ),
                        onSelected: _busy
                            ? null
                            : (_) => _run(() => _load(section)),
                      ),
                  ],
                ),
                if (_section == 'Payments') ...[
                  FilledButton(
                    onPressed: _busy ? null : _payment,
                    child: const Text('Record payment'),
                  ),
                  if (_receipt != null) SelectableText(_receipt!),
                ] else if (_section != null && !_busy && _rows.isEmpty)
                  const ListTile(title: Text('No records')),
                for (final row in _rows)
                  ListTile(
                    title: Text(
                      (row['customerName'] ??
                              row['jobCardNumber'] ??
                              row['serviceType'] ??
                              row['id'])
                          .toString(),
                    ),
                    subtitle: Text(
                      [
                        row['status'],
                        row['timeSlot'] ?? row['scheduledAt'],
                      ].whereType<String>().join(' · '),
                    ),
                    onTap: _busy ? null : () => _rowAction(row),
                    trailing: const Icon(Icons.chevron_right),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
