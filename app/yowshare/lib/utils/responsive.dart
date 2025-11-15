import 'package:flutter/material.dart';

/// Simple responsive helper to standardize breakpoints and scaled sizing.
class Screen {
  final BuildContext context;
  final Size size;
  final double width;
  final double height;

  Screen(this.context)
      : size = MediaQuery.of(context).size,
        width = MediaQuery.of(context).size.width,
        height = MediaQuery.of(context).size.height;

  bool get isSmallPhone => width < 400;
  bool get isPhone => width >= 400 && width < 800;
  bool get isTablet => width >= 800 && width < 1200;
  bool get isDesktop => width >= 1200;

  /// Scales a value relative to a base width (360 typical mobile width).
  double scaleWidth(double value, {double base = 360}) {
    return (width / base) * value;
  }

  /// Scales by height relative to a base height (780 typical mobile height).
  double scaleHeight(double value, {double base = 780}) {
    return (height / base) * value;
  }

  /// Returns an adaptive padding value.
  EdgeInsets adaptivePadding({
    double horizontal = 16,
    double vertical = 12,
  }) {
    return EdgeInsets.symmetric(
      horizontal: scaleWidth(horizontal),
      vertical: scaleHeight(vertical),
    );
  }
}

/// A builder widget to provide three common layout tiers:
/// mobile (phone), tablet, desktop. Use to switch widgets easily.
class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final screen = Screen(context);

    if (screen.isDesktop && desktop != null) {
      return desktop!;
    } else if (screen.isTablet && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}
