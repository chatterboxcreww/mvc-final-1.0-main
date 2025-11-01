// lib/features/settings/screens/export_data_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../../../core/providers/user_data_provider.dart';
import '../../../core/providers/step_counter_provider.dart';
import '../../../core/providers/achievement_provider.dart';
import '../../../core/models/user_data.dart';
import '../../../core/models/daily_step_data.dart';
import '../../../core/models/achievement.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../widgets/settings_section.dart';

class ExportDataScreen extends StatefulWidget {
  const ExportDataScreen({super.key});

  @override
  State<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  bool _includeStepsData = true;
  bool _includeWaterData = true;
  bool _includeMoodData = true;
  bool _includeGoalsData = true;
  bool _includeAchievements = true;
  bool _includeHealthQuestions = false;
  
  String _selectedTimeRange = '30 days';
  final List<String> _timeRanges = ['7 days', '30 days', '90 days', '6 months', '1 year', 'All time'];
  
  bool _isExporting = false;

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
                      Colors.orange,
                      Colors.orange.withValues(alpha: 0.8),
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
                        "Export Your Data",
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
                      // Export Information Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.file_download_outlined,
                                  color: Colors.orange,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Export Your Health Data",
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Download your complete health journey as a professional PDF report. Perfect for sharing with healthcare providers or keeping personal records.",
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Time Range Selection
                      SettingsSection(
                        title: "Time Range",
                        children: [
                          Container(
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
                                  child: Icon(Icons.date_range_outlined, color: Colors.purple, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Select Time Period",
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      DropdownButton<String>(
                                        value: _selectedTimeRange,
                                        isExpanded: true,
                                        underline: const SizedBox(),
                                        items: _timeRanges.map((String range) {
                                          return DropdownMenuItem<String>(
                                            value: range,
                                            child: Text(range),
                                          );
                                        }).toList(),
                                        onChanged: (String? newValue) {
                                          if (newValue != null) {
                                            setState(() => _selectedTimeRange = newValue);
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

                      // Data Selection
                      SettingsSection(
                        title: "Data to Include",
                        children: [
                          _buildDataSelectionTile(
                            title: "Steps & Activity",
                            subtitle: "Daily steps, distance, calories burned",
                            icon: Icons.directions_walk_outlined,
                            color: Colors.green,
                            value: _includeStepsData,
                            onChanged: (value) => setState(() => _includeStepsData = value ?? false),
                          ),
                          _buildDataSelectionTile(
                            title: "Water Intake",
                            subtitle: "Daily hydration tracking and goals",
                            icon: Icons.water_drop_outlined,
                            color: Colors.blue,
                            value: _includeWaterData,
                            onChanged: (value) => setState(() => _includeWaterData = value ?? false),
                          ),
                          _buildDataSelectionTile(
                            title: "Mood Tracking",
                            subtitle: "Daily mood entries and patterns",
                            icon: Icons.sentiment_satisfied_outlined,
                            color: Colors.amber,
                            value: _includeMoodData,
                            onChanged: (value) => setState(() => _includeMoodData = value ?? false),
                          ),
                          _buildDataSelectionTile(
                            title: "Goals & Progress",
                            subtitle: "Weekly goals and achievement progress",
                            icon: Icons.flag_outlined,
                            color: Colors.purple,
                            value: _includeGoalsData,
                            onChanged: (value) => setState(() => _includeGoalsData = value ?? false),
                          ),
                          _buildDataSelectionTile(
                            title: "Achievements",
                            subtitle: "Badges, level-ups, and milestones",
                            icon: Icons.emoji_events_outlined,
                            color: Colors.orange,
                            value: _includeAchievements,
                            onChanged: (value) => setState(() => _includeAchievements = value ?? false),
                          ),
                          _buildDataSelectionTile(
                            title: "Health Questions",
                            subtitle: "Personal health profile and responses",
                            icon: Icons.health_and_safety_outlined,
                            color: Colors.red,
                            value: _includeHealthQuestions,
                            onChanged: (value) => setState(() => _includeHealthQuestions = value ?? false),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Export Button
                      Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange, Colors.orange.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isExporting ? null : _exportData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isExporting
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      "Generating PDF...",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.picture_as_pdf_outlined, color: Colors.white),
                                    SizedBox(width: 12),
                                    Text(
                                      "Generate PDF Report",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Export Features Card
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
                              Icons.verified_outlined,
                              color: Colors.green,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Professional PDF Report",
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "• Comprehensive health summary\n• Charts and progress graphs\n• Professional formatting\n• Perfect for healthcare providers",
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

  Widget _buildDataSelectionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool value,
    required ValueChanged<bool?> onChanged,
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
      child: CheckboxListTile(
        value: value,
        onChanged: (bool? newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
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

  void _exportData() async {
    if (!_hasDataSelected()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one data type to export.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      // Get user data with proper null handling
      final userProvider = context.read<UserDataProvider>();
      final stepProvider = context.read<StepCounterProvider>();
      final achievementProvider = context.read<AchievementProvider>();
      
      // Ensure we have the latest data
      await userProvider.syncLocalChangesToFirebase();
      
      final userData = userProvider.userData;
      final stepData = stepProvider.weeklyStepData;
      final achievements = achievementProvider.unlockedAchievements;

      // Validate that we have actual user data
      if (userData.userId.isEmpty) {
        throw Exception('No user data available. Please ensure you are logged in.');
      }

      print('Export Debug - User Data:');
      print('Name: ${userData.name}');
      print('Age: ${userData.age}');
      print('Height: ${userData.height}');
      print('Weight: ${userData.weight}');
      print('Step Data Count: ${stepData.length}');
      print('Achievements Count: ${achievements.length}');

      // Generate PDF with validated data
      final pdf = await _generatePDF(userData, stepData, achievements);
      
      // Save PDF to Downloads folder
      Directory? directory;
      
      if (Platform.isAndroid) {
        // For Android, use the Downloads directory
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          // Fallback to external storage downloads
          final external = await getExternalStorageDirectory();
          directory = Directory('${external?.path}/Download');
        }
      } else if (Platform.isIOS) {
        // For iOS, use Documents directory (iOS doesn't have accessible Downloads)
        directory = await getApplicationDocumentsDirectory();
      } else {
        // For other platforms, use Documents directory
        directory = await getApplicationDocumentsDirectory();
      }
      
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final filePath = '${directory.path}/health_report_$timestamp.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      setState(() => _isExporting = false);

      if (mounted) {
        _showExportSuccessDialog(filePath);
      }
    } catch (e) {
      setState(() => _isExporting = false);
      
      print('Export Error: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<pw.Document> _generatePDF(UserData userData, List<DailyStepData> stepData, List<Achievement> achievements) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.orange300,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Row(
                  children: [
                    pw.Icon(pw.IconData(0xe52e), size: 30),
                    pw.SizedBox(width: 15),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Health Report',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.Text(
                          'Generated on ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            pw.SizedBox(height: 30),
            
            // User Information
            pw.Text(
              'Personal Information',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Name: ${userData.name?.isNotEmpty == true ? userData.name : "Not specified"}'),
                  pw.SizedBox(height: 5),
                  pw.Text('Age: ${userData.age != null && userData.age! > 0 ? "${userData.age} years" : "Not specified"}'),
                  pw.SizedBox(height: 5),
                  pw.Text('Height: ${userData.height != null && userData.height! > 0 ? "${userData.height!.toStringAsFixed(1)} cm" : "Not specified"}'),
                  pw.SizedBox(height: 5),
                  pw.Text('Weight: ${userData.weight != null && userData.weight! > 0 ? "${userData.weight!.toStringAsFixed(1)} kg" : "Not specified"}'),
                  pw.SizedBox(height: 5),
                  pw.Text('Activity Level: ${userData.activityLevel?.isNotEmpty == true ? userData.activityLevel : "Not specified"}'),
                  pw.SizedBox(height: 5),
                  pw.Text('Member Since: ${userData.memberSince != null ? DateFormat('MMMM dd, yyyy').format(userData.memberSince!) : "Not specified"}'),
                  if (userData.dailyStepGoal != null && userData.dailyStepGoal! > 0) ...[
                    pw.SizedBox(height: 5),
                    pw.Text('Daily Step Goal: ${userData.dailyStepGoal} steps'),
                  ],
                  if (userData.dailyWaterGoal != null && userData.dailyWaterGoal! > 0) ...[
                    pw.SizedBox(height: 5),
                    pw.Text('Daily Water Goal: ${userData.dailyWaterGoal} glasses'),
                  ],
                ],
              ),
            ),
            
            pw.SizedBox(height: 30),
            
            // Step Data (if selected)
            if (_includeStepsData) ...[
              pw.Text(
                'Activity Summary ($_selectedTimeRange)',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (stepData.isNotEmpty) ...[
                      pw.Text('Total Steps: ${stepData.fold(0, (sum, data) => sum + data.steps)}'),
                      pw.SizedBox(height: 5),
                      pw.Text('Average Daily Steps: ${(stepData.fold(0, (sum, data) => sum + data.steps) / stepData.length).round()}'),
                      pw.SizedBox(height: 5),
                      pw.Text('Goals Met: ${stepData.where((data) => data.goalReached).length}/${stepData.length}'),
                      pw.SizedBox(height: 5),
                      pw.Text('Best Day: ${stepData.fold<DailyStepData?>(null, (best, current) => best == null || current.steps > best.steps ? current : best)?.steps ?? 0} steps'),
                      pw.SizedBox(height: 10),
                      pw.Text('Daily Breakdown:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ...stepData.take(10).map((data) => pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 3),
                        child: pw.Text('${DateFormat('MMM dd').format(data.date)}: ${data.steps} steps${data.goalReached ? " ✓ Goal Reached" : ""}'),
                      )),
                    ] else ...[
                      pw.Text('No step data available for the selected time range.'),
                      pw.SizedBox(height: 5),
                      pw.Text('Please use the app to track your daily steps.'),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
            ],
            
            // Achievements (if selected)
            if (_includeAchievements) ...[
              pw.Text(
                'Achievements Unlocked',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Total Achievements: ${achievements.length}'),
                    pw.SizedBox(height: 10),
                    ...achievements.take(10).map((achievement) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 5),
                      child: pw.Row(
                        children: [
                          pw.Text('🏆', style: pw.TextStyle(fontSize: 16)),
                          pw.SizedBox(width: 10),
                          pw.Expanded(
                            child: pw.Text('${achievement.name}: ${achievement.description}'),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
            ],
            
            // Health Goals Summary
            if (_includeGoalsData) ...[
              pw.Text(
                'Health Goals',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Daily Step Goal: ${userData.dailyStepGoal ?? 10000} steps'),
                    pw.SizedBox(height: 5),
                    pw.Text('Daily Water Goal: ${userData.dailyWaterGoal ?? 8} glasses'),
                    pw.SizedBox(height: 5),
                    pw.Text('Current Weight: ${userData.weight ?? "Not set"} kg'),
                  ],
                ),
              ),
            ],
            
            // Footer
            pw.SizedBox(height: 30),
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'This report was generated by your Health Tracking App',
                    style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'For questions about this data, please consult with your healthcare provider.',
                    style: pw.TextStyle(fontSize: 10),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );
    
    return pdf;
  }

  bool _hasDataSelected() {
    return _includeStepsData ||
           _includeWaterData ||
           _includeMoodData ||
           _includeGoalsData ||
           _includeAchievements ||
           _includeHealthQuestions;
  }

  void _showExportSuccessDialog(String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green),
            SizedBox(width: 12),
            Text("Export Complete"),
          ],
        ),
        content: Text(
          "Your health data has been successfully exported as a PDF for the period: $_selectedTimeRange.\n\n"
          "The report has been saved to your device and is ready to share.",
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                // Just show a message that file was saved instead of trying to open it
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('PDF saved to: $filePath'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not process file'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("View File Location"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await Share.shareXFiles([XFile(filePath)], text: 'My Health Report');
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not share file'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Share"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Done"),
          ),
        ],
      ),
    );
  }
}
