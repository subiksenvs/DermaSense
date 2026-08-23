import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/foundation.dart';

class AppFirebaseService {
  static Future<void> initialize() async {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyCfLmfJrjO6ujp_muwPKB7KZ0cpefMWWWI",
          authDomain: "dermasenseai-1dd95.firebaseapp.com",
          projectId: "dermasenseai-1dd95",
          storageBucket: "dermasenseai-1dd95.firebasestorage.app",
          messagingSenderId: "509696574029",
          appId: "1:509696574029:web:01223a37f7503736f55204",
          measurementId: "G-5YTXJZ1BTT",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  }
}
