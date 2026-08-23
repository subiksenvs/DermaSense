import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  String? _userId;
  StreamSubscription? _subscription;

  List<AnalysisRecord> get records => _records;
  bool get isLoading => _isLoading;

  HistoryProvider() {
    _isLoading = false;
  }

  void updateUserId(String? newUserId) {
    if (_userId == newUserId) return;
    _userId = newUserId;
    _subscription?.cancel();
    
    if (_userId != null) {
      _loadHistory();
    } else {
      _records = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  void _loadHistory() {
    _isLoading = true;
    notifyListeners();
    
    _subscription = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('history')
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) {
      _records = snapshot.docs.map((doc) => AnalysisRecord.fromJson(doc.data())).toList();
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint("Error loading history from Firestore: $e");
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> addRecord(AnalysisRecord record) async {
    if (_userId == null) return;
    
    // We update local state immediately for fast UI
    _records.insert(0, record);
    notifyListeners();
    
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('history')
          .doc(record.id)
          .set(record.toJson());
    } catch (e) {
      debugPrint("Error saving history to Firestore: $e");
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
