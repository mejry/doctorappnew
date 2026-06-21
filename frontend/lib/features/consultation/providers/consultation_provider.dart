// lib/features/consultation/providers/consultation_provider.dart - MISE À JOUR
import 'package:flutter/foundation.dart';
import '../models/consultation.dart';
import '../services/consultation_service.dart';

class ConsultationProvider with ChangeNotifier {
  final ConsultationService _consultationService = ConsultationService();

  List<Consultation> _consultations = [];
  Consultation? _selectedConsultation;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Consultation> get consultations => _consultations;
  Consultation? get selectedConsultation => _selectedConsultation;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all consultations
  Future<void> loadConsultations() async {
    _setLoading(true);
    try {
      _consultations = await _consultationService.getAllConsultations();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Load consultations by patient
  Future<void> loadConsultationsByPatient(String patientId) async {
    _setLoading(true);
    try {
      _consultations =
          await _consultationService.getConsultationsByPatientId(patientId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // 🆕 NOUVELLE MÉTHODE: Add consultation with automatic prescription creation
  Future<Map<String, String?>> addConsultationWithPrescription(
      Consultation consultation) async {
    _setLoading(true);
    try {
      final newConsultation =
          await _consultationService.createConsultation(consultation);
      _consultations.add(newConsultation);
      _error = null;
      notifyListeners();

      // Return both consultation and prescription IDs
      return {
        'consultationId': newConsultation.id,
        'prescriptionId':
            null, // Will be set later when prescription is created
      };
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return {
        'consultationId': null,
        'prescriptionId': null,
      };
    } finally {
      _setLoading(false);
    }
  }

  // Add consultation (original method)
  Future<String?> addConsultation(Consultation consultation) async {
    _setLoading(true);
    try {
      final newConsultation =
          await _consultationService.createConsultation(consultation);
      _consultations.add(newConsultation);
      _error = null;
      notifyListeners();
      return newConsultation.id;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Update consultation
  Future<bool> updateConsultation(String id, Consultation consultation) async {
    _setLoading(true);
    try {
      final updatedConsultation =
          await _consultationService.updateConsultation(id, consultation);
      final index = _consultations.indexWhere((c) => c.id == id);
      if (index != -1) {
        _consultations[index] = updatedConsultation;
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete consultation
  Future<bool> deleteConsultation(String id) async {
    _setLoading(true);
    try {
      await _consultationService.deleteConsultation(id);
      _consultations.removeWhere((c) => c.id == id);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 🆕 NOUVELLE MÉTHODE: Get consultation by ID
  Future<Consultation?> getConsultationById(String id) async {
    try {
      // Check if already loaded
      final existingConsultation = _consultations.firstWhere(
        (c) => c.id == id,
        orElse: () => throw StateError('Not found'),
      );
      return existingConsultation;
    } catch (e) {
      // If not found in memory, fetch from service
      try {
        return await _consultationService.getConsultationById(id);
      } catch (e) {
        _error = e.toString();
        notifyListeners();
        return null;
      }
    }
  }

  // Select consultation
  void selectConsultation(Consultation consultation) {
    _selectedConsultation = consultation;
    notifyListeners();
  }

  // 🆕 NOUVELLE MÉTHODE: Clear selected consultation
  void clearSelectedConsultation() {
    _selectedConsultation = null;
    notifyListeners();
  }

  // 🆕 NOUVELLE MÉTHODE: Refresh consultations
  Future<void> refreshConsultations() async {
    await loadConsultations();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // 🆕 NOUVELLE MÉTHODE: Clear all data
  void clearData() {
    _consultations.clear();
    _selectedConsultation = null;
    _error = null;
    notifyListeners();
  }
}
