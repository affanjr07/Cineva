import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/routes.dart';
import 'auth_validators.dart';
import 'auth_widgets.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // AuthGate listens to Supabase and swaps to CinevaHome on success.
      await AuthService.instance.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = AuthService.instance.friendlyError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openRegister() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(cinevaPageRoute(const RegisterScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthHeader(
              eyebrow: 'Sign in',
              title: 'Welcome back',
              subtitle:
                  'Sign in to continue watching and keep your watchlist in '
                  'sync.',
            ),
            const SizedBox(height: AppSpacing.xxxl),
            if (_error != null) ...[
              AuthErrorBanner(message: _error!),
              const SizedBox(height: AppSpacing.lg),
            ],
            AuthTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: AuthValidators.email,
            ),
            const SizedBox(height: AppSpacing.lg),
            AuthTextField(
              controller: _passwordController,
              label: 'Password',
              hint: 'Your password',
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              validator: AuthValidators.password,
              onFieldSubmitted: (_) => _submit(),
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl + 4),
            AuthPrimaryButton(
              label: 'Sign in',
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'New to Cineva?',
                  style: AppType.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                TextButton(
                  onPressed: _loading ? null : _openRegister,
                  child: Text(
                    'Create account',
                    style: AppType.bodySmall.copyWith(
                      color: AppColors.primarySoft,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
