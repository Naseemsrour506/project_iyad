import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_localization.dart';
import '../../core/app_theme.dart';
import '../../models/analysis_result_model.dart';
import '../../models/child_model.dart';
import '../../providers/alerts_provider.dart';
import '../../providers/children_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/messages_provider.dart';
import '../../utils/csv_file_picker.dart';
import '../../widgets/app_error_view.dart';
import '../../widgets/app_loading_indicator.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/responsive_content.dart';
import '../../widgets/risk_badge.dart';
import '../auth/auth_validators.dart';
import '../children/add_child_screen.dart';

class AnalyzeMessageScreen extends StatefulWidget {
  const AnalyzeMessageScreen({super.key});

  @override
  State<AnalyzeMessageScreen> createState() => _AnalyzeMessageScreenState();
}

class _AnalyzeMessageScreenState extends State<AnalyzeMessageScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _messageController = TextEditingController();

  int? _selectedChildId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ChildrenProvider>().loadChildren();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedChildId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('יש לבחור ילד לפני ניתוח ההודעה.')),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();

    final MessagesProvider messages = context.read<MessagesProvider>();
    final AlertsProvider alerts = context.read<AlertsProvider>();

    final AnalysisResultModel? result = await messages.analyzeMessage(
      childId: _selectedChildId!,
      message: _messageController.text.trim(),
    );

    if (!mounted || result == null) return;

    // A High result makes the backend create an alert, so the badge must catch up.
    if (result.isHighRisk) {
      await alerts.refreshUnreadCount();
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isHighRisk
              ? 'הניתוח הושלם — זוהה סיכון גבוה ונוצרה התראה.'
              : 'הניתוח הושלם בהצלחה.',
        ),
      ),
    );
  }

  Future<void> _uploadCsv() async {
    if (_selectedChildId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('יש לבחור ילד לפני העלאת קובץ CSV.')),
      );
      return;
    }

    final int childId = _selectedChildId!;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final MessagesProvider messages = context.read<MessagesProvider>();
    final AlertsProvider alerts = context.read<AlertsProvider>();
    final DashboardProvider dashboard = context.read<DashboardProvider>();

    PickedCsvFile? pickedFile;

    try {
      pickedFile = await pickCsvFile();
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('העלאת CSV נתמכת כרגע בדפדפן בלבד.')),
      );
      return;
    }

    if (pickedFile == null) return;

    final BatchAnalysisResultModel? result = await messages.uploadCsvMessages(
      childId: childId,
      filename: pickedFile.filename,
      fileBytes: pickedFile.bytes,
    );

    if (result == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            messages.analysisError ?? 'אירעה שגיאה בהעלאת קובץ ה-CSV.',
          ),
        ),
      );
      return;
    }

    await alerts.refreshUnreadCount();
    await dashboard.loadStats(force: true);
    await messages.loadMessages(force: true);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'הקובץ הועלה בהצלחה — נותחו ${result.totalMessages} הודעות, '
          'מתוכן ${result.highRiskCount} בסיכון גבוה.',
        ),
      ),
    );
  }

  Future<void> _openAddChild() async {
    final bool? created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => const AddChildScreen(),
      ),
    );

    if (created != true || !mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('הילד נוסף בהצלחה!')));
  }

  @override
  Widget build(BuildContext context) {
    final ChildrenProvider children = context.watch<ChildrenProvider>();
    final MessagesProvider messages = context.watch<MessagesProvider>();

    if (children.isLoading && children.children.isEmpty) {
      return const AppLoadingIndicator(message: 'טוען ילדים...');
    }

    if (children.errorMessage != null && children.children.isEmpty) {
      return AppErrorView(
        message: children.errorMessage!,
        onRetry: () => children.loadChildren(force: true),
      );
    }

    if (children.isEmpty) {
      return EmptyState(
        icon: Icons.person_search_rounded,
        title: 'צריך להוסיף ילד תחילה',
        description: 'ניתוח הודעות מתבצע תמיד עבור פרופיל ילד מסוים.',
        actionLabel: 'הוספת ילד',
        onAction: _openAddChild,
      );
    }

    // Keep the selection valid if the children list changed.
    if (_selectedChildId != null &&
        children.childById(_selectedChildId!) == null) {
      _selectedChildId = null;
    }

    return ListView(
      children: <Widget>[
        ResponsiveContent(
          maxWidth: 760,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _Header(),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (messages.analysisError != null) ...<Widget>[
                          AppErrorBanner(message: messages.analysisError!),
                          const SizedBox(height: 16),
                        ],
                        DropdownButtonFormField<int>(
                          initialValue: _selectedChildId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'בחירת ילד',
                            prefixIcon: Icon(Icons.child_care_rounded),
                          ),
                          items: children.children
                              .map(
                                (ChildModel child) => DropdownMenuItem<int>(
                                  value: child.childId,
                                  child: Text(
                                    '${child.fullName} · גיל ${child.age}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: messages.isBusy
                              ? null
                              : (int? value) =>
                                    setState(() => _selectedChildId = value),
                          validator: (int? value) =>
                              value == null ? 'יש לבחור ילד' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _messageController,
                          enabled: !messages.isBusy,
                          maxLines: 6,
                          minLines: 4,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: const InputDecoration(
                            labelText: 'תוכן ההודעה',
                            hintText: 'הדביקו כאן את ההודעה בעברית לניתוח...',
                            alignLabelWithHint: true,
                          ),
                          validator: AuthValidators.message,
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: messages.isBusy ? null : _submit,
                          icon: messages.isAnalyzing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome_rounded),
                          label: Text(
                            messages.isAnalyzing
                                ? 'מנתח את ההודעה...'
                                : 'ניתוח ההודעה',
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: messages.isBusy ? null : _uploadCsv,
                          icon: messages.isUploadingCsv
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Icon(Icons.upload_file_rounded),
                          label: Text(
                            messages.isUploadingCsv
                                ? 'מעלה ומנתח את הקובץ...'
                                : 'העלאת CSV וניתוח הודעות',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (messages.lastResult != null) ...<Widget>[
                const SizedBox(height: 20),
                _ResultCard(
                  result: messages.lastResult!,
                  childName: children.childName(messages.lastResult!.childId),
                  onClear: () {
                    context.read<MessagesProvider>().clearLastResult();
                    _messageController.clear();
                  },
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'ניתוח הודעה',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'בדקו הודעה בעברית וקבלו קטגוריה, רמת סיכון והסבר.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Displays the result returned by the backend. Nothing here is hardcoded.
class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.result,
    required this.childName,
    required this.onClear,
  });

  final AnalysisResultModel result;
  final String childName;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color riskColor = AppTheme.riskColor(result.riskLevel);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: riskColor.withValues(alpha: 0.10),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'תוצאת הניתוח',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                RiskBadge(riskLevel: result.riskLevel, large: true),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    InfoChip(label: childName, icon: Icons.child_care_rounded),
                    InfoChip(
                      label: AppLabels.category(result.category),
                      icon: Icons.category_rounded,
                    ),
                    InfoChip(
                      label: 'ודאות ${AppLabels.confidence(result.confidence)}',
                      icon: Icons.percent_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _Field(
                  label: 'רמת ודאות',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: result.confidence.clamp(0, 1).toDouble(),
                          minHeight: 10,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppLabels.confidence(result.confidence),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: riskColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _Field(
                  label: 'ההודעה שנותחה',
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      result.message,
                      style: const TextStyle(height: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _Field(
                  label: 'הסבר',
                  child: Text(
                    result.explanation,
                    style: const TextStyle(height: 1.5),
                  ),
                ),
                if (result.isHighRisk) ...<Widget>[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.highRiskColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.notifications_active_rounded,
                          color: AppTheme.highRiskColor,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'נוצרה התראה חדשה בעקבות רמת הסיכון הגבוהה.',
                            style: TextStyle(
                              color: AppTheme.highRiskColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('ניקוי התוצאה'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
