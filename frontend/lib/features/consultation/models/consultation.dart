// lib/features/consultation/models/consultation.dart
import 'package:flutter/foundation.dart';

class Consultation {
  final String? id;
  final String? patientId;
  final String? patientName;
  final DateTime date;
  final String time;
  final String type;
  final String status;
  final List<String> symptoms;
  final List<String> diagnosis;
  final List<String> prescribedAnalyses;
  final String? notes;
  final int? duration;
  final bool isEmergency;
  final String? medicalHistoryId;

  Consultation({
    this.id,
    this.patientId,
    this.patientName,
    required this.date,
    required this.time,
    required this.type,
    required this.status,
    this.symptoms = const [],
    this.diagnosis = const [],
    this.prescribedAnalyses = const [],
    this.notes,
    this.duration,
    this.isEmergency = false,
    this.medicalHistoryId,
  });

  factory Consultation.fromJson(Map<String, dynamic> json) {
    try {
      DateTime parsedDate;

      // Handle different date formats
      if (json['date'] is String) {
        parsedDate = DateTime.parse(json['date']);
      } else if (json['date'] is Map) {
        // Handle MongoDB date format
        parsedDate =
            DateTime.parse(json['date']['\$date'] ?? json['date']['date']);
      } else {
        parsedDate = DateTime.now();
      }

      return Consultation(
        id: json['_id'] ?? json['id'],
        patientId: json['patientId'],
        patientName: json['patientName'],
        date: parsedDate,
        time: json['time'] ?? '00:00',
        type: json['type'] ?? 'Consultation',
        status: json['status'] ?? 'Scheduled',
        symptoms: (json['symptoms'] as List?)?.cast<String>() ?? [],
        diagnosis: (json['diagnosis'] as List?)?.cast<String>() ?? [],
        prescribedAnalyses:
            (json['prescribedAnalyses'] as List?)?.cast<String>() ?? [],
        notes: json['notes'],
        duration: json['duration'],
        isEmergency: json['isEmergency'] ??
            json['type']?.toLowerCase() == 'emergency' ??
            false,
        medicalHistoryId: json['medicalHistoryId'],
      );
    } catch (e) {
      debugPrint('❌ Error parsing consultation JSON: $e');
      debugPrint('Raw JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (patientId != null) 'patientId': patientId,
      if (patientName != null) 'patientName': patientName,
      'date': date.toIso8601String(), // 👈 FORMAT ISO STRING
      'time': time,
      'type': type,
      'status': status,
      'symptoms': symptoms,
      'diagnosis': diagnosis,
      'prescribedAnalyses': prescribedAnalyses,
      'notes': notes,
      'duration': duration,
      'isEmergency': isEmergency, // 👈 NOUVEAU CHAMP
      'medicalHistoryId': medicalHistoryId,
    };
  }

  // 👈 MÉTHODE POUR CRÉER UNE COPIE
  Consultation copyWith({
    String? id,
    String? patientId,
    String? patientName,
    DateTime? date,
    String? time,
    String? type,
    String? status,
    List<String>? symptoms,
    List<String>? diagnosis,
    List<String>? prescribedAnalyses,
    String? notes,
    int? duration,
    bool? isEmergency,
    String? medicalHistoryId,
  }) {
    return Consultation(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      date: date ?? this.date,
      time: time ?? this.time,
      type: type ?? this.type,
      status: status ?? this.status,
      symptoms: symptoms ?? this.symptoms,
      diagnosis: diagnosis ?? this.diagnosis,
      prescribedAnalyses: prescribedAnalyses ?? this.prescribedAnalyses,
      notes: notes ?? this.notes,
      duration: duration ?? this.duration,
      isEmergency: isEmergency ?? this.isEmergency,
      medicalHistoryId: medicalHistoryId ?? this.medicalHistoryId,
    );
  }

  @override
  String toString() {
    return 'Consultation(id: $id, patientId: $patientId, date: $date, time: $time, type: $type, status: $status)';
  }
}
