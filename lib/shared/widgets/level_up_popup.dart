// lib/shared/widgets/level_up_popup.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LevelUpPopup extends StatefulWidget {
  final int newLevel;
  final int xpGained;
  final String? achievement;
  final VoidCallback? onClose;

  const LevelUpPopup({
    super.key,
    required this.newLevel,
    required this.xpGained,
    this.achievement,
    this.onClose,
  });

  @override
  State<LevelUpPopup> createState() => _LevelUpPopupState();
}

class _LevelUpPopupState extends State<LevelUpPopup> {
  @override
  void initState() {
    super.initState();
    
    // Trigger haptic feedback
    HapticFeedback.heavyImpact();
    
    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onClose?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Simple trophy icon
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber,
                      Colors.orange,
                      Colors.amber,
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Congratulations text
              Text(
                "🎉 Congratulations! 🎉",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Level up message
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyLarge,
                  children: [
                    const TextSpan(text: "You've reached "),
                    TextSpan(
                      text: "Level ${widget.newLevel}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 18,
                      ),
                    ),
                    const TextSpan(text: "!"),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // XP gained
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "+${widget.xpGained} XP",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              
              if (widget.achievement != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.military_tech,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Achievement Unlocked:",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        widget.achievement!,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onClose?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Continue",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper function to show the popup
Future<void> showLevelUpPopup(
  BuildContext context, {
  required int newLevel,
  required int xpGained,
  String? achievement,
  VoidCallback? onClose,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => LevelUpPopup(
      newLevel: newLevel,
      xpGained: xpGained,
      achievement: achievement,
      onClose: onClose,
    ),
  );
}
