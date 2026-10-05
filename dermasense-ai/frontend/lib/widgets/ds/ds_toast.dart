import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum ToastType { success, error, info }

class DSToast {
  static OverlayEntry? _currentEntry;

  /// Show a modern top-right intimation toast notification
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        title: title,
        type: type,
        onDismiss: () {
          if (_currentEntry == entry) {
            entry.remove();
            _currentEntry = null;
          }
        },
        duration: duration,
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  static void showSuccess(BuildContext context, String message, {String? title, Duration duration = const Duration(seconds: 3)}) {
    show(context, message, type: ToastType.success, title: title, duration: duration);
  }

  static void showError(BuildContext context, String message, {String? title, Duration duration = const Duration(seconds: 3)}) {
    show(context, message, type: ToastType.error, title: title, duration: duration);
  }

  static void showInfo(BuildContext context, String message, {String? title, Duration duration = const Duration(seconds: 3)}) {
    show(context, message, type: ToastType.info, title: title, duration: duration);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final String? title;
  final ToastType type;
  final VoidCallback onDismiss;
  final Duration duration;

  const _ToastWidget({
    required this.message,
    this.title,
    required this.type,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.4, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getAccentColor() {
    switch (widget.type) {
      case ToastType.success:
        return const Color(0xFF10B981); // Emerald Green
      case ToastType.error:
        return const Color(0xFFEF4444); // Crimson Red
      case ToastType.info:
        return AppTheme.primary; // Neon Coral/Peach
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case ToastType.success:
        return Icons.check_circle_rounded;
      case ToastType.error:
        return Icons.error_rounded;
      case ToastType.info:
        return Icons.info_rounded;
    }
  }

  String _getDefaultTitle() {
    switch (widget.type) {
      case ToastType.success:
        return "Success";
      case ToastType.error:
        return "Notice";
      case ToastType.info:
        return "DermaSense";
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top + 12.0;
    final accentColor = _getAccentColor();
    final headerTitle = widget.title ?? _getDefaultTitle();

    return Positioned(
      top: topPadding,
      right: 16.0,
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: (mediaQuery.size.width - 32).clamp(240.0, 360.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B), // Dark rich charcoal
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.4),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.15),
                    blurRadius: 14,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIcon(),
                      color: accentColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          headerTitle,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.message,
                          style: const TextStyle(
                            color: Color(0xFFFAFAFA),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      _controller.reverse().then((_) {
                        widget.onDismiss();
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.close_rounded,
                        color: Color(0xFFA1A1AA),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
