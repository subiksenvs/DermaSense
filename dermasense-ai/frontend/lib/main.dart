import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/firebase_service.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/skin_profile_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/history_provider.dart';
import 'screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await AppFirebaseService.initialize();
  runApp(const DermaSenseApp());
}

class DermaSenseApp extends StatelessWidget {
  const DermaSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, SkinProfileProvider>(
          create: (_) => SkinProfileProvider(),
          update: (_, auth, previous) => previous!..updateUserId(auth.currentUser?.uid),
        ),
        ChangeNotifierProxyProvider<AuthProvider, FavoritesProvider>(
          create: (_) => FavoritesProvider(),
          update: (_, auth, previous) => previous!..updateUserId(auth.currentUser?.uid),
        ),
        ChangeNotifierProxyProvider<AuthProvider, HistoryProvider>(
          create: (_) => HistoryProvider(),
          update: (_, auth, previous) => previous!..updateUserId(auth.currentUser?.uid),
        ),
      ],
      child: MaterialApp(
        title: 'DermaSense AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
