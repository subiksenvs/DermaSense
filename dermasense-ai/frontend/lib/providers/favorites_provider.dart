import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesProvider with ChangeNotifier {
  List<String> _favoriteIds = [];
  bool _isLoading = true;

  FavoritesProvider() {
    _loadFavorites();
  }

  List<String> get favoriteIds => _favoriteIds;
  bool get isLoading => _isLoading;

  bool isFavorite(String id) => _favoriteIds.contains(id);

  Future<void> _loadFavorites() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final favString = prefs.getString('favorites');
      if (favString != null) {
        _favoriteIds = List<String>.from(json.decode(favString));
      }
    } catch (e) {
      debugPrint("Error loading favorites: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(String id) async {
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('favorites', json.encode(_favoriteIds));
    } catch (e) {
      debugPrint("Error saving favorites: $e");
    }
  }
}
