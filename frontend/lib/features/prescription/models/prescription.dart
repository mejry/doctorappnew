// lib/features/prescription/models/prescription.dart - FIXED VERSION WITH NULL SAFETY

import 'package:flutter/material.dart';

class Prescription {
  final String? id;
  final String consultation;
  final PrescriptionInfo prescriptionInfo;
  final List<PrescriptionMedication> medications;
  final ClinicalContext? clinicalContext;
  final PharmacyInfo? pharmacy;
  final List<PrescriptionHistory>? history;
  final String? pdfPath;

  Prescription({
    this.id,
    required this.consultation,
    required this.prescriptionInfo,
    this.medications = const [],
    this.clinicalContext,
    this.pharmacy,
    this.history,
    this.pdfPath,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    try {
      return Prescription(
        id: json['_id'] ?? json['id'],
        consultation: json['consultation'] ?? '',
        prescriptionInfo:
            PrescriptionInfo.fromJson(json['prescriptionInfo'] ?? {}),
        medications: (json['medications'] as List?)
                ?.map((m) => PrescriptionMedication.fromJson(m ?? {}))
                .toList() ??
            [],
        clinicalContext: json['clinicalContext'] != null
            ? ClinicalContext.fromJson(json['clinicalContext'])
            : null,
        pharmacy: json['pharmacy'] != null
            ? PharmacyInfo.fromJson(json['pharmacy'])
            : null,
        history: (json['history'] as List?)
            ?.map((h) => PrescriptionHistory.fromJson(h ?? {}))
            .toList(),
        pdfPath: json['pdfPath'],
      );
    } catch (e) {
      // Return a default prescription if parsing fails
      return Prescription(
        id: json['_id'] ?? json['id'] ?? 'unknown',
        consultation: json['consultation'] ?? 'unknown',
        prescriptionInfo: PrescriptionInfo(
          type: 'Regular',
          status: 'Unknown',
          date: DateTime.now(),
          time: '00:00',
        ),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'consultation': consultation,
      'prescriptionInfo': prescriptionInfo.toJson(),
      'medications': medications.map((m) => m.toJson()).toList(),
      if (clinicalContext != null) 'clinicalContext': clinicalContext!.toJson(),
      if (pharmacy != null) 'pharmacy': pharmacy!.toJson(),
      if (history != null) 'history': history!.map((h) => h.toJson()).toList(),
      if (pdfPath != null) 'pdfPath': pdfPath,
    };
  }

  // Extensions utiles
  bool get isActive => prescriptionInfo.status.toLowerCase() == 'active';
  bool get isPending => prescriptionInfo.status.toLowerCase() == 'pending';
  bool get isCompleted => prescriptionInfo.status.toLowerCase() == 'completed';
  bool get hasMedications => medications.isNotEmpty;

  int get medicationCount => medications.length;

  String get statusDisplay {
    switch (prescriptionInfo.status.toLowerCase()) {
      case 'active':
        return '🟢 Active';
      case 'pending':
        return '🟡 Pending';
      case 'completed':
        return '🔵 Completed';
      case 'cancelled':
        return '🔴 Cancelled';
      case 'expired':
        return '⚪ Expired';
      default:
        return prescriptionInfo.status;
    }
  }

  Color get statusColor {
    switch (prescriptionInfo.status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Prescription copyWith({
    String? id,
    String? consultation,
    PrescriptionInfo? prescriptionInfo,
    List<PrescriptionMedication>? medications,
    ClinicalContext? clinicalContext,
    PharmacyInfo? pharmacy,
    List<PrescriptionHistory>? history,
    String? pdfPath,
  }) {
    return Prescription(
      id: id ?? this.id,
      consultation: consultation ?? this.consultation,
      prescriptionInfo: prescriptionInfo ?? this.prescriptionInfo,
      medications: medications ?? this.medications,
      clinicalContext: clinicalContext ?? this.clinicalContext,
      pharmacy: pharmacy ?? this.pharmacy,
      history: history ?? this.history,
      pdfPath: pdfPath ?? this.pdfPath,
    );
  }
}

class PrescriptionInfo {
  final String type;
  final String status;
  final DateTime date;
  final String time;
  final int validityDays;
  final String? notes;

  PrescriptionInfo({
    required this.type,
    required this.status,
    required this.date,
    required this.time,
    this.validityDays = 30,
    this.notes,
  });

  factory PrescriptionInfo.fromJson(Map<String, dynamic> json) {
    try {
      // Handle null or missing fields gracefully
      DateTime parsedDate;
      try {
        if (json['date'] != null) {
          parsedDate = DateTime.parse(json['date'].toString());
        } else {
          parsedDate = DateTime.now();
        }
      } catch (e) {
  
        parsedDate = DateTime.now();
      }

      return PrescriptionInfo(
        type: json['type']?.toString() ?? 'Regular',
        status: json['status']?.toString() ?? 'Unknown',
        date: parsedDate,
        time: json['time']?.toString() ?? '00:00',
        validityDays: json['validityDays'] as int? ?? 30,
        notes: json['notes']?.toString(),
      );
    } catch (e) {
      debugPrint('❌ Error parsing PrescriptionInfo: $e');
      
      // Return default values if parsing fails
      return PrescriptionInfo(
        type: 'Regular',
        status: 'Unknown',
        date: DateTime.now(),
        time: '00:00',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'status': status,
      'date': date.toIso8601String(),
      'time': time,
      'validityDays': validityDays,
      if (notes != null) 'notes': notes,
    };
  }
}

class PrescriptionMedication {
  final String? medication;
  final CustomMedication? customMedication;
  final Dosage dosage;
  final Quantity? quantity;
  final Refills? refills;

  PrescriptionMedication({
    this.medication,
    this.customMedication,
    required this.dosage,
    this.quantity,
    this.refills,
  });

  factory PrescriptionMedication.fromJson(Map<String, dynamic> json) {
    try {
      return PrescriptionMedication(
        medication: json['medication'] is String
            ? json['medication']
            : json['medication']?['_id'],
        customMedication: json['customMedication'] != null
            ? CustomMedication.fromJson(json['customMedication'])
            : null,
        dosage: Dosage.fromJson(json['dosage'] ?? {}),
        quantity: json['quantity'] != null
            ? Quantity.fromJson(json['quantity'])
            : null,
        refills:
            json['refills'] != null ? Refills.fromJson(json['refills']) : null,
      );
    } catch (e) {
      debugPrint('❌ Error parsing PrescriptionMedication: $e');
      // Return a default medication if parsing fails
      return PrescriptionMedication(
        dosage: Dosage(
          strength: 'Unknown',
          frequency: 'Unknown',
          duration: 'Unknown',
          route: 'Unknown',
          instructions: 'Parsing error',
        ),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      if (medication != null) 'medication': medication,
      if (customMedication != null)
        'customMedication': customMedication!.toJson(),
      'dosage': dosage.toJson(),
      if (quantity != null) 'quantity': quantity!.toJson(),
      if (refills != null) 'refills': refills!.toJson(),
    };
  }

  String get displayName {
    if (customMedication != null) {
      return customMedication!.name;
    } else if (medication != null) {
      return 'Medication ID: $medication';
    }
    return 'Unknown medication';
  }
}

class CustomMedication {
  final String name;
  final String? description;
  final String? category;

  CustomMedication({
    required this.name,
    this.description,
    this.category,
  });

  factory CustomMedication.fromJson(Map<String, dynamic> json) {
    return CustomMedication(
      name: json['name']?.toString() ?? 'Unknown',
      description: json['description']?.toString(),
      category: json['category']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
    };
  }
}

class Dosage {
  final String? strength;
  final String? frequency;
  final String? duration;
  final String? route;
  final String? instructions;

  Dosage({
    this.strength,
    this.frequency,
    this.duration,
    this.route,
    this.instructions,
  });

  factory Dosage.fromJson(Map<String, dynamic> json) {
    return Dosage(
      strength: json['strength']?.toString(),
      frequency: json['frequency']?.toString(),
      duration: json['duration']?.toString(),
      route: json['route']?.toString(),
      instructions: json['instructions']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (strength != null) 'strength': strength,
      if (frequency != null) 'frequency': frequency,
      if (duration != null) 'duration': duration,
      if (route != null) 'route': route,
      if (instructions != null) 'instructions': instructions,
    };
  }

  String get displayText {
    final parts = <String>[];
    if (frequency != null) parts.add(frequency!);
    if (duration != null) parts.add('for $duration');
    if (route != null) parts.add('($route)');
    return parts.join(' ');
  }
}

class Quantity {
  final int? prescribed;
  final int? dispensed;
  final String? unit;

  Quantity({
    this.prescribed,
    this.dispensed,
    this.unit,
  });

  factory Quantity.fromJson(Map<String, dynamic> json) {
    return Quantity(
      prescribed: json['prescribed'] as int?,
      dispensed: json['dispensed'] as int?,
      unit: json['unit']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (prescribed != null) 'prescribed': prescribed,
      if (dispensed != null) 'dispensed': dispensed,
      if (unit != null) 'unit': unit,
    };
  }
}

class Refills {
  final int? allowed;
  final int? remaining;

  Refills({
    this.allowed,
    this.remaining,
  });

  factory Refills.fromJson(Map<String, dynamic> json) {
    return Refills(
      allowed: json['allowed'] as int?,
      remaining: json['remaining'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (allowed != null) 'allowed': allowed,
      if (remaining != null) 'remaining': remaining,
    };
  }
}

class ClinicalContext {
  final String? diagnosis;
  final String? icdCode;
  final String priority;

  ClinicalContext({
    this.diagnosis,
    this.icdCode,
    this.priority = 'Routine',
  });

  factory ClinicalContext.fromJson(Map<String, dynamic> json) {
    return ClinicalContext(
      diagnosis: json['diagnosis']?.toString(),
      icdCode: json['icdCode']?.toString(),
      priority: json['priority']?.toString() ?? 'Routine',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (diagnosis != null) 'diagnosis': diagnosis,
      if (icdCode != null) 'icdCode': icdCode,
      'priority': priority,
    };
  }
}

class PharmacyInfo {
  final bool dispensed;
  final DateTime? dispenseDate;
  final String? pharmacyName;
  final String? pharmacistName;

  PharmacyInfo({
    this.dispensed = false,
    this.dispenseDate,
    this.pharmacyName,
    this.pharmacistName,
  });

  factory PharmacyInfo.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['dispenseDate'] != null) {
      try {
        parsedDate = DateTime.parse(json['dispenseDate'].toString());
      } catch (e) {
        debugPrint('⚠️ Error parsing dispenseDate: ${json['dispenseDate']}');
      }
    }

    return PharmacyInfo(
      dispensed: json['dispensed'] as bool? ?? false,
      dispenseDate: parsedDate,
      pharmacyName: json['pharmacyName']?.toString(),
      pharmacistName: json['pharmacistName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dispensed': dispensed,
      if (dispenseDate != null) 'dispenseDate': dispenseDate!.toIso8601String(),
      if (pharmacyName != null) 'pharmacyName': pharmacyName,
      if (pharmacistName != null) 'pharmacistName': pharmacistName,
    };
  }
}

class PrescriptionHistory {
  final String action;
  final String performedBy;
  final DateTime timestamp;
  final String? notes;

  PrescriptionHistory({
    required this.action,
    required this.performedBy,
    required this.timestamp,
    this.notes,
  });

  factory PrescriptionHistory.fromJson(Map<String, dynamic> json) {
    DateTime parsedTimestamp;
    try {
      parsedTimestamp = DateTime.parse(json['timestamp'].toString());
    } catch (e) {
      debugPrint('⚠️ Error parsing timestamp: ${json['timestamp']}');
      parsedTimestamp = DateTime.now();
    }

    return PrescriptionHistory(
      action: json['action']?.toString() ?? 'Unknown',
      performedBy: json['performedBy']?.toString() ?? 'Unknown',
      timestamp: parsedTimestamp,
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'performedBy': performedBy,
      'timestamp': timestamp.toIso8601String(),
      if (notes != null) 'notes': notes,
    };
  }
}
