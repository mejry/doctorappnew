import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/features/appointment/models/appointment.dart';
import 'package:frontend/features/appointment/services/appointment_service.dart';
import 'package:frontend/shared/widgets/permission_widget.dart';

class AppointmentListScreen extends StatefulWidget {
  final VoidCallback onAddAppointmentPressed;

  const AppointmentListScreen({
    super.key,
    required this.onAddAppointmentPressed,
  });

  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  List<Appointment> _appointments = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedType;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    try {
      final appointments = await _appointmentService.getAllAppointments(
        search: _searchQuery,
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

  List<Appointment> get _filteredAppointments {
    return _appointments.where((appointment) {
      final matchesSearch = _searchQuery.isEmpty ||
          appointment.patientName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          appointment.doctorName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          appointment.type
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
      final matchesStatus =
          _selectedStatus == null || appointment.status == _selectedStatus;
      final matchesType =
          _selectedType == null || appointment.type == _selectedType;
      return matchesSearch && matchesStatus && matchesType;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return PermissionWidget(
      permission: 'view_appointment',
      fallback: _buildAccessDenied(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('Appointments',
              style: TextStyle(color: Colors.black)),
          actions: [
            Container(
              width: 260,
              height: 40,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: TextField(
                onChanged: (value) => setState(() {
                  _searchQuery = value;
                }),
                decoration: InputDecoration(
                  hintText: 'Search appointments...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
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
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 12),
                        child: const Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text('Date',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('Patient',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('Doctor',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text('Type',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text('Status',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text('Duration',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, thickness: 1),
                      Expanded(
                        child: _filteredAppointments.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24.0),
                                  child: Text(
                                    'No appointments found',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _filteredAppointments.length,
                                itemBuilder: (context, index) {
                                  final appointment =
                                      _filteredAppointments[index];
                                  return _buildAppointmentRow(appointment);
                                },
                              ),
                      ),
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
                            Text('Total: ${_filteredAppointments.length} appointments'),
                            Row(
                              children: [
                                _buildStatusCount('Scheduled', AppColors.primary),
                                const SizedBox(width: 16),
                                _buildStatusCount('Completed', Colors.green),
                                const SizedBox(width: 16),
                                _buildStatusCount('Cancelled', Colors.red),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildAppointmentRow(Appointment appointment) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  DateFormat('yyyy-MM-dd').format(appointment.date) + '\n${appointment.time}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  appointment.patientName,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  appointment.doctorName,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  appointment.type,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  appointment.status,
                  style: TextStyle(
                    fontSize: 13,
                    color: appointment.status == 'Cancelled'
                        ? Colors.red
                        : AppColors.primary,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '${appointment.duration}m',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1),
      ],
    );
  }

  Widget _buildStatusCount(String status, Color color) {
    final count = _filteredAppointments
        .where((appointment) => appointment.status == status)
        .length;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text('$status: $count'),
      ],
    );
  }

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
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  const DropdownMenuItem(
                      value: 'Consultation', child: Text('Consultation')),
                  const DropdownMenuItem(
                      value: 'Follow-up', child: Text('Follow-up')),
                  const DropdownMenuItem(
                      value: 'Emergency', child: Text('Emergency')),
                  const DropdownMenuItem(value: 'Test', child: Text('Test')),
                  const DropdownMenuItem(value: 'Procedure', child: Text('Procedure')),
                ],
                onChanged: (value) {
                  setState(() => _selectedType = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  const DropdownMenuItem(value: 'Scheduled', child: Text('Scheduled')),
                  const DropdownMenuItem(value: 'Checked-in', child: Text('Checked-in')),
                  const DropdownMenuItem(value: 'In-progress', child: Text('In-progress')),
                  const DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                  const DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                ],
                onChanged: (value) {
                  setState(() => _selectedStatus = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
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
            Text(
              'Access Denied',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'You do not have permission to view appointments.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
