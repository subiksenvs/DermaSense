import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalysisRecord {
  final String id;
  final DateTime date;
  final int overallScore;
  final String imagePath;
  final Map<String, double> conditions;
  final Map<String, double> metrics;

  AnalysisRecord({
    required this.id,
    required this.date,
    required this.overallScore,
    required this.imagePath,
    required this.conditions,
    required this.metrics,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'overallScore': overallScore,
    'imagePath': imagePath,
    'conditions': conditions,
    'metrics': metrics,
  };

  factory AnalysisRecord.fromJson(Map<String, dynamic> json) => AnalysisRecord(
    id: json['id'],
    date: DateTime.parse(json['date']),
    overallScore: json['overallScore'],
    imagePath: json['imagePath'],
    conditions: Map<String, double>.from(json['conditions']),
    metrics: Map<String, double>.from(json['metrics']),
  );
}

class HistoryProvider with ChangeNotifier {
  List<AnalysisRecord> _records = [];
  bool _isLoading = true;

  List<AnalysisRecord> get records => _records;
  bool get isLoading => _isLoading;

  HistoryProvider() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyString = prefs.getString('analysis_history');
      if (historyString != null) {
        final List<dynamic> decoded = json.decode(historyString);
        _records = decoded.map((e) => AnalysisRecord.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint("Error loading history: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addRecord(AnalysisRecord record) async {
    _records.insert(0, record);
    notifyListeners();
    _saveHistory();
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('analysis_history', json.encode(_records.map((e) => e.toJson()).toList()));
    } catch (e) {
      debugPrint("Error saving history: $e");
    }
  }
}
