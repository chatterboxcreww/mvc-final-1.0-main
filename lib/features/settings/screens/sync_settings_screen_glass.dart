// lib/features/settings/screens/sync_settings_screen.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/glass_background.dart';
import '../widgets/glass_settings_tile.dart';

class SyncSettingsScreen extends StatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  State<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends State<SyncSettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  bool _autoSync = true;
  bool _syncOnWiFiOnly = true;
  bool _syncStepsData = true;
  bool _syncWaterData = true;
  bool _syncAchievements = true;
  bool _isManualSyncing = false;
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _lastSyncTime = DateTime.now().subtract(const Duration(minutes: 15));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'Sync & Backup',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: GlassBackgroundPainter(
                animation: _controller,
                colorScheme: colorScheme,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  
                  // Last Sync Info
                  GlassCard(
                    child: Row(
                      children: [
                        Icon(Icons.cloud_done, color: Colors.green, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Last Synced',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                _lastSyncTime != null
                                    ? '${_lastSyncTime!.hour}:${_lastSyncTime!.minute.toString().padLeft(2, '0')}'
                                    : 'Never',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GlassButton(
                          text: 'Sync Now',
                          icon: Icons.sync,
                          onPressed: _isManualSyncing ? null : _performManualSync,
                          isPrimary: true,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  _buildSectionTitle(context, 'Sync Settings'),
                  const SizedBox(height: 12),
                  GlassSwitchTile(
                    icon: Icons.sync,
                    title: "Auto Sync",
                    subtitle: "Automatically sync data in background",
                    color: Colors.blue,
                    value: _autoSync,
                    onChanged: (value) => setState(() => _autoSync = value),
                  ),
                  GlassSwitchTile(
                    icon: Icons.wifi,
                    title: "WiFi Only",
                    subtitle: "Sync only when connected to WiFi",
                    color: Colors.purple,
                    value: _syncOnWiFiOnly,
                    onChanged: (value) => setState(() => _syncOnWiFiOnly = value),
                  ),

                  const SizedBox(height: 24),

                  _buildSectionTitle(context, 'Data to Sync'),
                  const SizedBox(height: 12),
                  GlassSwitchTile(
                    icon: Icons.directions_walk,
                    title: "Steps Data",
                    subtitle: "Sync daily step counts",
                    color: Colors.green,
                    value: _syncStepsData,
                    onChanged: (value) => setState(() => _syncStepsData = value),
                  ),
                  GlassSwitchTile(
                    icon: Icons.water_drop,
                    title: "Water Intake",
                    subtitle: "Sync water consumption data",
                    color: Colors.blue,
                    value: _syncWaterData,
                    onChanged: (value) => setState(() => _syncWaterData = value),
                  ),
                  GlassSwitchTile(
                    icon: Icons.emoji_events,
                    title: "Achievements",
                    subtitle: "Sync achievements and badges",
                    color: Colors.amber,
                    value: _syncAchievements,
                    onChanged: (value) => setState(() => _syncAchievements = value),
                  ),

                  const SizedBox(height: 32),

                  GlassButton(
                    text: 'Save Settings',
                    icon: Icons.save_outlined,
                    onPressed: _saveSettings,
                    isPrimary: true,
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Future<void> _performManualSync() async {
    setState(() => _isManualSyncing = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isManualSyncing = false;
      _lastSyncTime = DateTime.now();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data synced successfully!')),
      );
    }
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sync settings saved!')),
    );
  }
}
