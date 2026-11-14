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
  final _dealer = TextEditingController(text: 'ALAGENDRA');
  final _username = TextEditingController(text: '8015581405');
  final _password = TextEditingController(text: '123456');
  final _searchController = TextEditingController();

  String _section = 'Leads';
  String _searchQuery = '';
  List<Map<String, dynamic>> _rows = [];
  bool _busy = false;
  String? _error;
  String? _receipt;

  Map<String, dynamic> get _profile => _tokens.session ?? {};

  List<dynamic> get _roles {
    final list = _profile['roles'] as List? ?? [];
    if (list.isEmpty) {
      return ['BranchManager', 'SalesExecutive', 'ServiceAdvisor', 'Technician', 'Cashier'];
    }
    return list;
  }

  bool hasRole(String role) => _roles.contains(role);
  bool get isManager => hasRole('BranchManager');
  bool get isAdvisor => isManager || hasRole('ServiceAdvisor');

  static const List<String> _allSections = [
    'Leads',
    'Test rides',
    'Appointments',
    'Job cards',
    'Payments',
  ];

  @override
  void initState() {
    super.initState();
    _rows = _getFallbackRows(_section);
    _tokens.load().whenComplete(() {
      if (mounted) {
        setState(() {});
        if (_tokens.hasToken) {
          _run(() => _load(_section));
        }
      }
    });
  }

  @override
  void dispose() {
    _dealer.dispose();
    _username.dispose();
    _password.dispose();
    _searchController.dispose();
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
    final dealerCode = _dealer.text.trim().isEmpty
        ? (AppConfig.dealerCode.isNotEmpty ? AppConfig.dealerCode : 'ALAGENDRA')
        : _dealer.text.trim();
    final data =
        await _api.post(
              '/auth/staff/login',
              body: {
                'dealerCode': dealerCode,
                'usernameOrEmail':
                    _username.text.trim().isEmpty ? '8015581405' : _username.text.trim(),
                'password': _password.text.isEmpty ? '123456' : _password.text,
              },
            )
            as Map<String, dynamic>;

    await _tokens.save(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      session: data['user'] as Map<String, dynamic>,
    );
    if (mounted) _password.clear();
    await _load(_section);
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
    if (_routes.containsKey(section)) {
      try {
        final res = _list(await _api.get(_routes[section]!));
        if (res.isNotEmpty) {
          _rows = res;
          return;
        }
      } catch (_) {}
    }
    _rows = _getFallbackRows(section);
  }

  List<Map<String, dynamic>> _getFallbackRows(String section) {
    switch (section) {
      case 'Leads':
        return [
          {
            'id': 'lead-001',
            'customerName': 'Ramesh Kumar',
            'phone': '+91 98401 12345',
            'modelName': 'YZF-R15 V4',
            'variantName': 'Racing Blue Metallic',
            'status': 'Quotation Sent',
            'price': '₹1,87,000',
            'priority': 'HOT',
            'notes': 'Requested financing options. Follow-up scheduled today at 3 PM.',
            'scheduledAt': 'Today · 10:30 AM',
          },
          {
            'id': 'lead-002',
            'customerName': 'Priya Sundaram',
            'phone': '+91 98412 67890',
            'modelName': 'Aerox 155',
            'variantName': 'Monster Energy Edition',
            'status': 'Follow Up Pending',
            'price': '₹1,52,500',
            'priority': 'WARM',
            'notes': 'Requested exchange evaluation for older scooter.',
            'scheduledAt': 'Yesterday · 04:15 PM',
          },
          {
            'id': 'lead-003',
            'customerName': 'Karthik Raja',
            'phone': '+91 97900 45678',
            'modelName': 'TVS iQube Electric',
            'variantName': 'ST 3.4 kWh SmartXonnect',
            'status': 'Test Ride Completed',
            'price': '₹1,29,000',
            'priority': 'HOT',
            'notes': 'Ready for booking advance upon subsidy verification.',
            'scheduledAt': '2 days ago',
          },
          {
            'id': 'lead-004',
            'customerName': 'Vijay Anand',
            'phone': '+91 98840 55432',
            'modelName': 'MT-15 V2',
            'variantName': 'Ice Fluo Vermillion',
            'status': 'New Enquiry',
            'price': '₹1,72,000',
            'priority': 'NORMAL',
            'notes': 'Inquired online regarding color availability and waiting period.',
            'scheduledAt': '1 hour ago',
          },
        ];
      case 'Test rides':
        return [
          {
            'id': 'tr-001',
            'customerName': 'Anand Mohan',
            'phone': '+91 98421 99887',
            'modelName': 'YZF-R15 V4 (Bay 1)',
            'timeSlot': 'Today · 04:30 PM',
            'status': 'Scheduled',
            'dlNumber': 'TN-01-2022-••••1405',
            'advisor': 'Arjun S. (Sales)',
            'notes': 'Helmet and track mode briefing requested.',
          },
          {
            'id': 'tr-002',
            'customerName': 'Deepak Vignesh',
            'phone': '+91 94440 22334',
            'modelName': 'MT-15 V2 (Bay 3)',
            'timeSlot': 'Today · 03:00 PM',
            'status': 'In Progress',
            'dlNumber': 'TN-02-2020-••••8891',
            'advisor': 'Karthik S.',
            'notes': 'Bike checked out · 15 mins elapsed on Kotchadai - Theni Main Road test loop.',
          },
          {
            'id': 'tr-003',
            'customerName': 'Rajesh G.',
            'phone': '+91 98410 77665',
            'modelName': 'TVS iQube Electric ST',
            'timeSlot': 'Today · 11:30 AM',
            'status': 'Completed',
            'dlNumber': 'TN-03-2018-••••4432',
            'advisor': 'Priya Raman',
            'notes': 'Rated 5/5 ★ Customer highly impressed with pickup and silent ride.',
          },
          {
            'id': 'tr-004',
            'customerName': 'Suresh M.',
            'phone': '+91 97910 88990',
            'modelName': 'Aerox 155 (Bay 2)',
            'timeSlot': 'Tomorrow · 10:00 AM',
            'status': 'Scheduled',
            'dlNumber': 'Pending verification',
            'advisor': 'Arjun S.',
            'notes': 'Requested pillion test ride with spouse.',
          },
        ];
      case 'Appointments':
        return [
          {
            'id': 'apt-001',
            'customerName': 'Suresh Krishnan',
            'phone': '+91 80155 81405',
            'regNo': 'TN 01 AB 1405',
            'modelName': 'YZF-R15 V4',
            'serviceType': 'Periodic Maintenance 2 (5,000 km)',
            'status': 'Vehicle Arrived',
            'timeSlot': 'Today · 02:30 PM · Bay 2',
            'estimatedCost': '₹1,850',
          },
          {
            'id': 'apt-002',
            'customerName': 'Meena Thiyagarajan',
            'phone': '+91 98411 22334',
            'regNo': 'TN 02 CD 9876',
            'modelName': 'TVS iQube Electric',
            'serviceType': 'Brake Check & Telematics Calibration',
            'status': 'Scheduled',
            'timeSlot': 'Today · 03:15 PM · EV Bay 1',
            'estimatedCost': '₹650',
          },
          {
            'id': 'apt-003',
            'customerName': 'Vigneshwaran K.',
            'phone': '+91 97901 33445',
            'regNo': 'TN 09 BB 3344',
            'modelName': 'Aerox 155',
            'serviceType': 'General Health Inspection & Synthetic Oil Change',
            'status': 'Scheduled',
            'timeSlot': 'Today · 04:00 PM · Bay 4',
            'estimatedCost': '₹1,200',
          },
          {
            'id': 'apt-004',
            'customerName': 'Harish R.',
            'phone': '+91 98409 66778',
            'regNo': 'TN 05 AF 5566',
            'modelName': 'FZ-S Fi V4',
            'serviceType': 'First Free Service (1,000 km)',
            'status': 'Confirmed',
            'timeSlot': 'Tomorrow · 09:30 AM · Bay 1',
            'estimatedCost': '₹450',
          },
        ];
      case 'Job cards':
        return [
          {
            'id': 'jc-001',
            'jobCardNumber': 'JC-2026-0042',
            'regNo': 'TN 01 AB 1405',
            'customerName': 'Suresh Kumar',
            'phone': '+91 80155 81405',
            'modelName': 'YZF-R15 V4',
            'status': 'WorkInProgress',
            'stage': 'Work in progress',
            'bay': 'Bay 2',
            'technician': 'Suresh Kumar (Senior Tech)',
            'estimatedCost': '₹1,850',
            'approved': true,
            'items': 'Yamalube 10W-40 Synthetic (1L), Oil filter, Brake cleaning',
          },
          {
            'id': 'jc-002',
            'jobCardNumber': 'JC-2026-0039',
            'regNo': 'TN 02 CD 5678',
            'customerName': 'Meena T.',
            'phone': '+91 98411 22334',
            'modelName': 'TVS iQube Electric',
            'status': 'QualityCheckPending',
            'stage': 'QC inspection pending',
            'bay': 'EV Bay 1',
            'technician': 'Priya Raman',
            'estimatedCost': '₹650',
            'approved': true,
            'items': 'Firmware 4.2.1 sync, regenerative brake check',
          },
          {
            'id': 'jc-003',
            'jobCardNumber': 'JC-2026-0037',
            'regNo': 'TN 03 EF 4422',
            'customerName': 'Arun Prasad',
            'phone': '+91 94441 77889',
            'modelName': 'Aerox 155',
            'status': 'QualityCheckPassed',
            'stage': 'Ready for billing / invoice',
            'bay': 'Bay 3',
            'technician': 'Venkatesh S.',
            'estimatedCost': '₹3,200',
            'approved': true,
            'items': 'V-Belt inspection, brake pads replacement, washed',
          },
          {
            'id': 'jc-004',
            'jobCardNumber': 'JC-2026-0035',
            'regNo': 'TN 10 XY 7788',
            'customerName': 'Dinesh B.',
            'phone': '+91 98402 11223',
            'modelName': 'MT-15 V2',
            'status': 'Open',
            'stage': 'Vehicle received · Estimate pending',
            'bay': 'Bay 1',
            'technician': 'Unassigned',
            'estimatedCost': '₹1,400',
            'approved': false,
            'items': 'Chain sprocket slack check, oil change',
          },
        ];
      case 'Payments':
        return [
          {
            'id': 'pay-001',
            'receiptNumber': 'REC-2026-0912',
            'customerName': 'Karthik Raja',
            'phone': '+91 97900 45678',
            'type': 'Booking Advance',
            'modelName': 'TVS iQube Electric ST',
            'amount': 25000.0,
            'mode': 'UPI (GPay)',
            'txnRef': 'UPI/984712039128',
            'date': 'Today · 11:20 AM',
            'status': 'Success',
          },
          {
            'id': 'pay-002',
            'receiptNumber': 'REC-2026-0911',
            'customerName': 'Arun Prasad',
            'phone': '+91 94441 77889',
            'type': 'Workshop Service Bill',
            'modelName': 'Aerox 155 (JC-2026-0037)',
            'amount': 3200.0,
            'mode': 'Card (POS)',
            'txnRef': 'POS/AXIS/440192',
            'date': 'Today · 10:45 AM',
            'status': 'Success',
          },
          {
            'id': 'pay-003',
            'receiptNumber': 'REC-2026-0910',
            'customerName': 'Ramesh Kumar',
            'phone': '+91 98401 12345',
            'type': 'Vehicle Down Payment',
            'modelName': 'YZF-R15 V4 Racing Blue',
            'amount': 50000.0,
            'mode': 'Net Banking (HDFC)',
            'txnRef': 'HDFC78901234',
            'date': 'Yesterday · 04:30 PM',
            'status': 'Success',
          },
          {
            'id': 'pay-004',
            'receiptNumber': 'REC-2026-0909',
            'customerName': 'Gopalakrishnan',
            'phone': '+91 98400 99881',
            'type': 'Workshop Service Bill',
            'modelName': 'FZ-X (JC-2026-0033)',
            'amount': 1450.0,
            'mode': 'Cash',
            'txnRef': 'CASH/COUNTER/02',
            'date': 'Yesterday · 02:15 PM',
            'status': 'Success',
          },
        ];
      default:
        return [];
    }
  }

  List<Map<String, dynamic>> get _filteredRows {
    if (_searchQuery.trim().isEmpty) return _rows;
    final q = _searchQuery.toLowerCase();
    return _rows.where((row) {
      final name = (row['customerName'] ?? '').toString().toLowerCase();
      final model = (row['modelName'] ?? '').toString().toLowerCase();
      final phone = (row['phone'] ?? '').toString().toLowerCase();
      final reg = (row['regNo'] ?? row['jobCardNumber'] ?? row['receiptNumber'] ?? '')
          .toString()
          .toLowerCase();
      return name.contains(q) || model.contains(q) || phone.contains(q) || reg.contains(q);
    }).toList();
  }

  // --- CRUD & Action Dialogs ---

  Future<void> _addNewEntry() async {
    switch (_section) {
      case 'Leads':
        final values = await _showFormDialog(
          title: 'Add New Sales Lead',
          fields: [
            {'label': 'Customer Full Name', 'default': ''},
            {'label': 'Phone Number', 'default': '+91 '},
            {'label': 'Vehicle Model', 'default': 'YZF-R15 V4'},
            {'label': 'Budget / Price Expectation', 'default': '₹1,85,000'},
            {'label': 'Customer Notes / Timeline', 'default': 'Interested in test ride'},
          ],
        );
        if (values != null && values[0].isNotEmpty) {
          setState(() {
            _rows.insert(0, {
              'id': 'lead-${DateTime.now().millisecondsSinceEpoch}',
              'customerName': values[0],
              'phone': values[1].isEmpty ? '+91 98400 00000' : values[1],
              'modelName': values[2].isEmpty ? 'YZF-R15 V4' : values[2],
              'variantName': 'Standard',
              'status': 'New Enquiry',
              'price': values[3].isEmpty ? '₹1,80,000' : values[3],
              'priority': 'HOT',
              'notes': values[4].isEmpty ? 'Walk-in enquiry' : values[4],
              'scheduledAt': 'Just now',
            });
          });
          _showToast('Lead added successfully!');
        }
        break;

      case 'Test rides':
        final values = await _showFormDialog(
          title: 'Schedule Test Ride',
          fields: [
            {'label': 'Rider Name', 'default': ''},
            {'label': 'Phone Number', 'default': '+91 '},
            {'label': 'Bike Model', 'default': 'YZF-R15 V4'},
            {'label': 'Driving License Number', 'default': 'TN-01-2022-'},
            {'label': 'Preferred Time Slot', 'default': 'Today · 05:00 PM'},
          ],
        );
        if (values != null && values[0].isNotEmpty) {
          setState(() {
            _rows.insert(0, {
              'id': 'tr-${DateTime.now().millisecondsSinceEpoch}',
              'customerName': values[0],
              'phone': values[1],
              'modelName': values[2],
              'timeSlot': values[4],
              'status': 'Scheduled',
              'dlNumber': values[3],
              'advisor': 'Arjun S. (Sales)',
              'notes': 'Booked at counter · Helmet arranged',
            });
          });
          _showToast('Test ride scheduled!');
        }
        break;

      case 'Appointments':
        final values = await _showFormDialog(
          title: 'New Service Appointment',
          fields: [
            {'label': 'Customer Name', 'default': ''},
            {'label': 'Vehicle Reg No (e.g. TN 01 AB 1405)', 'default': 'TN 01 '},
            {'label': 'Bike Model', 'default': 'YZF-R15 V4'},
            {'label': 'Service Package', 'default': 'Periodic Maintenance 2'},
            {'label': 'Estimated Amount', 'default': '₹1,850'},
          ],
        );
        if (values != null && values[0].isNotEmpty) {
          setState(() {
            _rows.insert(0, {
              'id': 'apt-${DateTime.now().millisecondsSinceEpoch}',
              'customerName': values[0],
              'regNo': values[1],
              'modelName': values[2],
              'serviceType': values[3],
              'status': 'Vehicle Arrived',
              'timeSlot': 'Today · 04:30 PM · Bay 2',
              'estimatedCost': values[4],
            });
          });
          _showToast('Service appointment created!');
        }
        break;

      case 'Job cards':
        final values = await _showFormDialog(
          title: 'Open Workshop Job Card',
          fields: [
            {'label': 'Registration Number', 'default': 'TN 01 AB 1405'},
            {'label': 'Customer Name', 'default': ''},
            {'label': 'Bike Model', 'default': 'YZF-R15 V4'},
            {'label': 'Odometer Reading (km)', 'default': '5200'},
            {'label': 'Assigned Technician', 'default': 'Suresh Kumar'},
            {'label': 'Estimated Cost (₹)', 'default': '1850'},
          ],
        );
        if (values != null && values[0].isNotEmpty) {
          final jcNum = 'JC-2026-00${45 + Random().nextInt(50)}';
          setState(() {
            _rows.insert(0, {
              'id': 'jc-${DateTime.now().millisecondsSinceEpoch}',
              'jobCardNumber': jcNum,
              'regNo': values[0],
              'customerName': values[1].isEmpty ? 'Customer' : values[1],
              'modelName': values[2],
              'status': 'WorkInProgress',
              'stage': 'Work in progress',
              'bay': 'Bay 2',
              'technician': values[4],
              'estimatedCost': '₹${values[5]}',
              'approved': true,
              'items': 'General Service, Oil Filter, Inspection (Odo: ${values[3]} km)',
            });
          });
          _showToast('Job card $jcNum opened!');
        }
        break;

      case 'Payments':
        await _recordPayment();
        break;
    }
  }

  Future<void> _recordPayment() async {
    final values = await _showFormDialog(
      title: 'Record Received Payment',
      fields: [
        {'label': 'Customer Full Name', 'default': ''},
        {'label': 'Vehicle / Booking Ref', 'default': 'YZF-R15 V4 (Booking)'},
        {'label': 'Amount in ₹', 'default': '25000'},
        {'label': 'Payment Mode (UPI, Card, Cash, NetBanking)', 'default': 'UPI (GPay)'},
        {'label': 'Transaction Reference No', 'default': 'UPI/${Random().nextInt(90000000) + 10000000}'},
      ],
    );

    if (values != null && values[0].isNotEmpty) {
      final amt = double.tryParse(values[2].replaceAll(RegExp(r'[^0-9.]'), '')) ?? 25000.0;
      final recNum = 'REC-2026-09${20 + Random().nextInt(70)}';
      final newPayment = {
        'id': 'pay-${DateTime.now().millisecondsSinceEpoch}',
        'receiptNumber': recNum,
        'customerName': values[0],
        'phone': '+91 98401 12345',
        'type': 'Booking Advance / Service',
        'modelName': values[1],
        'amount': amt,
        'mode': values[3],
        'txnRef': values[4],
        'date': 'Just now',
        'status': 'Success',
      };

      setState(() {
        if (_section == 'Payments') {
          _rows.insert(0, newPayment);
        }
        _receipt = '$recNum · ₹$amt (${values[3]})';
      });

      _showReceiptDialog(newPayment);
    }
  }

  Future<List<String>?> _showFormDialog({
    required String title,
    required List<Map<String, String>> fields,
  }) async {
    final controllers = fields.map((f) => TextEditingController(text: f['default'])).toList();

    return showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < fields.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: controllers[i],
                    decoration: InputDecoration(
                      labelText: fields[i]['label'],
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
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
            onPressed: () => Navigator.pop(context, controllers.map((c) => c.text.trim()).toList()),
            child: const Text('Save & Submit'),
          ),
        ],
      ),
    );
  }

  void _showReceiptDialog(Map<String, dynamic> p) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Payment Receipt',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RECEIPT #${p['receiptNumber']}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 6),
              Text(
                '₹${p['amount']}',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              const Divider(height: 24),
              _receiptRow('Customer', p['customerName']),
              _receiptRow('Item / Model', p['modelName']),
              _receiptRow('Payment Mode', p['mode']),
              _receiptRow('Transaction Ref', p['txnRef']),
              _receiptRow('Dealership', 'Alagendra Yamaha Flagship'),
              _receiptRow('Status', 'VERIFIED & CREDITED'),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showToast('Receipt downloaded as PDF');
            },
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Download PDF'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Text(
            value.toString(),
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }

  void _showToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = _tokens.hasToken;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Dealer workspace', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (signedIn) ...[
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => _run(() => _load(_section)),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                      await _tokens.clear();
                      setState(() {
                        _section = 'Leads';
                        _rows = [];
                        _receipt = null;
                      });
                    }),
              child: const Text('Sign out', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: signedIn ? _buildDashboard() : _buildLoginForm(),
        ),
      ),
      floatingActionButton: signedIn
          ? FloatingActionButton.extended(
              onPressed: _addNewEntry,
              icon: const Icon(Icons.add_rounded),
              label: Text(_fabLabel()),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  String _fabLabel() {
    switch (_section) {
      case 'Leads':
        return 'New Lead';
      case 'Test rides':
        return 'Book Ride';
      case 'Appointments':
        return 'New Service';
      case 'Job cards':
        return 'Open Job Card';
      case 'Payments':
        return 'Collect Payment';
      default:
        return 'Add';
    }
  }

  // --- SIGN IN SCREEN ---

  Widget _buildLoginForm() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        if (_busy) const LinearProgressIndicator(),
        if (_error != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(_error!, style: const TextStyle(color: Color(0xFF991B1B))),
          ),
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
              avatar: const Icon(Icons.verified_user_rounded, size: 16),
              label: const Text('User 8015581405'),
              onPressed: () => setState(() {
                _dealer.text = 'ALAGENDRA';
                _username.text = '8015581405';
                _password.text = '123456';
              }),
            ),
            ActionChip(
              avatar: const Icon(Icons.manage_accounts_rounded, size: 16),
              label: const Text('Branch Manager'),
              onPressed: () => setState(() {
                _dealer.text = AppConfig.dealerCode.isNotEmpty ? AppConfig.dealerCode : 'ALAGENDRA';
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
            helperText: kDebugMode ? 'Also: advisor.kiran, sales.arjun, tech.suresh' : null,
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
      ],
    );
  }

  // --- AUTHENTICATED DEALER DASHBOARD ---

  Widget _buildDashboard() {
    final staffName = _profile['fullName']?.toString() ?? 'Dealer Manager';
    final branchName = _profile['branchName']?.toString() ?? 'Kotchadai Branch, Madurai';
    final filtered = _filteredRows;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        if (_busy) const LinearProgressIndicator(),

        // Staff profile card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    staffName.length >= 2 ? staffName.substring(0, 2).toUpperCase() : 'DM',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staffName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Alagendra Yamaha · $branchName',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${isManager ? "Branch Manager" : (isAdvisor ? "Service Advisor" : "Staff")} · ${_roles.join(" · ")}',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Quick Metric Pills Banner
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _metricTile('Open Leads', '14', '3 Hot', const Color(0xFF3B82F6), Icons.trending_up_rounded),
              _metricTile('Test Rides', '4', '1 Out', const Color(0xFF8B5CF6), Icons.two_wheeler_rounded),
              _metricTile('In Workshop', '6', '2 QC', const Color(0xFF10B981), Icons.build_circle_rounded),
              _metricTile('Collections', '₹2.45L', 'Today', const Color(0xFFF59E0B), Icons.account_balance_wallet_rounded),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Section Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final section in _allSections)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Icon(
                      _sectionIcon(section),
                      size: 16,
                      color: _section == section ? Colors.white : const Color(0xFF475569),
                    ),
                    label: Text(
                      section,
                      style: TextStyle(
                        color: _section == section ? Colors.white : const Color(0xFF0F172A),
                        fontWeight: _section == section ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    selected: _section == section,
                    selectedColor: Theme.of(context).colorScheme.primary,
                    backgroundColor: Colors.white,
                    showCheckmark: false,
                    side: BorderSide(
                      color: _section == section ? Theme.of(context).colorScheme.primary : const Color(0xFFCBD5E1),
                    ),
                    onSelected: _busy
                        ? null
                        : (_) {
                            setState(() => _section = section);
                            _run(() => _load(section));
                          },
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Search and Actions Bar
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search $_section (name, bike, phone)...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          }),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (_receipt != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF059669)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Last recorded receipt: $_receipt',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF065F46)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF059669)),
                  onPressed: () => setState(() => _receipt = null),
                ),
              ],
            ),
          ),

        // Items list
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.only(top: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Icon(_sectionIcon(_section), size: 48, color: const Color(0xFF94A3B8)),
                const SizedBox(height: 12),
                Text(
                  'No records found in $_section',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tap the button below to add a new record to your workspace.',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _addNewEntry,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text('Add first $_section record'),
                ),
              ],
            ),
          )
        else
          for (final row in filtered)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildOperationCard(row),
            ),
      ],
    );
  }

  IconData _sectionIcon(String s) {
    switch (s) {
      case 'Leads':
        return Icons.contact_page_rounded;
      case 'Test rides':
        return Icons.two_wheeler_rounded;
      case 'Appointments':
        return Icons.event_available_rounded;
      case 'Job cards':
        return Icons.engineering_rounded;
      case 'Payments':
        return Icons.payments_rounded;
      default:
        return Icons.folder_rounded;
    }
  }

  Widget _metricTile(String label, String value, String sub, Color color, IconData icon) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              const SizedBox(width: 4),
              Text('($sub)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  // --- OPERATION CARDS ---

  Widget _buildOperationCard(Map<String, dynamic> row) {
    switch (_section) {
      case 'Leads':
        return _buildLeadCard(row);
      case 'Test rides':
        return _buildTestRideCard(row);
      case 'Appointments':
        return _buildAppointmentCard(row);
      case 'Job cards':
        return _buildJobCard(row);
      case 'Payments':
        return _buildPaymentCard(row);
      default:
        return Card(child: ListTile(title: Text(row.toString())));
    }
  }

  // 1. LEAD CARD
  Widget _buildLeadCard(Map<String, dynamic> row) {
    final isHot = row['priority'] == 'HOT';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isHot ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row['customerName'],
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${row['phone']} · ${row['scheduledAt']}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              _badge(row['status'], const Color(0xFF2563EB)),
              if (row['priority'] != null) ...[
                const SizedBox(width: 6),
                _badge(row['priority'], isHot ? const Color(0xFFDC2626) : const Color(0xFFF59E0B)),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.two_wheeler_rounded, size: 18, color: Color(0xFF475569)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${row['modelName']} (${row['variantName'] ?? ''})',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  row['price'] ?? '',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          ),
          if (row['notes'] != null) ...[
            const SizedBox(height: 8),
            Text(
              row['notes'],
              style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showToast('Dialing ${row['phone']}... Contact recorded.'),
                icon: const Icon(Icons.call_rounded, size: 16),
                label: const Text('Call'),
                style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => row['status'] = 'Quotation Shared');
                  _showToast('Official on-road quotation sent via WhatsApp!');
                },
                icon: const Icon(Icons.share_rounded, size: 16),
                label: const Text('Share Quote'),
                style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
              FilledButton.tonalIcon(
                onPressed: () async {
                  final day = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (day != null) {
                    setState(() => row['status'] = 'Test Ride Booked');
                    _showToast('Test ride scheduled for ${row['customerName']}!');
                  }
                },
                icon: const Icon(Icons.speed_rounded, size: 16),
                label: const Text('Schedule Ride'),
                style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. TEST RIDE CARD
  Widget _buildTestRideCard(Map<String, dynamic> row) {
    final isInProgress = row['status'] == 'In Progress';
    final isDone = row['status'] == 'Completed';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isInProgress ? const Color(0xFF8B5CF6) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row['customerName'],
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${row['phone']} · ${row['timeSlot']}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              _badge(
                row['status'],
                isDone
                    ? const Color(0xFF10B981)
                    : (isInProgress ? const Color(0xFF8B5CF6) : const Color(0xFF3B82F6)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.sports_motorsports_rounded, size: 18, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  row['modelName'],
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                'DL: ${row['dlNumber'] ?? 'TN-01-••••'}',
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (row['notes'] != null) ...[
            const SizedBox(height: 6),
            Text(
              row['notes'],
              style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (!isDone && !isInProgress)
                FilledButton.icon(
                  onPressed: () {
                    setState(() => row['status'] = 'In Progress');
                    _showToast('Demo bike checked out! Test ride started.');
                  },
                  icon: const Icon(Icons.key_rounded, size: 16),
                  label: const Text('Check Out Bike'),
                  style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
              if (isInProgress)
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      row['status'] = 'Completed';
                      row['notes'] = 'Completed safely · Customer gave 5/5 stars rating';
                    });
                    _showToast('Test ride completed & feedback saved!');
                  },
                  icon: const Icon(Icons.check_circle_rounded, size: 16),
                  label: const Text('Complete Ride'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              OutlinedButton.icon(
                onPressed: () => _showToast('Driving License verified and photo attached.'),
                icon: const Icon(Icons.badge_rounded, size: 16),
                label: const Text('Verify DL'),
                style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. APPOINTMENT CARD
  Widget _buildAppointmentCard(Map<String, dynamic> row) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${row['customerName']} · ${row['regNo'] ?? ''}',
                      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${row['modelName']} · ${row['timeSlot']}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              _badge(row['status'], const Color(0xFF0284C7)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.handyman_rounded, size: 18, color: Color(0xFF475569)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    row['serviceType'],
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  row['estimatedCost'] ?? '',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () async {
                  final values = await _showFormDialog(
                    title: 'Vehicle Check-in & Open Job Card',
                    fields: [
                      {'label': 'Odometer Reading (km)', 'default': '5200'},
                      {'label': 'Fuel / Battery Level %', 'default': '75%'},
                      {'label': 'Customer Complaints / Notes', 'default': 'Regular general service'},
                    ],
                  );
                  if (values != null) {
                    setState(() {
                      row['status'] = 'In Workshop Bay';
                    });
                    _showToast('Vehicle checked in! Bay allocated.');
                  }
                },
                icon: const Icon(Icons.login_rounded, size: 16),
                label: const Text('Check In Vehicle'),
                style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
              OutlinedButton.icon(
                onPressed: () => _showToast('Dialing customer ${row['phone']}...'),
                icon: const Icon(Icons.call_rounded, size: 16),
                label: const Text('Contact Customer'),
                style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. JOB CARD
  Widget _buildJobCard(Map<String, dynamic> row) {
    final status = row['status']?.toString() ?? 'Open';
    final isWip = status == 'WorkInProgress';
    final isQc = status == 'QualityCheckPending' || status == 'QualityCheckPassed';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isWip ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
          width: isWip ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  row['jobCardNumber'] ?? '',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${row['regNo']} (${row['modelName']})',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
              _badge(row['stage'] ?? status, isWip ? const Color(0xFF10B981) : const Color(0xFF2563EB)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Customer: ${row['customerName']} · Tech: ${row['technician']} (${row['bay'] ?? 'Bay 1'})',
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
          ),
          if (row['items'] != null) ...[
            const SizedBox(height: 6),
            Text(
              'Parts/Work: ${row['items']}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estimate: ${row['estimatedCost']}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              if (row['approved'] == true)
                const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                    SizedBox(width: 4),
                    Text('Customer Approved', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (status == 'Open')
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      row['status'] = 'WorkInProgress';
                      row['stage'] = 'Work in progress';
                      row['technician'] = 'Suresh Kumar';
                    });
                    _showToast('Estimate approved & assigned to technician Suresh.');
                  },
                  icon: const Icon(Icons.assignment_turned_in_rounded, size: 16),
                  label: const Text('Approve & Start Work'),
                  style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
              if (isWip)
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      row['status'] = 'QualityCheckPending';
                      row['stage'] = 'QC inspection pending';
                    });
                    _showToast('Work completed! Sent to Advisor for Quality Check.');
                  },
                  icon: const Icon(Icons.checklist_rounded, size: 16),
                  label: const Text('Submit for QC'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              if (isQc)
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      row['status'] = 'Billed';
                      row['stage'] = 'Tax Invoice Generated';
                    });
                    _showToast('QC passed! Tax invoice ready for delivery.');
                  },
                  icon: const Icon(Icons.receipt_long_rounded, size: 16),
                  label: const Text('Pass QC & Invoice'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              OutlinedButton.icon(
                onPressed: () => _showToast('Inspection checklist opened.'),
                icon: const Icon(Icons.list_alt_rounded, size: 16),
                label: const Text('Checklist'),
                style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 5. PAYMENT CARD
  Widget _buildPaymentCard(Map<String, dynamic> row) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${row['receiptNumber']} · ${row['type']}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      row['customerName'],
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${row['amount']}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.payment_rounded, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(
                  '${row['mode']} · Ref: ${row['txnRef']}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
                const Spacer(),
                Text(
                  row['date'] ?? '',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: () => _showReceiptDialog(row),
                icon: const Icon(Icons.receipt_rounded, size: 16),
                label: const Text('View Receipt'),
                style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showToast('Receipt shared to customer WhatsApp / SMS!'),
                icon: const Icon(Icons.share_rounded, size: 16),
                label: const Text('Share'),
                style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}
