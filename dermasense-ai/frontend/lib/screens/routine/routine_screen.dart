import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/routine_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/skin_profile_provider.dart';
import '../analysis/analysis_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ds/ds_card.dart';
import '../../widgets/ds/ds_button.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureRoutineLoaded();
    });
  }

  void _ensureRoutineLoaded({bool force = false}) {
    if (!mounted) return;
    final routineProvider = context.read<RoutineProvider>();
    final historyProvider = context.read<HistoryProvider>();
    final profileProvider = context.read<SkinProfileProvider>();

    if (force || routineProvider.routineData == null) {
      routineProvider.generateRoutine(
        historyProvider,
        profileProvider,
        force: force,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final routineProvider = context.watch<RoutineProvider>();
    final historyProvider = context.watch<HistoryProvider>();
    final hasHistory = historyProvider.records.isNotEmpty;

    final routineData = routineProvider.routineData;
    final isLoading = routineProvider.isLoading;
    final error = routineProvider.error;
    final basisDesc = routineProvider.basisDescription;

    // Trigger routine generation if still null and not loading
    if (routineData == null && !isLoading && error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ensureRoutineLoaded();
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Personalized Routine"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Regenerate Routine",
            onPressed: () => _ensureRoutineLoaded(force: true),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: AppTheme.primary),
                    const SizedBox(height: AppTheme.space16),
                    Text(
                      "Formulating clinical routine...",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              )
            : error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.space32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppTheme.error, size: 48),
                          const SizedBox(height: AppTheme.space16),
                          Text(error,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppTheme.error)),
                          const SizedBox(height: AppTheme.space16),
                          DSButton(
                            label: "Regenerate",
                            onPressed: () => _ensureRoutineLoaded(force: true),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space20,
                      vertical: AppTheme.space16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Basis / Provenance Banner Card
                        if (basisDesc != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              border: Border.all(
                                color: AppTheme.primary.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome,
                                    color: AppTheme.primaryLight,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "CLINICAL AI REGIMEN",
                                        style: TextStyle(
                                          color: AppTheme.primaryLight,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        basisDesc,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.space16),
                        ],

                        // Prompt to take a fresh scan if user has no history
                        if (!hasHistory) ...[
                          DSCard(
                            variant: DSCardVariant.elevated,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AnalysisScreen(),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: AppTheme.primary,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.space16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Want Biomarker Precision?",
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: AppTheme.space4),
                                      Text(
                                        "Take a skin scan to fine-tune each step to exact diagnostics.",
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppTheme.textSecondary,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.space24),
                        ],

                        if (routineData != null)
                          ...AnimationConfiguration.toStaggeredList(
                            duration: const Duration(milliseconds: 500),
                            childAnimationBuilder: (widget) => SlideAnimation(
                              verticalOffset: 30.0,
                              child: FadeInAnimation(child: widget),
                            ),
                            children: [
                              _buildRoutineSection(
                                context,
                                "Morning Regimen",
                                "AM",
                                Icons.wb_sunny_rounded,
                                const Color(0xFFF2994A),
                                routineData['morning'] as List<dynamic>?,
                              ),
                              const SizedBox(height: AppTheme.space32),
                              _buildRoutineSection(
                                context,
                                "Evening Regimen",
                                "PM",
                                Icons.nightlight_round,
                                const Color(0xFF9B51E0),
                                routineData['evening'] as List<dynamic>?,
                              ),
                            ],
                          )
                        else
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                children: [
                                  const CircularProgressIndicator(color: AppTheme.primary),
                                  const SizedBox(height: 16),
                                  const Text("Generating your personalized skincare plan..."),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: AppTheme.space40),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildRoutineSection(
    BuildContext context,
    String title,
    String badge,
    IconData icon,
    Color accent,
    List<dynamic>? steps,
  ) {
    if (steps == null || steps.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: AppTheme.space12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Text(
                "${steps.length} STEPS",
                style: TextStyle(
                  color: accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: steps.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppTheme.space12),
          itemBuilder: (context, index) {
            final step = steps[index] as Map<String, dynamic>;
            return _buildStepCard(context, step, accent);
          },
        ),
      ],
    );
  }

  Widget _buildStepCard(BuildContext context, Map<String, dynamic> step, Color accent) {
    final stepNum = step['step'] ?? '-';
    final category = (step['category'] ?? 'Step').toString();
    final product = step['product'] ?? '';
    final why = step['why'] ?? '';
    final how = step['how'] ?? '';
    final time = step['time'] ?? '';

    return DSCard(
      variant: DSCardVariant.base,
      padding: const EdgeInsets.all(AppTheme.space16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number circle
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                "$stepNum",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: accent,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHighlight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        category.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryLight,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    if (time.isNotEmpty)
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  product,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (why.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded,
                          size: 14, color: AppTheme.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          why,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (how.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.touch_app_outlined,
                          size: 14, color: AppTheme.secondaryLight),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          how,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
