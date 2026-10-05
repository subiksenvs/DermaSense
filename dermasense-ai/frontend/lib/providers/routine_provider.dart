import 'package:flutter/material.dart';
import 'skin_profile_provider.dart';
import 'history_provider.dart';

class RoutineProvider with ChangeNotifier {
  Map<String, dynamic>? _routineData;
  bool _isLoading = false;
  String? _error;
  String? _lastGeneratedForRecordId;
  String? _basisDescription;

  Map<String, dynamic>? get routineData => _routineData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get basisDescription => _basisDescription;

  /// Generates a personalized skincare routine based on latest scan or skin profile.
  void generateRoutine(
    HistoryProvider historyProvider,
    SkinProfileProvider profileProvider, {
    bool force = false,
  }) {
    final hasHistory = historyProvider.records.isNotEmpty;
    final latestRecordId = hasHistory ? historyProvider.records.first.id : 'profile_baseline';

    if (!force && _routineData != null && _lastGeneratedForRecordId == latestRecordId) {
      return;
    }

    final rawSkinType = profileProvider.profile.skinType;
    final skinType = (rawSkinType != null && rawSkinType.trim().isNotEmpty)
        ? rawSkinType.trim().toLowerCase()
        : 'combination';

    final concerns = profileProvider.profile.skinConcerns
        .map((c) => c.trim().toLowerCase())
        .where((c) => c.isNotEmpty)
        .toList();

    List<String> activeIssues = [];

    if (hasHistory) {
      final latestRecord = historyProvider.records.first;
      _basisDescription = "Based on Clinical Scan from ${_formatDate(latestRecord.date)}";

      final conditions = <String, double>{};
      if (latestRecord.conditions.isNotEmpty) {
        conditions.addAll(latestRecord.conditions);
      }
      if (latestRecord.metrics.isNotEmpty) {
        latestRecord.metrics.forEach((k, v) {
          final scaled = v <= 1.0 ? v * 100.0 : v;
          if (!conditions.containsKey(k) || conditions[k]! < scaled) {
            conditions[k] = scaled;
          }
        });
      }

      final sorted = conditions.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      activeIssues = sorted
          .where((e) => e.value > 15.0)
          .map((e) => e.key.toLowerCase())
          .toList();

      // Add profile concerns if activeIssues has few items
      for (final c in concerns) {
        if (!activeIssues.contains(c)) {
          activeIssues.add(c);
        }
      }
    } else {
      _basisDescription = "Personalized for ${skinType.toUpperCase()} skin profile";
      activeIssues = List.from(concerns);
    }

    _isLoading = false;
    _routineData = _buildRuleBasedRoutine(skinType, concerns, activeIssues);
    _lastGeneratedForRecordId = latestRecordId;
    _error = null;
    notifyListeners();
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return "${d.day} ${months[d.month - 1]}";
  }

