import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/skin_profile_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/history_provider.dart';
import 'screens/splash/splash_screen.dart';

void main() {
  runApp(const DermaSenseApp());
}

class DermaSenseApp extends StatelessWidget {
  const DermaSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SkinProfileProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
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
