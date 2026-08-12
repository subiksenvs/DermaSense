import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
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
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        profile.fullName.isEmpty ? 'User' : profile.fullName,
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.email,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(profile: profile),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text("Edit Profile"),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
                        },
                        icon: const Icon(Icons.history, size: 18),
                        label: const Text("View Analysis History"),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Personal Information
                _buildSectionHeader("Personal Information"),
                const SizedBox(height: 16),
                _buildInfoCard(
                  context,
                  [
                    _buildInfoRow("Age", profile.age?.toString() ?? 'Not set'),
                    const Divider(),
                    _buildInfoRow("Location", profile.location ?? 'Not set'),
                  ],
                ),
                
                const SizedBox(height: 24),

                // Skin Profile
                _buildSectionHeader("Skin Profile"),
                const SizedBox(height: 16),
                _buildInfoCard(
                  context,
                  [
                    _buildInfoRow("Skin Type", profile.skinType ?? 'Not set'),
                    const Divider(),
                    _buildInfoRow("Primary Concerns", profile.skinConcerns.isEmpty ? 'None' : profile.skinConcerns.join(', ')),
                  ],
                ),

                const SizedBox(height: 24),

                // Preferences
                _buildSectionHeader("Preferences"),
                const SizedBox(height: 16),
                _buildInfoCard(
                  context,
                  [
                    _buildInfoRow("Budget", profile.budget != null ? '\$${profile.budget?.toStringAsFixed(2)}' : 'Not set'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
