import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_localization.dart';
import '../../models/child_model.dart';
import '../../models/message_model.dart';
import '../../providers/children_provider.dart';
import '../../providers/messages_provider.dart';
import '../../widgets/app_error_view.dart';
import '../../widgets/app_loading_indicator.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/responsive_content.dart';
import '../../widgets/risk_badge.dart';

class MessageHistoryScreen extends StatefulWidget {
  const MessageHistoryScreen({super.key});

  @override
  State<MessageHistoryScreen> createState() => _MessageHistoryScreenState();
}

class _MessageHistoryScreenState extends State<MessageHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ChildrenProvider>().loadChildren();
      context.read<MessagesProvider>().loadMessages();
    });
  }

  Future<void> _refresh() =>
      context.read<MessagesProvider>().loadMessages(force: true);

  @override
  Widget build(BuildContext context) {
    final MessagesProvider messages = context.watch<MessagesProvider>();
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
                  isLoading: messages.isLoading,
                  onRefresh: _refresh,
                  count: messages.messages.length,
                ),
                const SizedBox(height: 16),
                _ChildFilter(
                  children: children.children,
                  selectedChildId: messages.selectedChildFilter,
                  enabled: !messages.isLoading,
                  onChanged: (int? childId) =>
                      context.read<MessagesProvider>().setChildFilter(childId),
                ),
                const SizedBox(height: 16),
                _buildContent(messages, children),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(MessagesProvider messages, ChildrenProvider children) {
    if (messages.isLoading && messages.messages.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: AppLoadingIndicator(message: 'טוען היסטוריה...'),
      );
    }

    if (messages.errorMessage != null && messages.messages.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: AppErrorView(message: messages.errorMessage!, onRetry: _refresh),
      );
    }

    if (messages.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: EmptyState(
          icon: Icons.history_rounded,
          title: 'אין הודעות להצגה',
          description:
              'נתחו הודעה במסך "ניתוח" והיא תופיע כאן, או שנו את הסינון.',
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: messages.messages.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        final AnalyzedMessageModel message = messages.messages[index];
        return _MessageCard(
          message: message,
          childName: children.childName(message.childId),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.isLoading,
    required this.onRefresh,
    required this.count,
  });

  final bool isLoading;
  final Future<void> Function() onRefresh;
  final int count;

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
                'היסטוריית הודעות',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count הודעות שנותחו',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
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

class _ChildFilter extends StatelessWidget {
  const _ChildFilter({
    required this.children,
    required this.selectedChildId,
    required this.enabled,
    required this.onChanged,
  });

  final List<ChildModel> children;
  final int? selectedChildId;
  final bool enabled;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

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
              label: const Text('כל הילדים'),
              selected: selectedChildId == null,
              onSelected: enabled ? (_) => onChanged(null) : null,
            ),
            for (final ChildModel child in children)
              ChoiceChip(
                label: Text(child.fullName),
                selected: selectedChildId == child.childId,
                onSelected: enabled ? (_) => onChanged(child.childId) : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, required this.childName});

  final AnalyzedMessageModel message;
  final String childName;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: Theme(
        // Remove the default ExpansionTile divider lines for a cleaner card.
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: Text(
            message.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                RiskBadge(riskLevel: message.riskLevel, useShortLabel: true),
                InfoChip(label: childName, icon: Icons.child_care_rounded),
                InfoChip(
                  label: AppLabels.category(message.category),
                  icon: Icons.category_rounded,
                ),
                InfoChip(
                  label: AppLabels.confidence(message.confidence),
                  icon: Icons.percent_rounded,
                ),
              ],
            ),
          ),
          children: <Widget>[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                'ההודעה המלאה',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(message.message, style: const TextStyle(height: 1.5)),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                'הסבר',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                message.explanation,
                style: const TextStyle(height: 1.5),
              ),
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
                Text(
                  AppLabels.dateTime(message.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
