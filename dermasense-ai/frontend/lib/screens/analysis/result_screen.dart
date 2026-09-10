import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ds/ds_card.dart';
import '../../widgets/ds/ds_progress.dart';

class ResultScreen extends StatefulWidget {
  final Map<String, dynamic>? scanResult;
  final Uint8List? originalImage;

  const ResultScreen({super.key, this.scanResult, this.originalImage});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late final PageController _heatmapPageController;
  late final ScrollController _chipsScrollController;
  int _currentHeatmapIndex = 0;
  String? _activeRealKey; // Only the selected biomarker displays real camera image
  final Map<int, GlobalKey> _chipKeyMap = {};

  // Metadata for each biomarker: Label, Icon, Anatomical Zone, and Accent Color
  static const Map<String, _BiomarkerMeta> _biomarkerMeta = {
    'acne_severity': _BiomarkerMeta(
      label: 'Active Acne & Breakouts',
      icon: Icons.warning_amber_rounded,
      zone: 'T-Zone & Cheeks',
      color: AppTheme.error,
      clinicalDesc: 'Inflammatory papules & erythematous lesion cores',
    ),
    'redness': _BiomarkerMeta(
      label: 'Redness & Erythema',
      icon: Icons.flare_rounded,
      zone: 'Malar Cheeks & Nose',
      color: Color(0xFFFF5252),
      clinicalDesc: 'Micro-capillary dilation & localized irritation',
    ),
    'blemishes': _BiomarkerMeta(
      label: 'Blemishes & Imperfections',
      icon: Icons.adjust_rounded,
      zone: 'Full Facial Canvas',
      color: AppTheme.warning,
      clinicalDesc: 'High-contrast surface lesions & textural spots',
    ),
    'pigment': _BiomarkerMeta(
      label: 'Pigmentation & Melanin',
      icon: Icons.blur_circular_rounded,
      zone: 'Cheeks & Forehead',
      color: Color(0xFFE5A93B),
      clinicalDesc: 'Localized hyperpigmentation & melanin clustering',
    ),
    'sun_damage': _BiomarkerMeta(
      label: 'Sun Damage & UV Spots',
      icon: Icons.wb_sunny_rounded,
      zone: 'Sun-Exposed Zones',
      color: Colors.amber,
      clinicalDesc: 'Sub-surface actinic photo-damage & lentigines',
    ),
    'wrinkles': _BiomarkerMeta(
      label: 'Wrinkles & Rhytides',
      icon: Icons.waves_rounded,
      zone: 'Forehead & Periorbital',
      color: Color(0xFFBA68C8),
      clinicalDesc: 'Directional creases along relaxed skin tension lines',
    ),
    'dark_circles': _BiomarkerMeta(
      label: 'Dark Circles',
      icon: Icons.remove_red_eye_outlined,
      zone: 'Infraorbital / Under-Eye',
      color: Color(0xFF9B51E0),
      clinicalDesc: 'Periorbital melanin & vascular shadow pooling',
    ),
    'eye_bags': _BiomarkerMeta(
      label: 'Eye Bags & Puffiness',
      icon: Icons.visibility_rounded,
      zone: 'Lower Eyelid Margin',
      color: Color(0xFF7E57C2),
      clinicalDesc: 'Fluid accumulation & orbital fat contour protrusion',
    ),
    'firmness': _BiomarkerMeta(
      label: 'Skin Firmness & Tension',
      icon: Icons.compress_rounded,
      zone: 'Jawline & Jowl Contour',
      color: Color(0xFF26A69A),
      clinicalDesc: 'Structural tissue descent & dermal laxity index',
    ),
    'pore_dilation': _BiomarkerMeta(
      label: 'Dilated & Enlarged Pores',
      icon: Icons.filter_center_focus_rounded,
      zone: 'Nose & Medial Cheeks',
      color: Color(0xFFFF8A65),
      clinicalDesc: 'Noticeably enlarged follicular ostia & sebum congestion',
    ),
    'pores': _BiomarkerMeta(
      label: 'Follicular Pore Density',
      icon: Icons.grain_rounded,
      zone: 'Central Facial Grid',
      color: AppTheme.primaryLight,
      clinicalDesc: 'Overall follicular opening distribution & visibility',
    ),
    'texture': _BiomarkerMeta(
      label: 'Surface Micro-Roughness',
      icon: Icons.texture_rounded,
      zone: 'Lateral Cheeks',
      color: AppTheme.secondaryLight,
      clinicalDesc: 'Keratinization uniformity & micro-relief smoothness',
    ),
    'oiliness': _BiomarkerMeta(
      label: 'Oiliness & Sebum Shine',
      icon: Icons.water_drop_rounded,
      zone: 'Sebaceous T-Zone',
      color: Color(0xFFFFB74D),
      clinicalDesc: 'Specular highlight reflectance & lipid accumulation',
    ),
    'hydration': _BiomarkerMeta(
      label: 'Skin Hydration Level',
      icon: Icons.opacity_rounded,
      zone: 'Stratum Corneum',
      color: AppTheme.info,
      clinicalDesc: 'Moisture barrier plumpness & diffuse radiance',
    ),
    'barrier_health': _BiomarkerMeta(
      label: 'Barrier Resilience',
      icon: Icons.shield_outlined,
      zone: 'Epidermal Shield',
      color: Color(0xFFFF7043),
      clinicalDesc: 'Acid mantle integrity & sub-clinical micro-flaking',
    ),
    'tone_evenness': _BiomarkerMeta(
      label: 'Complexion Uniformity (ITA°)',
      icon: Icons.palette_outlined,
      zone: 'Overall Complexion',
      color: Color(0xFF4FC3F7),
      clinicalDesc: 'Chromaticity dispersion across anatomical boundaries',
    ),
    'radiance': _BiomarkerMeta(
      label: 'Radiance & Vital Glow',
      icon: Icons.auto_awesome_rounded,
      zone: 'Diffuse Light Scatter',
      color: Color(0xFF66BB6A),
      clinicalDesc: 'Healthy skin luminosity vs muddy/sallow dullness',
    ),
  };

