import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class SkinProfileProvider with ChangeNotifier {
  UserProfile _profile = UserProfile.empty();
  bool _isLoading = true;
  String? _userId;
  StreamSubscription? _subscription;
  static const String _prefsKey = 'cached_user_profile';

  SkinProfileProvider() {
    _isLoading = false;
  }

  void updateUserId(String? newUserId) {
    if (_userId == newUserId) return;
    _userId = newUserId;
    _subscription?.cancel();

    if (_userId != null) {
      _loadProfile();
    } else {
      _profile = UserProfile.empty();
      _isLoading = false;
      _clearCache();
      notifyListeners();
    }
  }

  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}
  }

  UserProfile get profile => _profile;
  bool get isLoading => _isLoading;

  Future<void> _loadProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_prefsKey);
      if (cachedData != null) {
        _profile = UserProfile.fromJson(jsonDecode(cachedData));
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading profile from cache: $e");
    }

    _subscription = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('data')
        .doc('profile')
        .snapshots()
        .listen(
          (snapshot) async {
            if (snapshot.exists) {
              _profile = UserProfile.fromFirestore(
                snapshot.data()!,
                snapshot.id,
              );

              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString(_prefsKey, jsonEncode(_profile.toJson()));
              } catch (e) {
                debugPrint("Error saving profile to cache: $e");
              }
            } else {
              // Defaults if no profile exists
              _profile = UserProfile(
                id: 'profile',
                fullName: 'User',
                email: 'user@example.com',
                age: 25,
                skinType: 'Combination',
                skinConcerns: ['Acne', 'Hydration'],
              );
              // Create initial profile in Firestore
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(_userId)
                  .collection('data')
                  .doc('profile')
                  .set(_profile.toFirestore());
            }
            _isLoading = false;
            notifyListeners();
          },
          onError: (e) {
            debugPrint("Error loading profile from Firestore: $e");
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<bool> updateProfile(UserProfile newProfile) async {
    if (_userId == null) return false;

    try {
      _profile = newProfile;
      notifyListeners(); // Immediate UI update

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(_profile.toJson()));

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('profile')
          .set(_profile.toFirestore(), SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint("Error saving profile to Firestore: $e");
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
