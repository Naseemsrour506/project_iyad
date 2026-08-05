import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../providers/alerts_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/alerts/alerts_screen.dart';
import '../screens/analysis/analyze_message_screen.dart';
import '../screens/children/children_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/history/message_history_screen.dart';

/// One entry in the main navigation.
class _NavSection {
  const _NavSection({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.builder,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget Function() builder;
}

/// Authenticated shell: a NavigationBar on narrow screens and a NavigationRail
/// on wide (web/desktop) screens.
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  static const int _alertsIndex = 4;

  static final List<_NavSection> _sections = <_NavSection>[
    _NavSection(
      label: 'לוח בקרה',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      builder: () => const DashboardScreen(),
    ),
    _NavSection(
      label: 'ילדים',
      icon: Icons.family_restroom_outlined,
      selectedIcon: Icons.family_restroom_rounded,
      builder: () => const ChildrenScreen(),
    ),
    _NavSection(
      label: 'ניתוח',
      icon: Icons.psychology_alt_outlined,
      selectedIcon: Icons.psychology_alt_rounded,
      builder: () => const AnalyzeMessageScreen(),
    ),
    _NavSection(
      label: 'היסטוריה',
      icon: Icons.history_outlined,
      selectedIcon: Icons.history_rounded,
      builder: () => const MessageHistoryScreen(),
    ),
    _NavSection(
      label: 'התראות',
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications_rounded,
      builder: () => const AlertsScreen(),
    ),
  ];

  @override
  void initState() {
    super.initState();

    // The unread badge should be accurate as soon as the shell appears.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AlertsProvider>().refreshUnreadCount();
    });
  }

  void _onSectionSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _confirmLogout() async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('התנתקות'),
        content: const Text('האם אתם בטוחים שברצונכם להתנתק מהחשבון?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('ביטול'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('התנתקות'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    await context.read<AuthProvider>().logout();
  }

  /// Badge showing the number of unread alerts.
  Widget _alertsIconWithBadge(IconData icon) {
    final int unread = context.watch<AlertsProvider>().unreadCount;

    return Badge(
      isLabelVisible: unread > 0,
      label: Text('$unread'),
      child: Icon(icon),
    );
  }

  Widget _buildIcon(int index, {required bool selected}) {
    final _NavSection section = _sections[index];
    final IconData icon = selected ? section.selectedIcon : section.icon;

    return index == _alertsIndex ? _alertsIconWithBadge(icon) : Icon(icon);
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide =
        MediaQuery.sizeOf(context).width >= AppTheme.wideLayoutBreakpoint;

    // IndexedStack keeps each section's scroll position and loaded state.
    final Widget body = IndexedStack(
      index: _selectedIndex,
      children: _sections
          .map((_NavSection section) => section.builder())
          .toList(),
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            Icon(
              Icons.shield_moon_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            const Text('Safe Kid'),
          ],
        ),
        actions: <Widget>[
          const _UserChip(),
          IconButton(
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'התנתקות',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isWide
          ? Row(
              children: <Widget>[
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onSectionSelected,
                  labelType: NavigationRailLabelType.all,
                  destinations: <NavigationRailDestination>[
                    for (int i = 0; i < _sections.length; i++)
                      NavigationRailDestination(
                        icon: _buildIcon(i, selected: false),
                        selectedIcon: _buildIcon(i, selected: true),
                        label: Text(_sections[i].label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onSectionSelected,
              destinations: <NavigationDestination>[
                for (int i = 0; i < _sections.length; i++)
                  NavigationDestination(
                    icon: _buildIcon(i, selected: false),
                    selectedIcon: _buildIcon(i, selected: true),
                    label: _sections[i].label,
                  ),
              ],
            ),
    );
  }
}

/// Shows the signed-in parent's name; collapses to an avatar on narrow screens.
class _UserChip extends StatelessWidget {
  const _UserChip();

  @override
  Widget build(BuildContext context) {
    final String? name = context.select<AuthProvider, String?>(
      (AuthProvider provider) => provider.user?.fullName,
    );
    final String? initial = context.select<AuthProvider, String?>(
      (AuthProvider provider) => provider.user?.initial,
    );

    if (name == null) return const SizedBox.shrink();

    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool showName = MediaQuery.sizeOf(context).width >= 500;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 16,
            backgroundColor: colors.primaryContainer,
            child: Text(
              initial ?? '?',
              style: TextStyle(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (showName) ...<Widget>[
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