  @override
  void initState() {
    super.initState();
    _heatmapPageController = PageController(viewportFraction: 0.85);
    _chipsScrollController = ScrollController();
  }

  @override
  void dispose() {
    _heatmapPageController.dispose();
    _chipsScrollController.dispose();
    super.dispose();
  }

  void _scrollChipToCenter(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_chipsScrollController.hasClients) return;
      final chipKey = _chipKeyMap[index];
      final keyContext = chipKey?.currentContext;
      if (keyContext != null) {
        final box = keyContext.findRenderObject() as RenderBox?;
        final scrollBox = _chipsScrollController.position.context.notificationContext?.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize && scrollBox != null && scrollBox.hasSize) {
          final position = box.localToGlobal(Offset.zero, ancestor: scrollBox);
          final currentOffset = _chipsScrollController.offset;
          final targetOffset = currentOffset + position.dx - (scrollBox.size.width / 2) + (box.size.width / 2);
          _chipsScrollController.animateTo(
            targetOffset.clamp(0.0, _chipsScrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
          return;
        }
      }
      final screenWidth = MediaQuery.of(context).size.width;
      const approxChipWidth = 140.0;
      final target = (index * approxChipWidth) - (screenWidth / 2) + (approxChipWidth / 2);
      _chipsScrollController.animateTo(
        target.clamp(0.0, _chipsScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _onHeatmapSwiped(int index, List<String> keys) {
    setState(() {
      _currentHeatmapIndex = index;
      _activeRealKey = null; // Revert back to normal heatmap when tab switched
    });
    _scrollChipToCenter(index);
  }

  void _onChipTapped(int index) {
    setState(() {
      _currentHeatmapIndex = index;
      _activeRealKey = null; // Revert back to normal heatmap when tab switched
    });
    _heatmapPageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
    _scrollChipToCenter(index);
  }

  @override
  Widget build(BuildContext context) {
    final scores = widget.scanResult?['scores'] as Map<String, dynamic>? ?? {};
    final overlays = widget.scanResult?['overlays'] as Map<String, dynamic>? ?? {};
    final overlayKeys = overlays.keys.toList();

    // Weighted overall skin score calculation
    double overallScore = 0.85;
    if (scores.isNotEmpty) {
      final weights = <String, double>{
        'acne_severity': 1.6,
        'blemishes': 1.3,
        'redness': 1.3,
        'barrier_health': 1.4,
        'wrinkles': 1.2,
        'sun_damage': 1.1,
        'dark_circles': 0.9,
        'eye_bags': 0.8,
        'pore_dilation': 0.9,
        'pores': 0.8,
        'texture': 0.9,
        'tone_evenness': 1.0,
        'oiliness': 0.8,
        'pigment': 1.1,
        'firmness': 1.0,
        'radiance': 0.9,
        'hydration': 1.0,
      };

      double totalWeight = 0.0;
      double weightedPenalty = 0.0;

      for (var entry in scores.entries) {
        double val = (entry.value as num).toDouble();
        double penalty = (entry.key == 'hydration') ? (1.0 - val) : val;
        double w = weights[entry.key] ?? 1.0;
        weightedPenalty += penalty * w;
        totalWeight += w;
      }

      if (totalWeight > 0) {
        overallScore = (1.0 - (weightedPenalty / totalWeight)).clamp(0.10, 0.99);
      }
    }

    final scoreInt = (overallScore * 100).round();
    String healthStatus;
    Color statusColor;

    if (scoreInt >= 85) {
      healthStatus = "Optimal Health & Glow";
      statusColor = AppTheme.success;
    } else if (scoreInt >= 70) {
      healthStatus = "Good / Minor Attention";
      statusColor = AppTheme.info;
    } else if (scoreInt >= 55) {
      healthStatus = "Moderate Concerns Detected";
      statusColor = AppTheme.warning;
    } else {
      healthStatus = "Clinical Care Recommended";
      statusColor = AppTheme.error;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Dermatological Report"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Score Header Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
              child: DSCard(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.space24, horizontal: AppTheme.space16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_user_rounded, size: 20, color: statusColor),
                        const SizedBox(width: 8),
                        Text(
                          "Clinical Skin Health Index",
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space20),
                    DSProgressCircle(
                      value: overallScore,
                      size: 140,
                      strokeWidth: 11,
                      color: statusColor,
                      centerText: "$scoreInt",
                      centerSubText: "/100",
                    ),
                    const SizedBox(height: AppTheme.space16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        healthStatus,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Validated across 17 clinical diagnostic biomarkers",
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.space24),

            // ==========================================
            // TOP-NOTCH SWIPEABLE AI HEATMAP CAROUSEL
            // ==========================================
            if (overlayKeys.isNotEmpty) ...[
              _buildTopNotchHeatmapViewer(
                context: context,
                keys: overlayKeys,
                overlays: overlays,
                scores: scores,
              ),
              const SizedBox(height: AppTheme.space32),
            ],

            // Section 1: Active Concerns & Blemishes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
              child: _buildCategorySection(
                context: context,
                title: "🚨 Active Skin Concerns",
                subtitle: "Inflammatory and localized pigmentation findings",
                metrics: [
                  if (scores.containsKey('acne_severity'))
                    _MetricItem('acne_severity', 'Acne & Active Breakouts', scores['acne_severity'], AppTheme.error, isPositive: false),
                  if (scores.containsKey('redness'))
                    _MetricItem('redness', 'Redness & Erythema', scores['redness'], AppTheme.error, isPositive: false),
                  if (scores.containsKey('blemishes'))
                    _MetricItem('blemishes', 'Blemishes & Lesions', scores['blemishes'], AppTheme.warning, isPositive: false),
                  if (scores.containsKey('pigment'))
                    _MetricItem('pigment', 'Pigmentation & Melanin', scores['pigment'], const Color(0xFFE5A93B), isPositive: false),
                  if (scores.containsKey('sun_damage'))
                    _MetricItem('sun_damage', 'Sun Damage & Actinic Spots', scores['sun_damage'], Colors.amber, isPositive: false),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space24),

            // Section 2: Aging & Structural Tone
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
              child: _buildCategorySection(
                context: context,
                title: "⏳ Aging & Structural Integrity",
                subtitle: "Wrinkles, tension, and peri-orbital contour",
                metrics: [
                  if (scores.containsKey('wrinkles'))
                    _MetricItem('wrinkles', 'Wrinkles & Rhytides', scores['wrinkles'], AppTheme.secondary, isPositive: false),
                  if (scores.containsKey('dark_circles'))
                    _MetricItem('dark_circles', 'Infraorbital Dark Circles', scores['dark_circles'], const Color(0xFF9B51E0), isPositive: false),
                  if (scores.containsKey('eye_bags'))
                    _MetricItem('eye_bags', 'Eye Bags & Puffiness', scores['eye_bags'], const Color(0xFFBB6BD9), isPositive: false),
                  if (scores.containsKey('firmness'))
                    _MetricItem('firmness', 'Skin Laxity / Descent', scores['firmness'], const Color(0xFF6FCF97), isPositive: false),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space24),

            // Section 3: Surface & Barrier Quality
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
              child: _buildCategorySection(
                context: context,
                title: "✨ Surface & Barrier Health",
                subtitle: "Sebum, hydration, micro-relief and tone uniformity",
                metrics: [
                  if (scores.containsKey('hydration'))
                    _MetricItem('hydration', 'Skin Hydration Level', scores['hydration'], AppTheme.info, isPositive: true),
                  if (scores.containsKey('barrier_health'))
                    _MetricItem('barrier_health', 'Barrier Compromise', scores['barrier_health'], const Color(0xFFF2994A), isPositive: false),
                  if (scores.containsKey('pore_dilation'))
                    _MetricItem('pore_dilation', 'Enlarged Pore Openings', scores['pore_dilation'], AppTheme.primaryLight, isPositive: false),
                  if (scores.containsKey('pores'))
                    _MetricItem('pores', 'Overall Pore Density', scores['pores'], AppTheme.primaryLight, isPositive: false),
                  if (scores.containsKey('texture'))
                    _MetricItem('texture', 'Surface Roughness', scores['texture'], AppTheme.secondaryLight, isPositive: false),
                  if (scores.containsKey('oiliness'))
                    _MetricItem('oiliness', 'Sebum & Shine Level', scores['oiliness'], AppTheme.warning, isPositive: false),
                  if (scores.containsKey('tone_evenness'))
                    _MetricItem('tone_evenness', 'Tone Unevenness (ITA°)', scores['tone_evenness'], const Color(0xFF56CCF2), isPositive: false),
                  if (scores.containsKey('radiance'))
                    _MetricItem('radiance', 'Skin Dullness Index', scores['radiance'], const Color(0xFF27AE60), isPositive: false),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space32),

            // Clinical Actives & Recommendations Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
              child: _buildRecommendationsCard(context, scores),
            ),
            const SizedBox(height: AppTheme.space40),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TOP NOTCH AI HEATMAP CAROUSEL WIDGET
  // ==========================================
  Widget _buildTopNotchHeatmapViewer({
    required BuildContext context,
    required List<String> keys,
    required Map<String, dynamic> overlays,
    required Map<String, dynamic> scores,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with Swipe Hint & Live Counter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 18),
                      const SizedBox(width: 6),
                      Text("Explainable AI Heatmap", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 19)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text("Swipe left / right on map to explore", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHighlight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  "${(_currentHeatmapIndex + 1).toString().padLeft(2, '0')} / ${keys.length.toString().padLeft(2, '0')}",
                  style: const TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Synchronized Horizontal Biomarker Selector Tabs
        SizedBox(
          height: 42,
          child: SingleChildScrollView(
            controller: _chipsScrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
            child: Row(
              children: List.generate(keys.length, (index) {
                final key = keys[index];
                final meta = _biomarkerMeta[key];
                final isSelected = index == _currentHeatmapIndex;
                final color = meta?.color ?? AppTheme.primary;
                final chipKey = _chipKeyMap.putIfAbsent(index, () => GlobalKey());

                return GestureDetector(
                  key: chipKey,
                  onTap: () => _onChipTapped(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withValues(alpha: 0.22) : AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : Colors.white.withValues(alpha: 0.08),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          meta?.icon ?? Icons.circle,
                          size: 15,
                          color: isSelected ? color : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          meta?.label ?? key,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ==========================================
        // SWIPEABLE PAGEVIEW CAROUSEL
        // ==========================================
        SizedBox(
          height: 385,
          child: PageView.builder(
            controller: _heatmapPageController,
            onPageChanged: (index) => _onHeatmapSwiped(index, keys),
            itemCount: keys.length,
            itemBuilder: (context, index) {
              final key = keys[index];
              final meta = _biomarkerMeta[key];
              final accentColor = meta?.color ?? AppTheme.primary;
              final scoreVal = (scores[key] as num?)?.toDouble() ?? 0.0;
              final isHydration = key == 'hydration';
              final severityPercent = (scoreVal * 100).round();

              String severityBadgeText;
              Color badgeColor;
              if (isHydration) {
                if (severityPercent >= 70) {
                  severityBadgeText = "Optimal Hydration";
                  badgeColor = AppTheme.success;
                } else if (severityPercent >= 45) {
                  severityBadgeText = "Normal Moisture";
                  badgeColor = AppTheme.info;
                } else {
                  severityBadgeText = "Dehydrated";
                  badgeColor = AppTheme.warning;
                }
              } else {
                if (severityPercent <= 20) {
                  severityBadgeText = "Minimal / Clear";
                  badgeColor = AppTheme.success;
                } else if (severityPercent <= 50) {
                  severityBadgeText = "Mild Severity";
                  badgeColor = AppTheme.warning;
                } else {
                  severityBadgeText = "Elevated Severity";
                  badgeColor = AppTheme.error;
                }
              }

              final overlayBase64 = overlays[key] as String?;
              final isShowingReal = _activeRealKey == key;

              return AnimatedPadding(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceBase,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.12),
                        blurRadius: 18,
                        spreadRadius: 1,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge - 1.5),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // 1. Base Image: Either Heatmap or Natural Photo based on toggle
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 250),
                          crossFadeState: isShowingReal || overlayBase64 == null
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          firstChild: overlayBase64 != null
                              ? Image.memory(
                                  base64Decode(overlayBase64.split(',').last),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                )
                              : const SizedBox.shrink(),
                          secondChild: widget.originalImage != null
                              ? Image.memory(
                                  widget.originalImage!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                )
                              : Container(
                                  color: Colors.black26,
                                  child: const Center(
                                    child: Text("No camera image", style: TextStyle(color: Colors.white54)),
                                  ),
                                ),
                        ),

                        // 2. Top Floating Glassmorphic HUD Bar
                        Positioned(
                          top: 12,
                          left: 12,
                          right: 12,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Biomarker Icon & Tag
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(meta?.icon ?? Icons.biotech, size: 15, color: accentColor),
                                    const SizedBox(width: 6),
                                    Text(
                                      meta?.zone ?? "Target Area",
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),

                              // Quick Compare Button ("Tap or Hold to View Real Image")
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  setState(() {
                                    if (_activeRealKey == key) {
                                      _activeRealKey = null; // Revert back to normal
                                    } else {
                                      _activeRealKey = key; // Only this image becomes real!
                                    }
                                  });
                                },
                                onLongPressStart: (_) {
                                  setState(() => _activeRealKey = key);
                                },
                                onLongPressEnd: (_) {
                                  setState(() => _activeRealKey = null); // Revert on release
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isShowingReal
                                        ? AppTheme.primary
                                        : Colors.black.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isShowingReal ? AppTheme.primaryLight : Colors.white24,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isShowingReal ? Icons.visibility : Icons.compare_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        isShowingReal ? "Natural Photo" : "Hold for Real",
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 4. Bottom Clinical Intelligence Card
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.95),
                                  Colors.black.withValues(alpha: 0.75),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        meta?.label ?? key,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: badgeColor.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                                      ),
                                      child: Text(
                                        "$severityPercent% • $severityBadgeText",
                                        style: TextStyle(
                                          color: badgeColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  meta?.clinicalDesc ?? "Quantitative dermatological computer-vision finding.",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 11.5,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),

        // Carousel Dot Indicator & Chevron Navigation Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left Chevron
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 28),
                color: _currentHeatmapIndex > 0 ? AppTheme.primaryLight : AppTheme.textDisabled,
                onPressed: _currentHeatmapIndex > 0
                    ? () => _onChipTapped(_currentHeatmapIndex - 1)
                    : null,
              ),

              // Animated Indicator Dots
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(keys.length, (index) {
                        final isSelected = index == _currentHeatmapIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          height: 6,
                          width: isSelected ? 22 : 6,
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primary : AppTheme.surfaceHighlight,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),

              // Right Chevron
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 28),
                color: _currentHeatmapIndex < keys.length - 1 ? AppTheme.primaryLight : AppTheme.textDisabled,
                onPressed: _currentHeatmapIndex < keys.length - 1
                    ? () => _onChipTapped(_currentHeatmapIndex + 1)
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection({
    required BuildContext context,
    required String title,
    required String subtitle,
    required List<_MetricItem> metrics,
  }) {
    if (metrics.isEmpty) return const SizedBox.shrink();

    return DSCard(
      padding: const EdgeInsets.all(AppTheme.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: AppTheme.space16),
          ...metrics.map((item) {
            double displayVal = item.value.clamp(0.0, 1.0);
            int percent = (displayVal * 100).round();
            return Padding(
              padding: const EdgeInsets.only(bottom: 14.0),
              child: DSProgressBar(
                label: item.label,
                value: displayVal,
                valueText: item.isPositive ? "$percent% Optimal" : "$percent% Severity",
                color: item.color,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard(BuildContext context, Map<String, dynamic> scores) {
    // Determine top 3 concerns
    final concerns = <MapEntry<String, double>>[];
    for (var entry in scores.entries) {
      if (entry.key == 'hydration') continue;
      concerns.add(MapEntry(entry.key, (entry.value as num).toDouble()));
    }
    concerns.sort((a, b) => b.value.compareTo(a.value));

    final recommendations = <String, List<String>>{
      'acne_severity': ['2% Salicylic Acid (BHA)', 'Niacinamide 4%', 'Benzoyl Peroxide spot treatment'],
      'redness': ['Azelaic Acid 10%', 'Centella Asiatica (Cica)', 'Green Tea EGCG'],
      'barrier_health': ['Ceramide NP Complex', 'Panthenol (Vitamin B5)', 'Oat Beta-Glucan'],
      'wrinkles': ['Encapsulated Retinol 0.2%', 'Copper Tripeptide-1', 'Matrixyl 3000'],
      'dark_circles': ['Caffeine 5% Eye Serum', 'Vitamin K Oxide', 'Haloxyl Peptides'],
      'eye_bags': ['Cooling Caffeine Gel', 'Peptide Eye Complex', 'Lymphatic Drainage Massage'],
      'pores': ['Niacinamide 10% + Zinc PCA', 'Gentle Salicylic Cleanser', 'Clay Pore Mask'],
      'pore_dilation': ['Zinc PCA 1%', 'Mandelic Acid 10%', 'Lightweight Mattifying Gel'],
      'sun_damage': ['Broad Spectrum SPF 50+ Daily', 'Vitamin C 15% (L-Ascorbic Acid)', 'Ferulic Acid'],
      'pigment': ['Tranexamic Acid 3%', 'Alpha Arbutin 2%', 'Niacinamide 5%'],
      'oiliness': ['Oil-Free Gel Hydrator', 'Zinc PCA Sebum Regulator', 'BHA Gentle Toner'],
      'texture': ['Lactic Acid 5% Exfoliant', 'PHA Gentle Toner', 'Squalane Moisture Balance'],
      'radiance': ['Vitamin C 10%', 'Glow Peptides', 'Hydrating Hyaluronic Mist'],
    };

    final topConcerns = concerns.take(3).toList();

    return DSCard(
      padding: const EdgeInsets.all(AppTheme.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science_rounded, color: AppTheme.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                "Clinical Active Recommendations",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Personalized dermatological actives targeted to your highest concern markers:",
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: AppTheme.space16),
          ...topConcerns.map((c) {
            final actives = recommendations[c.key] ?? ['Daily Gentle Cleanser', 'Broad Spectrum SPF', 'Hydrating Moisturizer'];
            final featureMeta = _biomarkerMeta[c.key];
            final featureLabel = featureMeta?.label ?? c.key;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceHighlight,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(featureLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                      Text("${(c.value * 100).round()}% Severity", style: TextStyle(fontSize: 11, color: AppTheme.primaryLight, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: actives.map((active) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                        ),
                        child: Text(active, style: const TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontWeight: FontWeight.w600)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _BiomarkerMeta {
  final String label;
  final IconData icon;
  final String zone;
  final Color color;
  final String clinicalDesc;

  const _BiomarkerMeta({
    required this.label,
    required this.icon,
    required this.zone,
    required this.color,
    required this.clinicalDesc,
  });
}

class _MetricItem {
  final String key;
  final String label;
  final double value;
  final Color color;
  final bool isPositive;

  _MetricItem(this.key, this.label, dynamic val, this.color, {this.isPositive = false})
      : value = (val as num?)?.toDouble() ?? 0.0;
}
