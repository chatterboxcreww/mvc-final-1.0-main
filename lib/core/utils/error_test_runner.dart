// lib/core/utils/error_test_runner.dart
import 'package:flutter/material.dart';
import 'dependency_error_handler.dart';

/// A utility to test error handling functionality
class ErrorTestRunner {
  static void runTests(BuildContext context) {
    debugPrint('🧪 Starting Error Handling Tests...');
    
    // Test 1: Dependency Error Detection
    _testDependencyErrorDetection();
    
    // Test 2: Safe Provider Operations
    _testSafeProviderOperations(context);
    
    // Test 3: Error Handler Status
    _testErrorHandlerStatus();
    
    debugPrint('🧪 Error Handling Tests Completed');
  }
  
  static void _testDependencyErrorDetection() {
    debugPrint('🧪 Test 1: Dependency Error Detection');
    
    final testErrors = [
      '_dependents.isEmpty: is not true',
      'setState() called after dispose()',
      'Looking up a deactivated widget',
      'Regular error message',
    ];
    
    for (final error in testErrors) {
      final isDependencyError = DependencyErrorHandler.isDependencyError(error);
      debugPrint('   Error: "$error" -> Dependency Error: $isDependencyError');
    }
  }
  
  static void _testSafeProviderOperations(BuildContext context) {
    debugPrint('🧪 Test 2: Safe Provider Operations');
    
    try {
      // Test safe read (this might fail if provider doesn't exist, but shouldn't crash)
      final navigator = SafeDependencyProvider.safeRead<NavigatorState>(context);
      debugPrint('   Safe read result: ${navigator != null ? "Success" : "Null"}');
      
      // Test safe watch (this might fail if provider doesn't exist, but shouldn't crash)
      final navigatorWatch = SafeDependencyProvider.safeWatch<NavigatorState>(context);
      debugPrint('   Safe watch result: ${navigatorWatch != null ? "Success" : "Null"}');
      
    } catch (e) {
      debugPrint('   Safe provider test error (expected): $e');
    }
  }
  
  static void _testErrorHandlerStatus() {
    debugPrint('🧪 Test 3: Error Handler Status');
    
    final status = DependencyErrorHandler().getStatus();
    debugPrint('   Status: $status');
    
    // Register a test widget
    DependencyErrorHandler().registerWidget('test_widget_123');
    
    final statusAfterRegister = DependencyErrorHandler().getStatus();
    debugPrint('   Status after register: $statusAfterRegister');
    
    // Unregister the test widget
    DependencyErrorHandler().unregisterWidget('test_widget_123');
    
    final statusAfterUnregister = DependencyErrorHandler().getStatus();
    debugPrint('   Status after unregister: $statusAfterUnregister');
  }
  
  /// Simulate a dependency error for testing
  static void simulateDependencyError() {
    debugPrint('🧪 Simulating dependency error...');
    
    try {
      throw FlutterError('_dependents.isEmpty: is not true (test simulation)');
    } catch (e) {
      if (DependencyErrorHandler.isDependencyError(e)) {
        debugPrint('🧪 Dependency error caught and handled: $e');
        DependencyErrorHandler().handleDependencyError(e, StackTrace.current);
      } else {
        debugPrint('🧪 Unexpected error type: $e');
      }
    }
  }
  
  /// Get a summary of the error handling system status
  static Map<String, dynamic> getSystemStatus() {
    return {
      'dependency_handler_status': DependencyErrorHandler().getStatus(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// A debug widget that shows error handling test results
class ErrorTestWidget extends StatelessWidget {
  const ErrorTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Handling Tests'),
        backgroundColor: Colors.blue.shade100,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Error Handling Test Suite',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => ErrorTestRunner.runTests(context),
              child: const Text('Run All Tests'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ErrorTestRunner.simulateDependencyError(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade100,
                foregroundColor: Colors.orange.shade700,
              ),
              child: const Text('Simulate Dependency Error'),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'System Status:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          ErrorTestRunner.getSystemStatus().toString(),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}