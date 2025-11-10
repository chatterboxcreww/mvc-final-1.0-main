// lib/shared/widgets/health_card.dart
import 'package:flutter/material.dart';

class HealthCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool elevated;
  final IconData? leadingIcon;
  final Color? iconColor;

  const HealthCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.padding,
    this.onTap,
    this.elevated = true,
    this.leadingIcon,
    this.iconColor,
  });

  // Compact variant with minimal padding
  const HealthCard.compact({
    super.key,
    required this.child,
    this.backgroundColor,
    EdgeInsetsGeometry? padding,
    this.onTap,
    this.elevated = false,
    this.leadingIcon,
    this.iconColor,
  }) : padding = padding ?? const EdgeInsets.all(12.0);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: elevated ? 8 : 2,
      color: backgroundColor ?? colorScheme.surface,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24), // More rounded for modern look
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (backgroundColor ?? colorScheme.surface).withValues(alpha: 0.95),
                  (backgroundColor ?? colorScheme.surface),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: padding ?? const EdgeInsets.all(16.0),
            child: leadingIcon != null
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (iconColor ?? colorScheme.primary).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          leadingIcon,
                          color: iconColor ?? colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: child),
                    ],
                  )
                : child,
          ),
        ),
      ),
    );
  }
}
