// lib/core/services/step_tracking_integration_helper.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/improved_step_counter_provider.dart';
import '../providers/step_counter_provider.dart';
import '../models/user_data.dart';
import 'step_data_migration_service.dart';
import 'improved_step_tracking_service.dart';
import 'unified_step_storage_service.dart';

/// Helper class to integrate the improved step tracking system
/// Provides backward compatibility and easy migration
class StepTrackingIntegrationHelper {
  static final StepTrackingIntegrationHelper _instance = 
      StepTrackingIntegrationHelper._internal();
  factory StepTrackingIntegrationHelper() => _instance;
  StepTrackingIntegrationHelper._internal();

  bool _useImprovedSystem = true; // Set to true to use new system
  bool _migrationComplete = false;

  /// Initialize step tracking system
  /// Call this early in app startup
  Future<void> initialize({bool useImprovedSystem = true}) async {
    _useImprovedSystem = useImprovedSystem;
    
    if (_useImprovedSystem) {
      debugPrint('StepTrackingIntegrationHelper: Using improved system');
      
      // Run migration if needed
      await StepDataMigrationService().migrateIfNeeded();
      _migrationComplete = true;
      
      // Initialize services
      await UnifiedStepStorageService().initialize();
      await ImprovedStepTrackingService().start();
    } else {
      debugPrint('StepTrackingIntegrationHelper: Using legacy system');
    }
  }

  /// Get the appropriate provider for the current system
  ChangeNotifierProvider getStepCounterProvider() {
    if (_useImprovedSystem) {
      return ChangeNotifierProvider<ImprovedStepCounterProvider>(
        create: (_) => ImprovedStepCounterProvider(),
      );
    } else {
      return ChangeNotifierProvider<StepCounterProvider>(
        create: (_) => StepCounterProvider(),
      );
    }
  }

  /// Initialize provider with user data
  Future<void> initializeProvider(BuildContext context, UserData userData) async {
    if (_useImprovedSystem) {
      final provider = Provider.of<ImprovedStepCounterProvider>(
        context,
        listen: false,
      );
      await provider.initialize(userData);
    } else {
      final provider = Provider.of<StepCounterProvider>(
        context,
        listen: false,
      );
      provider.updateUser(userData);
    }
  }

  /// Get today's step count (works with both systems)
  Future<int> getTodaySteps(BuildContext context) async {
    if (_useImprovedSystem) {
      final provider = Provider.of<ImprovedStepCounterProvider>(
        context,
        listen: false,
      );
      return provider.todaySteps;
    } else {
      final provider = Provider.of<StepCounterProvider>(
        context,
        listen: false,
      );
      return provider.todaySteps;
    }
  }

  /// Get step statistics (works with both systems)
  Future<Map<String, dynamic>> getStepStats(BuildContext context) async {
    if (_useImprovedSystem) {
      final provider = Provider.of<ImprovedStepCounterProvider>(
        context,
        listen: false,
      );
      return await provider.getStepStats();
    } else {
      // Legacy system doesn't have getStepStats, create compatible response
      final provider = Provider.of<StepCounterProvider>(
        context,
        listen: false,
      );
      return {
        'today': provider.todaySteps,
        'goal': 10000, // Default goal
        'weeklyTotal': provider.weeklyStepData.fold(0, (sum, data) => sum + data.steps),
        'weeklyAverage': provider.weeklyStepData.isEmpty 
            ? 0 
            : provider.weeklyStepData.fold(0, (sum, data) => sum + data.steps) ~/ 
              provider.weeklyStepData.length,
        'streak': provider.streak,
        'distance': provider.distanceMeters,
        'calories': provider.caloriesBurned,
      };
    }
  }

  /// Check if using improved system
  bool get isUsingImprovedSystem => _useImprovedSystem;

  /// Check if migration is complete
  bool get isMigrationComplete => _migrationComplete;

  /// Get migration status
  Future<Map<String, dynamic>> getMigrationStatus() async {
    return await StepDataMigrationService().getMigrationStatus();
  }

  /// Force switch to improved system (with migration)
  Future<void> switchToImprovedSystem(BuildContext context) async {
    if (_useImprovedSystem) {
      debugPrint('StepTrackingIntegrationHelper: Already using improved system');
      return;
    }
    
    debugPrint('StepTrackingIntegrationHelper: Switching to improved system');
    
    // Run migration
    await StepDataMigrationService().migrateIfNeeded();
    
    // Initialize new system
    await UnifiedStepStorageService().initialize();
    await ImprovedStepTrackingService().start();
    
    _useImprovedSystem = true;
    _migrationComplete = true;
    
    debugPrint('StepTrackingIntegrationHelper: Switch complete');
  }

  /// Rollback to legacy system (emergency fallback)
  Future<void> rollbackToLegacySystem() async {
    if (!_useImprovedSystem) {
      debugPrint('StepTrackingIntegrationHelper: Already using legacy system');
      return;
    }
    
    debugPrint('StepTrackingIntegrationHelper: Rolling back to legacy system');
    
    // Stop improved services
    await ImprovedStepTrackingService().stop();
    UnifiedStepStorageService().dispose();
    
    _useImprovedSystem = false;
    
    debugPrint('StepTrackingIntegrationHelper: Rollback complete');
  }

  /// Get system status for debugging
  Map<String, dynamic> getSystemStatus() {
    return {
      'useImprovedSystem': _useImprovedSystem,
      'migrationComplete': _migrationComplete,
      'trackingServiceStatus': _useImprovedSystem 
          ? ImprovedStepTrackingService().getStatus()
          : {'status': 'legacy_system'},
    };
  }
}

/// Widget to display migration progress
class MigrationProgressWidget extends StatefulWidget {
  final VoidCallback? onComplete;
  
  const MigrationProgressWidget({Key? key, this.onComplete}) : super(key: key);

  @override
  State<MigrationProgressWidget> createState() => _MigrationProgressWidgetState();
}

class _MigrationProgressWidgetState extends State<MigrationProgressWidget> {
  bool _isLoading = true;
  String _status = 'Checking migration status...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _checkMigration();
  }

  Future<void> _checkMigration() async {
    try {
      setState(() {
        _status = 'Checking for data migration...';
      });
      
      final migrationStatus = await StepDataMigrationService().getMigrationStatus();
      
      if (migrationStatus['migrationComplete'] == true) {
        setState(() {
          _status = 'Migration complete!';
          _isLoading = false;
        });
        
        await Future.delayed(const Duration(seconds: 1));
        widget.onComplete?.call();
      } else {
        setState(() {
          _status = 'Migrating step data...';
        });
        
        await StepDataMigrationService().migrateIfNeeded();
        
        setState(() {
          _status = 'Migration complete!';
          _isLoading = false;
        });
        
        await Future.delayed(const Duration(seconds: 1));
        widget.onComplete?.call();
      }
    } catch (e) {
      setState(() {
        _status = 'Migration error: $e';
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading)
                const CircularProgressIndicator()
              else if (_hasError)
                const Icon(Icons.error, color: Colors.red, size: 48)
              else
                const Icon(Icons.check_circle, color: Colors.green, size: 48),
              const SizedBox(height: 16),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              if (_hasError) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _hasError = false;
                    });
                    _checkMigration();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
