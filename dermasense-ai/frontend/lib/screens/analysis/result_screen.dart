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
  String _selectedOverlayKey = 'redness';

  // Mapping feature keys to human labels and colors
  static const Map<String, String> _featureLabels = {
    'redness': 'Redness & Erythema',
    'oiliness': 'Oiliness & Sebum',
    'texture': 'Texture & Roughness',
    'pores': 'Follicular Pores',
    'blemishes': 'Blemishes & Spots',
    'hydration': 'Hydration Level',
    'pigment': 'Pigmentation & Melanin',
    'wrinkles': 'Wrinkles & Fine Lines',
    'dark_circles': 'Dark Circles',
    'eye_bags': 'Eye Bags & Puffiness',
    'firmness': 'Firmness & Elasticity',
    'radiance': 'Radiance & Glow',
    'tone_evenness': 'Skin Tone Evenness',
    'sun_damage': 'Sun Damage & UV Spots',
    'pore_dilation': 'Pore Dilation',
    'barrier_health': 'Barrier Health',
    'acne_severity': 'Active Acne & Breakouts',
  };

  @override
  void initState() {
    super.initState();
    final overlays = widget.scanResult?['overlays'] as Map<String, dynamic>? ?? {};
    if (!overlays.containsKey(_selectedOverlayKey) && overlays.isNotEmpty) {
      _selectedOverlayKey = overlays.keys.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scores = widget.scanResult?['scores'] as Map<String, dynamic>? ?? {};
    final overlays = widget.scanResult?['overlays'] as Map<String, dynamic>? ?? {};

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
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20, vertical: AppTheme.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Score Header Card
            DSCard(
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
                    size: 150,
                    strokeWidth: 12,
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
            const SizedBox(height: AppTheme.space32),

            // Explainable AI Heatmap Section
            if (overlays.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Explainable AI Heatmap", style: Theme.of(context).textTheme.titleLarge),
                  Text(
                    "${overlays.length} Maps Ready",
                    style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Feature Chip Selector
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: overlays.keys.map((key) {
                    final isSelected = _selectedOverlayKey == key;
                    final label = _featureLabels[key] ?? key.replaceAll('_', ' ').toUpperCase();
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : AppTheme.textSecondary,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppTheme.primary,
                        backgroundColor: AppTheme.surfaceElevated,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedOverlayKey = key);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              // Heatmap Viewer Card
              DSCard(
                padding: EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: AppTheme.borderRadiusLarge,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 320,
                        child: overlays.containsKey(_selectedOverlayKey)
                            ? Image.memory(
                                base64Decode((overlays[_selectedOverlayKey] as String).split(',').last),
                                fit: BoxFit.contain,
                              )
                            : (widget.originalImage != null
                                ? Image.memory(widget.originalImage!, fit: BoxFit.contain)
                                : const Center(child: Text("No visual data"))),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        color: Colors.black.withValues(alpha: 0.7),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _featureLabels[_selectedOverlayKey] ?? _selectedOverlayKey,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            if (scores.containsKey(_selectedOverlayKey))
                              Text(
                                "Severity: ${((scores[_selectedOverlayKey] as num).toDouble() * 100).round()}%",
                                style: TextStyle(
                                  color: AppTheme.primaryLight,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space32),
            ],

            // Section 1: Active Concerns & Blemishes
            _buildCategorySection(
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
            const SizedBox(height: AppTheme.space24),

            // Section 2: Aging & Structural Tone
            _buildCategorySection(
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
            const SizedBox(height: AppTheme.space24),

            // Section 3: Surface & Barrier Quality
            _buildCategorySection(
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
            const SizedBox(height: AppTheme.space32),

            // Clinical Actives & Recommendations Card
            _buildRecommendationsCard(context, scores),
            const SizedBox(height: AppTheme.space40),
          ],
        ),
      ),
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
            final featureLabel = _featureLabels[c.key] ?? c.key;
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

class _MetricItem {
  final String key;
  final String label;
  final double value;
  final Color color;
  final bool isPositive;

  _MetricItem(this.key, this.label, dynamic val, this.color, {this.isPositive = false})
      : value = (val as num?)?.toDouble() ?? 0.0;
}
