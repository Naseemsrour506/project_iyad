import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_error_view.dart';
import 'auth_scaffold.dart';
import 'auth_validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();

    // On success AuthGate swaps the whole tree, so no navigation is needed here.
    await context.read<AuthProvider>().login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  void _goToRegister() {
    context.read<AuthProvider>().clearError();
    Navigator.of(context).pushNamed(AppRoutes.register);
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final bool isBusy = auth.isBusy;

    return AuthScaffold(
      title: 'ברוכים הבאים',
      subtitle: 'התחברו כדי להמשיך לניהול הבטיחות של ילדיכם',
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
              controller: _emailController,
              enabled: !isBusy,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const <String>[AutofillHints.email],
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
              textInputAction: TextInputAction.done,
              autofillHints: const <String>[AutofillHints.password],
              textDirection: TextDirection.ltr,
              onFieldSubmitted: (_) => isBusy ? null : _submit(),
              decoration: InputDecoration(
                labelText: 'סיסמה',
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
              validator: AuthValidators.loginPassword,
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
                  : const Text('התחברות'),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text('אין לכם חשבון?'),
                TextButton(
                  onPressed: isBusy ? null : _goToRegister,
                  child: const Text('הרשמה'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
