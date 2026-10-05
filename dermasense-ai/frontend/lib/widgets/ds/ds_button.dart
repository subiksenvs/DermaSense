import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum DSButtonVariant { primary, secondary, outline, text, glass }

class DSButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final DSButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;

  const DSButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = DSButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget buttonContent = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(right: AppTheme.space12),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _getTextColor(),
            ),
          )
        else if (icon != null) ...[
          Icon(icon, size: 20, color: _getTextColor()),
          const SizedBox(width: AppTheme.space8),
        ],
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: _getTextColor(),
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );

    Widget button;

    switch (variant) {
      case DSButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusPill),
            padding: const EdgeInsets.symmetric(vertical: AppTheme.space16, horizontal: AppTheme.space24),
          ),
          child: buttonContent,
        );
        break;
      case DSButtonVariant.secondary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.surfaceElevated,
            foregroundColor: AppTheme.textPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusPill),
            padding: const EdgeInsets.symmetric(vertical: AppTheme.space16, horizontal: AppTheme.space24),
          ),
          child: buttonContent,
        );
        break;
      case DSButtonVariant.outline:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.textPrimary,
            side: const BorderSide(color: AppTheme.surfaceHighlight, width: 1.5),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusPill),
            padding: const EdgeInsets.symmetric(vertical: AppTheme.space16, horizontal: AppTheme.space24),
          ),
          child: buttonContent,
        );
        break;
      case DSButtonVariant.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primaryLight,
            padding: const EdgeInsets.symmetric(vertical: AppTheme.space16, horizontal: AppTheme.space24),
          ),
          child: buttonContent,
        );
        break;
      case DSButtonVariant.glass:
        button = InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: AppTheme.borderRadiusPill,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.space16, horizontal: AppTheme.space24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: AppTheme.borderRadiusPill,
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: buttonContent,
          ),
        );
        break;
    }

    return isFullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }

  Color _getTextColor() {
    switch (variant) {
      case DSButtonVariant.primary:
        return Colors.white;
      case DSButtonVariant.secondary:
      case DSButtonVariant.outline:
      case DSButtonVariant.glass:
        return AppTheme.textPrimary;
      case DSButtonVariant.text:
        return AppTheme.primaryLight;
    }
  }
}
