import 'package:flutter/foundation.dart';

class Appointment {
  final String? id;
  final String patientName;
  final String? patientEmail;
  final String? patientPhone;
  final String doctorId;
  final String doctorName;
  final DateTime date;
  final String time;
  final String type;
  final String status;
  final String? notes;
  final int duration;
  final String? cancellationReason;
  final bool reminderSent;

  Appointment({
    this.id,
    required this.patientName,
    this.patientEmail,
    this.patientPhone,
    required this.doctorId,
    required this.doctorName,
    required this.date,
    required this.time,
    required this.type,
    this.status = 'Scheduled',
    this.notes,
    this.duration = 30,
    this.cancellationReason,
    this.reminderSent = false,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    try {
      DateTime parsedDate;
      if (json['date'] is String) {
        parsedDate = DateTime.parse(json['date']);
      } else if (json['date'] is Map) {
        parsedDate = DateTime.parse(json['date']['\$date'] ?? json['date']['date']);
      } else {
        parsedDate = DateTime.now();
      }

      final patientContact = json['patientContact'] as Map<String, dynamic>?;

      return Appointment(
        id: json['_id'] ?? json['id'],
        patientName: json['patientName'] ?? '',
        patientEmail: patientContact?['email'],
        patientPhone: patientContact?['phone'],
        doctorId: json['doctorId'] ?? '',
        doctorName: json['doctorName'] ?? '',
        date: parsedDate,
        time: json['time'] ?? '00:00',
        type: json['type'] ?? 'Consultation',
        status: json['status'] ?? 'Scheduled',
        notes: json['notes'],
        duration: json['duration'] is int
            ? json['duration']
            : int.tryParse('${json['duration']}') ?? 30,
        cancellationReason: json['cancellationReason'],
        reminderSent: json['reminderSent'] == true,
      );
    } catch (e) {
      debugPrint('Error parsing appointment JSON: $e');
      debugPrint('Raw JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    final contact = <String, dynamic>{};
    if (patientEmail != null && patientEmail!.isNotEmpty) {
      contact['email'] = patientEmail;
    }
    if (patientPhone != null && patientPhone!.isNotEmpty) {
      contact['phone'] = patientPhone;
    }

    return {
      if (id != null) 'id': id,
      'patientName': patientName,
      if (contact.isNotEmpty) 'patientContact': contact,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'date': date.toIso8601String(),
      'time': time,
      'type': type,
      'status': status,
      'notes': notes,
      'duration': duration,
      'cancellationReason': cancellationReason,
      'reminderSent': reminderSent,
    };
  }
}
