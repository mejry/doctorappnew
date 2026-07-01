// lib/core/models/user.dart - VERSION CORRIGÉE
import 'package:frontend/features/auth/models/role.dart' as RoleModel;

class User {
  final String id;
  final String email;
  final String firstname;
  final String lastname;
  final String? phone;
  final String role; // Rôle principal (nom)
  final List<RoleModel.Role> additionalRoles; // ✅ Rôles additionnels
  final List<String>
      additionalRoleIds; // ✅ IDs des rôles additionnels (pour l'auth)
  final List<String> allRoleNames; // ✅ Tous les noms de rôles
  final List<String> allPermissions; // ✅ Toutes les permissions
  final bool active;
  final bool emailVerified;
  final bool twoFactorEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLogin;
  final DateTime? passwordChangedAt; // ✅ NOUVEAU CHAMP
  final String? specialite;

  User({
    required this.id,
    required this.email,
    required this.firstname,
    required this.lastname,
    this.phone,
    required this.role,
    this.additionalRoles = const [],
    this.additionalRoleIds = const [],
    this.allRoleNames = const [],
    this.allPermissions = const [],
    this.active = true,
    this.emailVerified = false,
    this.twoFactorEnabled = false,
    required this.createdAt,
    required this.updatedAt,
    this.lastLogin,
    this.passwordChangedAt, // ✅ NOUVEAU CHAMP
    this.specialite,
  });

  String get fullName {
    final first = firstname.trim();
    final last = lastname.trim();
    if (first.isNotEmpty && first == last) {
      return first;
    }

    final name = '$first $last'.trim();
    if (name.isNotEmpty) {
      return name;
    }

    final emailName = email.split('@').first.trim();
    return emailName.isNotEmpty ? emailName : email;
  }

  // ✅ Méthode pour vérifier si l'utilisateur a une permission
  bool hasPermission(String permission) {
    return allPermissions.contains(permission);
  }

  // ✅ Méthode pour vérifier si l'utilisateur a un rôle
  bool hasRole(String roleName) {
    return allRoleNames.contains(roleName);
  }

