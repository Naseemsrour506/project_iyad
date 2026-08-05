import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_localization.dart';
import '../../core/app_theme.dart';
import '../../models/alert_model.dart';
import '../../providers/alerts_provider.dart';
import '../../providers/children_provider.dart';
import '../../widgets/app_error_view.dart';
import '../../widgets/app_loading_indicator.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/responsive_content.dart';
import '../../widgets/risk_badge.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ChildrenProvider>().loadChildren();
      context.read<AlertsProvider>().loadAlerts();
      context.read<AlertsProvider>().refreshUnreadCount();
    });
  }

  Future<void> _refresh() async {
    final AlertsProvider alerts = context.read<AlertsProvider>();
    await alerts.loadAlerts(force: true);
    await alerts.refreshUnreadCount();
  }

  Future<void> _markAsRead(int alertId) async {
    final String? error = await context.read<AlertsProvider>().markAsRead(
      alertId,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'ההתראה סומנה כנקראה.'),
        backgroundColor: error == null
            ? null
            : Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AlertsProvider alerts = context.watch<AlertsProvider>();
    final ChildrenProvider children = context.watch<ChildrenProvider>();

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          ResponsiveContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _Header(
                  unreadCount: alerts.unreadCount,
                  isLoading: alerts.isLoading,
                  onRefresh: _refresh,
                ),
                const SizedBox(height: 16),
                _FilterBar(
                  unreadOnly: alerts.unreadOnly,
                  enabled: !alerts.isLoading,
                  onChanged: (bool value) =>
                      context.read<AlertsProvider>().setUnreadOnly(value),
                ),
                const SizedBox(height: 16),
                _buildContent(alerts, children),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AlertsProvider alerts, ChildrenProvider children) {
    if (alerts.isLoading && alerts.alerts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: AppLoadingIndicator(message: 'טוען התראות...'),
      );
    }

    if (alerts.errorMessage != null && alerts.alerts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: AppErrorView(message: alerts.errorMessage!, onRetry: _refresh),
      );
    }

    if (alerts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: EmptyState(
          icon: Icons.notifications_off_outlined,
          title: alerts.unreadOnly
              ? 'אין התראות שלא נקראו'
              : 'אין התראות להצגה',
          description: alerts.unreadOnly
              ? 'כל ההתראות שלכם סומנו כנקראו.'
              : 'התראות נוצרות אוטומטית כאשר מזוהה הודעה ברמת סיכון גבוהה.',
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: alerts.alerts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        final AlertModel alert = alerts.alerts[index];
        return _AlertCard(
          alert: alert,
          childName: children.childName(alert.childId),
          onMarkAsRead: alert.isRead ? null : () => _markAsRead(alert.alertId),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.unreadCount,
    required this.isLoading,
    required this.onRefresh,
  });

  final int unreadCount;
  final bool isLoading;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'התראות',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                unreadCount == 0
                    ? 'אין התראות שלא נקראו'
                    : '$unreadCount התראות שלא נקראו',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: unreadCount == 0
                      ? theme.colorScheme.onSurfaceVariant
                      : AppTheme.highRiskColor,
                  fontWeight: unreadCount == 0
                      ? FontWeight.w400
                      : FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: isLoading ? null : onRefresh,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'רענון',
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.unreadOnly,
    required this.enabled,
    required this.onChanged,
  });

  final bool unreadOnly;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.filter_alt_outlined, size: 20),
            ),
            ChoiceChip(
              label: const Text('כל ההתראות'),
              selected: !unreadOnly,
              onSelected: enabled ? (_) => onChanged(false) : null,
            ),
            ChoiceChip(
              label: const Text('לא נקראו בלבד'),
              selected: unreadOnly,
              onSelected: enabled ? (_) => onChanged(true) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.childName,
    required this.onMarkAsRead,
  });

  final AlertModel alert;
  final String childName;
  final VoidCallback? onMarkAsRead;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color riskColor = AppTheme.riskColor(alert.riskLevel);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: riskColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    alert.isRead
                        ? Icons.notifications_none_rounded
                        : Icons.notifications_active_rounded,
                    color: riskColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    alert.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: alert.isRead
                          ? FontWeight.w600
                          : FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _ReadStatusChip(isRead: alert.isRead),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                RiskBadge(riskLevel: alert.riskLevel, useShortLabel: true),
                InfoChip(label: childName, icon: Icons.child_care_rounded),
                InfoChip(
                  label: AppLabels.category(alert.category),
                  icon: Icons.category_rounded,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Icon(
                  Icons.schedule_rounded,
                  size: 15,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    AppLabels.dateTime(alert.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (onMarkAsRead != null)
                  TextButton.icon(
                    onPressed: onMarkAsRead,
                    icon: const Icon(Icons.done_rounded, size: 18),
                    label: const Text('סימון כנקרא'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadStatusChip extends StatelessWidget {
  const _ReadStatusChip({required this.isRead});

  final bool isRead;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    final Color background = isRead
        ? colors.surfaceContainerHighest
        : AppTheme.highRiskColor.withValues(alpha: 0.12);
    final Color foreground = isRead
        ? colors.onSurfaceVariant
        : AppTheme.highRiskColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isRead ? 'נקראה' : 'חדשה',
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
