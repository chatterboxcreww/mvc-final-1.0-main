// lib/core/utils/error_handling_example.dart
import 'package:flutter/material.dart';
import 'dependency_error_handler.dart';
import 'widget_lifecycle_manager.dart';

/// Example of how to use the error handling system
class ErrorHandlingExample extends StatefulWidget {
  const ErrorHandlingExample({super.key});

  @override
  State<ErrorHandlingExample> createState() => _ErrorHandlingExampleState();
}

class _ErrorHandlingExampleState extends State<ErrorHandlingExample>
    with TickerProviderStateMixin, WidgetLifecycleManager {
  
  late AnimationController _controller;
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    
    // Create animation controller and add it to lifecycle manager
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    addAnimationController(_controller);
    
    // Start animation
    _controller.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return DependencyErrorWrapper(
      errorBuilder: (context, error) {
        return Container(
          color: Colors.orange.shade100,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning, size: 48, color: Colors.orange),
                SizedBox(height: 16),
                Text(
                  'Error Handled Successfully!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Error Handling Example'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.8 + (_controller.value * 0.4),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Center(
                        child: Text(
                          '$_counter',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // Use safeSetState instead of regular setState
                  safeSetState(() {
                    _counter++;
                  });
                },
                child: const Text('Increment Counter'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // This demonstrates safe provider usage
                  final navigator = SafeDependencyProvider.safeRead<NavigatorState>(context);
                  if (navigator != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Safe provider access successful!')),
                    );
                  }
                },
                child: const Text('Test Safe Provider'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Example of a widget that might have dependency issues
class ProblematicWidget extends StatefulWidget {
  const ProblematicWidget({super.key});

  @override
  State<ProblematicWidget> createState() => _ProblematicWidgetState();
}

class _ProblematicWidgetState extends State<ProblematicWidget>
    with DependencyErrorMixin {
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('Widget ID: $widgetId'),
          const SizedBox(height: 8),
          Text('Is Safely Mounted: $isSafelyMounted'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Use safeSetState to prevent dependency errors
              safeSetState(() {
                // Some state change
              });
            },
            child: const Text('Safe State Update'),
          ),
        ],
      ),
    );
  }
}