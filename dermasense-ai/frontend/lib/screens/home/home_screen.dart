import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ai_service.dart';
import '../../providers/history_provider.dart';
import '../../providers/notification_provider.dart';
import '../../theme/app_theme.dart';
import '../analysis/analysis_screen.dart';
import '../profile/profile_screen.dart';
import '../routine/routine_screen.dart';
import '../doctors/doctors_screen.dart';
import '../history/history_screen.dart';
import '../../widgets/ds/ds_card.dart';
import '../../widgets/ds/ds_avatar.dart';
import '../../widgets/ds/ds_progress.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _dailyTip = "";
  bool _isFetchingTip = true;

  @override
  void initState() {
    super.initState();
    _fetchDailyTip();
  }

  Future<void> _fetchDailyTip() async {
    try {
      final tip = await AiService().generateText(
        prompt: "Provide a single, short, insightful daily skincare tip (maximum 2 sentences). Be highly informative and varied.",
      );
      if (mounted) {
        setState(() {
          _dailyTip = tip.isNotEmpty ? tip : "Stay hydrated and wear sunscreen every day!";
          _isFetchingTip = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dailyTip = "Remember to patch test new products before applying them fully.";
          _isFetchingTip = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimationLimiter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: AnimationConfiguration.toStaggeredList(
                        duration: const Duration(milliseconds: 600),
                        childAnimationBuilder: (widget) => SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(child: widget),
                        ),
                        children: [
                          const SizedBox(height: AppTheme.space24),
                          _buildSkinScoreSection(context),
                          const SizedBox(height: AppTheme.space40),
                          _buildDiscoverSection(context),
                          const SizedBox(height: AppTheme.space24),
                          _buildDailyTipSection(context),
                          const SizedBox(height: AppTheme.space24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppTheme.background,
      pinned: true,
      floating: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 80,
      titleSpacing: AppTheme.space24,
      centerTitle: false,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 24, letterSpacing: -0.5),
              children: const [
                TextSpan(text: "Derma", style: TextStyle(color: Colors.white)),
                TextSpan(text: "Sense", style: TextStyle(color: AppTheme.primaryColor)),
              ],
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            "INTELLIGENT SKIN CARE",
            style: TextStyle(
              color: AppTheme.textSecondary,
              letterSpacing: 1.2,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              fontFamily: 'Outfit',
            ),
          ),
        ],
      ),
      actions: [
        Consumer<NotificationProvider>(
          builder: (context, provider, child) {
            return Badge(
              isLabelVisible: provider.unreadCount > 0,
              label: Text(provider.unreadCount.toString()),
              offset: const Offset(-4, 4),
              child: IconButton(
                icon: const Icon(Icons.notifications_none, color: AppTheme.textSecondary),
                onPressed: () {
                  Navigator.pushNamed(context, '/notifications');
                },
              ),
            );
          },
        ),
        const SizedBox(width: AppTheme.space8),
        DSAvatar(
          radius: 18,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
          },
        ),
        const SizedBox(width: AppTheme.space24),
      ],
    );
  }

  Widget _buildSkinScoreSection(BuildContext context) {
    return Consumer<HistoryProvider>(
      builder: (context, historyProvider, child) {
        if (historyProvider.records.isEmpty) {
          return DSCard(
            width: double.infinity,
            variant: DSCardVariant.elevated,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalysisScreen()));
            },
            child: Column(
              children: [
                Icon(Icons.camera_alt_outlined, color: AppTheme.primary, size: 48),
                const SizedBox(height: AppTheme.space16),
                Text(
                  "Analyze to see recommendations",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppTheme.space8),
                Text(
                  "Take a skin scan to get your personalized AM/PM routine.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        final latestRecord = historyProvider.records.first;
        final latestScore = latestRecord.overallScore;
        final hasHistory = historyProvider.records.length > 1;
        
        int diff = 0;
        if (hasHistory) {
          diff = latestScore - historyProvider.records[1].overallScore;
        }

        return DSCard(
          width: double.infinity,
          variant: DSCardVariant.elevated,
          padding: const EdgeInsets.all(AppTheme.space32),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, color: AppTheme.primaryColor, size: 16),
                  const SizedBox(width: AppTheme.space8),
                  Text(
                    "SKIN SCORE",
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.primaryColor,
                          letterSpacing: 2.0,
                          fontSize: 12,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space24),
              DSProgressCircle(
                value: latestScore / 100.0,
                size: 160,
                strokeWidth: 12,
                centerText: "$latestScore",
                centerSubText: "/100",
                color: AppTheme.primary,
                backgroundColor: AppTheme.surfaceHighlight,
              ),
              const SizedBox(height: AppTheme.space24),
              if (hasHistory)
                if (diff != 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12, vertical: AppTheme.space4),
                    decoration: BoxDecoration(
                      color: diff > 0 ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.warning.withValues(alpha: 0.1),
                      borderRadius: AppTheme.borderRadiusPill,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          diff > 0 ? Icons.trending_up : Icons.trending_down,
                          color: diff > 0 ? AppTheme.success : AppTheme.warning,
                          size: 16,
                        ),
                        const SizedBox(width: AppTheme.space4),
                        Text(
                          "${diff.abs()} points ${diff > 0 ? 'higher' : 'lower'} than last time",
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: diff > 0 ? AppTheme.success : AppTheme.warning,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12, vertical: AppTheme.space4),
                    decoration: BoxDecoration(
                      color: AppTheme.info.withValues(alpha: 0.1),
                      borderRadius: AppTheme.borderRadiusPill,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.trending_flat,
                          color: AppTheme.info,
                          size: 16,
                        ),
                        const SizedBox(width: AppTheme.space4),
                        Text(
                          "No change from last time",
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.info,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  )
              else
                Text(
                  "Great start on your journey!",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDiscoverSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Discover", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppTheme.space16),
        GridView.count(
          padding: EdgeInsets.zero,
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppTheme.space16,
          crossAxisSpacing: AppTheme.space16,
          childAspectRatio: 1.1,
          children: [
            _buildFeatureCard(
              context,
              "Analyze",
              "Scan your skin",
              Icons.document_scanner_outlined,
              AppTheme.primary,
              () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalysisScreen())),
            ),
            _buildFeatureCard(
              context,
              "Routine",
              "Your AM/PM plan",
              Icons.spa_outlined,
              AppTheme.secondary,
              () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RoutineScreen())),
            ),
            _buildFeatureCard(
              context,
              "Analytics",
              "Score History",
              Icons.history,
              AppTheme.secondary,
              () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen())),
            ),
            _buildFeatureCard(
              context,
              "Consult",
              "Talk to experts",
              Icons.medical_services_outlined,
              AppTheme.info,
              () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DoctorsScreen())),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCard(BuildContext context, String title, String subtitle, IconData icon, Color accent, VoidCallback onTap) {
    return DSCard(
      variant: DSCardVariant.base,
      padding: const EdgeInsets.all(AppTheme.space16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: AppTheme.borderRadiusMedium,
            ),
            child: Icon(icon, color: accent, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppTheme.space4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTipSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Daily Insight", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppTheme.space16),
        DSCard(
          width: double.infinity,
          variant: DSCardVariant.outline,
          padding: const EdgeInsets.all(AppTheme.space20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHighlight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lightbulb_outline, color: AppTheme.primaryLight, size: 20),
              ),
              const SizedBox(width: AppTheme.space16),
              Expanded(
                child: _isFetchingTip
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: SkeletonPulse(),
                      )
                    : Text(
                        _dailyTip,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SkeletonPulse extends StatefulWidget {
  const SkeletonPulse({super.key});

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(color: AppTheme.surfaceHighlight, borderRadius: BorderRadius.circular(6)),
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: 120,
            decoration: BoxDecoration(color: AppTheme.surfaceHighlight, borderRadius: BorderRadius.circular(6)),
          ),
        ],
      ),
    );
  }
}
