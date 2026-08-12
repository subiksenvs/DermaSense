import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class SkinProfileProvider with ChangeNotifier {
  UserProfile _profile = UserProfile.empty();
  bool _isLoading = true;

  SkinProfileProvider() {
    _loadProfile();
  }

  UserProfile get profile => _profile;
  bool get isLoading => _isLoading;

  Future<void> _loadProfile() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileString = prefs.getString('user_profile');
      if (profileString != null) {
        _profile = UserProfile.fromJson(json.decode(profileString));
      } else {
        // Defaults if no profile exists
        _profile = UserProfile(
          fullName: 'Sarah',
          email: 'sarah@example.com',
          age: 28,
          skinType: 'Combination',
          skinConcerns: ['Acne', 'Hydration'],
        );
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(UserProfile newProfile) async {
    try {
      _profile = newProfile;
      notifyListeners(); // Immediate UI update

      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString('user_profile', json.encode(_profile.toJson()));
      return success;
    } catch (e) {
      debugPrint("Error saving profile: $e");
      return false;
    }
  }
}
