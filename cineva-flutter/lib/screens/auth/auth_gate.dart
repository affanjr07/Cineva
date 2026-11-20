import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';
import 'auth_unavailable_screen.dart';
import 'login_screen.dart';

/// Keeps the authenticated app and the auth flow in sync with the Supabase
/// session. Persisted sessions are restored before `runApp` is called.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.authenticated});

  final Widget authenticated;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Session? _session;
  StreamSubscription<AuthState>? _subscription;

  @override
  void initState() {
    super.initState();
    _session = AuthService.instance.currentSession;
    _subscription = AuthService.instance.authStateChanges?.listen(
      (state) {
        if (!mounted) return;
        setState(() => _session = state.session);
      },
      onError: (Object _) {
        // Keep the last known session if the auth stream reports a transient
        // network error. A later event will update it again.
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.instance.isReady) {
      return AuthUnavailableScreen(
        message: AuthService.instance.configurationIssue,
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: _session == null
          ? const LoginScreen(key: ValueKey('auth-login'))
          : KeyedSubtree(
              key: const ValueKey('auth-app'),
              child: widget.authenticated,
            ),
    );
  }
}
