import 'package:cineva_flutter/screens/auth/auth_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthValidators', () {
    test('validates email addresses', () {
      expect(AuthValidators.email(''), 'Email is required.');
      expect(AuthValidators.email('not-an-email'), 'Enter a valid email.');
      expect(AuthValidators.email('user@example.com'), isNull);
    });

    test('requires a password', () {
      expect(AuthValidators.password(''), 'Password is required.');
      expect(AuthValidators.password('secret'), isNull);
    });

    test('requires at least eight characters for new passwords', () {
      expect(AuthValidators.newPassword('short'), 'Use at least 8 characters.');
      expect(AuthValidators.newPassword('long-enough'), isNull);
    });

    test('checks password confirmation', () {
      expect(
        AuthValidators.confirmPassword('other', 'secret123'),
        'Passwords do not match.',
      );
      expect(AuthValidators.confirmPassword('secret123', 'secret123'), isNull);
    });

    test('requires a full name', () {
      expect(AuthValidators.fullName(' '), 'Full name is required.');
      expect(AuthValidators.fullName('A'), 'Enter your full name.');
      expect(AuthValidators.fullName('Affan'), isNull);
    });
  });
}
