import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FavoritesProvider with ChangeNotifier {
  List<String> _favoriteIds = [];
  bool _isLoading = true;
  String? _userId;
  StreamSubscription? _subscription;

  FavoritesProvider() {
    _isLoading = false;
  }

  void updateUserId(String? newUserId) {
    if (_userId == newUserId) return;
    _userId = newUserId;
    _subscription?.cancel();
    
    if (_userId != null) {
      _loadFavorites();
    } else {
      _favoriteIds = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  List<String> get favoriteIds => _favoriteIds;
  bool get isLoading => _isLoading;

  bool isFavorite(String id) => _favoriteIds.contains(id);

  void _loadFavorites() {
    _isLoading = true;
    notifyListeners();
    
    _subscription = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('data')
        .doc('favorites')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data['ids'] != null) {
          _favoriteIds = List<String>.from(data['ids']);
        }
      } else {
        _favoriteIds = [];
        // Create initial document
        FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .collection('data')
            .doc('favorites')
            .set({'ids': []});
      }
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint("Error loading favorites from Firestore: $e");
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> toggleFavorite(String id) async {
    if (_userId == null) return;
    
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('favorites')
          .set({'ids': _favoriteIds}, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error saving favorites to Firestore: $e");
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
