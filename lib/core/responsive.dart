import 'package:flutter/material.dart';

/// Standard breakpoint definitions and responsive layout helpers for CafeVerse.
class Breakpoints {
  Breakpoints._();

  /// Maximum width for compact mobile layout.
  static const double compact = 600.0;

  /// Maximum width for medium/tablet layout.
  static const double medium = 840.0;

  /// Maximum width for expanded tablet/small desktop layout.
  static const double expanded = 1200.0;

  /// Optimal maximum width for content containers on wide displays.
  static const double maxContentWidth = 1280.0;

  /// Optimal maximum width for reading text blocks and forms.
  static const double maxTextContentWidth = 800.0;
}

/// Helper extension on BuildContext to quickly query responsive window tiers.
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  bool get isCompact => screenWidth < Breakpoints.compact;
  bool get isMedium =>
      screenWidth >= Breakpoints.compact && screenWidth < Breakpoints.medium;
  bool get isWide => screenWidth >= Breakpoints.medium;
}

/// A responsive widget builder that provides compact, medium, and wide layouts based on BoxConstraints.
class ResponsiveLayout extends StatelessWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints) compact;
  final Widget Function(BuildContext context, BoxConstraints constraints)? medium;
  final Widget Function(BuildContext context, BoxConstraints constraints)? wide;

  const ResponsiveLayout({
    super.key,
    required this.compact,
    this.medium,
    this.wide,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Breakpoints.medium && wide != null) {
          return wide!(context, constraints);
        }
        if (constraints.maxWidth >= Breakpoints.compact && medium != null) {
          return medium!(context, constraints);
        }
        return compact(context, constraints);
      },
    );
  }
}
