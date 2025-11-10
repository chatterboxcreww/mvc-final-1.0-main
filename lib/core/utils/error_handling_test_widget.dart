// lib/core/utils/error_handling_test_widget.dart
import 'package:flutter/material.dart';
import 'dependency_error_handler.dart';
import 'widget_lifecycle_manager.dart';

/// A test widget to verify error handling works correctly
class ErrorHandlingTestWidget extends StatefulWidget {
  const ErrorHandlingTestWidget({super.key});

  @override
  State<ErrorHandlingTestWidget> createState() => _ErrorHandlingTestWidgetState();
}

class _ErrorHandlingTestWidgetState extends State<ErrorHandlingTestWidget>
    with WidgetLifecycleManager {
  
  bool _shouldThrowError = false;
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return DependencyErrorWrapper(
      errorBuilder: (context, error) {
        return Container(
          color: Colors.orange.shade100,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning, size: 48, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  'Error Handled Successfully!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: ${error.toString()}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _shouldThrowError = false;
                    });
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Error Handling Test'),
          backgroundColor: Colors.blue.shade100,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Error Handling Test Widget',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              Text(
                'Counter: $_counter',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  safeSetState(() {
                    _counter++;
                  });
                },
                child: const Text('Increment Counter'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _shouldThrowError = true;
                  });
                  // This will trigger a dependency error
                  _simulateDependencyError();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade100,
                  foregroundColor: Colors.red.shade700,
                ),
                child: const Text('Simulate Dependency Error'),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Dependency Error Handler Status:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...DependencyErrorHandler().getStatus().entries.map(
                      (entry) => Text('${entry.key}: ${entry.value}'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _simulateDependencyError() {
    // Simulate a dependency error by trying to use a disposed resource
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_shouldThrowError) {
        throw FlutterError('_dependents.isEmpty: is not true (simulated error)');
      }
    });
  }
}

/// A debug widget to show error handling status
class ErrorHandlingStatusWidget extends StatelessWidget {
  const ErrorHandlingStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final status = DependencyErrorHandler().getStatus();
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Error Handler Status',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          ...status.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    entry.value.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}