import 'package:flutter/material.dart';

import '../utils/breakpoints.dart';

/// Picks a builder based on the available layout width, measured via
/// [LayoutBuilder] rather than [MediaQuery] — this reacts to the actual
/// content-box width (e.g. the space left after a persistent nav rail),
/// not the full browser viewport.
///
/// Only [mobile] is required; [tablet]/[desktop]/[wide] fall back to the
/// next-narrowest builder that was provided.
class ResponsiveLayout extends StatelessWidget {
  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;
  final WidgetBuilder? wide;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.wide,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (Breakpoints.isWide(width)) {
          return (wide ?? desktop ?? tablet ?? mobile)(context);
        }
        if (Breakpoints.isDesktop(width)) {
          return (desktop ?? tablet ?? mobile)(context);
        }
        if (Breakpoints.isTablet(width)) {
          return (tablet ?? mobile)(context);
        }
        return mobile(context);
      },
    );
  }
}

/// Centers content and caps it at [Breakpoints.maxContentWidth] once the
/// available width passes the `wide` breakpoint, so cards/grids don't
/// stretch into thin, unreadable bars on ultra-wide monitors.
class MaxWidthContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const MaxWidthContent({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.maxContentWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
