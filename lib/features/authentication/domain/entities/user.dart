import 'package:equatable/equatable.dart';

/// User entity - domain layer representation
class User extends Equatable {
  final int? id;

  /// Firebase Auth UID for cloud-backed accounts. Null for legacy/local-only records.
  final String? firebaseUid;
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
    this.firebaseUid,
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

  /// Check if user is the Owner/Admin (paper-aligned single clinic operator)
  bool get isOwnerAdmin => role == UserRole.ownerAdmin;

  @override
  List<Object?> get props => [
    id,
    firebaseUid,
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
    String? firebaseUid,
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
      firebaseUid: firebaseUid ?? this.firebaseUid,
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
///
/// Active paper-aligned roles: [petOwner] and [ownerAdmin].
/// [staff], [veterinarian], [admin] are RESERVE roles for a bigger future
/// clinic — still valid, still enforced, just not provisioned for the
/// single-operator (DocMyk's PILA VET HUB) deployment.
enum UserRole {
  petOwner('PET_OWNER'),
  veterinarian('VETERINARIAN'),
  staff('STAFF'),
  admin('ADMIN'),
  ownerAdmin('OWNER_ADMIN');

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
      case UserRole.ownerAdmin:
        return 'Owner/Admin';
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
