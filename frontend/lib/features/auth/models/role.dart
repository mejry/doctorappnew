// lib/features/auth/models/role.dart - Version corrigée pour parser le JSON backend
class Role {
  final String id;
  final String name;
  final List<String> permissions;
  final List<String> assignedUsers; // ✅ IDs des utilisateurs assignés
  final List<UserSummary>
      assignedUsersDetails; // ✅ Détails des utilisateurs assignés
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Role({
    required this.id,
    required this.name,
    required this.permissions,
    this.assignedUsers = const [],
    this.assignedUsersDetails = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    // ✅ Extraire les utilisateurs assignés avec gestion flexible
    List<String> assignedUsers = [];
    if (json['assignedUsers'] is List) {
      final assignedUsersData = json['assignedUsers'] as List;
      for (var item in assignedUsersData) {
        if (item is String) {
          // Si c'est déjà un string (ID), l'ajouter directement
          assignedUsers.add(item);
        } else if (item is Map<String, dynamic>) {
          // Si c'est un objet utilisateur, extraire l'ID
          final userId = item['_id'] ?? item['id'] ?? '';
          if (userId.isNotEmpty) {
            assignedUsers.add(userId);
          }
        }
      }
    }

    // ✅ Extraire les détails des utilisateurs assignés
    List<UserSummary> assignedUsersDetails = [];
    if (json['assignedUsersDetails'] is List) {
      assignedUsersDetails = (json['assignedUsersDetails'] as List)
          .map((userJson) => UserSummary.fromJson(userJson))
          .toList();
    } else if (json['assignedUsers'] is List) {
      // ✅ Fallback: Si assignedUsersDetails n'existe pas, construire depuis assignedUsers
      final assignedUsersData = json['assignedUsers'] as List;
      for (var item in assignedUsersData) {
        if (item is Map<String, dynamic>) {
          // Convertir les objets utilisateur en UserSummary
          try {
            final userSummary = UserSummary(
              id: item['_id'] ?? item['id'] ?? '',
              name:
                  '${item['firstname'] ?? ''} ${item['lastname'] ?? ''}'.trim(),
              email: item['email'] ?? '',
            );
            assignedUsersDetails.add(userSummary);
          } catch (e) {
            print('Error parsing user summary: $e');
          }
        }
      }
    }

    return Role(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      permissions: List<String>.from(json['permissions'] ?? []),
      assignedUsers: assignedUsers,
      assignedUsersDetails: assignedUsersDetails,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'permissions': permissions,
      'assignedUsers': assignedUsers,
      'assignedUsersDetails':
          assignedUsersDetails.map((u) => u.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Role copyWith({
    String? id,
    String? name,
    List<String>? permissions,
    List<String>? assignedUsers,
    List<UserSummary>? assignedUsersDetails,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Role(
      id: id ?? this.id,
      name: name ?? this.name,
      permissions: permissions ?? this.permissions,
      assignedUsers: assignedUsers ?? this.assignedUsers,
      assignedUsersDetails: assignedUsersDetails ?? this.assignedUsersDetails,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ✅ Classe pour les détails simplifiés des utilisateurs
class UserSummary {
  final String id;
  final String name;
  final String email;

  UserSummary({
    required this.id,
    required this.name,
    required this.email,
  });

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}

// Request models pour les rôles
class CreateRoleRequest {
  final String name;
  final List<String> permissions;
  final List<String> users; // ✅ IDs des utilisateurs à assigner

  CreateRoleRequest({
    required this.name,
    required this.permissions,
    this.users = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'permissions': permissions,
      'users': users,
    };
  }
}

class UpdateRoleRequest {
  final String? name;
  final List<String>? permissions;
  final List<String>? users; // ✅ IDs des utilisateurs à assigner

  UpdateRoleRequest({
    this.name,
    this.permissions,
    this.users,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (permissions != null) data['permissions'] = permissions;
    if (users != null) data['users'] = users;
    return data;
  }
}
