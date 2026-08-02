import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/app_error_view.dart';
import 'auth_scaffold.dart';
import 'auth_validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();

    final bool success = await context.read<AuthProvider>().register(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted || !success) return;

    // `POST /api/auth/register` returns a user object, not a token, so the
    // parent is sent back to the login screen instead of being auto-logged-in.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ההרשמה הושלמה בהצלחה! כעת ניתן להתחבר.'),
        duration: Duration(seconds: 4),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final bool isBusy = auth.isBusy;

    return AuthScaffold(
      title: 'יצירת חשבון',
      subtitle: 'הירשמו כדי להתחיל להגן על ילדיכם ברשת',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (auth.errorMessage != null) ...<Widget>[
              AppErrorBanner(message: auth.errorMessage!),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _fullNameController,
              enabled: !isBusy,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'שם מלא',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: AuthValidators.fullName,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              enabled: !isBusy,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'אימייל',
                hintText: 'parent@example.com',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: AuthValidators.email,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              enabled: !isBusy,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: 'סיסמה',
                helperText: 'לפחות 8 תווים',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  tooltip: _obscurePassword ? 'הצגת סיסמה' : 'הסתרת סיסמה',
                ),
              ),
              validator: AuthValidators.password,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              enabled: !isBusy,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              textDirection: TextDirection.ltr,
              onFieldSubmitted: (_) => isBusy ? null : _submit(),
              decoration: InputDecoration(
                labelText: 'אימות סיסמה',
                prefixIcon: const Icon(Icons.lock_reset_rounded),
                suffixIcon: IconButton(
                  onPressed: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  tooltip: _obscureConfirmPassword
                      ? 'הצגת סיסמה'
                      : 'הסתרת סיסמה',
                ),
              ),
              validator: (String? value) => AuthValidators.confirmPassword(
                value,
                _passwordController.text,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: isBusy ? null : _submit,
              child: isBusy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('הרשמה'),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text('כבר יש לכם חשבון?'),
                TextButton(
                  onPressed: isBusy
                      ? null
                      : () {
                          context.read<AuthProvider>().clearError();
                          Navigator.of(context).pop();
                        },
                  child: const Text('התחברות'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
