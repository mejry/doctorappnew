import 'package:flutter/foundation.dart';
import '../models/medication.dart';
import '../services/medication_service.dart';

class MedicationProvider with ChangeNotifier {
  final MedicationService _medicationService = MedicationService();

  List<Medication> _medications = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Medication> get medications => _medications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMedications => _medications.isNotEmpty;

  /// Charger tous les médicaments
  Future<void> loadMedications() async {
    _setLoading(true);
    _clearError();

    try {
      _medications = await _medicationService.getAllMedications();
      debugPrint('Loaded ${_medications.length} medications');
      notifyListeners();
    } catch (e) {
      _setError('Failed to load medications: $e');
      debugPrint('Error loading medications: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Rechercher des médicaments
  Future<void> searchMedications(String query) async {
    if (query.trim().isEmpty) {
      await loadMedications();
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      _medications = await _medicationService.searchMedications(query);
      debugPrint('Found ${_medications.length} medications for query: $query');
      notifyListeners();
    } catch (e) {
      _setError('Failed to search medications: $e');
      debugPrint('Error searching medications: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Créer un nouveau médicament
  Future<bool> createMedication(Map<String, dynamic> medicationData) async {
    try {
      final newMedication =
          await _medicationService.createMedication(medicationData);
      _medications.insert(0, newMedication);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to create medication: $e');
      return false;
    }
  }

  /// Mettre à jour un médicament
  Future<bool> updateMedication(
      String id, Map<String, dynamic> medicationData) async {
    try {
      debugPrint('Updating medication $id with data: $medicationData');

      final updatedMedication =
          await _medicationService.updateMedication(id, medicationData);

      debugPrint('Updated medication received: ${updatedMedication.toJson()}');
      debugPrint(
          'Updated dosage: ${updatedMedication.dosage?.standard?.adult?.dose}');

      final index = _medications.indexWhere((med) => med.id == id);
      if (index != -1) {
        _medications[index] = updatedMedication;
        debugPrint('Medication updated at index $index');

        // Forcer une mise à jour immédiate de l'interface
        notifyListeners();

        // Debug : vérifier que le dosage est bien dans la liste mappée
        final mapped = medicationsAsMap.firstWhere((med) => med['id'] == id);
        debugPrint(
            'Mapped medication dosage after update: ${mapped['dosage']}');
      } else {
        debugPrint(
            'Medication with id $id not found in local list, reloading...');
        // Recharger la liste complète si le médicament n'est pas trouvé localement
        await loadMedications();
      }

      return true;
    } catch (e) {
      _setError('Failed to update medication: $e');
      debugPrint('Update error: $e');
      return false;
    }
  }

  /// Supprimer un médicament
  Future<bool> deleteMedication(String id) async {
    try {
      final success = await _medicationService.deleteMedication(id);

      if (success) {
        _medications.removeWhere((med) => med.id == id);
        notifyListeners();
      }

      return success;
    } catch (e) {
      _setError('Failed to delete medication: $e');
      return false;
    }
  }

  /// Convertir les médicaments en format compatible avec l'interface existante
  List<Map<String, dynamic>> get medicationsAsMap {
    return _medications.map((medication) {
      debugPrint('Mapping medication: ${medication.identification.name}');
      debugPrint('Dosage info: ${medication.dosage?.standard?.adult?.dose}');

      return {
        'id': medication.id,
        'name': medication.identification.name,
        'code': medication.identification.ndc ??
            medication.identification.codes?['internal'] ??
            'N/A',
        'dosage': _getDosage(medication), // Changé ici
        'form': medication.pharmaceutical?.dosageForm ??
            medication.pharmaceutical?.form ??
            'Unknown',
        'stock': _getStockInfo(medication),
        'genericName': medication.identification.genericName ?? '',
        'brandName': medication.identification.brandName ?? '',
        'brandNames': _getBrandNames(medication),
        'manufacturer': _getManufacturerName(medication),
        'manufacturerName': _getManufacturerName(medication),
        'manufacturerCountry': _getManufacturerCountry(medication),
        'ingredient': _getIngredient(medication),
        'strength': _getStrength(medication),
        'route': _getRoute(medication),
        'storageConditions': _getStorageConditions(medication),
        'shelfLife': _getShelfLife(medication),
      };
    }).toList();
  }

  /// Helper pour obtenir le dosage
  String _getDosage(Medication medication) {
    // Priorité 1: Dosage standard adulte
    if (medication.dosage?.standard?.adult?.dose != null) {
      return medication.dosage!.standard!.adult!.dose!;
    }

    // Priorité 2: Première force de dosage (fallback)
    if (medication.pharmaceutical?.strengths != null &&
        medication.pharmaceutical!.strengths!.isNotEmpty) {
      return medication.pharmaceutical!.strengths!.first;
    }

    // Priorité 3: Force depuis la composition
    if (medication.pharmaceutical?.composition != null &&
        medication.pharmaceutical!.composition!.isNotEmpty) {
      return medication.pharmaceutical!.composition!.first.strength ?? 'N/A';
    }

    return 'N/A';
  }

  /// Helper pour obtenir les infos de stock
  int _getStockInfo(Medication medication) {
    return medication.inventory?.currentStock ?? 0;
  }

  /// Helper pour obtenir les noms de marque
  String _getBrandNames(Medication medication) {
    if (medication.identification.brandNames != null &&
        medication.identification.brandNames!.isNotEmpty) {
      return medication.identification.brandNames!.join(', ');
    }
    return medication.identification.brandName ?? '';
  }

  /// Helper pour obtenir le nom du fabricant
  String _getManufacturerName(Medication medication) {
    final manufacturer = medication.identification.manufacturer;
    if (manufacturer is Map<String, dynamic>) {
      return manufacturer['name']?.toString() ?? '';
    } else if (manufacturer is String) {
      return manufacturer;
    }
    return '';
  }

  /// Helper pour obtenir le pays du fabricant
  String _getManufacturerCountry(Medication medication) {
    final manufacturer = medication.identification.manufacturer;
    if (manufacturer is Map<String, dynamic>) {
      return manufacturer['country']?.toString() ?? '';
    }
    return '';
  }

  /// Helper pour obtenir l'ingrédient
  String _getIngredient(Medication medication) {
    if (medication.pharmaceutical?.composition != null &&
        medication.pharmaceutical!.composition!.isNotEmpty) {
      return medication.pharmaceutical!.composition!.first.ingredient ?? '';
    }
    return '';
  }

  /// Helper pour obtenir la force
  String _getStrength(Medication medication) {
    if (medication.pharmaceutical?.composition != null &&
        medication.pharmaceutical!.composition!.isNotEmpty) {
      return medication.pharmaceutical!.composition!.first.strength ?? '';
    }
    return '';
  }

  /// Helper pour obtenir la route
  String _getRoute(Medication medication) {
    return medication.pharmaceutical?.route ?? '';
  }

  /// Helper pour obtenir les conditions de stockage
  String _getStorageConditions(Medication medication) {
    return medication.pharmaceutical?.storage?.conditions ?? '';
  }

  /// Helper pour obtenir la durée de conservation
  String _getShelfLife(Medication medication) {
    return medication.pharmaceutical?.storage?.shelfLife ?? '';
  }

  /// Effacer l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Méthodes privées
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
