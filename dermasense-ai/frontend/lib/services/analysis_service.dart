import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnalysisService {
  static String get _baseUrl {
    // Allows passing --dart-define=API_URL=http://192.168.x.x:8000 during build/run
    const envUrl = String.fromEnvironment('API_URL', defaultValue: '');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    // Fallback for emulator and local testing
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  static Future<Map<String, dynamic>> analyzeSkin(Uint8List imageBytes, String filename) async {
    final uri = Uri.parse('$_baseUrl/api/analyze');
    
    var request = http.MultipartRequest('POST', uri);
    
    request.files.add(http.MultipartFile.fromBytes(
      'image',
      imageBytes,
      filename: filename,
    ));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(responseBody);
    } else {
      String errorMessage = "Failed to analyze image";
      try {
        final errorJson = jsonDecode(responseBody);
        if (errorJson['detail'] != null) {
          errorMessage = errorJson['detail'].toString();
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }

  static Future<void> saveScanToHistory(Map<String, dynamic> result) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // We do not save the original image to save space as requested by user.
    // We only save the result data.
    final dataToSave = {
      'timestamp': FieldValue.serverTimestamp(),
      'scores': result['scores'],
      // We don't save overlays (base64) to firestore as they are huge. 
      // In a real app we'd upload overlays to Firebase Storage if needed, 
      // but here we just store scores.
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('scan_history')
        .add(dataToSave);
  }
}