  factory User.fromJson(Map<String, dynamic> json) {
    // ✅ Extraire le rôle principal
    String primaryRole = '';
    if (json['role'] is Map && json['role']['name'] != null) {
      primaryRole = json['role']['name'];
    } else if (json['role'] is String) {
      primaryRole = json['role'];
    }

    // ✅ Extraire les IDs des rôles additionnels (pour l'auth response)
    List<String> additionalRoleIds = [];
    if (json['additionalRoles'] is List) {
      final additionalRolesData = json['additionalRoles'] as List;
      if (additionalRolesData.isNotEmpty &&
          additionalRolesData.first is String) {
        additionalRoleIds = List<String>.from(additionalRolesData);
      }
    }

    // ✅ Extraire les rôles additionnels complets (pour l'API users-with-roles)
    List<RoleModel.Role> additionalRoles = [];
    if (json['additionalRoles'] is List) {
      final additionalRolesData = json['additionalRoles'] as List;
      if (additionalRolesData.isNotEmpty && additionalRolesData.first is Map) {
        additionalRoles = additionalRolesData
            .map((roleJson) => RoleModel.Role.fromJson(roleJson))
            .toList();
      }
    }

    // ✅ Extraire tous les noms de rôles depuis allRoleNames
    List<String> allRoleNames = [];
    if (json['allRoleNames'] is List) {
      allRoleNames = List<String>.from(json['allRoleNames']);
    } else {
      allRoleNames = [primaryRole];
      allRoleNames.addAll(additionalRoles.map((r) => r.name));
      allRoleNames =
          allRoleNames.where((name) => name.isNotEmpty).toSet().toList();
    }

    // ✅ Extraire toutes les permissions depuis allPermissions
    List<String> allPermissions = [];
    if (json['allPermissions'] is List) {
      allPermissions = List<String>.from(json['allPermissions']);
    } else {
      if (json['role'] is Map && json['role']['permissions'] != null) {
        allPermissions = List<String>.from(json['role']['permissions']);
      }
      for (var role in additionalRoles) {
        allPermissions.addAll(role.permissions);
      }
      allPermissions = allPermissions.toSet().toList();
    }

    // ✅ CORRIGÉ: Gérer les dates avec des valeurs par défaut
    DateTime now = DateTime.now();
    DateTime createdAt = now;
    DateTime updatedAt = now;

    try {
      if (json['createdAt'] != null) {
        createdAt = DateTime.parse(json['createdAt']);
      }
    } catch (e) {
      // Utiliser la date actuelle si parsing échoue
      createdAt = now;
    }

    try {
      if (json['updatedAt'] != null) {
        updatedAt = DateTime.parse(json['updatedAt']);
      }
    } catch (e) {
      // Utiliser la date actuelle si parsing échoue
      updatedAt = now;
    }

    return User(
      id: json['_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      phone: json['phone'],
      role: primaryRole,
      additionalRoles: additionalRoles,
      additionalRoleIds: additionalRoleIds,
      allRoleNames: allRoleNames,
      allPermissions: allPermissions,
      active: json['active'] ?? true,
      emailVerified: json['emailVerified'] ?? false,
      twoFactorEnabled: json['twoFactorEnabled'] ?? false,
      createdAt: createdAt, // ✅ CORRIGÉ
      updatedAt: updatedAt, // ✅ CORRIGÉ
      lastLogin:
          json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
      passwordChangedAt: json['passwordChangedAt'] != null
          ? DateTime.parse(json['passwordChangedAt'])
          : null, // ✅ NOUVEAU
      specialite: json['specialite'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstname': firstname,
      'lastname': lastname,
      'phone': phone,
      'role': role,
      'additionalRoles': additionalRoles.map((r) => r.toJson()).toList(),
      'additionalRoleIds': additionalRoleIds,
      'allRoleNames': allRoleNames,
      'allPermissions': allPermissions,
      'active': active,
      'emailVerified': emailVerified,
      'twoFactorEnabled': twoFactorEnabled,
      'createdAt': createdAt.toIso8601String(), // ✅ CORRIGÉ
      'updatedAt': updatedAt.toIso8601String(), // ✅ CORRIGÉ
      'lastLogin': lastLogin?.toIso8601String(),
      'passwordChangedAt': passwordChangedAt?.toIso8601String(), // ✅ NOUVEAU
      'specialite': specialite,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? firstname,
    String? lastname,
    String? phone,
    String? role,
    List<RoleModel.Role>? additionalRoles,
    List<String>? additionalRoleIds,
    List<String>? allRoleNames,
    List<String>? allPermissions,
    bool? active,
    bool? emailVerified,
    bool? twoFactorEnabled,
    DateTime? createdAt, // ✅ CORRIGÉ
    DateTime? updatedAt, // ✅ CORRIGÉ
    DateTime? lastLogin,
    DateTime? passwordChangedAt, // ✅ NOUVEAU
    String? specialite,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstname: firstname ?? this.firstname,
      lastname: lastname ?? this.lastname,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      additionalRoles: additionalRoles ?? this.additionalRoles,
      additionalRoleIds: additionalRoleIds ?? this.additionalRoleIds,
      allRoleNames: allRoleNames ?? this.allRoleNames,
      allPermissions: allPermissions ?? this.allPermissions,
      active: active ?? this.active,
      emailVerified: emailVerified ?? this.emailVerified,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      createdAt: createdAt ?? this.createdAt, // ✅ CORRIGÉ
      updatedAt: updatedAt ?? this.updatedAt, // ✅ CORRIGÉ
      lastLogin: lastLogin ?? this.lastLogin,
      passwordChangedAt:
          passwordChangedAt ?? this.passwordChangedAt, // ✅ NOUVEAU
      specialite: specialite ?? this.specialite,
    );
  }

  @override
  String toString() {
    return 'User{id: $id, email: $email, fullName: $fullName, role: $role, allRoles: $allRoleNames, permissions: $allPermissions}';
  }
}
