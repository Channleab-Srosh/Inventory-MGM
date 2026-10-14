/// User profile model for authentication and User Management
class UserProfile {
  final String id;
  String name;
  String email;
  String role;
  String? username;
  String? firstName;
  String? lastName;
  String? phone;
  String status;
  String? avatarUrl;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.username,
    this.firstName,
    this.lastName,
    this.phone,
    this.status = 'Active',
    this.avatarUrl,
  }) {
    if (username == null || username!.isEmpty) {
      username = email.contains('@') ? email.split('@').first : email;
    }
    if (firstName == null && lastName == null) {
      final parts = name.trim().split(' ');
      firstName = parts.isNotEmpty ? parts.first : '';
      lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }
  }

  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  bool get isStaff => role.toUpperCase() == 'STAFF';
  bool get isActive => status.toLowerCase() == 'active';

  /// Avatar initials for display
  String get initials {
    if (firstName != null &&
        firstName!.isNotEmpty &&
        lastName != null &&
        lastName!.isNotEmpty) {
      return '${firstName![0]}${lastName![0]}'.toUpperCase();
    }
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? role,
    String? username,
    String? firstName,
    String? lastName,
    String? phone,
    String? status,
    String? avatarUrl,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
