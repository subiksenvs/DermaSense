import 'dart:convert';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class DSAvatar extends StatefulWidget {
  final String? imageUrl;
  final double radius;
  final VoidCallback? onTap;

  const DSAvatar({
    super.key,
    this.imageUrl,
    this.radius = 24.0,
    this.onTap,
  });

  @override
  State<DSAvatar> createState() => _DSAvatarState();
}

class _DSAvatarState extends State<DSAvatar> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    final hasImage = widget.imageUrl != null && widget.imageUrl!.isNotEmpty;

    if (hasImage) {
      if (widget.imageUrl!.startsWith('data:image')) {
        imageProvider = MemoryImage(base64Decode(widget.imageUrl!.split(',').last));
      } else if (widget.imageUrl!.startsWith('http')) {
        imageProvider = NetworkImage(widget.imageUrl!);
      }
    }

    Widget avatar = MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.radius * 2,
        height: widget.radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.surfaceElevated,
          border: Border.all(
            color: _isHovered ? Colors.white : AppTheme.primary,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered ? AppTheme.primary.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.3),
              blurRadius: _isHovered ? 15 : 10,
              offset: const Offset(0, 4),
            ),
          ],
          image: imageProvider != null
              ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
              : null,
        ),
        child: imageProvider == null
            ? Icon(
                Icons.person_outline,
                color: _isHovered ? AppTheme.textPrimary : AppTheme.textSecondary,
                size: widget.radius,
              )
            : null,
      ),
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap,
        child: avatar,
      );
    }

    return avatar;
  }
}
