import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Constrains page content to a readable width and centers it, so wide web
/// windows do not stretch forms and cards across the full viewport.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = AppTheme.maxContentWidth,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
