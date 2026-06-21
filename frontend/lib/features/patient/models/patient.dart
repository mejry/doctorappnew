// lib/features/patient/models/patient.dart
class Patient {
  final String? id;
  final String firstName;
  final String lastName;
  final String email;
  final String gender;
  final DateTime dateOfBirth;
  final String? address;
  final String? civilStatus;
  final String? phoneNumber;
  final List<EmergencyContact>? emergencyContacts;
  final DateTime? dateOfRegistration;

  Patient({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.gender,
    required this.dateOfBirth,
    this.address,
    this.civilStatus,
    this.phoneNumber,
    this.emergencyContacts,
    this.dateOfRegistration,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['_id'] ?? json['id'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      gender: json['gender'] ?? '',
      dateOfBirth: DateTime.parse(json['dob'] ?? json['dateOfBirth']),
      address: json['address'],
      civilStatus: json['civilStatus'],
      phoneNumber: json['phoneNumber'],
      emergencyContacts: (json['emergencyContacts'] as List?)
          ?.map((e) => EmergencyContact.fromJson(e))
          .toList(),
      dateOfRegistration: json['dateOfRegistration'] != null
          ? DateTime.parse(json['dateOfRegistration'])
          : null,
    );
  }

// Dans patient.dart, modifier la méthode toJson()
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      if (id != null) 'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'gender': gender,
      'dob': dateOfBirth
          .toIso8601String()
          .split('T')[0], // 👈 Format YYYY-MM-DD seulement
      'civilStatus': civilStatus,
      'dateOfRegistration': dateOfRegistration?.toIso8601String(),
    };

    // 👈 N'ajouter que si non-null et non-vide
    if (address != null && address!.isNotEmpty) {
      json['address'] = address;
    }

    if (phoneNumber != null && phoneNumber!.isNotEmpty) {
      json['phoneNumber'] = phoneNumber;
    }

    if (emergencyContacts != null && emergencyContacts!.isNotEmpty) {
      json['emergencyContacts'] =
          emergencyContacts!.map((e) => e.toJson()).toList();
    }

    return json;
  }

  String get fullName => '$firstName $lastName';
  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }
}

class EmergencyContact {
  final String name;
  final String phone;
  final String relationship;

  EmergencyContact({
    required this.name,
    required this.phone,
    required this.relationship,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      relationship: json['relationship'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'relationship': relationship,
    };
  }
}
