import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _dataSharingEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: ListView(
        children: [
          _buildSectionHeader("App Preferences"),
          SwitchListTile(
            title: const Text("Push Notifications"),
            subtitle: const Text("Receive reminders and insights"),
            value: _notificationsEnabled,
            onChanged: (val) {
              setState(() {
                _notificationsEnabled = val;
              });
            },
            secondary: const Icon(Icons.notifications_active),
          ),
          SwitchListTile(
            title: const Text("Dark Theme"),
            subtitle: const Text("Switch to dark mode (Coming Soon)"),
            value: _darkModeEnabled,
            onChanged: (val) {
              setState(() {
                _darkModeEnabled = val;
              });
            },
            secondary: const Icon(Icons.dark_mode),
          ),
          
          const Divider(),
          _buildSectionHeader("Privacy & Security"),
          SwitchListTile(
            title: const Text("Share Data Anonymously"),
            subtitle: const Text("Help improve our AI models"),
            value: _dataSharingEnabled,
            onChanged: (val) {
              setState(() {
                _dataSharingEnabled = val;
              });
            },
            secondary: const Icon(Icons.security),
          ),
          ListTile(
            title: const Text("Change Password"),
            leading: const Icon(Icons.lock),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password change dialog')));
            },
          ),
          
          const Divider(),
          _buildSectionHeader("Account"),
          ListTile(
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            leading: const Icon(Icons.logout, color: Colors.red),
            onTap: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
