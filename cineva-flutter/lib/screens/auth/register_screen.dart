import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'auth_validators.dart';
import 'auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
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
      final response = await AuthService.instance.register(
        fullName: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (response.session == null) {
        // Email confirmation is enabled in Supabase. The user can sign in
        // after opening the confirmation link in their inbox.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account created. Check your email to confirm it, then sign in.',
            ),
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        // AuthGate will show the main app; remove the pushed register route.
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = AuthService.instance.friendlyError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
              eyebrow: 'Join Cineva',
              title: 'Create your account',
              subtitle:
                  'Save films, follow every episode, and keep your watchlist '
                  'in sync across devices.',
            ),
            const SizedBox(height: AppSpacing.xxxl),
            if (_error != null) ...[
              AuthErrorBanner(message: _error!),
              const SizedBox(height: AppSpacing.lg),
            ],
            AuthTextField(
              controller: _nameController,
              label: 'Full name',
              hint: 'Your name',
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: AuthValidators.fullName,
            ),
            const SizedBox(height: AppSpacing.lg),
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
              hint: 'At least 8 characters',
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: AuthValidators.newPassword,
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
            const SizedBox(height: AppSpacing.lg),
            AuthTextField(
              controller: _confirmController,
              label: 'Confirm password',
              hint: 'Repeat your password',
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              validator: (value) => AuthValidators.confirmPassword(
                value,
                _passwordController.text,
              ),
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.xxl + 4),
            AuthPrimaryButton(
              label: 'Create account',
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Already have an account?',
                  style: AppType.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(
                    'Sign in',
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
