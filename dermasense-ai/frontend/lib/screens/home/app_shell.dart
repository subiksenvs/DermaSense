import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../home/home_screen.dart';
import '../analysis/analysis_screen.dart';
import '../routine/routine_screen.dart';
import '../chat/chat_screen.dart';
import '../profile/profile_screen.dart';
import '../../theme/app_theme.dart';
import '../../providers/routine_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/skin_profile_provider.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final Map<int, Widget> _loadedScreens = {};
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadedScreens[0] = const HomeScreen();
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();

    // Kick off background routine generation once the widget tree is built
    // so the Routine tab is ready right after login.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final historyProvider = context.read<HistoryProvider>();
      final profileProvider = context.read<SkinProfileProvider>();
      context.read<RoutineProvider>().generateRoutine(
        historyProvider,
        profileProvider,
      );
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    
    // Ensure routine is loaded when switching to Routine tab
    if (index == 2) {
      final historyProvider = context.read<HistoryProvider>();
      final profileProvider = context.read<SkinProfileProvider>();
      context.read<RoutineProvider>().generateRoutine(
        historyProvider,
        profileProvider,
      );
    }

    setState(() {
      _currentIndex = index;
    });
    
    _fadeController.reset();
    _fadeController.forward();
  }

  Widget _getScreen(int index) {
    return _loadedScreens.putIfAbsent(index, () {
      switch (index) {
        case 0:
          return const HomeScreen();
        case 1:
          return const AnalysisScreen();
        case 2:
          return const RoutineScreen();
        case 3:
          return const ChatScreen();
        case 4:
          return const ProfileScreen();
        default:
          return const HomeScreen();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBody: false,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_currentIndex != 0) {
            _onTabTapped(0);
          }
        },
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: IndexedStack(
            index: _currentIndex,
            children: List.generate(
              5,
              (i) => _loadedScreens.containsKey(i)
                  ? _loadedScreens[i]!
                  : (i == _currentIndex ? _getScreen(i) : const SizedBox.shrink()),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.only(
            left: AppTheme.space16,
            right: AppTheme.space16,
            bottom: AppTheme.space20,
            top: AppTheme.space8,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space8, vertical: AppTheme.space8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated.withValues(alpha: 0.95),
              borderRadius: AppTheme.borderRadiusPill,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: AppTheme.surfaceHighlight.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(0, Icons.home_filled, Icons.home_outlined, "Home"),
                _buildNavItem(1, Icons.camera_alt, Icons.camera_alt_outlined, "Analyze"),
                _buildNavItem(2, Icons.spa, Icons.spa_outlined, "Routine"),
                _buildNavItem(3, Icons.auto_awesome, Icons.auto_awesome_outlined, "AI"),
                _buildNavItem(4, Icons.person, Icons.person_outline, "Profile"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData selectedIcon, IconData unselectedIcon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutQuint,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12, vertical: AppTheme.space8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: AppTheme.borderRadiusPill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
              child: Icon(
                isSelected ? selectedIcon : unselectedIcon,
                key: ValueKey<bool>(isSelected),
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                size: 24,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: AppTheme.space4),
              AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: 12,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
