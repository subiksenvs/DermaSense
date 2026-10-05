import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

enum DSCardVariant { base, elevated, glass, outline }

class DSCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final DSCardVariant variant;
  final double? width;
  final double? height;
  final BorderRadiusGeometry? borderRadius;

  const DSCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.space24),
    this.onTap,
    this.variant = DSCardVariant.base,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? AppTheme.borderRadiusLarge;

    BoxDecoration decoration;
    switch (variant) {
      case DSCardVariant.base:
        decoration = BoxDecoration(
          color: AppTheme.surfaceBase,
          borderRadius: effectiveRadius,
        );
        break;
      case DSCardVariant.elevated:
        decoration = BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: effectiveRadius,
        );
        break;
      case DSCardVariant.glass:
        decoration = BoxDecoration(
          color: AppTheme.surfaceHighlight.withValues(alpha: 0.6),
          borderRadius: effectiveRadius,
          border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
        );
        break;
      case DSCardVariant.outline:
        decoration = BoxDecoration(
          color: Colors.transparent,
          borderRadius: effectiveRadius,
          border: Border.all(color: AppTheme.surfaceHighlight, width: 1.5),
        );
        break;
    }

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: decoration,
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveRadius as BorderRadius,
          child: content,
        ),
      );
    }

    return content.animate().fade(duration: 400.ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOutQuad);
  }
}
