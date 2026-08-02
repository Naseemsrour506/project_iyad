import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/children_provider.dart';
import '../../widgets/app_error_view.dart';
import '../auth/auth_validators.dart';

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    // `parent_id` is intentionally not sent; the backend takes it from the JWT.
    final String? error = await context.read<ChildrenProvider>().addChild(
      fullName: _fullNameController.text.trim(),
      age: int.parse(_ageController.text.trim()),
    );

    if (!mounted) return;

    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bool isSubmitting = context.select<ChildrenProvider, bool>(
      (ChildrenProvider provider) => provider.isSubmitting,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('הוספת ילד')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          'פרטי הילד',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'הוסיפו פרופיל כדי לנתח עבורו הודעות ולקבל התראות.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 22),
                        if (_errorMessage != null) ...<Widget>[
                          AppErrorBanner(message: _errorMessage!),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _fullNameController,
                          enabled: !isSubmitting,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'שם מלא',
                            prefixIcon: Icon(Icons.child_care_rounded),
                          ),
                          validator: AuthValidators.fullName,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _ageController,
                          enabled: !isSubmitting,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          onFieldSubmitted: (_) =>
                              isSubmitting ? null : _submit(),
                          decoration: const InputDecoration(
                            labelText: 'גיל',
                            helperText: 'בין 1 ל-18',
                            prefixIcon: Icon(Icons.cake_outlined),
                          ),
                          validator: AuthValidators.childAge,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: isSubmitting ? null : _submit,
                          icon: isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Icon(Icons.check_rounded),
                          label: Text(isSubmitting ? 'שומר...' : 'שמירת הילד'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: isSubmitting
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('ביטול'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
