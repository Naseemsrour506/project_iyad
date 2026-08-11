import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_localization.dart';
import '../../core/app_theme.dart';
import '../../models/dashboard_stats_model.dart';
import '../../providers/dashboard_provider.dart';
import '../../utils/csv_download.dart';
import '../../widgets/app_error_view.dart';
import '../../widgets/app_loading_indicator.dart';
import '../../widgets/dashboard_stat_card.dart';
import '../../widgets/responsive_content.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DashboardProvider>().loadStats();
    });
  }

  Future<void> _refresh() =>
      context.read<DashboardProvider>().loadStats(force: true);

  Future<void> _exportCsv() async {
    final DashboardProvider provider = context.read<DashboardProvider>();
    final String? csvContent = await provider.exportReportCsv();

    if (!mounted) return;

    if (csvContent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'אירעה שגיאה בהורדת הדוח.'),
        ),
      );
      return;
    }

    try {
      downloadCsvFile('safechat_report.csv', csvContent);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('הדוח הורד בהצלחה.')));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('הורדת CSV נתמכת כרגע בדפדפן בלבד.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final DashboardProvider provider = context.watch<DashboardProvider>();

    if (provider.isLoading && provider.stats == null) {
      return const AppLoadingIndicator(message: 'טוען נתונים...');
    }

    if (provider.errorMessage != null && provider.stats == null) {
      return AppErrorView(message: provider.errorMessage!, onRetry: _refresh);
    }

    final DashboardStatsModel? stats = provider.stats;
    if (stats == null) {
      return AppErrorView(message: 'אין נתונים להצגה.', onRetry: _refresh);
    }

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
                  onRefresh: _refresh,
                  onExport: _exportCsv,
                  isLoading: provider.isLoading,
                  isExporting: provider.isExporting,
                ),
                const SizedBox(height: 20),
                _StatsGrid(stats: stats),
                const SizedBox(height: 20),
                _RiskBreakdown(stats: stats),
                const SizedBox(height: 16),
                _CategoryBreakdown(stats: stats),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onRefresh,
    required this.onExport,
    required this.isLoading,
    required this.isExporting,
  });

  final Future<void> Function() onRefresh;
  final Future<void> Function() onExport;
  final bool isLoading;
  final bool isExporting;

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
                'לוח בקרה',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'סקירה כללית של הפעילות והסיכונים',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: isExporting ? null : onExport,
          icon: isExporting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download_rounded),
          tooltip: 'הורדת דוח CSV',
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: isLoading ? null : onRefresh,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'רענון',
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final DashboardStatsModel stats;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    final List<Widget> cards = <Widget>[
      DashboardStatCard(
        label: 'ילדים רשומים',
        value: '${stats.totalChildren}',
        icon: Icons.family_restroom_rounded,
        color: colors.primary,
      ),
      DashboardStatCard(
        label: 'הודעות שנותחו',
        value: '${stats.totalMessages}',
        icon: Icons.forum_rounded,
        color: colors.tertiary,
      ),
      DashboardStatCard(
        label: 'סיכון נמוך',
        value: '${stats.lowRiskCount}',
        icon: Icons.check_circle_outline_rounded,
        color: AppTheme.lowRiskColor,
      ),
      DashboardStatCard(
        label: 'סיכון בינוני',
        value: '${stats.mediumRiskCount}',
        icon: Icons.warning_amber_rounded,
        color: AppTheme.mediumRiskColor,
      ),
      DashboardStatCard(
        label: 'סיכון גבוה',
        value: '${stats.highRiskCount}',
        icon: Icons.report_gmailerrorred_rounded,
        color: AppTheme.highRiskColor,
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Aim for ~220px wide cards, between 1 and 4 per row.
        final int columns = (constraints.maxWidth / 220).floor().clamp(1, 4);

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: columns == 1 ? 2.8 : 1.55,
          children: cards,
        );
      },
    );
  }
}

class _RiskBreakdown extends StatelessWidget {
  const _RiskBreakdown({required this.stats});

  final DashboardStatsModel stats;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'התפלגות לפי רמת סיכון',
      icon: Icons.speed_rounded,
      child: Column(
        children: <Widget>[
          for (final String risk in AppLabels.riskOrder)
            StatBarRow(
              label: AppLabels.riskLevel(risk),
              count: stats.riskLevels[risk] ?? 0,
              total: stats.totalMessages,
              color: AppTheme.riskColor(risk),
            ),
        ],
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.stats});

  final DashboardStatsModel stats;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    // Show every category the backend returned, keeping the canonical order
    // first so the layout stays stable between refreshes.
    final List<String> categories = <String>[
      ...AppLabels.categoryOrder.where(
        (String key) => stats.categories.containsKey(key),
      ),
      ...stats.categories.keys.where(
        (String key) => !AppLabels.categoryOrder.contains(key),
      ),
    ];

    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return _SectionCard(
      title: 'התפלגות לפי קטגוריה',
      icon: Icons.category_rounded,
      child: Column(
        children: <Widget>[
          for (final String category in categories)
            StatBarRow(
              label: AppLabels.category(category),
              count: stats.categoryCount(category),
              total: stats.totalMessages,
              color: category == 'Normal'
                  ? AppTheme.lowRiskColor
                  : colors.primary,
            ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
