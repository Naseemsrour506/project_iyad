import 'package:flutter/material.dart';

import '../core/app_localization.dart';
import '../core/app_theme.dart';

/// Coloured badge for a backend risk level (`Low` / `Medium` / `High`).
class RiskBadge extends StatelessWidget {
  const RiskBadge({
    super.key,
    required this.riskLevel,
    this.large = false,
    this.useShortLabel = false,
  });

  final String riskLevel;
  final bool large;
  final bool useShortLabel;

  IconData get _icon {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return Icons.check_circle_outline_rounded;
      case 'medium':
        return Icons.warning_amber_rounded;
      case 'high':
        return Icons.report_gmailerrorred_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color color = AppTheme.riskColor(riskLevel);
    final String label = useShortLabel
        ? AppLabels.shortRiskLevel(riskLevel)
        : AppLabels.riskLevel(riskLevel);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 10,
        vertical: large ? 10 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(_icon, size: large ? 20 : 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: large ? 15 : 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Neutral pill used for categories and other secondary metadata.
class InfoChip extends StatelessWidget {
  const InfoChip({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 15, color: colors.onSurfaceVariant),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
