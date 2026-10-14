import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../data/mock_data.dart';
import '../core/constants/app_constants.dart';

/// Handles authentication state, profile, and user management for ADMIN
class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  UserProfile? _user;
  String? _error;
  bool _loading = false;

  // In-memory users list for User Management
  final List<UserProfile> _users = [
    UserProfile(
      id: 'u1',
      username: 'admin',
      name: 'Alex Johnson',
      firstName: 'Alex',
      lastName: 'Johnson',
      email: AppConstants.mockEmail,
      role: 'ADMIN',
      phone: '+1 555-0199',
      status: 'Active',
    ),
    UserProfile(
      id: 'u2',
      username: 'sarah.c',
      name: 'Sarah Connor',
      firstName: 'Sarah',
      lastName: 'Connor',
      email: 'staff@inventory.com',
      role: 'STAFF',
      phone: '+1 555-0244',
      status: 'Active',
    ),
    UserProfile(
      id: 'u3',
      username: 'john.doe',
      name: 'John Doe',
      firstName: 'John',
      lastName: 'Doe',
      email: 'john@inventory.com',
      role: 'STAFF',
      phone: '+1 555-0377',
      status: 'Inactive',
    ),
  ];

  bool get isAuthenticated => _isAuthenticated;
  UserProfile? get user => _user;
  String? get error => _error;
  bool get loading => _loading;
  List<UserProfile> get users => List.unmodifiable(_users);

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Mock login: checks against hardcoded credentials or registered users
  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    final cleanEmail = email.trim().toLowerCase();
    
    // Check against standard mock user or matching user in _users
    if (cleanEmail == AppConstants.mockEmail.toLowerCase() &&
        password == AppConstants.mockPassword) {
      _isAuthenticated = true;
      _user = _users.firstWhere(
        (u) => u.email.toLowerCase() == cleanEmail,
        orElse: () => MockData.currentUser,
      );
      _loading = false;
      notifyListeners();
      return true;
    }

    // Check staff demo login or other in-memory users
    final found = _users.firstWhere(
      (u) =>
          (u.email.toLowerCase() == cleanEmail ||
              u.username?.toLowerCase() == cleanEmail) &&
          password == 'password123',
      orElse: () => UserProfile(id: '', name: '', email: '', role: ''),
    );

    if (found.id.isNotEmpty) {
      if (!found.isActive) {
        _error = 'This account has been deactivated. Contact an administrator.';
        _loading = false;
        notifyListeners();
        return false;
      }
      _isAuthenticated = true;
      _user = found;
      _loading = false;
      notifyListeners();
      return true;
    }

    _error = 'Invalid email/username or password.';
    _loading = false;
    notifyListeners();
    return false;
  }

  /// Feature 6: Register Screen - Always creates STAFF role
  Future<bool> register({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    final exists = _users.any((u) =>
        u.email.toLowerCase() == email.trim().toLowerCase() ||
        u.username?.toLowerCase() == username.trim().toLowerCase());

    if (exists) {
      _error = 'A user with this email or username already exists.';
      _loading = false;
      notifyListeners();
      return false;
    }

    final newUser = UserProfile(
      id: 'u${DateTime.now().millisecondsSinceEpoch}',
      username: username.trim(),
      name: '$firstName $lastName'.trim(),
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.trim().toLowerCase(),
      role: 'STAFF', // Strictly STAFF
      status: 'Active',
    );

    _users.add(newUser);
    _isAuthenticated = true;
    _user = newUser;
    _loading = false;
    notifyListeners();
    return true;
  }

  /// Update user profile
  void updateProfile(String name, String email) {
    if (_user != null) {
      _user = _user!.copyWith(name: name, email: email);
      final idx = _users.indexWhere((u) => u.id == _user!.id);
      if (idx != -1) {
        _users[idx] = _user!;
      }
      notifyListeners();
    }
  }

  /// Feature 41: Edit Profile details (cannot change own role)
  void updateDetailedProfile({
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
  }) {
    if (_user != null) {
      _user = _user!.copyWith(
        firstName: firstName,
        lastName: lastName,
        name: '$firstName $lastName'.trim(),
        email: email,
        phone: phone,
      );
      final idx = _users.indexWhere((u) => u.id == _user!.id);
      if (idx != -1) {
        _users[idx] = _user!;
      }
      notifyListeners();
    }
  }

  /// Feature 42: Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _loading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));

    if (currentPassword != AppConstants.mockPassword && currentPassword != 'password123') {
      _error = 'Current password is incorrect';
      _loading = false;
      notifyListeners();
      return false;
    }

    _loading = false;
    _error = null;
    notifyListeners();
    return true;
  }

  /// Feature 45: Add User (Admin only)
  void addUser(UserProfile newUser) {
    _users.add(newUser);
    notifyListeners();
  }

  /// Feature 46: Edit User (Admin only)
  void updateUser(UserProfile updated) {
    final idx = _users.indexWhere((u) => u.id == updated.id);
    if (idx != -1) {
      _users[idx] = updated;
      if (_user?.id == updated.id) {
        _user = updated;
      }
      notifyListeners();
    }
  }

  /// Feature 47: Toggle active/inactive status (Admin only)
  void toggleUserStatus(String userId) {
    final idx = _users.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      final current = _users[idx];
      final newStatus = current.isActive ? 'Inactive' : 'Active';
      _users[idx] = current.copyWith(status: newStatus);
      if (_user?.id == userId) {
        _user = _users[idx];
      }
      notifyListeners();
    }
  }

  void logout() {
    _isAuthenticated = false;
    _user = null;
    _error = null;
    notifyListeners();
  }
}
