// lib/features/patient/providers/patient_provider.dart - VERSION AMÉLIORÉE
import 'package:flutter/foundation.dart';
import '../models/patient.dart';
import '../models/medical_history.dart';
import '../services/patient_service.dart';

class PatientProvider with ChangeNotifier {
  final PatientService _patientService = PatientService();

  List<Patient> _patients = [];
  Patient? _selectedPatient;
  List<MedicalHistory> _medicalHistories = [];
  bool _isLoading = false;
  String? _error;
  int _currentMonthPatientCount = 0;

  // Getters
  List<Patient> get patients => _patients;
  Patient? get selectedPatient => _selectedPatient;
  List<MedicalHistory> get medicalHistories => _medicalHistories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentMonthPatientCount => _currentMonthPatientCount;
  bool get hasPatients => _patients.isNotEmpty;

  // Load all patients
  Future<void> loadPatients() async {
    _setLoading(true);
    try {
      _patients = await _patientService.getAllPatients();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Add patient
  Future<bool> addPatient(Patient patient) async {
    _setLoading(true);
    try {
      final newPatient = await _patientService.createPatient(patient);
      _patients.insert(0, newPatient); // Add to beginning of list
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

  // Update patient
  Future<bool> updatePatient(String id, Patient patient) async {
    _setLoading(true);
    try {
      final updatedPatient = await _patientService.updatePatient(id, patient);
      final index = _patients.indexWhere((p) => p.id == id);
      if (index != -1) {
        _patients[index] = updatedPatient;
      }

      // Update selected patient if it's the same one
      if (_selectedPatient?.id == id) {
        _selectedPatient = updatedPatient;
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

  // Delete patient
  Future<bool> deletePatient(String id) async {
    _setLoading(true);
    try {
      await _patientService.deletePatient(id);
      _patients.removeWhere((p) => p.id == id);

      // Clear selected patient if it's the deleted one
      if (_selectedPatient?.id == id) {
        _selectedPatient = null;
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

  // Search patients
  Future<void> searchPatients({
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    _setLoading(true);
    try {
      _patients = await _patientService.searchPatients(
        firstName: firstName,
        lastName: lastName,
        email: email,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // 🆕 Filter patients
  Future<void> filterPatients({
    String? gender,
    DateTime? dateOfBirth,
    String? civilStatus,
  }) async {
    _setLoading(true);
    try {
      _patients = await _patientService.filterPatients(
        gender: gender,
        dateOfBirth: dateOfBirth,
        civilStatus: civilStatus,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Select patient
  void selectPatient(Patient patient) {
    _selectedPatient = patient;
    notifyListeners();
  }

  // Clear selected patient
  void clearSelectedPatient() {
    _selectedPatient = null;
    notifyListeners();
  }

  // Load medical history for patient
  Future<void> loadMedicalHistory(String patientId) async {
    _setLoading(true);
    try {
      _medicalHistories =
          await _patientService.getMedicalHistoryByPatientId(patientId);
      _error = null;

    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Add medical history
  Future<bool> addMedicalHistory(
      String patientId, MedicalHistory medicalHistory) async {
    _setLoading(true);
    try {
      final newHistory =
          await _patientService.addMedicalHistory(patientId, medicalHistory);
      _medicalHistories.insert(0, newHistory); // Add to beginning
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

  // 🆕 Update medical history
  Future<bool> updateMedicalHistory(
      String id, MedicalHistory medicalHistory) async {
    _setLoading(true);
    try {
      final updatedHistory =
          await _patientService.updateMedicalHistory(id, medicalHistory);
      final index = _medicalHistories.indexWhere((h) => h.id == id);
      if (index != -1) {
        _medicalHistories[index] = updatedHistory;
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

  // 🆕 Delete medical history
  Future<bool> deleteMedicalHistory(String id) async {
    _setLoading(true);
    try {
      await _patientService.deleteMedicalHistory(id);
      _medicalHistories.removeWhere((h) => h.id == id);
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

  // 🆕 Load current month patient count
  Future<void> loadCurrentMonthPatientCount() async {
    try {
      _currentMonthPatientCount =
          await _patientService.getCurrentMonthPatientCount();
      notifyListeners();
    } catch (e) {
      ('❌ Error loading current month patient count: $e');
    }
  }

  // 🆕 Search medical history
  Future<void> searchMedicalHistory(
    String patientId, {
    String? vitals,
    DateTime? date,
  }) async {
    _setLoading(true);
    try {
      _medicalHistories = await _patientService.searchMedicalHistory(
        patientId,
        vitals: vitals,
        date: date,
      );
      _error = null;
         } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // 🆕 Refresh data (reload patients and stats)
  Future<void> refreshData() async {
    await Future.wait([
      loadPatients(),
      loadCurrentMonthPatientCount(),
    ]);
  }

  // 🆕 Get patient by ID from current list
  Patient? getPatientById(String id) {
    try {
      return _patients.firstWhere((patient) => patient.id == id);
    } catch (e) {
      return null;
    }
  }

  // 🆕 Get patients by status/criteria
  List<Patient> getPatientsByGender(String gender) {
    return _patients.where((patient) => patient.gender == gender).toList();
  }

  List<Patient> getPatientsByCivilStatus(String civilStatus) {
    return _patients
        .where((patient) => patient.civilStatus == civilStatus)
        .toList();
  }

  List<Patient> getRecentPatients({int limit = 10}) {
    final sortedPatients = List<Patient>.from(_patients);
    sortedPatients.sort((a, b) => (b.dateOfRegistration ?? DateTime.now())
        .compareTo(a.dateOfRegistration ?? DateTime.now()));
    return sortedPatients.take(limit).toList();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearData() {
    _patients.clear();
    _medicalHistories.clear();
    _selectedPatient = null;
    _error = null;
    _currentMonthPatientCount = 0;
    notifyListeners();
  }

  // 🆕 Statistics getters
  Map<String, dynamic> get patientStatistics {
    if (_patients.isEmpty) return {};

    final maleCount = _patients.where((p) => p.gender == 'Male').length;
    final femaleCount = _patients.where((p) => p.gender == 'Female').length;

    final ageGroups = <String, int>{
      '0-18': 0,
      '19-35': 0,
      '36-60': 0,
      '60+': 0,
    };

    for (final patient in _patients) {
      final age = patient.age;
      if (age <= 18) {
        ageGroups['0-18'] = ageGroups['0-18']! + 1;
      } else if (age <= 35) {
        ageGroups['19-35'] = ageGroups['19-35']! + 1;
      } else if (age <= 60) {
        ageGroups['36-60'] = ageGroups['36-60']! + 1;
      } else {
        ageGroups['60+'] = ageGroups['60+']! + 1;
      }
    }

    return {
      'total': _patients.length,
      'male': maleCount,
      'female': femaleCount,
      'ageGroups': ageGroups,
      'currentMonth': _currentMonthPatientCount,
    };
  }
}
