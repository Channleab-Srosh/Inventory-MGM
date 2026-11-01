import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/user_profile.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';

/// Reusable modal sheet for adding and editing users (Admin only)
class AddEditUserSheet extends StatefulWidget {
  final UserProfile? user;
  const AddEditUserSheet({super.key, this.user});

  static Future<void> show(BuildContext context, {UserProfile? user}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddEditUserSheet(user: user),
    );
  }

  @override
  State<AddEditUserSheet> createState() => _AddEditUserSheetState();
}

class _AddEditUserSheetState extends State<AddEditUserSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _passwordCtrl;
  bool _obscurePassword = true;
  String _role = 'STAFF';
  String _status = 'Active';
  bool _isSubmitting = false;
  String? _serverError;

  bool get _isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _usernameCtrl = TextEditingController(text: u?.username ?? '');
    _nameCtrl = TextEditingController(text: u?.name ?? '');
    _emailCtrl = TextEditingController(text: u?.email ?? '');
    _phoneCtrl = TextEditingController(text: u?.phone ?? '');
    _passwordCtrl = TextEditingController(
      text: u == null ? AppUtils.generateRandomPassword() : '',
    );
    if (u != null) {
      _role = u.role.toUpperCase();
      _status = u.status;
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _serverError = null);
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();

    final username = _usernameCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim();

    // Check admin limit (Max 3)
    final int currentAdminCount = auth.users.where((u) => u.isAdmin).length;
    final bool targetIsAdmin = widget.user?.isAdmin ?? false;
    if (_role == 'ADMIN' && !targetIsAdmin && currentAdminCount >= 3) {
      setState(() {
        _serverError = 'Cannot assign ADMIN: Maximum limit of 3 administrator accounts has been reached.';
      });
      return;
    }

    setState(() => _isSubmitting = true);

    if (_isEditing) {
      final updated = widget.user!.copyWith(
        username: username,
        name: name,
        email: email,
        phone: phone,
        role: _role,
        status: _status,
      );
      final ok = await auth.updateUser(updated);
      if (mounted) {
        setState(() => _isSubmitting = false);
        if (ok) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User details updated successfully!')),
          );
        } else {
          setState(() {
            _serverError = auth.error ?? 'Failed to update user';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(auth.error ?? 'Failed to update user'), backgroundColor: AppColors.danger),
          );
        }
      }
    } else {
      final newUser = UserProfile(
        id: 'u${DateTime.now().millisecondsSinceEpoch}',
        username: username,
        name: name,
        email: email,
        phone: phone,
        role: _role,
        status: _status,
        createdAt: DateTime.now(),
      );
      final customPassword = _passwordCtrl.text.trim();
      final password = customPassword.isEmpty ? AppUtils.generateRandomPassword() : customPassword;
      final ok = await auth.addUser(newUser, password: password);
      if (mounted) {
        setState(() => _isSubmitting = false);
        if (ok) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('New user created! Random password sent to ${newUser.email}. First login requires password change.'),
              backgroundColor: AppColors.inStock,
            ),
          );
        } else {
          setState(() {
            _serverError = auth.error ?? 'Failed to create user';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(auth.error ?? 'Failed to create user'), backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 540,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isEditing ? 'Edit User' : 'Create New User',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              if (_serverError != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _serverError!,
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Username
              TextFormField(
                controller: _usernameCtrl,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'e.g. dara or sokha',
                  prefixIcon: Icon(Icons.alternate_email, size: 20),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Username is required';
                  final trimmed = v.trim();
                  if (trimmed.length < 3) return 'Minimum 3 characters';
                  if (trimmed.length > 50) return 'Maximum 50 characters';
                  if (RegExp(r'\s').hasMatch(trimmed)) return 'Username cannot contain spaces';

                  final auth = context.read<AuthProvider>();
                  final exists = auth.users.any((u) =>
                      u.id != widget.user?.id &&
                      u.username?.toLowerCase() == trimmed.toLowerCase());
                  if (exists) {
                    return 'User already exists';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Full Name
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'e.g. Dara Chann',
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Full name is required' : null,
              ),
              const SizedBox(height: 14),

              // Email
              TextFormField(
                controller: _emailCtrl,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address (Gmail)',
                  hintText: 'dara@gmail.com',
                  prefixIcon: Icon(Icons.email_outlined, size: 20),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  final trimmed = v.trim();
                  final gmailRegex = RegExp(r'^[a-zA-Z0-9._%+\-]+@gmail\.com$');
                  if (!gmailRegex.hasMatch(trimmed)) {
                    return 'Only Gmail addresses (@gmail.com) are allowed';
                  }
                  final auth = context.read<AuthProvider>();
                  final exists = auth.users.any((u) =>
                      u.id != widget.user?.id &&
                      u.email.toLowerCase() == trimmed.toLowerCase());
                  if (exists) {
                    return 'Email already registered';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Phone
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                  hintText: '+855 12 345 678',
                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 14),

              // Temporary Generated Password (only when creating)
              if (!_isEditing) ...[
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Generated Temporary Password',
                    hintText: 'Auto-generated secure password',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Generate new random password',
                          icon: const Icon(Icons.refresh, size: 20),
                          onPressed: () {
                            setState(() {
                              _passwordCtrl.text = AppUtils.generateRandomPassword();
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ],
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Password is required';
                    }
                    if (v.trim().length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryActive,
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.mark_email_read_outlined,
                          size: 18, color: AppColors.primaryDark),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'A secure random password has been generated and will be sent automatically to the user\'s email address. The user will be required to change this password on their first login.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Role selector
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _role,
                decoration: const InputDecoration(
                  labelText: 'System Role',
                  prefixIcon: Icon(Icons.badge_outlined, size: 20),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'ADMIN',
                    child: Text('ADMIN (Full Access)', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'MANAGER',
                    child: Text('MANAGER (Inventory Management)', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'STAFF',
                    child: Text('STAFF (Standard Operations)', overflow: TextOverflow.ellipsis),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _role = val);
                },
              ),
              const SizedBox(height: 14),

              // Status selector
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Account Status',
                  prefixIcon: Icon(Icons.toggle_on_outlined, size: 20),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Active',
                    child: Text('Active (Can Log In)', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'Inactive',
                    child: Text('Inactive (Suspended)', overflow: TextOverflow.ellipsis),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _status = val);
                },
              ),
              const SizedBox(height: 24),

              // Submit button
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _save,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check),
                label: Text(
                  _isSubmitting
                      ? 'Processing...'
                      : (_isEditing ? 'Save Changes' : 'Create User'),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}

/// Dialog to change a user's system role
class UserRoleDialog {
  static Future<String?> show(BuildContext context, {required UserProfile target}) {
    String selectedRole = target.role.toUpperCase();
    if (selectedRole != 'ADMIN' && selectedRole != 'MANAGER' && selectedRole != 'STAFF') {
      selectedRole = 'STAFF';
    }

    final auth = context.read<AuthProvider>();
    final int adminCount = auth.users.where((u) => u.isAdmin).length;
    final bool isAlreadyAdmin = target.isAdmin;
    final bool adminLimitReached = !isAlreadyAdmin && adminCount >= 3;

    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Change User Role'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select a new role for "${target.name}":',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  if (adminLimitReached) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.danger),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Cannot assign ADMIN: Maximum limit of 3 administrator accounts has been reached.',
                              style: TextStyle(fontSize: 11, color: AppColors.danger, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  RadioGroup<String>(
                    groupValue: selectedRole,
                    onChanged: (val) {
                      if (val != null) {
                        if (val == 'ADMIN' && adminLimitReached) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cannot assign ADMIN: Maximum limit of 3 administrator accounts reached.'),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                          return;
                        }
                        setDialogState(() => selectedRole = val);
                      }
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioListTile<String>(
                          value: 'ADMIN',
                          title: Row(
                            children: [
                              const Text('ADMIN'),
                              const SizedBox(width: 6),
                              Text(
                                '($adminCount/3 active)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: adminLimitReached ? AppColors.danger : AppColors.secondaryText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            adminLimitReached
                                ? 'Limit reached (3 max). Demote an existing admin first.'
                                : 'Full system access and user management',
                            style: TextStyle(
                              fontSize: 12,
                              color: adminLimitReached ? AppColors.danger : null,
                            ),
                          ),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        const RadioListTile<String>(
                          value: 'MANAGER',
                          title: Text('MANAGER'),
                          subtitle: Text('Product & inventory management without user administration', style: TextStyle(fontSize: 12)),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        const RadioListTile<String>(
                          value: 'STAFF',
                          title: Text('STAFF'),
                          subtitle: Text('Standard inventory operations', style: TextStyle(fontSize: 12)),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: (selectedRole == 'ADMIN' && adminLimitReached)
                    ? null
                    : () => Navigator.pop(ctx, selectedRole),
                child: const Text('Save Role'),
              ),
            ],
          );
        },
      ),
    );
  }
}
