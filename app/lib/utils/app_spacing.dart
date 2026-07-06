import 'package:flutter/material.dart';

import 'breakpoints.dart';

/// Spacing scale extending the existing theme tokens (app_theme.dart,
/// app_color_scheme.dart) rather than replacing them. 4/8-based, matching
/// the paddings already used throughout the app (16/20/24).
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Section/card-grid gutter that grows on wider viewports — mobile keeps
  /// the current uniform 24px gap; desktop gets more breathing room.
  static double sectionGap(double width) {
    if (Breakpoints.isAtLeastDesktop(width)) return xxl;
    if (Breakpoints.isAtLeastTablet(width)) return xl;
    return lg;
  }

  /// Outer page padding — mobile keeps today's 20px edge padding; wider
  /// viewports get more so content doesn't hug the nav rail/window edge.
  static double pagePadding(double width) {
    if (Breakpoints.isAtLeastDesktop(width)) return xl;
    if (Breakpoints.isAtLeastTablet(width)) return lg;
    return md + xs; // 20, unchanged from today's Home padding
  }
}

/// Named typography steps built on the app's existing fonts (Lexend Mega
/// for display/headline, Public Sans for body) — same families and weights
/// used today, just given names and a modest size bump at wider breakpoints
/// instead of the ad hoc inline TextStyle literals scattered per-screen.
class AppTypeScale {
  const AppTypeScale._();

  static TextStyle display(double width, {Color color = Colors.black}) {
    return TextStyle(
      fontFamily: 'Lexend Mega',
      fontSize: Breakpoints.isAtLeastDesktop(width) ? 28 : 20,
      fontWeight: FontWeight.w700,
      color: color,
      height: 1.15,
    );
  }

  static TextStyle h1(double width, {Color color = Colors.black}) {
    return TextStyle(
      fontFamily: 'Lexend Mega',
      fontSize: Breakpoints.isAtLeastDesktop(width) ? 22 : 16,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: color,
      height: 1.2,
    );
  }

  static TextStyle h2(double width, {Color color = Colors.black}) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: Breakpoints.isAtLeastDesktop(width) ? 16 : 14,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.14,
      color: color,
    );
  }

  static TextStyle body(double width, {Color color = Colors.black}) {
    return TextStyle(
      fontFamily: 'Public Sans',
      fontSize: Breakpoints.isAtLeastDesktop(width) ? 15 : 14,
      fontWeight: FontWeight.w500,
      color: color,
    );
  }

  static TextStyle caption(double width, {Color color = Colors.black}) {
    return TextStyle(
      fontFamily: 'Public Sans',
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }
}
