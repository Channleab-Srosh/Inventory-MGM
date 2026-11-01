import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

/// Reusable 2-step OTP Password Recovery and Reset Dialog
/// Flow:
/// 1. Enter Email -> Backend sends 6-digit OTP via email
/// 2. Enter OTP & New Password -> Reset password via backend API
class ForgotPasswordDialog extends StatefulWidget {
  final String initialInput;
  final void Function(String email, String password) onPasswordReset;

  const ForgotPasswordDialog({
    super.key,
    required this.initialInput,
    required this.onPasswordReset,
  });

  /// Static helper to display the dialog easily from any screen
  static Future<void> show(
    BuildContext context, {
    String initialInput = '',
    required void Function(String email, String password) onPasswordReset,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => ForgotPasswordDialog(
        initialInput: initialInput,
        onPasswordReset: onPasswordReset,
      ),
    );
  }

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  late final TextEditingController _emailCtrl;
  final _otpCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  int _currentStep = 0; // 0: Email, 1: OTP & Reset Password
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _infoMessage;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialInput.trim());
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  // STEP 1: Send OTP to Email
  Future<void> _handleSendOtp({bool isResend = false}) async {
    if (!isResend && !_emailFormKey.currentState!.validate()) return;

    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email address.');
      return;
    }

    final auth = context.read<AuthProvider>();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await auth.sendOtpToEmail(email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      const genericMsg =
          'If an account with that email exists and is eligible, password reset instructions have been sent.';
      setState(() {
        _currentStep = 1;
        _infoMessage = genericMsg;
        _errorMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isResend ? 'Verification code resent to $email' : genericMsg),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      setState(() {
        _errorMessage = auth.error ?? 'Failed to send password reset request.';
      });
    }
  }

  // STEP 2: Reset Password with OTP
  Future<void> _handleResetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;

    final email = _emailCtrl.text.trim();
    final otp = _otpCtrl.text.trim();
    final newPassword = _newPasswordCtrl.text;

    final auth = context.read<AuthProvider>();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await auth.resetPasswordWithOtp(
      email: email,
      otp: otp,
      newPassword: newPassword,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      widget.onPasswordReset(email, newPassword);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Password reset successfully! You can now log in with your new password.'),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      setState(() {
        _errorMessage = auth.error ?? 'Failed to reset password.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: double.infinity , maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with Title and Close Button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.lock_reset, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Forgot Password',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'OTP Verification & Password Recovery',
                          style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: AppColors.secondaryText),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Step Progress Tracker
              _buildStepIndicator(),
              const SizedBox(height: 16),

              // Active Error Banner
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.danger, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.danger, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Content based on Current Step
              Flexible(
                child: SingleChildScrollView(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _currentStep == 0 ? _buildStep1Email(theme) : _buildStep2Reset(theme),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepItem(0, 'Enter Email', Icons.email_outlined),
          Container(
            width: 32,
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: _currentStep >= 1 ? AppColors.primary : Colors.grey.shade300,
          ),
          _buildStepItem(1, 'OTP & New Password', Icons.lock_outline),
        ],
      ),
    );
  }

  Widget _buildStepItem(int stepIndex, String title, IconData icon) {
    final isDone = _currentStep > stepIndex;
    final isCurrent = _currentStep == stepIndex;

    Color color;
    if (isDone) {
      color = AppColors.success;
    } else if (isCurrent) {
      color = AppColors.primary;
    } else {
      color = AppColors.secondaryText;
    }

    return Row(
      // mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isDone ? Icons.check_circle : icon,
          size: 9,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  // --- STEP 1: EMAIL & SEND OTP ---
  Widget _buildStep1Email(ThemeData theme) {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Enter your registered email address to receive a 6-digit OTP verification code:',
            style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address',
              hintText: 'user@example.com',
              prefixIcon: const Icon(Icons.email_outlined, size: 20),
              suffixIcon: _emailCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => _emailCtrl.clear(),
                    )
                  : null,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email address';
              return null;
            },
            onFieldSubmitted: (_) => _handleSendOtp(),
          ),
          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _handleSendOtp(),
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(_isLoading ? 'Sending OTP Code...' : 'Send OTP to Email'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ],
      ),
    );
  }

  // --- STEP 2: ENTER OTP & NEW PASSWORD ---
  Widget _buildStep2Reset(ThemeData theme) {
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Target email info row
          Row(
            children: [
              Expanded(
                child: Text(
                  'Code sent to: ${_emailCtrl.text}',
                  style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _currentStep = 0;
                    _errorMessage = null;
                  });
                },
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('Change', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          if (_infoMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Text(
                _infoMessage!,
                style: const TextStyle(fontSize: 12, color: AppColors.primaryDark),
              ),
            ),
          ],
          const SizedBox(height: 14),

          // 6-digit OTP input field
          TextFormField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
              color: AppColors.primary,
            ),
            decoration: const InputDecoration(
              labelText: '6-Digit OTP Code',
              hintText: '123456',
              counterText: '',
              prefixIcon: Icon(Icons.pin_outlined, size: 20),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'OTP code is required';
              if (!RegExp(r'^\d{6}$').hasMatch(v.trim())) {
                return 'OTP must be exactly 6 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 6),

          // Resend OTP action
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _isLoading ? null : () => _handleSendOtp(isResend: true),
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Resend Code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),

          // New Password field
          TextFormField(
            controller: _newPasswordCtrl,
            obscureText: _obscureNew,
            decoration: InputDecoration(
              labelText: 'New Password *',
              hintText: 'Minimum 6 characters',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter a new password';
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Confirm Password field
          TextFormField(
            controller: _confirmPasswordCtrl,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: 'Confirm New Password *',
              hintText: 'Re-enter your new password',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password';
              if (v != _newPasswordCtrl.text) return 'Passwords do not match';
              return null;
            },
            onFieldSubmitted: (_) => _handleResetPassword(),
          ),
          const SizedBox(height: 16),

          // Submit Reset Button
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleResetPassword,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.lock_reset, size: 18),
            label: Text(_isLoading ? 'Updating Password...' : 'Reset Password & Sign In'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ],
      ),
    );
  }
}
