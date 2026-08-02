import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_localization.dart';
import '../../models/child_model.dart';
import '../../providers/children_provider.dart';
import '../../widgets/app_error_view.dart';
import '../../widgets/app_loading_indicator.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/responsive_content.dart';
import 'add_child_screen.dart';

class ChildrenScreen extends StatefulWidget {
  const ChildrenScreen({super.key});

  @override
  State<ChildrenScreen> createState() => _ChildrenScreenState();
}

class _ChildrenScreenState extends State<ChildrenScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ChildrenProvider>().loadChildren();
    });
  }

  Future<void> _refresh() =>
      context.read<ChildrenProvider>().loadChildren(force: true);

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
    final ChildrenProvider provider = context.watch<ChildrenProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddChild,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('הוספת ילד'),
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(ChildrenProvider provider) {
    if (provider.isLoading && provider.children.isEmpty) {
      return const AppLoadingIndicator(message: 'טוען ילדים...');
    }

    if (provider.errorMessage != null && provider.children.isEmpty) {
      return AppErrorView(message: provider.errorMessage!, onRetry: _refresh);
    }

    if (provider.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.6,
              child: EmptyState(
                icon: Icons.family_restroom_rounded,
                title: 'עדיין לא הוספתם ילדים',
                description:
                    'הוסיפו פרופיל ילד כדי להתחיל לנתח הודעות ולקבל התראות.',
                actionLabel: 'הוספת ילד',
                onAction: _openAddChild,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          ResponsiveContent(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _Header(
                  count: provider.children.length,
                  isLoading: provider.isLoading,
                  onRefresh: _refresh,
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final int columns = (constraints.maxWidth / 320)
                        .floor()
                        .clamp(1, 3);

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.children.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: 132,
                      ),
                      itemBuilder: (BuildContext context, int index) =>
                          _ChildCard(child: provider.children[index]),
                    );
                  },
                ),
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
    required this.count,
    required this.isLoading,
    required this.onRefresh,
  });

  final int count;
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
                'הילדים שלי',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count פרופילים רשומים',
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

class _ChildCard extends StatelessWidget {
  const _ChildCard({required this.child});

  final ChildModel child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String initial = child.fullName.trim().isEmpty
        ? '?'
        : child.fullName.trim().substring(0, 1).toUpperCase();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 26,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    child.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'גיל ${child.age}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (child.createdAt != null) ...<Widget>[
                    const SizedBox(height: 6),
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.event_outlined,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'נוסף ב-${AppLabels.date(child.createdAt)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
