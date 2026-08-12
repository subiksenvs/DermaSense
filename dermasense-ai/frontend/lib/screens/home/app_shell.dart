import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../analysis/analysis_screen.dart';
import '../routine/routine_screen.dart';
import '../chat/chat_screen.dart';

import '../profile/profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const AnalysisScreen(),
    const RoutineScreen(),
    const ChatScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: "Home"),
          NavigationDestination(icon: Icon(Icons.camera), label: "Analyze"),
          NavigationDestination(icon: Icon(Icons.spa), label: "Routine"),
          NavigationDestination(icon: Icon(Icons.chat), label: "Assistant"),
          NavigationDestination(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
