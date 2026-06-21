// lib/features/patient/models/medical_history.dart
class MedicalHistory {
  final String? id;
  final String patientId;
  final double? bloodGlucoseLevel;
  final int? heartRate;
  final int? oxygenSaturation;
  final String? bloodPressure;
  final int? respiratoryRate;
  final double? bodyTemperature;
  final double? weight;
  final double? height;
  final List<String>? chronicDiseases;
  final List<String>? allergies;
  final String? smokingStatus;
  final String? alcoholConsumption;
  final List<CurrentMedication>? currentMedications;

  MedicalHistory({
    this.id,
    required this.patientId,
    this.bloodGlucoseLevel,
    this.heartRate,
    this.oxygenSaturation,
    this.bloodPressure,
    this.respiratoryRate,
    this.bodyTemperature,
    this.weight,
    this.height,
    this.chronicDiseases,
    this.allergies,
    this.smokingStatus,
    this.alcoholConsumption,
    this.currentMedications,
  });

  factory MedicalHistory.fromJson(Map<String, dynamic> json) {
    return MedicalHistory(
      id: json['_id'] ?? json['id'],
      patientId: json['patientId'] ?? '',
      bloodGlucoseLevel: json['bloodGlucoseLevel']?.toDouble(),
      heartRate: json['heartRate'],
      oxygenSaturation: json['oxygenSaturation'],
      bloodPressure: json['bloodPressure'],
      respiratoryRate: json['respiratoryRate'],
      bodyTemperature: json['bodyTemperature']?.toDouble(),
      weight: json['weight']?.toDouble(),
      height: json['height']?.toDouble(),
      chronicDiseases: (json['chronicDiseases'] as List?)?.cast<String>(),
      allergies: (json['allergies'] as List?)?.cast<String>(),
      smokingStatus: json['smokingStatus'],
      alcoholConsumption: json['alcoholConsumption'],
      currentMedications: (json['currentMedications'] as List?)
          ?.map((e) => CurrentMedication.fromJson(e))
          .toList(),
    );
  }

// Dans medical_history.dart, modifier la méthode toJson()
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      if (id != null) 'id': id,
      'patientId': patientId,
    };

    // 👈 N'ajouter les champs que s'ils ne sont pas null
    if (bloodGlucoseLevel != null)
      json['bloodGlucoseLevel'] = bloodGlucoseLevel;
    if (heartRate != null) json['heartRate'] = heartRate;
    if (oxygenSaturation != null) json['oxygenSaturation'] = oxygenSaturation;
    if (bloodPressure != null && bloodPressure!.isNotEmpty)
      json['bloodPressure'] = bloodPressure;
    if (respiratoryRate != null) json['respiratoryRate'] = respiratoryRate;
    if (bodyTemperature != null) json['bodyTemperature'] = bodyTemperature;
    if (weight != null) json['weight'] = weight;
    if (height != null) json['height'] = height;

    // 👈 Toujours inclure ces champs (ils peuvent être des listes vides)
    json['chronicDiseases'] = chronicDiseases ?? [];
    json['allergies'] = allergies ?? [];

    if (smokingStatus != null) json['smokingStatus'] = smokingStatus;
    if (alcoholConsumption != null)
      json['alcoholConsumption'] = alcoholConsumption;

    json['currentMedications'] =
        currentMedications?.map((e) => e.toJson()).toList() ?? [];

    return json;
  }
}

class CurrentMedication {
  final String name;
  final String dosage;
  final String frequency;

  CurrentMedication({
    required this.name,
    required this.dosage,
    required this.frequency,
  });

  factory CurrentMedication.fromJson(Map<String, dynamic> json) {
    return CurrentMedication(
      name: json['name'] ?? '',
      dosage: json['dosage'] ?? '',
      frequency: json['frequency'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
    };
  }
}
