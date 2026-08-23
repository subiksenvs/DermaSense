import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/skin_profile_provider.dart';
import '../../theme/app_theme.dart';
import '../analysis/analysis_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/glass_card.dart';
import '../routine/routine_screen.dart';
import '../chat/chat_screen.dart';
import '../doctors/doctors_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          // Background ambient glows
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 100, spreadRadius: 100),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(color: AppTheme.secondaryColor.withValues(alpha: 0.2), blurRadius: 80, spreadRadius: 80),
                ],
              ),
            ),
          ),
          
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 120.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Good morning,",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            context.watch<SkinProfileProvider>().profile.fullName.isEmpty 
                              ? "User" 
                              : context.watch<SkinProfileProvider>().profile.fullName,
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: 32,
                              foreground: Paint()
                                ..shader = const LinearGradient(
                                  colors: [Colors.white, Color(0xFFB0B0C0)],
                                ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProfileScreen()),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 2),
                          ),
                          child: Builder(
                            builder: (context) {
                              final profileImageUrl = context.watch<SkinProfileProvider>().profile.profileImageUrl;
                              return CircleAvatar(
                                radius: 26,
                                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                                backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                                    ? NetworkImage(profileImageUrl)
                                    : null,
                                child: (profileImageUrl == null || profileImageUrl.isEmpty)
                                    ? const Icon(Icons.person, color: AppTheme.primaryColor)
                                    : null,
                              );
                            }
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 36),
                  
                  // Premium Skin Health Score Card (Glassmorphism)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.surfaceColor.withValues(alpha: 0.6),
                              AppTheme.surfaceColor.withValues(alpha: 0.2),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.auto_awesome, color: AppTheme.secondaryColor, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "OVERALL SKIN HEALTH",
                                  style: TextStyle(
                                    color: AppTheme.secondaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [AppTheme.secondaryColor, AppTheme.primaryColor],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds),
                                  child: const Text(
                                    "82",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 64,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -2,
                                    ),
                                  ),
                                ),
                                Text(
                                  "/100",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.5)),
                              ),
                              child: const Text(
                                "Excellent Progress",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  Text(
                    "Discover",
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Quick Actions grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuickAction(context, Icons.center_focus_strong_rounded, "Analyze", AppTheme.primaryColor, () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalysisScreen()));
                      }),
                      _buildQuickAction(context, Icons.medical_information_rounded, "Consult", AppTheme.secondaryColor, () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const DoctorsScreen()));
                      }),
                      _buildQuickAction(context, Icons.auto_awesome_mosaic_rounded, "Routine", AppTheme.errorColor, () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const RoutineScreen()));
                      }),
                      _buildQuickAction(context, Icons.forum_rounded, "Assistant", AppTheme.successColor, () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatScreen()));
                      }),
                    ],
                  ),
                  const SizedBox(height: 40),
                  
                  Text(
                    "Daily Insight",
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Insight Card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.water_drop_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Hydration Alert",
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Your skin appears slightly dehydrated today. Use a gentle moisturizer.",
                                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label, Color accentColor, VoidCallback onTap) {
    return Column(
      children: [
        GlassCard(
          padding: EdgeInsets.zero,
          borderRadius: 20,
          onTap: onTap,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [accentColor.withValues(alpha: 0.3), accentColor.withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(icon, color: accentColor, size: 30),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        )
      ],
    );
  }
}
