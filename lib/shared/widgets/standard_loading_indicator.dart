// lib/shared/widgets/standard_loading_indicator.dart

import 'package:flutter/material.dart';

/// Standardized loading indicator used throughout the app
class StandardLoadingIndicator extends StatelessWidget {
  final String? message;
  final bool showMessage;
  final double? size;
  final Color? color;

  const StandardLoadingIndicator({
    super.key,
    this.message,
    this.showMessage = true,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size ?? 40,
            height: size ?? 40,
            child: CircularProgressIndicator(
              color: color ?? colorScheme.primary,
              strokeWidth: 3,
            ),
          ),
          if (showMessage && message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Full-screen loading overlay
class StandardLoadingScreen extends StatelessWidget {
  final String message;
  final bool canDismiss;
  final VoidCallback? onDismiss;

  const StandardLoadingScreen({
    super.key,
    required this.message,
    this.canDismiss = false,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StandardLoadingIndicator(
                message: message,
                size: 48,
              ),
              if (canDismiss) ...[
                const SizedBox(height: 32),
                TextButton(
                  onPressed: onDismiss,
                  child: const Text('Cancel'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline loading indicator for cards and sections
class InlineLoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;

  const InlineLoadingIndicator({
    super.key,
    this.message,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        if (message != null) ...[
          const SizedBox(width: 12),
          Text(
            message!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}