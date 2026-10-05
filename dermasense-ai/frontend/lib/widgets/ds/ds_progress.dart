import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class DSProgressCircle extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final String? centerText;
  final String? centerSubText;
  final Color? color;
  final Color? backgroundColor;

  const DSProgressCircle({
    super.key,
    required this.value,
    this.size = 120.0,
    this.strokeWidth = 10.0,
    this.centerText,
    this.centerSubText,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppTheme.primary;
    final effectiveBgColor = backgroundColor ?? AppTheme.surfaceHighlight;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: strokeWidth,
              color: effectiveBgColor,
            ),
          ),
          // Animated progress circle
          SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: value),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOutCubic,
              builder: (context, val, child) {
                return CircularProgressIndicator(
                  value: val,
                  strokeWidth: strokeWidth,
                  color: effectiveColor,
                  strokeCap: StrokeCap.round,
                );
              },
            ),
          ),
          // Center Text
          if (centerText != null)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  centerText!,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: effectiveColor,
                        fontSize: size * 0.3,
                        height: 1.1,
                      ),
                ),
                if (centerSubText != null)
                  Text(
                    centerSubText!,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: size * 0.1,
                        ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class DSProgressBar extends StatelessWidget {
  final String label;
  final double value; // 0.0 to 1.0
  final String? valueText;
  final Color? color;

  const DSProgressBar({
    super.key,
    required this.label,
    required this.value,
    this.valueText,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppTheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.textPrimary,
                  ),
            ),
            if (valueText != null)
              Text(
                valueText!,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: effectiveColor,
                    ),
              ),
          ],
        ),
        const SizedBox(height: AppTheme.space8),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.surfaceHighlight,
            borderRadius: AppTheme.borderRadiusPill,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: value),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    builder: (context, val, child) {
                      return Container(
                        width: constraints.maxWidth * val,
                        decoration: BoxDecoration(
                          color: effectiveColor,
                          borderRadius: AppTheme.borderRadiusPill,
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
