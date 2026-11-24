/// Compile-time Supabase configuration.
///
/// Values are supplied with `--dart-define-from-file=.env` or individual
/// `--dart-define` flags. Never put a service-role/secret key in the app.
class SupabaseConfig {
  SupabaseConfig._();

  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Cleaned Project URL that strips accidental `/rest/v1` or trailing slashes.
  static String get cleanUrl {
    var raw = url.trim();
    while (raw.endsWith('/')) {
      raw = raw.substring(0, raw.length - 1);
    }
    if (raw.endsWith('/rest/v1')) {
      raw = raw.substring(0, raw.length - '/rest/v1'.length);
    }
    while (raw.endsWith('/')) {
      raw = raw.substring(0, raw.length - 1);
    }
    return raw;
  }

  /// Supports both the new `sb_publishable_...` key and the legacy anon key.
  static String get clientKey {
    final publicKey = publishableKey.trim();
    return publicKey.isNotEmpty ? publicKey : anonKey.trim();
  }

  static bool get isConfigured => cleanUrl.isNotEmpty && clientKey.isNotEmpty;
}
