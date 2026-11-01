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
  DateTime createdAt;
  final bool mustChangePassword;

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
    DateTime? createdAt,
    this.mustChangePassword = false,
  }) : createdAt = createdAt ?? DateTime.now() {
    if (username == null || username!.isEmpty) {
      username = email.contains('@') ? email.split('@').first : email;
    }
    if (firstName == null && lastName == null) {
      final parts = name.trim().split(' ');
      firstName = parts.isNotEmpty ? parts.first : '';
      lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final fullName = json['fullName']?.toString() ?? json['name']?.toString() ?? '';
    final active = json['active'] as bool?;
    String status = 'Active';
    if (active != null) {
      status = active ? 'Active' : 'Inactive';
    } else if (json['status'] != null) {
      status = json['status'].toString();
    }

    // Role handling (strip "ROLE_" if present)
    String role = json['role']?.toString().toUpperCase() ?? 'STAFF';
    if (role.startsWith('ROLE_')) {
      role = role.substring(5);
    }

    return UserProfile(
      id: json['id']?.toString() ?? '',
      name: fullName,
      email: json['email']?.toString() ?? '',
      role: role,
      username: json['username']?.toString(),
      phone: json['phone']?.toString(),
      status: status,
      avatarUrl: json['avatarUrl']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      mustChangePassword: json['mustChangePassword'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': name,
      'name': name,
      'email': email,
      'role': role,
      'username': username,
      'phone': phone,
      'active': status.toLowerCase() == 'active',
      'createdAt': createdAt.toIso8601String(),
      'mustChangePassword': mustChangePassword,
    };
  }

  static const String roleAdmin = 'ADMIN';
  static const String roleManager = 'MANAGER';
  static const String roleWarehouseManager = 'WAREHOUSE_MANAGER';
  static const String roleStaff = 'STAFF';

  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  bool get isManager =>
      role.toUpperCase() == 'MANAGER' ||
      role.toUpperCase() == 'WAREHOUSE_MANAGER' ||
      role.toUpperCase() == 'WAREHOUSE MANAGER';
  bool get isWarehouseManager => isManager;
  bool get isStaff => role.toUpperCase() == 'STAFF';
  bool get isActive => status.toLowerCase() == 'active';

  /// Role-based permissions
  /// Staff cannot manage users.
  bool get canManageUsers => isAdmin && !isStaff;
  bool get canStockOut => true; // Staff, Manager, and Admin can all perform stock out
  bool get canStockIn => true;

  /// Supplier permissions: Staff cannot add/edit/delete suppliers (view only)
  bool get canManageSuppliers => !isStaff && (isAdmin || isManager);
  bool get canViewSuppliers => true;

  /// Category permissions: Staff can view categories (read-only), Admin & Manager can manage
  bool get canViewCategories => true;
  bool get canManageCategories => !isStaff && (isAdmin || isManager);

  /// Product permissions: Staff cannot add/edit/delete products (view only)
  bool get canManageProducts => !isStaff && (isAdmin || isManager);
  bool get canViewProducts => true;

  /// Customer permissions: Staff can view; Admin and Manager can create/update/status; Admin can delete
  bool get canViewCustomers => true;
  bool get canManageCustomers => !isStaff && (isAdmin || isManager);
  bool get canDeleteCustomers => isAdmin;

  /// Human-friendly display label for the role
  String get roleDisplayName {
    if (isAdmin) return 'Admin';
    if (isManager) {
      if (role.toUpperCase().contains('WAREHOUSE')) return 'Warehouse Manager';
      return 'Manager';
    }
    if (isStaff) return 'Staff';
    return role;
  }

  /// Uppercase badge title for the role
  String get roleBadgeLabel {
    if (isAdmin) return 'ADMIN';
    if (isManager) {
      if (role.toUpperCase().contains('WAREHOUSE')) return 'WAREHOUSE MANAGER';
      return 'MANAGER';
    }
    if (isStaff) return 'STAFF';
    return role.toUpperCase();
  }

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
    DateTime? createdAt,
    bool? mustChangePassword,
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
      createdAt: createdAt ?? this.createdAt,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
    );
  }
}
