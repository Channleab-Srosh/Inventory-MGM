import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_components.dart';

/// Screen displayed when user must change their temporary password on first login
class ForceChangePasswordScreen extends StatefulWidget {
  const ForceChangePasswordScreen({super.key});

  @override
  State<ForceChangePasswordScreen> createState() => _ForceChangePasswordScreenState();
}

class _ForceChangePasswordScreenState extends State<ForceChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.changePassword(
      _currentPasswordCtrl.text,
      _newPasswordCtrl.text,
    );

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully! Welcome.'),
          backgroundColor: AppColors.inStock,
        ),
      );
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Update Password'),
          automaticallyImplyLeading: false,
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Sign Out'),
              onPressed: () async {
                await auth.logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ResponsiveContainer(
                maxWidth: 440,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Icon & Title
                      Center(
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_reset,
                            size: 36,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Password Change Required',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user != null
                            ? 'Welcome, ${user.name}! Because this is your first login or your account was created by an administrator, please change your temporary password before proceeding.'
                            : 'Please change your temporary password before proceeding.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.secondaryText,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Error banner
                      if (auth.error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            auth.error!,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Current / Temporary Password
                      TextFormField(
                        controller: _currentPasswordCtrl,
                        obscureText: _obscureCurrent,
                        decoration: InputDecoration(
                          labelText: 'Temporary / Current Password',
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureCurrent
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscureCurrent = !_obscureCurrent),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please enter your temporary password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // New Password
                      TextFormField(
                        controller: _newPasswordCtrl,
                        obscureText: _obscureNew,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          prefixIcon: const Icon(Icons.lock, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNew
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscureNew = !_obscureNew),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please enter a new password';
                          }
                          if (v.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          if (v == _currentPasswordCtrl.text) {
                            return 'New password must be different from temporary password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Confirm New Password
                      TextFormField(
                        controller: _confirmPasswordCtrl,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          prefixIcon: const Icon(Icons.lock, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please confirm your new password';
                          }
                          if (v != _newPasswordCtrl.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Info banner
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryActive,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline,
                                size: 18, color: AppColors.primaryDark),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Once your password is updated, you will have immediate full access to your workspace according to your assigned role.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primaryDark,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      AppButton(
                        label: 'Update Password & Continue',
                        onPressed: auth.loading ? null : _submit,
                        isLoading: auth.loading,
                      ),
                      const SizedBox(height: 16),

                      // Sign out link
                      Center(
                        child: TextButton(
                          onPressed: () async {
                            await auth.logout();
                            if (context.mounted) {
                              context.go('/login');
                            }
                          },
                          child: const Text('Log out and return to sign in'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
