// lib/features/auth/models/user_request.dart - Version avec support multi-rôles
class CreateUserRequest {
  final String email;
  final String password;
  final String firstname;
  final String lastname;
  final String? specialite; // ✅ Remplace phone
  final String role; // ID du rôle principal
  final List<String>? additionalRoles; // ✅ IDs des rôles additionnels
  final bool? active;

  CreateUserRequest({
    required this.email,
    required this.password,
    required this.firstname,
    required this.lastname,
    this.specialite,
    required this.role,
    this.additionalRoles,
    this.active,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'email': email,
      'password': password,
      'firstname': firstname,
      'lastname': lastname,
      'role': role,
    };

    // Ajouter les champs optionnels seulement s'ils ne sont pas null
    if (specialite != null && specialite!.isNotEmpty) {
      json['specialite'] = specialite!;
    }

    if (additionalRoles != null && additionalRoles!.isNotEmpty) {
      json['additionalRoles'] = additionalRoles!;
    }

    if (active != null) {
      json['active'] = active!;
    }

    return json;
  }

  @override
  String toString() {
    return 'CreateUserRequest{email: $email, firstname: $firstname, lastname: $lastname, role: $role, additionalRoles: $additionalRoles, specialite: $specialite, active: $active}';
  }
}

class UpdateUserRequest {
  final String? email;
  final String? firstname;
  final String? lastname;
  final String? specialite; // ✅ Remplace phone
  final String? role; // ID du rôle principal
  final List<String>? additionalRoles; // ✅ IDs des rôles additionnels
  final bool? active;

  UpdateUserRequest({
    this.email,
    this.firstname,
    this.lastname,
    this.specialite,
    this.role,
    this.additionalRoles,
    this.active,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    // Ajouter seulement les champs non-null
    if (email != null) json['email'] = email;
    if (firstname != null) json['firstname'] = firstname;
    if (lastname != null) json['lastname'] = lastname;
    if (specialite != null) json['specialite'] = specialite;
    if (role != null) json['role'] = role;
    if (additionalRoles != null) json['additionalRoles'] = additionalRoles;
    if (active != null) json['active'] = active;

    return json;
  }

  // Helper pour vérifier si la requête est vide
  bool get isEmpty => toJson().isEmpty;

  @override
  String toString() {
    return 'UpdateUserRequest{email: $email, firstname: $firstname, lastname: $lastname, role: $role, additionalRoles: $additionalRoles, specialite: $specialite, active: $active}';
  }
}
