import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ds/ds_card.dart';
import '../../widgets/ds/ds_button.dart';
import '../../widgets/ds/ds_avatar.dart';
import '../../providers/skin_profile_provider.dart';
import '../../providers/history_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'edit_profile_screen.dart';
import '../settings/settings_screen.dart';
import '../history/history_screen.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<SkinProfileProvider>(
        builder: (context, provider, child) {
          final historyProvider = context.watch<HistoryProvider>();
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          final profile = provider.profile;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.space24),
              child: Column(
                children: [
                  // Header
                  Center(
                    child: Column(
                      children: [
                        DSAvatar(
                          imageUrl: profile.profileImageUrl,
                          radius: 54,
                        ),
                        const SizedBox(height: AppTheme.space16),
                        Text(
                          profile.fullName.isEmpty ? 'User' : profile.fullName,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: AppTheme.space4),
                        Text(
                          profile.email,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppTheme.space24),
                        DSButton(
                          variant: DSButtonVariant.secondary,
                          label: "Edit Profile",
                          icon: Icons.edit_outlined,
                          isFullWidth: false,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => EditProfileScreen(profile: profile)),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.space40),

                  // Personal Information
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Personal Information", style: Theme.of(context).textTheme.titleLarge),
                  ),
                  const SizedBox(height: AppTheme.space16),
                  DSCard(
                    variant: DSCardVariant.elevated,
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildInfoRow("Age", profile.age?.toString() ?? 'Not set'),
                        const Divider(),
                        _buildInfoRow("Location", profile.location ?? 'Not set'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.space32),

                  // Skin Profile
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Skin Profile", style: Theme.of(context).textTheme.titleLarge),
                  ),
                  const SizedBox(height: AppTheme.space16),
                  DSCard(
                    variant: DSCardVariant.elevated,
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildInfoRow("Skin Type", profile.skinType ?? 'Not set'),
                        const Divider(),
                        _buildInfoRow(
                          "Concerns",
                          profile.skinConcerns.isEmpty ? 'None' : profile.skinConcerns.join(', '),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.space32),

                  // Log Out Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: AppTheme.surfaceElevated,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Text("Log Out", style: TextStyle(fontWeight: FontWeight.bold)),
                            content: const Text("Are you sure you want to log out of DermaSense?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Cancel", style: TextStyle(color: AppTheme.textSecondary)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.error,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text("Log Out"),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && context.mounted) {
                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                          await authProvider.signOut();
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.logout_rounded, color: AppTheme.error, size: 20),
                      label: const Text(
                        "Log Out",
                        style: TextStyle(
                          color: AppTheme.error,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.error.withValues(alpha: 0.5), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        backgroundColor: AppTheme.error.withValues(alpha: 0.06),
                      ),
                    ),
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.space20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
