import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../auth/login_screen.dart';
import '../home/app_shell.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _centerOpacity, _centerScale;
  late Animation<double> _leftOpacity, _leftScale;
  late Animation<double> _rightOpacity, _rightScale;
  late Animation<double> _arcProgress;
  late Animation<double> _dotsProgress;
  late Animation<double> _sparkle1, _sparkle2;
  late Animation<double> _globalIllum;
  late Animation<double> _wordmarkOpacity;
  late Animation<Offset> _wordmarkSlide;
  late Animation<double> _taglineOpacity;
  late Animation<Offset> _taglineSlide;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppTheme.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Phase 2: Central droplet  0.3–0.9s  → 0.10–0.30
    _centerOpacity = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.10, 0.30, curve: Curves.easeOut));
    _centerScale = Tween<double>(begin: 0.94, end: 1.0).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.10, 0.30, curve: Curves.easeOutCubic)));

    // Phase 3: Left petal  0.5–1.1s  → 0.167–0.367
    _leftOpacity = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.167, 0.367, curve: Curves.easeOut));
    _leftScale = Tween<double>(begin: 0.94, end: 1.0).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.167, 0.367, curve: Curves.easeOutCubic)));

    // Phase 4: Right petal  0.6–1.2s  → 0.20–0.40
    _rightOpacity = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.20, 0.40, curve: Curves.easeOut));
    _rightScale = Tween<double>(begin: 0.94, end: 1.0).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.20, 0.40, curve: Curves.easeOutCubic)));

    // Phase 5: Arc draw  0.9–1.6s  → 0.30–0.55
    _arcProgress = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.30, 0.55, curve: Curves.easeOutCubic));

    // Phase 6: Dots  1.3–1.7s  → 0.433–0.567
    _dotsProgress = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.433, 0.567, curve: Curves.linear));

    // Phase 7: Sparkles  1.4–1.8s  → 0.467–0.60
    _sparkle1 = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.467, 0.567, curve: Curves.easeOutBack));
    _sparkle2 = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.500, 0.600, curve: Curves.easeOutBack));

    // Phase 8: Settle/illumination  1.7–2.1s  → 0.567–0.70
    _globalIllum = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 50),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 50),
    ]).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.567, 0.70)));

    // Phase 9: DermaSense wordmark  1.9–2.3s  → 0.633–0.767
    _wordmarkOpacity = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.633, 0.767, curve: Curves.easeOut));
    _wordmarkSlide =
        Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.633, 0.767, curve: Curves.easeOutCubic)));

    // Phase 10: Tagline  2.1–2.5s  → 0.70–0.833
    _taglineOpacity = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.70, 0.833, curve: Curves.easeOut));
    _taglineSlide =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.70, 0.833, curve: Curves.easeOutCubic)));

    _controller.forward().then((_) => _nav());
  }

  void _nav() {
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, _, _) =>
            auth.isAuthenticated ? const AppShell() : const LoginScreen(),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    // Logo: 62% of screen width, square canvas
    final logoSize = screenW * 0.62;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [


          // ── Logo + Typography ──
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Push logo slightly above center
                  SizedBox(height: screenH * 0.05),

                  // Logo canvas
                  SizedBox(
                    width: logoSize,
                    height: logoSize,
                    child: CustomPaint(
                      painter: _DermaSenseLogoPainter(
                        centerOpacity: _centerOpacity.value,
                        centerScale: _centerScale.value,
                        leftOpacity: _leftOpacity.value,
                        leftScale: _leftScale.value,
                        rightOpacity: _rightOpacity.value,
                        rightScale: _rightScale.value,
                        arcProgress: _arcProgress.value,
                        dotsProgress: _dotsProgress.value,
                        sparkle1: _sparkle1.value,
                        sparkle2: _sparkle2.value,
                        globalIllum: _globalIllum.value,
                      ),
                    ),
                  ),

                  SizedBox(height: screenH * 0.042),

                  // ── Phase 9: DermaSense wordmark ──
                  SlideTransition(
                    position: _wordmarkSlide,
                    child: Opacity(
                      opacity: _wordmarkOpacity.value,
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: screenW * 0.088,
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                          ),
                          children: [
                            const TextSpan(
                                text: 'Derma',
                                style: TextStyle(color: AppTheme.textPrimary)),
                            TextSpan(
                                text: 'Sense',
                                style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Phase 10: Tagline ──
                  SlideTransition(
                    position: _taglineSlide,
                    child: Opacity(
                      opacity: _taglineOpacity.value,
                      child: Padding(
                        // Compensate for letterSpacing which adds space to the right of the last character
                        padding: const EdgeInsets.only(left: 3.2),
                        child: const Text(
                          'INTELLIGENT SKINCARE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 3.2,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenH * 0.05),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DotDef {
  final double x;
  final double y;
  final double r;
  final Color c;
  const _DotDef(this.x, this.y, this.r, this.c);
}

// ═══════════════════════════════════════════════════════════
//  PRECISION LOGO PAINTER
//  Design canvas: 200 × 200 units (scaled to actual size)
//  All coordinates derived from the original DermaSense logo
// ═══════════════════════════════════════════════════════════
class _DermaSenseLogoPainter extends CustomPainter {
  final double centerOpacity, centerScale;
  final double leftOpacity, leftScale;
  final double rightOpacity, rightScale;
  final double arcProgress;
  final double dotsProgress;
  final double sparkle1, sparkle2;
  final double globalIllum;

  const _DermaSenseLogoPainter({
    required this.centerOpacity,
    required this.centerScale,
    required this.leftOpacity,
    required this.leftScale,
    required this.rightOpacity,
    required this.rightScale,
    required this.arcProgress,
    required this.dotsProgress,
    required this.sparkle1,
    required this.sparkle2,
    required this.globalIllum,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Map 200×200 design canvas → actual pixel size
    canvas.scale(size.width / 200, size.height / 200);

    // ─────────────────────────────────────────────────────────
    // A. CENTRAL DROPLET
    // ─────────────────────────────────────────────────────────
    final Path dropletPath = Path()
      ..moveTo(100, 30) // Top tip
      ..cubicTo(70, 45, 45, 75, 50, 115) // Perfect smooth left bend
      ..cubicTo(55, 150, 85, 160, 100, 180) // Plunges deeply into the arc
      ..cubicTo(115, 160, 145, 150, 150, 115) // Perfect smooth right bend
      ..cubicTo(155, 75, 130, 45, 100, 30)
      ..close();

    // ─────────────────────────────────────────────────────────
    // B. LEFT PETAL
    // ─────────────────────────────────────────────────────────
    final Path leftPetalPath = Path()
      ..moveTo(101, 180) // Overlaps center slightly to crush any gap
      ..cubicTo(70, 165, 10, 130, 30, 80) // Broad outer sweep
      ..cubicTo(95, 95, 90, 150, 101, 180) // Pushed heavily right to overlap droplet
      ..close();

    // ─────────────────────────────────────────────────────────
    // C. RIGHT PETAL
    // ─────────────────────────────────────────────────────────
    final Path rightPetalPath = Path()
      ..moveTo(99, 180) // Overlaps center slightly to crush any gap
      ..cubicTo(130, 165, 190, 130, 165, 85) // Broad outer sweep
      ..cubicTo(105, 100, 110, 150, 99, 180) // Pushed heavily left to overlap droplet
      ..close();

    // ─────────────────────────────────────────────────────────
    // D. OUTER ARC
    // ─────────────────────────────────────────────────────────
    // A mathematically perfect circular arc (R=77) to guarantee flawless bending
    final double arcStart = math.atan2(-70, 32); // From top-right
    final double arcEnd = math.atan2(72, -27);   // To bottom-left
    double arcSweep = arcEnd - arcStart;
    if (arcSweep < 0) arcSweep += 2 * math.pi;

    final Path arcPath = Path()
      ..addArc(
        Rect.fromCircle(center: const Offset(100, 100), radius: 79),
        arcStart,
        arcSweep,
      );

    // ─────────────────────────────────────────────────────────
    // GRADIENT SHADERS
    // ─────────────────────────────────────────────────────────

    // Central droplet: directional light from top-left
    final Shader dropletShader = LinearGradient(
      begin: const Alignment(-0.8, -0.8), // Top-left light source
      end: const Alignment(0.8, 1.0),
      colors: [
        const Color(0xFFFFFFFF), // Glowing white highlight on left shoulder
        AppTheme.primaryLight,
        AppTheme.secondaryLight,
        AppTheme.secondary,
        AppTheme.primaryDark,
      ],
      stops: const [0.0, 0.15, 0.40, 0.70, 1.0],
    ).createShader(const Rect.fromLTWH(45, 30, 110, 150));

    // Left petal: soft peach inner → warm peach-orange → deep terracotta outer
    final Shader leftShader = LinearGradient(
      begin: const Alignment(0.0, -1.0), // Top-center light (hits tip and inner rim)
      end: const Alignment(-1.0, 1.0),
      colors: [
        const Color(0xFFFFFFFF), // Glowing tip
        AppTheme.primaryLight,
        AppTheme.primary,
        AppTheme.primaryDark,
      ],
      stops: const [0.0, 0.20, 0.60, 1.0],
    ).createShader(const Rect.fromLTWH(10, 80, 90, 100));

    // Right petal: taupe variants
    final Shader rightShader = LinearGradient(
      begin: const Alignment(0.0, -1.0), // Top-center light (hits tip and inner rim)
      end: const Alignment(1.0, 1.0),
      colors: [
        const Color(0xFFFFFFFF), // Glowing tip
        AppTheme.secondaryLight,
        AppTheme.secondary,
        const Color(0xFF6A574F), // Deep taupe
      ],
      stops: const [0.0, 0.20, 0.60, 1.0],
    ).createShader(const Rect.fromLTWH(100, 85, 90, 95));

    // Arc: sweeps underneath petals
    final Shader arcShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppTheme.primaryDark.withValues(alpha: 0.0),
        AppTheme.primaryDark,
        AppTheme.primary,
        AppTheme.primaryLight, // Brightest at middle
        AppTheme.primary,
        AppTheme.primaryDark,
        AppTheme.primaryDark.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.1, 0.3, 0.5, 0.7, 0.9, 1.0],
    ).createShader(const Rect.fromLTWH(80, 20, 130, 175));

    // ─────────────────────────────────────────────────────────
    // DRAW — left petal → right petal → center droplet (on top)
    // ─────────────────────────────────────────────────────────

    void drawShape(
        Path path, Shader shader, double opacity, double scale, Offset pivot) {
      if (opacity <= 0) return;
      canvas.save();

      // Scale transform from pivot point
      canvas.translate(pivot.dx, pivot.dy);
      canvas.scale(scale);
      canvas.translate(-pivot.dx, -pivot.dy);

      // Apply opacity via saveLayer when animating in
      if (opacity < 1.0) {
        canvas.saveLayer(
          const Rect.fromLTWH(0, 0, 200, 200),
          Paint()..color = Colors.white.withValues(alpha: opacity),
        );
      }

      // 1. Base gradient fill
      canvas.drawPath(path, Paint()..shader = shader);

      if (opacity < 1.0) canvas.restore();
      canvas.restore();
    }

    // Draw order matches the reference layering
    // Droplet is drawn first (in the back). Petals are drawn ON TOP, cupping it.
    drawShape(dropletPath, dropletShader, centerOpacity, centerScale,
        const Offset(100, 92)); // pivot: center of droplet body
    drawShape(leftPetalPath, leftShader, leftOpacity, leftScale,
        const Offset(55, 130)); // pivot: center-of-mass of left petal
    drawShape(rightPetalPath, rightShader, rightOpacity, rightScale,
        const Offset(145, 132)); // pivot: center-of-mass of right petal

    // ─────────────────────────────────────────────────────────
    // ARC — drawn ON TOP to smoothly cover the junction
    // ─────────────────────────────────────────────────────────
    if (arcProgress > 0) {
      final metric = arcPath.computeMetrics().first;
      final drawn = metric.extractPath(0, metric.length * arcProgress.clamp(0.0, 1.0));

      // Crisp principal stroke on top
      canvas.drawPath(
        drawn,
        Paint()
          ..shader = arcShader
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5 // Thicker to swallow the V gap completely
          ..strokeCap = StrokeCap.round,
      );
    }


    // ─────────────────────────────────────────────────────────
    // DOTS — 5 graduated circles along lower-right arc
    // ─────────────────────────────────────────────────────────
    if (dotsProgress > 0) {
      final dots = [
        const _DotDef(174.0, 98.0, 2.5, AppTheme.secondary),
        const _DotDef(170.0, 118.0, 3.5, AppTheme.secondaryLight),
        const _DotDef(160.0, 136.0, 5.0, AppTheme.primaryLight),
        const _DotDef(146.0, 152.0, 3.5, AppTheme.primary),
        const _DotDef(132.0, 165.0, 2.2, AppTheme.primaryDark), // Matches tight circular radius
      ];

      for (int i = 0; i < dots.length; i++) {
        final double start = i * 0.12;
        final double end = start + 0.40;
        final double p =
            ((dotsProgress - start) / (end - start)).clamp(0.0, 1.0);
        if (p <= 0) continue;

        final pos = Offset(dots[i].x, dots[i].y);
        final r = dots[i].r;
        final color = dots[i].c;

        // Crisp solid dot
        canvas.drawCircle(
          pos,
          r * p,
          Paint()..color = color.withValues(alpha: 0.95 * p),
        );
      }
    }

    // ─────────────────────────────────────────────────────────
    // GLOBAL ILLUMINATION BLOOM — subtle settle-in lighting
    // ─────────────────────────────────────────────────────────
    // Disabled per user request
  }

  @override
  bool shouldRepaint(covariant _DermaSenseLogoPainter old) => true;
}
