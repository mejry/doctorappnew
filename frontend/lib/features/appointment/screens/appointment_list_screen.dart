import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/core/services/session_manager.dart';
import 'package:frontend/features/appointment/models/appointment.dart';
import 'package:frontend/features/appointment/services/appointment_service.dart';
import 'package:frontend/shared/widgets/permission_widget.dart';

class AppointmentListScreen extends StatefulWidget {
  final VoidCallback onAddAppointmentPressed;
  final Function(Appointment)? onCompleteConsultation;

  const AppointmentListScreen({
    super.key,
    required this.onAddAppointmentPressed,
    this.onCompleteConsultation,
  });

  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final SessionManager _session = SessionManager();

  List<Appointment> _appointments = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedType;
  String? _selectedStatus;

  // Date-range filter
  String _dateFilter = 'all'; // all, today, week, month

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    try {
      final appointments = await _appointmentService.getAllAppointments(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: _selectedStatus,
        type: _selectedType,
      );
      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading appointments: $e')),
        );
      }
    }
  }

  // ─── DATE FILTERING ─────────────────────────────────────────────
  List<Appointment> get _filteredAppointments {
    final now = DateTime.now();
    return _appointments.where((a) {
      // text search
      final matchesSearch = _searchQuery.isEmpty ||
          a.patientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a.doctorName.toLowerCase().contains(_searchQuery.toLowerCase());
      // status
      final matchesStatus = _selectedStatus == null || a.status == _selectedStatus;
      // type
      final matchesType = _selectedType == null || a.type == _selectedType;
      // date range
      bool matchesDate = true;
      if (_dateFilter == 'today') {
        matchesDate = a.date.year == now.year &&
            a.date.month == now.month &&
            a.date.day == now.day;
      } else if (_dateFilter == 'week') {
        final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        matchesDate = a.date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
            a.date.isBefore(endOfWeek);
      } else if (_dateFilter == 'month') {
        matchesDate = a.date.year == now.year && a.date.month == now.month;
      }
      return matchesSearch && matchesStatus && matchesType && matchesDate;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  // ─── STATUS HELPERS ──────────────────────────────────────────────
  Color _statusColor(String status) {
    switch (status) {
      case 'Scheduled':
        return Colors.blue;
      case 'Checked-in':
        return Colors.orange;
      case 'In-progress':
        return Colors.deepPurple;
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      case 'No-show':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Scheduled':
        return Icons.schedule;
      case 'Checked-in':
        return Icons.how_to_reg;
      case 'In-progress':
        return Icons.play_circle_fill;
      case 'Completed':
        return Icons.check_circle;
      case 'Cancelled':
        return Icons.cancel;
      case 'No-show':
        return Icons.person_off;
      default:
        return Icons.info;
    }
  }

  // ─── ROLE CHECK ──────────────────────────────────────────────────
  String get _userRole => _session.userInfo?['role'] ?? '';
  bool get _isSecretary => ['Secretary', 'Receptionist', 'Admin'].contains(_userRole);
  bool get _isDoctor => ['Doctor', 'Admin'].contains(_userRole);

  // ─── STATUS ACTIONS ──────────────────────────────────────────────
  Future<void> _checkInPatient(Appointment a) async {
    try {
      await _appointmentService.checkInPatient(a.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${a.patientName} checked in ✅'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadAppointments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _startConsultation(Appointment a) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start Consultation'),
        content: Text('Start consultation for ${a.patientName}?\nThis will automatically create a consultation record.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Start'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _appointmentService.startConsultation(a.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Consultation started for ${a.patientName} 🩺'),
            backgroundColor: Colors.deepPurple,
          ),
        );
      }
      _loadAppointments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _completeConsultation(Appointment a) async {
    if (widget.onCompleteConsultation != null) {
      widget.onCompleteConsultation!(a);
      return;
    }

    final notesCtrl = TextEditingController();
    final durationCtrl = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Consultation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Complete consultation for ${a.patientName}?'),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: durationCtrl,
              decoration: const InputDecoration(
                labelText: 'Actual duration (minutes)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _appointmentService.completeConsultation(
        a.id!,
        notes: notesCtrl.text.isNotEmpty ? notesCtrl.text : null,
        actualDuration: int.tryParse(durationCtrl.text),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Consultation completed for ${a.patientName} ✅'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadAppointments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _cancelAppointment(Appointment a) async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cancel appointment for ${a.patientName}?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Cancellation reason *',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Back')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (reasonCtrl.text.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Reason is required')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Cancel Appointment'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _appointmentService.cancelAppointment(a.id!, reasonCtrl.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment cancelled for ${a.patientName}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      _loadAppointments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ─── BUILD ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PermissionWidget(
      permission: 'view_appointment',
      fallback: _buildAccessDenied(),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: const Text('Appointments', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          actions: [
            Container(
              width: 240,
              height: 40,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFilterDialog),
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAppointments),
            const SizedBox(width: 8),
            PermissionAddButton(
              permission: 'create_appointment',
              text: 'New Appointment',
              onPressed: widget.onAddAppointmentPressed,
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // ─── DATE FILTER CHIPS ───────────────────────
                    _buildDateFilterChips(),
                    const SizedBox(height: 12),
                    // ─── STATUS FILTER CHIPS ─────────────────────
                    _buildStatusFilterChips(),
                    const SizedBox(height: 12),
                    // ─── TABLE ───────────────────────────────────
                    Expanded(child: _buildAppointmentTable()),
                  ],
                ),
              ),
      ),
    );
  }

  // ─── DATE FILTER CHIPS ─────────────────────────────────────────
  Widget _buildDateFilterChips() {
    final filters = {
      'all': 'All dates',
      'today': "Today",
      'week': 'This week',
      'month': 'This month',
    };

    return Row(
      children: [
        const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        ...filters.entries.map((e) {
          final selected = _dateFilter == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(e.value),
              selected: selected,
              selectedColor: AppColors.primary.withOpacity(0.2),
              onSelected: (_) {
                setState(() => _dateFilter = e.key);
              },
            ),
          );
        }),
      ],
    );
  }

  // ─── STATUS FILTER CHIPS ───────────────────────────────────────
  Widget _buildStatusFilterChips() {
    final statuses = ['Scheduled', 'Checked-in', 'In-progress', 'Completed', 'Cancelled', 'No-show'];

    return Row(
      children: [
        const Icon(Icons.flag, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        FilterChip(
          label: const Text('All'),
          selected: _selectedStatus == null,
          selectedColor: AppColors.secondary.withOpacity(0.2),
          onSelected: (_) {
            setState(() => _selectedStatus = null);
            _loadAppointments();
          },
        ),
        const SizedBox(width: 6),
        ...statuses.map((s) {
          final selected = _selectedStatus == s;
          final count = _appointments.where((a) => a.status == s).length;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              avatar: Icon(_statusIcon(s), size: 16, color: _statusColor(s)),
              label: Text('$s ($count)'),
              selected: selected,
              selectedColor: _statusColor(s).withOpacity(0.15),
              onSelected: (_) {
                setState(() => _selectedStatus = selected ? null : s);
                _loadAppointments();
              },
            ),
          );
        }),
      ],
    );
  }

  // ─── TABLE ─────────────────────────────────────────────────────
  Widget _buildAppointmentTable() {
    final items = _filteredAppointments;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // header
          Container(
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('Date / Time', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Patient', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Doctor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('Type', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Actions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          const Divider(height: 1),
          // rows
          Expanded(
            child: items.isEmpty
                ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No appointments found', style: TextStyle(color: Colors.grey, fontSize: 16))))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (ctx, i) => _buildRow(items[i]),
                  ),
          ),
          // footer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: ${items.length} appointments'),
                Row(
                  children: [
                    _buildStatusDot('Scheduled', Colors.blue),
                    const SizedBox(width: 12),
                    _buildStatusDot('Checked-in', Colors.orange),
                    const SizedBox(width: 12),
                    _buildStatusDot('In-progress', Colors.deepPurple),
                    const SizedBox(width: 12),
                    _buildStatusDot('Completed', Colors.green),
                    const SizedBox(width: 12),
                    _buildStatusDot('Cancelled', Colors.red),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(Appointment a) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Date / Time
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('yyyy-MM-dd').format(a.date), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(a.time, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              // Patient
              Expanded(flex: 2, child: Text(a.patientName, style: const TextStyle(fontSize: 13))),
              // Doctor
              Expanded(flex: 2, child: Text(a.doctorName, style: const TextStyle(fontSize: 13))),
              // Type
              Expanded(flex: 1, child: Text(a.type, style: const TextStyle(fontSize: 13))),
              // Status chip
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    avatar: Icon(_statusIcon(a.status), size: 16, color: _statusColor(a.status)),
                    label: Text(a.status, style: TextStyle(fontSize: 12, color: _statusColor(a.status), fontWeight: FontWeight.w600)),
                    backgroundColor: _statusColor(a.status).withOpacity(0.1),
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              // Actions
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _buildActions(a),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  // ─── ACTION BUTTONS ────────────────────────────────────────────
  List<Widget> _buildActions(Appointment a) {
    final actions = <Widget>[];

    // Secretary: Scheduled → Check-in
    if (_isSecretary && a.status == 'Scheduled') {
      actions.add(
        Tooltip(
          message: 'Check-in patient',
          child: IconButton(
            icon: const Icon(Icons.how_to_reg, color: Colors.orange, size: 20),
            onPressed: () => _checkInPatient(a),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
        ),
      );
    }

    // Doctor: Checked-in → Start Consultation (In-progress)
    if (_isDoctor && a.status == 'Checked-in') {
      actions.add(
        Tooltip(
          message: 'Start Consultation',
          child: IconButton(
            icon: const Icon(Icons.play_circle_fill, color: Colors.deepPurple, size: 20),
            onPressed: () => _startConsultation(a),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
        ),
      );
    }

    // Doctor: In-progress → Complete
    if (_isDoctor && a.status == 'In-progress') {
      actions.add(
        Tooltip(
          message: 'Complete Consultation',
          child: IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 20),
            onPressed: () => _completeConsultation(a),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
        ),
      );
    }

    // Cancel (available for Scheduled / Checked-in)
    if ((a.status == 'Scheduled' || a.status == 'Checked-in') && (_isSecretary || _isDoctor)) {
      actions.add(
        Tooltip(
          message: 'Cancel Appointment',
          child: IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
            onPressed: () => _cancelAppointment(a),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
        ),
      );
    }

    if (actions.isEmpty) {
      actions.add(Text(
        a.status == 'Completed' ? 'Done' : '—',
        style: TextStyle(color: Colors.grey[400], fontSize: 12),
      ));
    }

    return actions;
  }

  Widget _buildStatusDot(String status, Color color) {
    final count = _filteredAppointments.where((a) => a.status == status).length;
    return Row(
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 4),
        Text('$count', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }

  // ─── FILTER DIALOG ──────────────────────────────────────────────
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter Appointments'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: 'Consultation', child: Text('Consultation')),
                  DropdownMenuItem(value: 'Follow-up', child: Text('Follow-up')),
                  DropdownMenuItem(value: 'Emergency', child: Text('Emergency')),
                  DropdownMenuItem(value: 'Test', child: Text('Test')),
                  DropdownMenuItem(value: 'Procedure', child: Text('Procedure')),
                ],
                onChanged: (v) => setState(() => _selectedType = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: 'Scheduled', child: Text('Scheduled')),
                  DropdownMenuItem(value: 'Checked-in', child: Text('Checked-in')),
                  DropdownMenuItem(value: 'In-progress', child: Text('In-progress')),
                  DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                  DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                ],
                onChanged: (v) => setState(() => _selectedStatus = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedType = null;
                  _selectedStatus = null;
                });
                Navigator.pop(context);
                _loadAppointments();
              },
              child: const Text('Clear Filters'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                Navigator.pop(context);
                _loadAppointments();
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccessDenied() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Appointments', style: TextStyle(color: Colors.black)),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text('Access Denied',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey)),
            SizedBox(height: 10),
            Text('You do not have permission to view appointments.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