  Map<String, dynamic> _buildRuleBasedRoutine(
    String skinType,
    List<String> concerns,
    List<String> issues,
  ) {
    List<Map<String, dynamic>> morning = [];
    List<Map<String, dynamic>> evening = [];

    bool hasIssue(String key) =>
        issues.any((i) => i.contains(key)) || concerns.any((c) => c.contains(key));

    // ==========================================
    // ☀️ MORNING REGIMEN
    // ==========================================
    int amStep = 1;

    // 1. Cleanser
    if (skinType.contains('oily') || skinType.contains('combination') || hasIssue('oiliness')) {
      morning.add({
        "step": amStep++,
        "category": "Cleanser",
        "product": "Purifying Gel Foaming Cleanser (with Zinc / BHA)",
        "why": "Removes overnight sebum without stripping the barrier",
        "how": "Massage onto damp skin for 45-60 seconds, rinse with lukewarm water",
        "time": "Daily AM"
      });
    } else if (skinType.contains('dry') || hasIssue('hydration') || hasIssue('barrier_health')) {
      morning.add({
        "step": amStep++,
        "category": "Cleanser",
        "product": "Hydrating Milk / Gentle Cream Cleanser",
        "why": "Protects delicate skin barrier and replenishes natural lipids",
        "how": "Gently massage onto damp face, rinse gently or wipe with soft towel",
        "time": "Daily AM"
      });
    } else {
      morning.add({
        "step": amStep++,
        "category": "Cleanser",
        "product": "Gentle Balancing Gel Cleanser",
        "why": "Refreshes and clears impurities while balancing skin pH",
        "how": "Lather a pea-sized amount with water and rinse thoroughly",
        "time": "Daily AM"
      });
    }

    // 2. Toner / Essence
    if (hasIssue('redness') || skinType.contains('sensitive') || hasIssue('barrier_health')) {
      morning.add({
        "step": amStep++,
        "category": "Toner",
        "product": "Centella Asiatica (Cica) & Heartleaf Soothing Toner",
        "why": "Instantly calms vascular flush and reduces erythema",
        "how": "Pat 2-3 layers into skin with clean fingertips",
        "time": "Daily AM"
      });
    } else if (hasIssue('pore_dilation') || hasIssue('pores') || hasIssue('oiliness')) {
      morning.add({
        "step": amStep++,
        "category": "Toner",
        "product": "Niacinamide 2% & Witch Hazel Balancing Essence",
        "why": "Regulates pore diameter and controls midday shine",
        "how": "Sweep gently over T-zone with cotton pad or palms",
        "time": "Daily AM"
      });
    } else {
      morning.add({
        "step": amStep++,
        "category": "Toner",
        "product": "Hydrating Multi-Molecular Hyaluronic Essence",
        "why": "Deeply saturates stratum corneum for plumper skin",
        "how": "Press gently into damp skin before serums",
        "time": "Daily AM"
      });
    }

    // 3. Treatment Serum
    if (hasIssue('acne_severity') || hasIssue('acne') || hasIssue('blemishes')) {
      morning.add({
        "step": amStep++,
        "category": "Serum",
        "product": "Salicylic Acid 2% (BHA) + Niacinamide 4% Serum",
        "why": "Penetrates lipid pores to eradicate acne bacteria & clear congestion",
        "how": "Apply 3-4 drops evenly to affected areas",
        "time": "Daily AM"
      });
    } else if (hasIssue('pigment') || hasIssue('sun_damage') || hasIssue('tone_evenness') || hasIssue('radiance')) {
      morning.add({
        "step": amStep++,
        "category": "Antioxidant Serum",
        "product": "Stabilized Vitamin C 15% (L-Ascorbic Acid) + Ferulic Acid",
        "why": "Inhibits tyrosinase, fades melanin hyperpigmentation, and boosts UV defense",
        "how": "Apply 4 drops to dry skin after toning, let absorb 1 minute",
        "time": "Daily AM"
      });
    } else if (hasIssue('wrinkles') || hasIssue('firmness')) {
      morning.add({
        "step": amStep++,
        "category": "Peptide Serum",
        "product": "Multi-Peptide + Copper Peptide 1% Firming Complex",
        "why": "Stimulates collagen synthesis and reinforces dermal elasticity",
        "how": "Gently massage 3-4 drops upward over face and neck",
        "time": "Daily AM"
      });
    } else {
      morning.add({
        "step": amStep++,
        "category": "Antioxidant Serum",
        "product": "Vitamin C 10% Brightening Radiance Booster",
        "why": "Neutralizes environmental oxidative stress for a glowing complexion",
        "how": "Dispense 3-4 drops and pat into face",
        "time": "Daily AM"
      });
    }

    // 4. Eye Care
    if (hasIssue('dark_circles') || hasIssue('eye_bags')) {
      morning.add({
        "step": amStep++,
        "category": "Eye Care",
        "product": "Caffeine 5% + EGCG De-Puffing Eye Contour Cream",
        "why": "Constricts peri-orbital capillaries to diminish morning puffiness and darkness",
        "how": "Tap a micro-dot gently along the orbital bone with ring finger",
        "time": "Daily AM"
      });
    }

    // 5. Daily Moisturizer
    if (skinType.contains('oily') || hasIssue('oiliness')) {
      morning.add({
        "step": amStep++,
        "category": "Moisturizer",
        "product": "Ultra-Light Oil-Free Water Gel (with Zinc PCA)",
        "why": "Hydrates skin without clogging sebaceous follicles",
        "how": "Smooth a nickel-sized amount evenly over face",
        "time": "Daily AM"
      });
    } else if (skinType.contains('dry') || hasIssue('hydration')) {
      morning.add({
        "step": amStep++,
        "category": "Moisturizer",
        "product": "Ceramide NP & Phytosphingosine Barrier Cream",
        "why": "Restores inter-cellular lipids to lock in moisture all day",
        "how": "Warm between fingertips and gently press into skin",
        "time": "Daily AM"
      });
    } else {
      morning.add({
        "step": amStep++,
        "category": "Moisturizer",
        "product": "Lightweight Hydrating Daily Fluid",
        "why": "Maintains optimal barrier homeostasis and all-day comfort",
        "how": "Apply evenly over face and neck",
        "time": "Daily AM"
      });
    }

    // 6. Broad Spectrum Sunscreen (Crucial)
    morning.add({
      "step": amStep++,
      "category": "Sun Protection",
      "product": "Broad Spectrum SPF 50+ PA++++ (Invisible Matte Finish)",
      "why": "Non-negotiable defense against UVA/UVB photo-aging and pigmentation recurrence",
      "how": "Apply 2 finger-lengths generously as the final AM step. Reapply if outdoors",
      "time": "Every Morning"
    });


    // ==========================================
    // 🌙 EVENING REGIMEN
    // ==========================================
    int pmStep = 1;

    // 1. First Cleanse (Double Cleanse)
    evening.add({
      "step": pmStep++,
      "category": "First Cleanse",
      "product": "Nourishing Cleansing Balm / Lipid Oil",
      "why": "Dissolves SPF, airborne pollutants, and stubborn particulate grime",
      "how": "Massage onto dry skin for 60s, emulsify with water, then rinse",
      "time": "Daily PM"
    });

    // 2. Second Cleanse
    if (skinType.contains('oily') || skinType.contains('combination') || hasIssue('acne_severity')) {
      evening.add({
        "step": pmStep++,
        "category": "Second Cleanse",
        "product": "Deep Clarifying Foaming Gel",
        "why": "Thoroughly lifts remaining residue and deeply clears follicular openings",
        "how": "Lather on wet skin for 45s and rinse thoroughly",
        "time": "Daily PM"
      });
    } else {
      evening.add({
        "step": pmStep++,
        "category": "Second Cleanse",
        "product": "Gentle Amino Acid Hydrating Cleanser",
        "why": "Ensures immaculate purity without disrupting the acid mantle",
        "how": "Gently massage on damp skin and rinse with lukewarm water",
        "time": "Daily PM"
      });
    }

    // 3. Night Targeted Active Treatment
    if (hasIssue('acne_severity') || hasIssue('acne') || hasIssue('blemishes')) {
      evening.add({
        "step": pmStep++,
        "category": "Targeted Treatment",
        "product": "Adapalene 0.1% / Micronized Benzoyl Peroxide Gel",
        "why": "Normalizes follicular keratinization and destroys acne bacteria overnight",
        "how": "Apply a pea-sized amount over clean, dry face (or spot treat blemishes)",
        "time": "Nightly PM"
      });
    } else if (hasIssue('wrinkles') || hasIssue('firmness')) {
      evening.add({
        "step": pmStep++,
        "category": "Clinical Retinoid",
        "product": "Encapsulated Retinaldehyde 0.05% / Retinol 0.3%",
        "why": "Accelerates cellular renewal and repairs structural collagen fibers",
        "how": "Apply pea-sized amount to completely dry skin (start 3x/week, build up)",
        "time": "3-5x Weekly PM"
      });
    } else if (hasIssue('texture') || hasIssue('pore_dilation') || hasIssue('pores')) {
      evening.add({
        "step": pmStep++,
        "category": "Resurfacing Exfoliant",
        "product": "Lactic Acid 7% + Glycolic Acid Gentle Resurfacing Liquid",
        "why": "Dissolves desmosomes between dead cells for silky smooth texture",
        "how": "Apply with a cotton pad 2-3 nights per week (do not rinse)",
        "time": "2-3x Weekly PM"
      });
    } else if (hasIssue('pigment') || hasIssue('sun_damage')) {
      evening.add({
        "step": pmStep++,
        "category": "Brightening Complex",
        "product": "Tranexamic Acid 3% + Alpha Arbutin 2% Dark Spot Corrector",
        "why": "Suppresses excess melanin pathway and evens out stubborn discoloration",
        "how": "Apply 3-4 drops evenly across face before night cream",
        "time": "Nightly PM"
      });
    } else {
      evening.add({
        "step": pmStep++,
        "category": "Repair Serum",
        "product": "Niacinamide 10% + Zinc 1% Restorative Serum",
        "why": "Fortifies skin barrier, calms inflammation, and regulates texture",
        "how": "Dispense 3-4 drops and gently smooth across skin",
        "time": "Nightly PM"
      });
    }

    // 4. Night Eye Treatment
    if (hasIssue('dark_circles') || hasIssue('eye_bags') || hasIssue('wrinkles')) {
      evening.add({
        "step": pmStep++,
        "category": "Night Eye Care",
        "product": "Multi-Peptide & Retinol Night Eye Regenerator",
        "why": "Accelerates overnight cellular restoration around fragile under-eye tissue",
        "how": "Delicately pat 1 pump around the orbital ring before sleeping",
        "time": "Nightly PM"
      });
    }

    // 5. Intensive Night Moisturizer / Sleeping Mask
    if (skinType.contains('oily')) {
      evening.add({
        "step": pmStep++,
        "category": "Night Moisturizer",
        "product": "Non-Comedogenic Barrier Repair Night Emulsion",
        "why": "Provides crucial overnight lipids without provoking comedones",
        "how": "Spread evenly over entire face and neck",
        "time": "Nightly PM"
      });
    } else if (skinType.contains('dry') || hasIssue('hydration') || hasIssue('barrier_health')) {
      evening.add({
        "step": pmStep++,
        "category": "Night Moisturizer",
        "product": "Bio-Lipid Intensive Cera-Repair Sleeping Balm",
        "why": "Creates a breathable moisture seal for intense dermal hydration",
        "how": "Apply a rich layer as the final step before bed",
        "time": "Nightly PM"
      });
    } else {
      evening.add({
        "step": pmStep++,
        "category": "Night Moisturizer",
        "product": "Nutritive Peptide Restorative Night Cream",
        "why": "Replenishes moisture reserves and supports overnight renewal cycles",
        "how": "Massage gently in upward circular motions",
        "time": "Nightly PM"
      });
    }

    return {
      "morning": morning,
      "evening": evening,
    };
  }

  void clearRoutine() {
    _routineData = null;
    _lastGeneratedForRecordId = null;
    _error = null;
    _isLoading = false;
    _basisDescription = null;
    notifyListeners();
  }
}
