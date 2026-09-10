import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import 'skin_profile_provider.dart';
import 'history_provider.dart';

class RoutineProvider with ChangeNotifier {
  Map<String, dynamic>? _routineData;
  bool _isLoading = false;
  String? _error;

  // Tracks the analysis record ID the current routine was generated for,
  // so we know when to regenerate (i.e., when a newer analysis comes in).
  String? _lastGeneratedForRecordId;

  Map<String, dynamic>? get routineData => _routineData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Generates a personalized skincare routine via AiService (with auto-fallback).
  Future<void> generateRoutine(
    HistoryProvider historyProvider,
    SkinProfileProvider profileProvider, {
    bool force = false,
  }) async {
    if (historyProvider.records.isEmpty) return;

    final latestRecordId = historyProvider.records.first.id;
    if (!force && _routineData != null && _lastGeneratedForRecordId == latestRecordId) {
      return;
    }

    final skinType = profileProvider.profile.skinType ?? 'Normal';
    final concerns = profileProvider.profile.skinConcerns.isNotEmpty
        ? profileProvider.profile.skinConcerns.join(', ')
        : 'general skin maintenance';

    final records = historyProvider.records;
    String conditions = 'None noted';
    if (records.isNotEmpty) {
      conditions = records.first.conditions.isNotEmpty
          ? records.first.conditions.entries
              .map((e) => '${e.key}: ${e.value.toStringAsFixed(2)}')
              .join(', ')
          : records.first.metrics.entries
              .map((e) => '${e.key}: ${e.value.toStringAsFixed(2)}')
              .join(', ');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prompt = """
Generate a personalized AM/PM skincare routine. The user has $skinType skin with concerns: $concerns. Recent scan conditions: $conditions.
You MUST return ONLY valid JSON with exactly this structure, no markdown blocks, no extra text:
{
  "morning": [
    { "step": 1, "category": "Cleanser", "product": "Gentle Cleanser", "why": "Removes impurities", "how": "Massage onto damp skin" }
  ],
  "evening": [
    { "step": 1, "category": "Cleanser", "product": "Oil Cleanser", "why": "Removes SPF", "how": "Massage onto dry skin" }
  ]
}
""";

      final rawText = await AiService().generateText(
        prompt: prompt,
        systemInstruction: 'You are the DermaSense AI Assistant. Provide concise skincare routines.',
      );

      final clean = AiService.cleanJson(rawText);
      _routineData = jsonDecode(clean) as Map<String, dynamic>;
      _lastGeneratedForRecordId = latestRecordId;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error generating routine: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears cached routine data (e.g., on logout).
  void clearRoutine() {
    _routineData = null;
    _lastGeneratedForRecordId = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
