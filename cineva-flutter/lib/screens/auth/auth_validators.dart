class AuthValidators {
  AuthValidators._();

  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required.';
    if (!_emailPattern.hasMatch(email)) return 'Enter a valid email.';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    return null;
  }

  static String? newPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (value.length < 8) {
      return 'Use at least 8 characters.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirm your password.';
    if (value != password) return 'Passwords do not match.';
    return null;
  }

  static String? fullName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Full name is required.';
    if (name.length < 2) return 'Enter your full name.';
    return null;
  }
}
