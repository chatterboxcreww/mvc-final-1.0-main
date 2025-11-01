// lib/features/settings/screens/sync_settings_screen.dart
import 'package:flutter/material.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

class SyncSettingsScreen extends StatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  State<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends State<SyncSettingsScreen> {
  bool _autoSync = true;
  bool _syncOnWiFiOnly = true;
  bool _syncStepsData = true;
  bool _syncWaterData = true;
  bool _syncMoodData = true;
  bool _syncGoalsData = true;
  bool _syncAchievements = true;
  
  String _syncFrequency = 'Real-time';
  final List<String> _syncFrequencies = ['Real-time', 'Hourly', 'Daily', 'Weekly'];
  
  bool _isManualSyncing = false;
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    // Simulate last sync time
    _lastSyncTime = DateTime.now().subtract(const Duration(minutes: 15));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        colors: [
          Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
          Theme.of(context).colorScheme.surface,
        ],
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.teal,
                      Colors.teal.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_rounded,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "Sync & Backup",
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Sync Status Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.teal.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.cloud_sync_rounded,
                                  color: Colors.teal,
                                  size: 32,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Sync Status",
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          color: Colors.teal,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _lastSyncTime != null
                                            ? "Last synced ${_formatLastSyncTime()}"
                                            : "Never synced",
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.teal.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.teal, Colors.teal.shade600],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ElevatedButton(
                                onPressed: _isManualSyncing ? null : _performManualSync,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isManualSyncing
                                    ? const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            "Syncing...",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.sync_rounded, color: Colors.white),
                                          SizedBox(width: 8),
                                          Text(
                                            "Sync Now",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Sync Settings
                      SettingsSection(
                        title: "Sync Settings",
                        children: [
                          _buildSwitchTile(
                            title: "Auto Sync",
                            subtitle: "Automatically sync data in the background",
                            icon: Icons.sync_rounded,
                            color: Colors.teal,
                            value: _autoSync,
                            onChanged: (value) => setState(() => _autoSync = value),
                          ),
                          _buildSwitchTile(
                            title: "WiFi Only",
                            subtitle: "Only sync when connected to WiFi",
                            icon: Icons.wifi_rounded,
                            color: Colors.blue,
                            value: _syncOnWiFiOnly,
                            onChanged: (value) => setState(() => _syncOnWiFiOnly = value),
                          ),
                          // Sync Frequency Dropdown
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.schedule_outlined, color: Colors.purple, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Sync Frequency",
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      DropdownButton<String>(
                                        value: _syncFrequency,
                                        isExpanded: true,
                                        underline: const SizedBox(),
                                        items: _syncFrequencies.map((String frequency) {
                                          return DropdownMenuItem<String>(
                                            value: frequency,
                                            child: Text(frequency),
                                          );
                                        }).toList(),
                                        onChanged: (String? newValue) {
                                          if (newValue != null) {
                                            setState(() => _syncFrequency = newValue);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Data to Sync
                      SettingsSection(
                        title: "Data to Sync",
                        children: [
                          _buildSwitchTile(
                            title: "Steps & Activity",
                            subtitle: "Daily steps, distance, calories burned",
                            icon: Icons.directions_walk_outlined,
                            color: Colors.green,
                            value: _syncStepsData,
                            onChanged: (value) => setState(() => _syncStepsData = value),
                          ),
                          _buildSwitchTile(
                            title: "Water Intake",
                            subtitle: "Daily hydration tracking and goals",
                            icon: Icons.water_drop_outlined,
                            color: Colors.blue,
                            value: _syncWaterData,
                            onChanged: (value) => setState(() => _syncWaterData = value),
                          ),
                          _buildSwitchTile(
                            title: "Mood Tracking",
                            subtitle: "Daily mood entries and patterns",
                            icon: Icons.sentiment_satisfied_outlined,
                            color: Colors.amber,
                            value: _syncMoodData,
                            onChanged: (value) => setState(() => _syncMoodData = value),
                          ),
                          _buildSwitchTile(
                            title: "Goals & Progress",
                            subtitle: "Weekly goals and achievement progress",
                            icon: Icons.flag_outlined,
                            color: Colors.purple,
                            value: _syncGoalsData,
                            onChanged: (value) => setState(() => _syncGoalsData = value),
                          ),
                          _buildSwitchTile(
                            title: "Achievements",
                            subtitle: "Badges, level-ups, and milestones",
                            icon: Icons.emoji_events_outlined,
                            color: Colors.orange,
                            value: _syncAchievements,
                            onChanged: (value) => setState(() => _syncAchievements = value),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Advanced Options
                      SettingsSection(
                        title: "Advanced",
                        children: [
                          SettingsTile(
                            title: "Force Full Sync",
                            subtitle: "Re-sync all data from the beginning",
                            icon: Icons.refresh_rounded,
                            color: Colors.orange,
                            onTap: () => _showForceFullSyncDialog(),
                          ),
                          SettingsTile(
                            title: "Clear Local Cache",
                            subtitle: "Remove cached data to free up space",
                            icon: Icons.clear_all_rounded,
                            color: Colors.red,
                            onTap: () => _showClearCacheDialog(),
                          ),
                          SettingsTile(
                            title: "Sync Conflicts",
                            subtitle: "Manage data conflicts and resolution",
                            icon: Icons.warning_amber_outlined,
                            color: Colors.amber,
                            onTap: () => _showSyncConflictsDialog(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Backup Information Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.backup_outlined,
                              color: Colors.green,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Your Data is Safe",
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "• Automatic cloud backup\n• End-to-end encryption\n• Cross-device synchronization\n• Offline access to recent data",
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.green.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        activeColor: color,
      ),
    );
  }

  void _performManualSync() async {
    setState(() => _isManualSyncing = true);

    try {
      // Simulate sync process
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() {
        _isManualSyncing = false;
        _lastSyncTime = DateTime.now();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isManualSyncing = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatLastSyncTime() {
    if (_lastSyncTime == null) return "";
    
    final now = DateTime.now();
    final difference = now.difference(_lastSyncTime!);
    
    if (difference.inMinutes < 1) {
      return "just now";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes} minutes ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours} hours ago";
    } else {
      return "${difference.inDays} days ago";
    }
  }

  void _showForceFullSyncDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Force Full Sync"),
        content: const Text(
          "This will re-sync all your data from the beginning. "
          "This may take several minutes and use significant data. "
          "Continue only if you're experiencing sync issues.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performManualSync();
            },
            child: const Text("Force Sync"),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear Local Cache"),
        content: const Text(
          "This will remove all cached data to free up storage space. "
          "Your data will be re-downloaded when needed. "
          "This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              "Clear Cache",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showSyncConflictsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sync Conflicts"),
        content: const Text(
          "No sync conflicts detected. Conflicts occur when the same data "
          "is modified on multiple devices before syncing. The app automatically "
          "resolves most conflicts by keeping the most recent changes.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}
