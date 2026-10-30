import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

enum AuthStatus { unconfigured, ready, failed }

/// Small singleton wrapper around Supabase Auth.
///
/// Passwords are handled entirely by Supabase Auth. The app never stores or
/// reads password hashes itself.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  AuthStatus _status = AuthStatus.unconfigured;
  SupabaseClient? _client;
  String? _configurationIssue;

  bool get isReady => _status == AuthStatus.ready;
  String? get configurationIssue => _configurationIssue;

  Session? get currentSession => _client?.auth.currentSession;
  User? get currentUser => currentSession?.user;
  Stream<AuthState>? get authStateChanges => _client?.auth.onAuthStateChange;

  String get displayName {
    final metadataName = currentUser?.userMetadata?['full_name'];
    final name = metadataName?.toString().trim() ?? '';
    if (name.isNotEmpty) return name;

    final email = currentUser?.email ?? '';
    if (email.contains('@')) return email.split('@').first;
    return 'Cineva user';
  }

  Future<void> initialize() async {
    if (_client != null) return;

    if (!SupabaseConfig.isConfigured) {
      _status = AuthStatus.unconfigured;
      _configurationIssue =
          'Supabase is not configured yet. Add SUPABASE_URL and '
          'SUPABASE_PUBLISHABLE_KEY to .env, then restart the app.';
      return;
    }

    final uri = Uri.tryParse(SupabaseConfig.url.trim());
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      _status = AuthStatus.failed;
      _configurationIssue =
          'SUPABASE_URL is invalid. Use the Project URL from Supabase.';
      return;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.url.trim(),
        publishableKey: SupabaseConfig.clientKey,
      );
      _client = Supabase.instance.client;
      _status = AuthStatus.ready;
      _configurationIssue = null;
    } catch (error) {
      _status = AuthStatus.failed;
      _configurationIssue = 'Supabase could not be initialized: $error';
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _requireClient().auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> register({
    required String fullName,
    required String email,
    required String password,
  }) {
    return _requireClient().auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName.trim()},
    );
  }

  Future<void> signOut() => _requireClient().auth.signOut();

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase Auth is not initialized.');
    }
    return client;
  }

  String friendlyError(Object error) {
    if (error is AuthException) {
      switch (error.code) {
        case 'invalid_credentials':
          return 'Email or password is incorrect.';
        case 'email_not_confirmed':
          return 'Please confirm your email before signing in.';
        case 'user_already_exists':
        case 'email_exists':
          return 'An account with this email already exists.';
        case 'weak_password':
          return 'That password is too weak. Use at least 8 characters.';
        case 'email_address_invalid':
          return 'Enter a valid email address.';
        case 'over_email_send_rate_limit':
          return 'Too many emails were sent. Please try again later.';
      }

      if (error.message.toLowerCase().contains('invalid login credentials')) {
        return 'Email or password is incorrect.';
      }
      if (error is AuthRetryableFetchException) {
        return 'Cannot reach Supabase. Check your internet connection.';
      }
      if (error.message.trim().isNotEmpty) return error.message;
    }

    return 'Something went wrong. Please try again.';
  }
}
