// lib/features/prescription/providers/prescription_provider.dart - VERSION MISE À JOUR
import 'package:flutter/foundation.dart';
import '../models/prescription.dart';
import '../services/prescription_service.dart';

class PrescriptionProvider with ChangeNotifier {
  final PrescriptionService _prescriptionService = PrescriptionService();

  List<Prescription> _prescriptions = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Prescription> get prescriptions => _prescriptions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasPrescriptions => _prescriptions.isNotEmpty;

  /// Load all prescriptions
  Future<void> loadPrescriptions() async {
    _setLoading(true);
    _clearError();

    try {
      _prescriptions = await _prescriptionService.getAllPrescriptions();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load prescriptions: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load prescriptions by consultation ID
  Future<void> loadPrescriptionsByConsultation(String consultationId) async {
    _setLoading(true);
    _clearError();

    try {
      _prescriptions = await _prescriptionService
          .getPrescriptionsByConsultation(consultationId);

      notifyListeners();
    } catch (e) {
      _setError('Failed to load prescriptions for consultation: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new prescription
  Future<bool> createPrescription(Map<String, dynamic> prescriptionData) async {
    try {
      final newPrescription =
          await _prescriptionService.createPrescription(prescriptionData);
      _prescriptions.insert(0, newPrescription); // Add to beginning of list
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to create prescription: $e');
      return false;
    }
  }

  /// Update prescription
  Future<bool> updatePrescription(
      String id, Map<String, dynamic> prescriptionData) async {
    try {
      final updatedPrescription =
          await _prescriptionService.updatePrescription(id, prescriptionData);
      final index = _prescriptions.indexWhere((p) => p.id == id);
      if (index != -1) {
        _prescriptions[index] = updatedPrescription;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update prescription: $e');
      return false;
    }
  }

  /// Delete prescription
  Future<bool> deletePrescription(String id) async {
    try {
      final success = await _prescriptionService.deletePrescription(id);
      if (success) {
        _prescriptions.removeWhere((p) => p.id == id);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Failed to delete prescription: $e');
      return false;
    }
  }

  /// Update prescription status
  Future<bool> updatePrescriptionStatus(
      String prescriptionId, String newStatus) async {
    try {
      // Find the prescription
      final prescription =
          _prescriptions.firstWhere((p) => p.id == prescriptionId);

      // Update the prescription data
      final updatedData = {
        'prescriptionInfo': {
          'type': prescription.prescriptionInfo.type,
          'status': newStatus, // Update status
          'date': prescription.prescriptionInfo.date.toIso8601String(),
          'time': prescription.prescriptionInfo.time,
          'validityDays': prescription.prescriptionInfo.validityDays,
          'notes': prescription.prescriptionInfo.notes,
        },
        'medications': prescription.medications
            .map((med) => {
                  ...(med.customMedication != null
                      ? {
                          'customMedication': {
                            'name': med.customMedication!.name,
                            'description': med.customMedication!.description,
                          }
                        }
                      : {
                          'medication': med.medication,
                        }),
                  'dosage': {
                    'strength': med.dosage.strength,
                    'frequency': med.dosage.frequency,
                    'duration': med.dosage.duration,
                    'route': med.dosage.route,
                    'instructions': med.dosage.instructions,
                  },
                })
            .toList(),
      };

      return await updatePrescription(prescriptionId, updatedData);
    } catch (e) {
      _setError('Failed to update prescription status: $e');
      return false;
    }
  }

  /// Export prescription as PDF
  Future<bool> exportPrescriptionAsPDF(String prescriptionId) async {
    try {
      final success =
          await _prescriptionService.exportPrescriptionAsPDF(prescriptionId);

      return success;
    } catch (e) {
      _setError('Failed to export prescription as PDF: $e');
      return false;
    }
  }

  /// Search prescriptions
  Future<void> searchPrescriptions(String query) async {
    if (query.trim().isEmpty) {
      await loadPrescriptions();
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      _prescriptions = await _prescriptionService.searchPrescriptions(query);
      notifyListeners();
    } catch (e) {
      _setError('Failed to search prescriptions: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get prescription by ID
  Prescription? getPrescriptionById(String id) {
    try {
      return _prescriptions.firstWhere((prescription) => prescription.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get prescription statistics
  Map<String, int> get prescriptionStatistics {
    if (_prescriptions.isEmpty) {
      return {
        'Pending': 0,
        'Active': 0,
        'Completed': 0,
        'Cancelled': 0,
        'Expired': 0
      };
    }

    final stats = <String, int>{};
    for (final prescription in _prescriptions) {
      final status = prescription.prescriptionInfo.status;
      stats[status] = (stats[status] ?? 0) + 1;
    }

    return {
      'Pending': stats['Pending'] ?? 0,
      'Active': stats['Active'] ?? 0,
      'Completed': stats['Completed'] ?? 0,
      'Cancelled': stats['Cancelled'] ?? 0,
      'Expired': stats['Expired'] ?? 0,
    };
  }

  /// Get prescriptions by status
  List<Prescription> getPrescriptionsByStatus(String status) {
    return _prescriptions
        .where((prescription) => prescription.prescriptionInfo.status == status)
        .toList();
  }

  /// Get recent prescriptions
  List<Prescription> getRecentPrescriptions({int limit = 10}) {
    final sortedPrescriptions = List<Prescription>.from(_prescriptions);
    sortedPrescriptions.sort(
        (a, b) => b.prescriptionInfo.date.compareTo(a.prescriptionInfo.date));
    return sortedPrescriptions.take(limit).toList();
  }

  /// Refresh data
  Future<void> refreshData() async {
    await loadPrescriptions();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear all data
  void clearData() {
    _prescriptions.clear();
    _error = null;
    notifyListeners();
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
