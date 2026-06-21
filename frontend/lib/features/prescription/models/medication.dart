// lib/features/prescription/models/medication.dart - VERSION CORRIGÉE
import 'package:flutter/foundation.dart';

class Medication {
  final String? id;
  final MedicationIdentification identification;
  final ClinicalInfo? clinical;
  final PharmaceuticalInfo? pharmaceutical;
  final RegulatoryInfo? regulatory;
  final DosageInfo? dosage;
  final InventoryInfo? inventory;
  final SafetyInfo? safety;

  Medication({
    this.id,
    required this.identification,
    this.clinical,
    this.pharmaceutical,
    this.regulatory,
    this.dosage,
    this.inventory,
    this.safety,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
 
    return Medication(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      identification:
          MedicationIdentification.fromJson(json['identification'] ?? {}),
      clinical: json['clinical'] != null
          ? ClinicalInfo.fromJson(json['clinical'])
          : null,
      pharmaceutical: json['pharmaceuticalProperties'] != null
          ? PharmaceuticalInfo.fromJson(json['pharmaceuticalProperties'])
          : null,
      regulatory: json['regulatory'] != null
          ? RegulatoryInfo.fromJson(json['regulatory'])
          : null,
      dosage:
          json['dosage'] != null ? DosageInfo.fromJson(json['dosage']) : null,
      inventory: json['inventory'] != null
          ? InventoryInfo.fromJson(json['inventory'])
          : null,
      safety:
          json['safety'] != null ? SafetyInfo.fromJson(json['safety']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'identification': identification.toJson(),
      if (clinical != null) 'clinical': clinical!.toJson(),
      if (pharmaceutical != null)
        'pharmaceuticalProperties': pharmaceutical!.toJson(),
      if (regulatory != null) 'regulatory': regulatory!.toJson(),
      if (dosage != null) 'dosage': dosage!.toJson(),
      if (inventory != null) 'inventory': inventory!.toJson(),
      if (safety != null) 'safety': safety!.toJson(),
    };
  }

  String get displayName => identification.name;
  String get genericName => identification.genericName ?? identification.name;
}

class MedicationIdentification {
  final String name;
  final String? genericName;
  final String? brandName;
  final List<String>? brandNames;
  final dynamic manufacturer; // Peut être String ou Map
  final String? ndc;
  final List<String>? aliases;
  final Map<String, dynamic>? codes;

  MedicationIdentification({
    required this.name,
    this.genericName,
    this.brandName,
    this.brandNames,
    this.manufacturer,
    this.ndc,
    this.aliases,
    this.codes,
  });

  factory MedicationIdentification.fromJson(Map<String, dynamic> json) {
    return MedicationIdentification(
      name: json['name']?.toString() ?? '',
      genericName: json['genericName']?.toString(),
      brandName: json['brandName']?.toString(),
      brandNames: _parseStringList(json['brandNames']),
      manufacturer: json['manufacturer'], // Garder tel quel
      ndc: json['ndc']?.toString() ?? json['codes']?['internal']?.toString(),
      aliases: _parseStringList(json['aliases']),
      codes: json['codes'] as Map<String, dynamic>?,
    );
  }

  static List<String>? _parseStringList(dynamic list) {
    if (list == null) return null;
    if (list is List) {
      return list.map((e) => e.toString()).toList();
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (genericName != null) 'genericName': genericName,
      if (brandName != null) 'brandName': brandName,
      if (brandNames != null) 'brandNames': brandNames,
      if (manufacturer != null) 'manufacturer': manufacturer,
      if (ndc != null) 'ndc': ndc,
      if (aliases != null) 'aliases': aliases,
      if (codes != null) 'codes': codes,
    };
  }
}

class ClinicalInfo {
  final List<String>? indications;
  final List<String>? contraindications;
  final List<String>? sideEffects;
  final List<String>? interactions;
  final String? therapeuticClass;
  final String? pharmacologicalClass;

  ClinicalInfo({
    this.indications,
    this.contraindications,
    this.sideEffects,
    this.interactions,
    this.therapeuticClass,
    this.pharmacologicalClass,
  });

  factory ClinicalInfo.fromJson(Map<String, dynamic> json) {
    return ClinicalInfo(
      indications: _parseStringList(json['indications']),
      contraindications: _parseStringList(json['contraindications']),
      sideEffects: _parseStringList(json['sideEffects']),
      interactions: _parseStringList(json['interactions']),
      therapeuticClass: json['therapeuticClass']?.toString(),
      pharmacologicalClass: json['pharmacologicalClass']?.toString(),
    );
  }

  static List<String>? _parseStringList(dynamic list) {
    if (list == null) return null;
    if (list is List) {
      return list.map((e) => e.toString()).toList();
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      if (indications != null) 'indications': indications,
      if (contraindications != null) 'contraindications': contraindications,
      if (sideEffects != null) 'sideEffects': sideEffects,
      if (interactions != null) 'interactions': interactions,
      if (therapeuticClass != null) 'therapeuticClass': therapeuticClass,
      if (pharmacologicalClass != null)
        'pharmacologicalClass': pharmacologicalClass,
    };
  }
}

class PharmaceuticalInfo {
  final String? dosageForm;
  final String? form;
  final List<String>? strengths;
  final String? route;
  final StorageInfo? storage;
  final List<CompositionInfo>? composition;

  PharmaceuticalInfo({
    this.dosageForm,
    this.form,
    this.strengths,
    this.route,
    this.storage,
    this.composition,
  });

  factory PharmaceuticalInfo.fromJson(Map<String, dynamic> json) {
    return PharmaceuticalInfo(
      dosageForm: json['dosageForm']?.toString(),
      form: json['form']?.toString(),
      strengths: _parseStringList(json['strengths']),
      route: json['route']?.toString(),
      storage: json['storage'] != null
          ? StorageInfo.fromJson(json['storage'])
          : null,
      composition: _parseCompositionList(json['composition']),
    );
  }

  static List<String>? _parseStringList(dynamic list) {
    if (list == null) return null;
    if (list is List) {
      return list.map((e) => e.toString()).toList();
    }
    return null;
  }

  static List<CompositionInfo>? _parseCompositionList(dynamic list) {
    if (list == null) return null;
    if (list is List) {
      return list
          .map((e) => CompositionInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      if (dosageForm != null) 'dosageForm': dosageForm,
      if (form != null) 'form': form,
      if (strengths != null) 'strengths': strengths,
      if (route != null) 'route': route,
      if (storage != null) 'storage': storage!.toJson(),
      if (composition != null)
        'composition': composition!.map((e) => e.toJson()).toList(),
    };
  }
}

class CompositionInfo {
  final String? ingredient;
  final String? strength;

  CompositionInfo({this.ingredient, this.strength});

  factory CompositionInfo.fromJson(Map<String, dynamic> json) {
    return CompositionInfo(
      ingredient: json['ingredient']?.toString(),
      strength: json['strength']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (ingredient != null) 'ingredient': ingredient,
      if (strength != null) 'strength': strength,
    };
  }
}

class StorageInfo {
  final String? temperature;
  final String? conditions;
  final String? shelfLife;

  StorageInfo({
    this.temperature,
    this.conditions,
    this.shelfLife,
  });

  factory StorageInfo.fromJson(Map<String, dynamic> json) {
    return StorageInfo(
      temperature: json['temperature']?.toString(),
      conditions: json['conditions']?.toString(),
      shelfLife: json['shelfLife']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (temperature != null) 'temperature': temperature,
      if (conditions != null) 'conditions': conditions,
      if (shelfLife != null) 'shelfLife': shelfLife,
    };
  }
}

class DosageInfo {
  final StandardDosage? standard;

  DosageInfo({this.standard});

  factory DosageInfo.fromJson(Map<String, dynamic> json) {
    return DosageInfo(
      standard: json['standard'] != null
          ? StandardDosage.fromJson(json['standard'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (standard != null) 'standard': standard!.toJson(),
    };
  }
}

class StandardDosage {
  final AdultDosage? adult;

  StandardDosage({this.adult});

  factory StandardDosage.fromJson(Map<String, dynamic> json) {

    return StandardDosage(
      adult: json['adult'] != null ? AdultDosage.fromJson(json['adult']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (adult != null) 'adult': adult!.toJson(),
    };
  }
}

class AdultDosage {
  final String? dose;
  final String? frequency;
  final String? maxDailyDose;

  AdultDosage({this.dose, this.frequency, this.maxDailyDose});

  factory AdultDosage.fromJson(Map<String, dynamic> json) {
    final dose = json['dose']?.toString();

    return AdultDosage(
      dose: dose,
      frequency: json['frequency']?.toString(),
      maxDailyDose: json['maxDailyDose']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (dose != null) 'dose': dose,
      if (frequency != null) 'frequency': frequency,
      if (maxDailyDose != null) 'maxDailyDose': maxDailyDose,
    };
  }
}

class InventoryInfo {
  final int? currentStock;
  final String? unit;
  final int? threshold;
  final String? status;

  InventoryInfo({this.currentStock, this.unit, this.threshold, this.status});

  factory InventoryInfo.fromJson(Map<String, dynamic> json) {
    return InventoryInfo(
      currentStock: _parseInt(json['currentStock']),
      unit: json['unit']?.toString(),
      threshold: _parseInt(json['threshold']),
      status: json['status']?.toString(),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      if (currentStock != null) 'currentStock': currentStock,
      if (unit != null) 'unit': unit,
      if (threshold != null) 'threshold': threshold,
      if (status != null) 'status': status,
    };
  }
}

class SafetyInfo {
  final PregnancyInfo? pregnancy;

  SafetyInfo({this.pregnancy});

  factory SafetyInfo.fromJson(Map<String, dynamic> json) {
    return SafetyInfo(
      pregnancy: json['pregnancy'] != null
          ? PregnancyInfo.fromJson(json['pregnancy'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (pregnancy != null) 'pregnancy': pregnancy!.toJson(),
    };
  }
}

class PregnancyInfo {
  final String? category;

  PregnancyInfo({this.category});

  factory PregnancyInfo.fromJson(Map<String, dynamic> json) {
    return PregnancyInfo(
      category: json['category']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (category != null) 'category': category,
    };
  }
}

class RegulatoryInfo {
  final String? fdaApproval;
  final bool? prescriptionRequired;
  final String? controlledSubstanceSchedule;
  final List<String>? blackBoxWarnings;

  RegulatoryInfo({
    this.fdaApproval,
    this.prescriptionRequired,
    this.controlledSubstanceSchedule,
    this.blackBoxWarnings,
  });

  factory RegulatoryInfo.fromJson(Map<String, dynamic> json) {
    return RegulatoryInfo(
      fdaApproval: json['fdaApproval']?.toString(),
      prescriptionRequired: json['prescriptionRequired'] as bool?,
      controlledSubstanceSchedule:
          json['controlledSubstanceSchedule']?.toString(),
      blackBoxWarnings: _parseStringList(json['blackBoxWarnings']),
    );
  }

  static List<String>? _parseStringList(dynamic list) {
    if (list == null) return null;
    if (list is List) {
      return list.map((e) => e.toString()).toList();
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      if (fdaApproval != null) 'fdaApproval': fdaApproval,
      if (prescriptionRequired != null)
        'prescriptionRequired': prescriptionRequired,
      if (controlledSubstanceSchedule != null)
        'controlledSubstanceSchedule': controlledSubstanceSchedule,
      if (blackBoxWarnings != null) 'blackBoxWarnings': blackBoxWarnings,
    };
  }
}
