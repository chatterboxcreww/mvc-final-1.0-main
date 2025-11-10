// lib/features/onboarding/widgets/feature_highlight_overlay.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/widgets/glass_container.dart';

/// Interactive overlay that highlights specific features for first-time users
class FeatureHighlightOverlay extends StatefulWidget {
  final Widget child;
  final bool showTutorial;

  const FeatureHighlightOverlay({
    super.key,
    required this.child,
    this.showTutorial = false,
  });

  @override
  State<FeatureHighlightOverlay> createState() => _FeatureHighlightOverlayState();
}

class _FeatureHighlightOverlayState extends State<FeatureHighlightOverlay> {
  int _currentStep = 0;
  bool _showOverlay = false;

  final List<HighlightStep> _highlights = [
    HighlightStep(
      title: 'Step Tracker',
      description: 'Track your daily steps automatically. Tap to view history!',
      targetKey: 'step_tracker',
    ),
    HighlightStep(
      title: 'Water Tracker',
      description: 'Log water intake and earn XP. Tap + to add a glass!',
      targetKey: 'water_tracker',
    ),
    HighlightStep(
      title: 'Bottom Navigation',
      description: 'Explore Feed, Progress, and Trends tabs for more features!',
      targetKey: 'bottom_nav',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkIfShouldShowTutorial();
  }

  Future<void> _checkIfShouldShowTutorial() async {
    if (widget.showTutorial) {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenHighlights = prefs.getBool('has_seen_highlights') ?? false;
      
      if (!hasSeenHighlights && mounted) {
        setState(() {
          _showOverlay = true;
        });
      }
    }
  }

  Future<void> _completeHighlights() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_highlights', true);
    
    if (mounted) {
      setState(() {
        _showOverlay = false;
      });
    }
  }

  void _nextStep() {
    if (_currentStep < _highlights.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _completeHighlights();
    }
  }

  void _skipTutorial() {
    _completeHighlights();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        
        if (_showOverlay)
          _buildOverlay(),
      ],
    );
  }

  Widget _buildOverlay() {
    final colorScheme = Theme.of(context).colorScheme;
    final currentHighlight = _highlights[_currentStep];
    
    return Material(
      color: Colors.black.withOpacity(0.7),
      child: SafeArea(
        child: Stack(
          children: [
            // Skip button
            Positioned(
              top: 16,
              right: 16,
              child: TextButton(
                onPressed: _skipTutorial,
                child: Text(
                  'Skip Tutorial',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            
            // Tooltip
            Positioned(
              bottom: 100,
              left: 24,
              right: 24,
              child: GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.lightbulb_outline,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            currentHighlight.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      currentHighlight.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Step ${_currentStep + 1} of ${_highlights.length}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _nextStep,
                          child: Text(
                            _currentStep == _highlights.length - 1 ? 'Got it!' : 'Next',
                          ),
                        ),
                      ],
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

class HighlightStep {
  final String title;
  final String description;
  final String targetKey;

  HighlightStep({
    required this.title,
    required this.description,
    required this.targetKey,
  });
}
