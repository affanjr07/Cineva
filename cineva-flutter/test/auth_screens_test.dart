import 'package:cineva_flutter/screens/auth/login_screen.dart';
import 'package:cineva_flutter/screens/auth/register_screen.dart';
import 'package:cineva_flutter/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _authApp(Widget home) {
  return MaterialApp(theme: buildAppTheme(), home: home);
}

void main() {
  testWidgets('login form renders and validates empty fields', (tester) async {
    await tester.pumpWidget(_authApp(const LoginScreen()));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);

    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Email is required.'), findsOneWidget);
    expect(find.text('Password is required.'), findsOneWidget);
  });

  testWidgets('login screen opens the register screen', (tester) async {
    await tester.pumpWidget(_authApp(const LoginScreen()));

    final createAccount = find.text('Create account');
    await tester.ensureVisible(createAccount);
    await tester.tap(createAccount);
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('register form renders its fields', (tester) async {
    await tester.pumpWidget(_authApp(const RegisterScreen()));

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
  });
}
