import 'package:equatable/equatable.dart';

/// User entity - domain layer representation
class User extends Equatable {
  final int? id;
  final String email;
  final String fullName;
  final String? phone;
  final UserRole role;
  final String? avatarUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.role,
    this.avatarUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if user is a veterinarian
  bool get isVeterinarian => role == UserRole.veterinarian;

  /// Check if user is staff
  bool get isStaff => role == UserRole.staff;

  /// Check if user is admin
  bool get isAdmin => role == UserRole.admin;

  /// Check if user is a pet owner
  bool get isPetOwner => role == UserRole.petOwner;

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        phone,
        role,
        avatarUrl,
        isActive,
        createdAt,
        updatedAt,
      ];

  User copyWith({
    int? id,
    String? email,
    String? fullName,
    String? phone,
    UserRole? role,
    String? avatarUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// User roles enum
enum UserRole {
  petOwner('PET_OWNER'),
  veterinarian('VETERINARIAN'),
  staff('STAFF'),
  admin('ADMIN');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.petOwner,
    );
  }

  String get displayName {
    switch (this) {
      case UserRole.petOwner:
        return 'Pet Owner';
      case UserRole.veterinarian:
        return 'Veterinarian';
      case UserRole.staff:
        return 'Staff';
      case UserRole.admin:
        return 'Admin';
    }
  }
}

/// Authentication result
class AuthResult extends Equatable {
  final User user;
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  const AuthResult({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  @override
  List<Object?> get props => [user, accessToken, refreshToken, expiresAt];
}