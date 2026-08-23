import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LiquidBackground extends StatefulWidget {
  final Widget child;

  const LiquidBackground({super.key, required this.child});

  @override
  State<LiquidBackground> createState() => _LiquidBackgroundState();
}

class _LiquidBackgroundState extends State<LiquidBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dark Base
        Container(color: AppTheme.backgroundDark),
        
        // Moving Liquid Blobs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Stack(
              children: [
                // Top Right Blob (Primary)
                Positioned(
                  top: -100 + sin(_controller.value * 2 * pi) * 50,
                  right: -100 + cos(_controller.value * 2 * pi) * 50,
                  child: _buildBlob(AppTheme.primaryColor, 300),
                ),
                // Bottom Left Blob (Secondary)
                Positioned(
                  bottom: -150 + cos(_controller.value * 2 * pi) * 100,
                  left: -100 + sin(_controller.value * 2 * pi) * 50,
                  child: _buildBlob(AppTheme.secondaryColor, 350),
                ),
                // Center Blob (Accent)
                Positioned(
                  top: MediaQuery.of(context).size.height / 3 + sin(_controller.value * pi) * 150,
                  left: MediaQuery.of(context).size.width / 4 + cos(_controller.value * pi) * 150,
                  child: _buildBlob(AppTheme.primaryLight, 200),
                ),
              ],
            );
          },
        ),
        
        // Massive Blur overlay to create the smooth liquid mesh effect
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
          child: Container(
            color: AppTheme.backgroundDark.withValues(alpha: 0.5),
          ),
        ),
        
        // Actual Content
        widget.child,
      ],
    );
  }

  Widget _buildBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.6),
      ),
    );
  }
}
