// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\home\widgets\profile_components\profile_detail_widgets.dart

// lib/features/home/widgets/profile_components/profile_detail_widgets.dart
import 'package:flutter/material.dart';

class ProfileDetailRow extends StatelessWidget {
  final String label;
  final String? value;
  final Color? valueColor;
  final IconData? icon;

  const ProfileDetailRow({
    super.key,
    required this.label,
    this.value,
    this.valueColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Icon(icon,
                size: 20,
                color: Color.fromRGBO(colorScheme.onSurfaceVariant.red, colorScheme.onSurfaceVariant.green, colorScheme.onSurfaceVariant.blue, 0.7)),
          if (icon != null) const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text('$label:',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value ?? 'Not set',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: valueColor ??
                      (value == null || value == 'Not set'
                          ? colorScheme.onSurfaceVariant.withValues(alpha: 0.8)
                          : colorScheme.onSurface)),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileCheckmarkRow extends StatelessWidget {
  final String label;
  final bool? value;
  final IconData? icon;

  const ProfileCheckmarkRow({
    super.key,
    required this.label,
    this.value,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    IconData displayIcon;
    Color iconColor;
    String displayText;
    if (value == true) {
      displayIcon = Icons.check_circle_outline_rounded;
      iconColor = colorScheme.primary;
      displayText = 'Yes';
    } else if (value == false) {
      displayIcon = Icons.highlight_off_rounded;
      iconColor = colorScheme.error;
      displayText = 'No';
    } else {
      displayIcon = Icons.help_outline_rounded;
      iconColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.8);
      displayText = 'Not set';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null)
            Icon(icon,
                size: 20,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
          if (icon != null) const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text('$label:',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Icon(displayIcon, color: iconColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  displayText,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: iconColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
