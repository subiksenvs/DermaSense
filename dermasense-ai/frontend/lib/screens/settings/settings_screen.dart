import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/ds/ds_card.dart';
import '../../widgets/ds/ds_toast.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../providers/history_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _downloadData() async {
    final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
    final records = historyProvider.records;

    if (records.isEmpty) {
      if (mounted) {
        DSToast.showInfo(context, 'No analysis data available to download.');
      }
      return;
    }

    if (mounted) {
      DSToast.showInfo(context, 'Preparing your data export...');
    }

    try {
      // 1. Collect all unique keys for conditions and metrics
      Set<String> conditionKeys = {};
      Set<String> metricKeys = {};
      
      for (var record in records) {
        conditionKeys.addAll(record.conditions.keys);
        metricKeys.addAll(record.metrics.keys);
      }

      List<String> sortedConditionKeys = conditionKeys.toList()..sort();
      List<String> sortedMetricKeys = metricKeys.toList()..sort();

      // 2. Build CSV header
      StringBuffer csvBuffer = StringBuffer();
      
      List<String> header = [
        'Scan ID',
        'Date',
        'Overall Score',
      ];
      header.addAll(sortedConditionKeys.map((k) => 'Condition: $k'));
      header.addAll(sortedMetricKeys.map((k) => 'Metric: $k'));
      
      csvBuffer.writeln(header.map((e) => '"$e"').join(','));

      // 3. Build rows
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
      
      for (var record in records) {
        List<String> row = [
          record.id,
          dateFormat.format(record.date),
          record.overallScore.toString(),
        ];
        
        for (var key in sortedConditionKeys) {
          row.add(record.conditions.containsKey(key) ? record.conditions[key]!.toStringAsFixed(2) : '');
        }
        
        for (var key in sortedMetricKeys) {
          row.add(record.metrics.containsKey(key) ? record.metrics[key]!.toStringAsFixed(2) : '');
        }
        
        csvBuffer.writeln(row.map((e) => '"$e"').join(','));
      }

      // 4. Save to temp file
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/DermaSense_Analysis_Data.csv';
      final file = File(filePath);
      await file.writeAsString(csvBuffer.toString());

      // 5. Share file
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'DermaSense Analysis Data',
        text: 'Here is your exported DermaSense skin analysis data.',
      );
    } catch (e) {
      if (mounted) {
        DSToast.showError(context, 'Failed to export data: $e');
      }
    }
  }
  void _showChangePasswordDialog() {
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text("Change Password"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: "New Password",
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: "Confirm Password",
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.only(right: 24, bottom: 24, left: 24),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: isLoading
                        ? null
                        : () async {
                            if (passwordController.text.length < 6) {
                              DSToast.showError(context, 'Password must be at least 6 characters');
                              return;
                            }
                            if (passwordController.text != confirmPasswordController.text) {
                              DSToast.showError(context, 'Passwords do not match');
                              return;
                            }
                            setState(() {
                              isLoading = true;
                            });
                            try {
                              await FirebaseAuth.instance.currentUser?.updatePassword(passwordController.text);
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                                if (context.mounted) {
                                  DSToast.showSuccess(context, 'Password updated successfully!');
                                }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                DSToast.showError(context, 'Error: $e');
                              }
                            } finally {
                              if (mounted) {
                                setState(() {
                                  isLoading = false;
                                });
                              }
                            }
                          },
                    child: isLoading 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                        : const Text("Update", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Privacy & Security"),
            DSCard(
              variant: DSCardVariant.glass,
              padding: EdgeInsets.zero,
              child: Column(
                children: [

                  ListTile(
                    title: const Text("Download My Data", style: TextStyle(fontWeight: FontWeight.w500)),
                    leading: Icon(Icons.download, color: Theme.of(context).colorScheme.primary),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: _downloadData,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text("Change Password", style: TextStyle(fontWeight: FontWeight.w500)),
                    leading: Icon(Icons.lock, color: Theme.of(context).colorScheme.primary),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: _showChangePasswordDialog,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text("Delete Analysis History", style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600)),
                    leading: const Icon(Icons.delete_outline, color: AppTheme.error),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Delete History"),
                          content: const Text("Are you sure you want to delete all your past skin analysis records? This cannot be undone."),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: AppTheme.error))),
                          ],
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        await Provider.of<HistoryProvider>(context, listen: false).clearHistory();
                        if (context.mounted) {
                          DSToast.showSuccess(context, 'Analysis history deleted.');
                        }
                      }
                    },
                  ),
                ],
              ),
            ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart),
            

          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    ).animate().fade(duration: 400.ms);
  }
}
