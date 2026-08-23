import 'dart:ui';
import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> onboardingData = [
    {
      "title": "Understand Your Skin",
      "text":
          "Discover your skin's unique needs with our advanced AI analysis technology.",
      "icon": Icons.face_retouching_natural_rounded,
      "color": AppTheme.primaryColor,
    },
    {
      "title": "AI-Assisted Analysis",
      "text":
          "Get preliminary screening and detailed insights into your skin health.",
      "icon": Icons.document_scanner_rounded,
      "color": AppTheme.secondaryColor,
    },
    {
      "title": "Personalized Care",
      "text":
          "Receive custom skincare routines tailored specifically for your skin profile.",
      "icon": Icons.auto_awesome_mosaic_rounded,
      "color": AppTheme.errorColor,
    },
    {
      "title": "Track Your Progress",
      "text":
          "Monitor your skin's improvement over time with our digital journal.",
      "icon": Icons.insights_rounded,
      "color": AppTheme.successColor,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          // Dynamic Animated Background Glow
          AnimatedPositioned(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOut,
            top: _currentPage == 0 ? -100 : (_currentPage == 1 ? 0 : 100),
            right: _currentPage % 2 == 0 ? -150 : null,
            left: _currentPage % 2 != 0 ? -150 : null,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: onboardingData[_currentPage]["color"].withValues(
                  alpha: 0.15,
                ),
                boxShadow: [
                  BoxShadow(
                    color: onboardingData[_currentPage]["color"].withValues(
                      alpha: 0.25,
                    ),
                    blurRadius: 120,
                    spreadRadius: 100,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top section for skip button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _goToLogin(),
                        child: Text(
                          "Skip",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Page View
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (value) {
                      setState(() {
                        _currentPage = value;
                      });
                    },
                    itemCount: onboardingData.length,
                    itemBuilder: (context, index) => OnboardingContent(
                      title: onboardingData[index]["title"]!,
                      text: onboardingData[index]["text"]!,
                      icon: onboardingData[index]["icon"]!,
                      accentColor: onboardingData[index]["color"]!,
                    ),
                  ),
                ),

                // Bottom Glassmorphism Control Panel
                ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(32, 32, 32, 48),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor.withValues(alpha: 0.5),
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              onboardingData.length,
                              (index) => buildDot(index: index),
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  colors:
                                      _currentPage == onboardingData.length - 1
                                      ? [
                                          AppTheme.primaryColor,
                                          AppTheme.secondaryColor,
                                        ]
                                      : [
                                          AppTheme.primaryColor,
                                          AppTheme.primaryColor,
                                        ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        _currentPage ==
                                            onboardingData.length - 1
                                        ? AppTheme.secondaryColor.withValues(
                                            alpha: 0.4,
                                          )
                                        : AppTheme.primaryColor.withValues(
                                            alpha: 0.4,
                                          ),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                ),
                                onPressed: () {
                                  if (_currentPage ==
                                      onboardingData.length - 1) {
                                    _goToLogin();
                                  } else {
                                    _pageController.nextPage(
                                      duration: const Duration(
                                        milliseconds: 500,
                                      ),
                                      curve: Curves.fastLinearToSlowEaseIn,
                                    );
                                  }
                                },
                                child: Text(
                                  _currentPage == onboardingData.length - 1
                                      ? "BEGIN JOURNEY"
                                      : "CONTINUE",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const LoginScreen(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  AnimatedContainer buildDot({required int index}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      margin: const EdgeInsets.only(right: 8),
      height: 6,
      width: _currentPage == index ? 32 : 12,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? onboardingData[_currentPage]["color"]
            : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(3),
        boxShadow: _currentPage == index
            ? [
                BoxShadow(
                  color: onboardingData[_currentPage]["color"].withValues(
                    alpha: 0.5,
                  ),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
    );
  }
}

class OnboardingContent extends StatelessWidget {
  final String title, text;
  final IconData icon;
  final Color accentColor;

  const OnboardingContent({
    super.key,
    required this.title,
    required this.text,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(flex: 2),
        // Glowing Floating Icon
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: accentColor.withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.2),
                blurRadius: 60,
                spreadRadius: 20,
              ),
            ],
          ),
          child: Center(child: Icon(icon, size: 80, color: Colors.white)),
        ),
        const Spacer(flex: 1),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.displayMedium?.copyWith(fontSize: 32),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: 16, height: 1.6),
          ),
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}
