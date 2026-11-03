import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';

/// Feature 15: Profile Screen (Every user can see: Name, Username, Email, Role, Status, Created Date)
/// Actions: Edit Profile, Change Password
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final theme = Theme.of(context);
    final isAdmin = user?.isAdmin == true;
    final isWarehouseManager = user?.isWarehouseManager == true;
    final roleColor = isAdmin
        ? AppColors.primary
        : (isWarehouseManager ? const Color(0xFFD97706) : const Color(0xFF0EA5E9));

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
          // Avatar & Header
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: roleColor,
                  child: Text(
                    user?.initials ?? 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.verified_user, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              user?.name ?? 'User',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 2),
          Center(
            child: Text(
              '@${user?.username ?? user?.email.split('@').first ?? ""}',
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    user?.roleBadgeLabel ?? 'STAFF',
                    style: TextStyle(
                      color: roleColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: (user?.isActive == true ? AppColors.inStock : AppColors.danger)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 3,
                        backgroundColor:
                            user?.isActive == true ? AppColors.inStock : AppColors.danger,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        (user?.status ?? 'Active').toUpperCase(),
                        style: TextStyle(
                          color: user?.isActive == true ? AppColors.inStock : AppColors.danger,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // User Information Card (Required by Notion Page 17: Name, Username, Email, Role, Status, Created Date)
          Card(
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.badge_outlined,
                  label: 'Full Name',
                  value: user?.name ?? '-',
                ),
                const Divider(height: 1, indent: 56),
                _InfoTile(
                  icon: Icons.alternate_email,
                  label: 'Username',
                  value: '@${user?.username ?? "-"}',
                ),
                const Divider(height: 1, indent: 56),
                _InfoTile(
                  icon: Icons.email_outlined,
                  label: 'Email Address',
                  value: user?.email ?? '-',
                ),
                const Divider(height: 1, indent: 56),
                _InfoTile(
                  icon: Icons.phone_outlined,
                  label: 'Phone Number',
                  value: (user?.phone != null && user!.phone!.isNotEmpty) ? user.phone! : 'Not set',
                ),
                const Divider(height: 1, indent: 56),
                _InfoTile(
                  icon: Icons.security_outlined,
                  label: 'System Role',
                  value: user?.roleDisplayName ?? 'Staff',
                ),
                const Divider(height: 1, indent: 56),
                _InfoTile(
                  icon: Icons.check_circle_outline,
                  label: 'Account Status',
                  value: user?.status ?? 'Active',
                ),
                const Divider(height: 1, indent: 56),
                _InfoTile(
                  icon: Icons.calendar_today_outlined,
                  label: 'Member Since',
                  value: user?.createdAt != null
                      ? AppUtils.formatDate(user!.createdAt)
                      : '01-Jan-2026',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Actions
          OutlinedButton.icon(
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Profile'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _EditProfileScreen()),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
          const SizedBox(height: 12),

          OutlinedButton.icon(
            icon: const Icon(Icons.lock_reset_outlined),
            label: const Text('Change Password'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _ChangePasswordScreen()),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    ),
  ),
);
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
      subtitle: Text(
        value,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Edit profile info screen
class _EditProfileScreen extends StatefulWidget {
  const _EditProfileScreen();

  @override
  State<_EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<_EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstCtrl;
  late final TextEditingController _lastCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _firstCtrl = TextEditingController(text: user?.firstName ?? user?.name ?? '');
    _lastCtrl = TextEditingController(text: user?.lastName ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthProvider>().updateDetailedProfile(
          firstName: _firstCtrl.text.trim(),
          lastName: _lastCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Profile updated successfully!'),
          ],
        ),
        backgroundColor: AppColors.inStock,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
            TextFormField(
              controller: _firstCtrl,
              decoration: const InputDecoration(
                labelText: 'First Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'First name is required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _lastCtrl,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }
}

/// Change password screen with actual verification
class _ChangePasswordScreen extends StatefulWidget {
  const _ChangePasswordScreen();

  @override
  State<_ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<_ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _newCtrl.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _newCtrl.removeListener(_onPasswordChanged);
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final auth = context.read<AuthProvider>();
    final ok = await auth.changePassword(_currentCtrl.text, _newCtrl.text);

    if (mounted) {
      setState(() => _submitting = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Password changed successfully!'),
              ],
            ),
            backgroundColor: AppColors.inStock,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.error ?? 'Incorrect current password'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
            _PasswordField(
              controller: _currentCtrl,
              label: 'Current Password',
              hint: 'Enter your existing password',
              obscure: _obscureCurrent,
              onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Current password is required' : null,
            ),
            const SizedBox(height: 14),
            _PasswordField(
              controller: _newCtrl,
              label: 'New Password',
              hint: 'At least 8 characters with complexity',
              obscure: _obscureNew,
              onToggle: () => setState(() => _obscureNew = !_obscureNew),
              validator: (v) => AppUtils.validateNewPassword(v, _currentCtrl.text),
            ),
            const SizedBox(height: 8),
            _PasswordChecklistBox(password: _newCtrl.text),
            const SizedBox(height: 14),
            _PasswordField(
              controller: _confirmCtrl,
              label: 'Confirm New Password',
              hint: 'Re-enter your new password',
              obscure: _obscureConfirm,
              onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              validator: (v) => AppUtils.validateConfirmPassword(v, _newCtrl.text),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _submitting ? null : _save,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.lock_reset),
              label: const Text('Update Password'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscure;
  final VoidCallback onToggle;
  final FormFieldValidator<String>? validator;

  const _PasswordField({
    required this.controller,
    required this.label,
    this.hint,
    required this.obscure,
    required this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: onToggle,
        ),
      ),
      validator: validator,
    );
  }
}

class _PasswordChecklistBox extends StatelessWidget {
  final String password;
  const _PasswordChecklistBox({required this.password});

  @override
  Widget build(BuildContext context) {
    final hasMinLength = password.length >= 8;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasLower = RegExp(r'[a-z]').hasMatch(password);
    final hasDigit = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecial = RegExp(r'[!@#\$%^&*(),.?":{}|<>\-_+=~`]').hasMatch(password);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'New password requirements:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 6),
          _ChecklistRow(label: 'At least 8 characters', met: hasMinLength),
          _ChecklistRow(label: 'At least 1 uppercase letter (A-Z)', met: hasUpper),
          _ChecklistRow(label: 'At least 1 lowercase letter (a-z)', met: hasLower),
          _ChecklistRow(label: 'At least 1 number (0-9)', met: hasDigit),
          _ChecklistRow(label: 'At least 1 special character (!@#\$%&*)', met: hasSpecial),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final String label;
  final bool met;
  const _ChecklistRow({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.circle_outlined,
            size: 14,
            color: met ? AppColors.inStock : AppColors.muted,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: met ? AppColors.inStock : AppColors.secondaryText,
              fontWeight: met ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
