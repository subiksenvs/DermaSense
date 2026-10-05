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

  factory AnalysisRecord.fromJson(Map<String, dynamic> json, String docId) {
    if (json.containsKey('scores') && !json.containsKey('overallScore')) {
      final scores = json['scores'] as Map<String, dynamic>? ?? {};
      double overallScore = 0.0;
      Map<String, double> metrics = {};
      if (scores.isNotEmpty) {
        double sum = 0;
        for (var entry in scores.entries) {
          double val = (entry.value as num).toDouble();
          metrics[entry.key] = val;
          sum += (1.0 - val);
        }
        overallScore = (sum / scores.length) * 100.0;
      }
      
      var timestamp = json['timestamp'];
      DateTime date = DateTime.now();
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      }

      return AnalysisRecord(
        id: docId,
        date: date,
        overallScore: overallScore.round(),
        imagePath: '',
        conditions: {},
        metrics: metrics,
      );
    }

    return AnalysisRecord(
      id: json['id'] ?? docId,
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      overallScore: (json['overallScore'] as num?)?.round() ?? 0,
      imagePath: json['imagePath'] ?? '',
      conditions: (json['conditions'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, (v as num).toDouble())) ?? {},
      metrics: (json['metrics'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, (v as num).toDouble())) ?? {},
    );
  }
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
    // If auth is bypassed for testing, use a persistent fallback ID so history works
    newUserId ??= 'test_user_123';
    
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
        .collection('scan_history')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      
      List<AnalysisRecord> parsedRecords = [];
      for (var doc in snapshot.docs) {
        try {
          parsedRecords.add(AnalysisRecord.fromJson(doc.data(), doc.id));
        } catch (e) {
          debugPrint("Skipping malformed history document ${doc.id}: $e");
        }
      }
      
      // Sort locally by date to ensure pending writes (which may have null server timestamps)
      // are correctly positioned at the top of the history list.
      parsedRecords.sort((a, b) => b.date.compareTo(a.date));
      
      _records = parsedRecords;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint("Error loading history from Firestore: $e");
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> addRecord(AnalysisRecord record) async {
    // We update local state immediately for fast UI
    _records.insert(0, record);
    notifyListeners();
    
    if (_userId == null) return;
    
    try {
      final dataToSave = record.toJson();
      // Ensure timestamp is always present for the orderBy clause
      dataToSave['timestamp'] = FieldValue.serverTimestamp();
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('scan_history')
          .doc(record.id)
          .set(dataToSave);
    } catch (e) {
      debugPrint("Error saving history to Firestore: $e");
    }
  }

  Future<void> clearHistory() async {
    if (_userId == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('scan_history')
          .get();
      
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      _records.clear();
      notifyListeners();
    } catch (e) {
      debugPrint("Error clearing history from Firestore: $e");
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
