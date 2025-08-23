import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { user, admin }

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final String? apartment;
  final String? phone;
  final DateTime createdAt;
  final DateTime lastLogin;
  final bool isActive;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.apartment,
    this.phone,
    required this.createdAt,
    required this.lastLogin,
    this.isActive = true,
  });

  // Getters para permisos basados en rol
  bool get canCreateEvents => role == UserRole.admin;
  bool get canManageFinances => role == UserRole.admin;
  bool get canViewReports => role == UserRole.admin;
  bool get canManageUsers => role == UserRole.admin;
  bool get isAdmin => role == UserRole.admin;
  bool get isUser => role == UserRole.user;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'apartment': apartment,
      'phone': phone,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
      'isActive': isActive,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.user,
      ),
      apartment: map['apartment'],
      phone: map['phone'],
      createdAt: _parseDateTime(map['createdAt']),
      lastLogin: _parseDateTime(map['lastLogin']),
      isActive: map['isActive'] ?? true,
    );
  }

  // Helper method para parsear fechas que pueden venir como String o Timestamp
  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    
    if (dateValue is Timestamp) {
      return dateValue.toDate();
    } else if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return DateTime.now();
      }
    } else if (dateValue is DateTime) {
      return dateValue;
    }
    
    return DateTime.now();
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    UserRole? role,
    String? apartment,
    String? phone,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? isActive,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      apartment: apartment ?? this.apartment,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
    );
  }
}

// Constantes para el sistema
class CommunityConstants {
  static const String communityCode = 'COMUNIDAD2025'; // Código para registro
  static const String defaultAdminEmail = 'admin@comunidad.com'; // Primer admin
}
