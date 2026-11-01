import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_components.dart';

/// Feature 6: Register Screen (Staff only registration)
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _otpSent = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.sendRegistrationOtp(_emailCtrl.text.trim());
    if (ok && mounted) {
      setState(() {
        _otpSent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification code sent to ${_emailCtrl.text.trim()}'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _resendCode() async {
    final email = _emailCtrl.text.trim();
    final gmailRegex = RegExp(r'^[a-zA-Z0-9._%+\-]+@gmail\.com$');
    if (!gmailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid Gmail address (@gmail.com)'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.sendRegistrationOtp(email);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A new verification code was sent to $email'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final fullName = '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'.trim();
    final phone = _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null;

    final success = await auth.register(
      username: _usernameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      fullName: fullName,
      phone: phone,
      otp: _otpCtrl.text.trim(),
    );

    if (success && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 52),
          title: const Text('Registration Submitted', textAlign: TextAlign.center),
          content: const Text(
            'Your email has been verified! Your account is now pending administrator approval before you can log in.\n\nPlease notify your system administrator to approve your account.',
            textAlign: TextAlign.center,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/login');
                },
                child: const Text('Back to Login'),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ResponsiveContainer(
              maxWidth: 440,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Join Inventory Workspace',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Register as a new staff member to manage inventory operations.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Staff Role Notice
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_outlined,
                              color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Standard staff permissions: View products & suppliers, perform Stock In & Stock Out. Staff accounts cannot add/edit/delete products or suppliers, view categories, or manage users.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Error banner
                    if (auth.error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.3)),
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

                    // Username
                    TextFormField(
                      controller: _usernameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.alternate_email, size: 20),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Username is required';
                        }
                        final len = v.trim().length;
                        if (len < 3 || len > 50) {
                          return 'Username must be between 3 and 50 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Email
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address (@gmail.com)',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email is required';
                        }
                        final gmailRegex = RegExp(r'^[a-zA-Z0-9._%+\-]+@gmail\.com$');
                        if (!gmailRegex.hasMatch(v.trim())) {
                          return 'Only Gmail addresses (@gmail.com) are allowed';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // First & Last Name row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'First Name',
                              prefixIcon: Icon(Icons.person_outline, size: 20),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Last Name',
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Phone (Optional)
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone (Optional)',
                        prefixIcon: Icon(Icons.phone_outlined, size: 20),
                      ),
                      validator: (v) {
                        if (v != null && v.trim().length > 20) {
                          return 'Phone cannot exceed 20 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Password
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 6) return 'Minimum 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Confirm Password
                    TextFormField(
                      controller: _confirmPasswordCtrl,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
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
                          return 'Please confirm password';
                        }
                        if (v != _passwordCtrl.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // 6-digit OTP code (only displayed after Send code is tapped)
                    if (_otpSent) ...[
                      TextFormField(
                        controller: _otpCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 6,
                        ),
                        decoration: const InputDecoration(
                          labelText: '6-Digit OTP Code',
                          hintText: '123456',
                          counterText: '',
                          prefixIcon: Icon(Icons.pin_outlined, size: 20),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'OTP code is required';
                          }
                          if (!RegExp(r'^\d{6}$').hasMatch(v.trim())) {
                            return 'OTP must be exactly 6 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: auth.loading ? null : _resendCode,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Resend Code',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 10),

                    // Submit Button
                    AppButton(
                      label: _otpSent ? 'Register' : 'Send code',
                      onPressed: auth.loading
                          ? null
                          : (_otpSent ? _register : _sendCode),
                      isLoading: auth.loading,
                    ),
                    const SizedBox(height: 16),

                    // Link back to login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account? ',
                            style: theme.textTheme.bodyMedium),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: theme.textTheme.bodyMedium?.fontSize,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
