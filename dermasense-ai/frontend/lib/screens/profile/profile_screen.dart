import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/animated_gradient_button.dart';
import '../../providers/skin_profile_provider.dart';
import 'edit_profile_screen.dart';
import '../settings/settings_screen.dart';
import '../history/history_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SkinProfileProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final profile = provider.profile;

        return Scaffold(
          appBar: AppBar(
            title: const Text("My Profile"),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Header
                Center(
                  child: Column(
                    children: [
                      // Profile image avatar
                      _buildProfileAvatar(context, profile.profileImageUrl),
                      const SizedBox(height: 16),
                      Text(
                        profile.fullName.isEmpty ? 'User' : profile.fullName,
                        style: Theme.of(
                          context,
                        ).textTheme.displayMedium?.copyWith(fontSize: 24),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.email,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 200,
                        child: AnimatedGradientButton(
                          text: "Edit Profile",
                          icon: Icons.edit,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditProfileScreen(profile: profile),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Personal Information
                _buildSectionHeader("Personal Information"),
                const SizedBox(height: 16),
                _buildInfoCard(context, [
                  _buildInfoRow("Age", profile.age?.toString() ?? 'Not set'),
                  const Divider(height: 1),
                  _buildInfoRow("Location", profile.location ?? 'Not set'),
                ]),

                const SizedBox(height: 24),

                // Skin Profile
                _buildSectionHeader("Skin Profile"),
                const SizedBox(height: 16),
                _buildInfoCard(context, [
                  _buildInfoRow("Skin Type", profile.skinType ?? 'Not set'),
                  const Divider(height: 1),
                  _buildInfoRow(
                    "Primary Concerns",
                    profile.skinConcerns.isEmpty
                        ? 'None'
                        : profile.skinConcerns.join(', '),
                  ),
                ]),

                const SizedBox(height: 24),

                // Preferences
                _buildSectionHeader("Preferences"),
                const SizedBox(height: 16),
                _buildInfoCard(context, [
                  _buildInfoRow(
                    "Budget",
                    profile.budget != null
                        ? '\$${profile.budget?.toStringAsFixed(2)}'
                        : 'Not set',
                  ),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileAvatar(BuildContext context, String? imagePath) {
    final hasImage = imagePath != null && imagePath.isNotEmpty;

    return Container(
      width: 108,
      height: 108,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(3), // Border width
      child: CircleAvatar(
        radius: 51,
        backgroundColor: Theme.of(context).colorScheme.surface,
        backgroundImage: hasImage
            ? (imagePath.startsWith('data:image')
                  ? MemoryImage(base64Decode(imagePath.split(',').last))
                  : NetworkImage(imagePath) as ImageProvider)
            : null,
        child: hasImage
            ? null
            : Icon(
                Icons.person,
                size: 50,
                color: Theme.of(context).colorScheme.primary,
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, List<Widget> children) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
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
