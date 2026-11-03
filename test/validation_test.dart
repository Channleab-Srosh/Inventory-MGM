import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management/core/utils/app_utils.dart';

void main() {
  group('Sign Up and Change Password Validation Tests', () {
    test('Password complexity validator enforces 8+ chars, upper, lower, digit, special', () {
      expect(AppUtils.validatePassword(null), 'Password is required');
      expect(AppUtils.validatePassword(''), 'Password is required');
      expect(AppUtils.validatePassword('Short1!'), 'Password must be at least 8 characters');
      expect(AppUtils.validatePassword('lowercase123!'), contains('uppercase'));
      expect(AppUtils.validatePassword('UPPERCASE123!'), contains('lowercase'));
      expect(AppUtils.validatePassword('NoDigitsHere!'), contains('number'));
      expect(AppUtils.validatePassword('NoSpecialChar123'), contains('special character'));
      expect(AppUtils.validatePassword('ValidPass@123'), isNull);
    });

    test('Confirm password validator checks equality', () {
      expect(AppUtils.validateConfirmPassword(null, 'ValidPass@123'), 'Please confirm password');
      expect(AppUtils.validateConfirmPassword('Mismatch@123', 'ValidPass@123'), 'Passwords do not match');
      expect(AppUtils.validateConfirmPassword('ValidPass@123', 'ValidPass@123'), isNull);
    });

    test('Change password validator blocks identical new password', () {
      expect(AppUtils.validateNewPassword('OldPassword@123', 'OldPassword@123'),
          'New password cannot be the same as current password');
      expect(AppUtils.validateNewPassword('NewPassword@123', 'OldPassword@123'), isNull);
    });

    test('Sign up username validator enforces length and allowed chars', () {
      expect(AppUtils.validateUsername(null), 'Username is required');
      expect(AppUtils.validateUsername('ab'), 'Username must be between 3 and 50 characters');
      expect(AppUtils.validateUsername('user name with spaces'), contains('Only letters, numbers'));
      expect(AppUtils.validateUsername('valid_user.123'), isNull);
    });

    test('Sign up email validator enforces Gmail address', () {
      expect(AppUtils.validateEmail(null), 'Email is required');
      expect(AppUtils.validateEmail('user@yahoo.com'), 'Only Gmail addresses (@gmail.com) are allowed');
      expect(AppUtils.validateEmail('user@gmail.com'), isNull);
    });

    test('Sign up name validator enforces letters and reasonable length', () {
      expect(AppUtils.validateNamePart(null, 'First name'), 'First name is required');
      expect(AppUtils.validateNamePart('John123', 'First name'), 'Only letters, spaces, and hyphens allowed');
      expect(AppUtils.validateNamePart('John', 'First name'), isNull);
    });

    test('Sign up phone validator enforces format if present', () {
      expect(AppUtils.validatePhone(null), isNull);
      expect(AppUtils.validatePhone(''), isNull);
      expect(AppUtils.validatePhone('123'), 'Enter a valid phone number (8-20 digits)');
      expect(AppUtils.validatePhone('+855 12 345 678'), isNull);
    });

    test('OTP validator enforces exactly 6 digits', () {
      expect(AppUtils.validateOtp(null), 'OTP code is required');
      expect(AppUtils.validateOtp(''), 'OTP code is required');
      expect(AppUtils.validateOtp('12345'), 'OTP must be exactly 6 digits');
      expect(AppUtils.validateOtp('1234567'), 'OTP must be exactly 6 digits');
      expect(AppUtils.validateOtp('abcdef'), 'OTP must be exactly 6 digits');
      expect(AppUtils.validateOtp('123456'), isNull);
    });
  });
}
