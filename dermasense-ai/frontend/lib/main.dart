import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/firebase_service.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/skin_profile_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/history_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/routine_provider.dart';
import 'services/notification_service.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/notifications/notifications_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    if (kDebugMode) {
      print("Warning: Failed to load .env file: $e");
    }
  }
  await AppFirebaseService.initialize();
  runApp(const DermaSenseApp());
}

class DermaSenseApp extends StatefulWidget {
  const DermaSenseApp({super.key});

  @override
  State<DermaSenseApp> createState() => _DermaSenseAppState();
}

class _DermaSenseAppState extends State<DermaSenseApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Initialize notification service after the widget tree builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().init(_navigatorKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
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
        ChangeNotifierProvider(create: (_) => RoutineProvider()),
      ],
      child: MaterialApp(
        title: 'DermaSense AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        navigatorKey: _navigatorKey,
        home: const SplashScreen(),
        routes: {
          '/notifications': (context) => const NotificationsScreen(),
        },
      ),
    );
  }
}
