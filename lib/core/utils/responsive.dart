import 'package:flutter/material.dart';

/// Responsive breakpoints for the app.
///
/// - mobile  : width < 600
/// - tablet  : 600 ≤ width < 1024
/// - desktop : width ≥ 1024
class AppBreakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
}

/// Convenience accessors for the current screen width.
class AppResponsive {
  AppResponsive._();

  static double screenWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static bool isMobile(BuildContext context) =>
      screenWidth(context) < AppBreakpoints.mobile;

  static bool isTablet(BuildContext context) {
    final w = screenWidth(context);
    return w >= AppBreakpoints.mobile && w < AppBreakpoints.tablet;
  }

  static bool isDesktop(BuildContext context) =>
      screenWidth(context) >= AppBreakpoints.tablet;

  static bool isTabletOrDesktop(BuildContext context) =>
      screenWidth(context) >= AppBreakpoints.mobile;

  /// Returns the horizontal screen padding scaled to the screen size.
  /// Mobile: 18, Tablet: 32, Desktop: 48
  static double screenPadding(BuildContext context) {
    if (isDesktop(context)) return 48;
    if (isTablet(context)) return 32;
    return 18;
  }

  /// Max content width for desktop to prevent content from stretching too wide.
  static double contentMaxWidth(BuildContext context) {
    if (isDesktop(context)) return 1200;
    return double.infinity;
  }
}

/// Widget that renders different subtrees based on screen size.
///
/// At minimum, [mobile] must be provided.
/// [tablet] falls back to [mobile] if not provided.
/// [desktop] falls back to [tablet] (then [mobile]) if not provided.
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (AppResponsive.isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    }
    if (AppResponsive.isTablet(context)) {
      return tablet ?? mobile;
    }
    return mobile;
  }
}

/// Wraps [child] in a centered, max-width constrained box.
/// Useful for capping content width on large screens.
class MaxWidthBox extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const MaxWidthBox({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding != null ? Padding(padding: padding!, child: child) : child,
      ),
    );
  }
}
