// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\home\widgets\profile_components\app_theme_card.dart

// lib/features/home/widgets/profile_components/app_theme_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/theme_provider.dart';

class AppThemeCard extends StatelessWidget {
  const AppThemeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('App Theme',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            Divider(height: 20, thickness: 1, color: colorScheme.outline),
            _buildThemeOption(
                context, 'System Default', AppThemeMode.system, themeProvider),
            _buildThemeOption(
                context, 'Light Theme', AppThemeMode.light, themeProvider),
            _buildThemeOption(
                context, 'Dark Theme', AppThemeMode.dark, themeProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
      BuildContext context, String title, AppThemeMode mode, ThemeProvider themeProvider) {
    final bool isSelected = themeProvider.themeMode == mode.toThemeMode();
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    Color backgroundColor = isSelected 
        ? colorScheme.secondaryContainer 
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
    Color foregroundColor = isSelected 
        ? colorScheme.onSecondaryContainer 
        : colorScheme.onSurfaceVariant;

    IconData icon;
    switch (mode) {
      case AppThemeMode.system:
        icon = Icons.settings_brightness_outlined;
        break;
      case AppThemeMode.light:
        icon = Icons.light_mode_outlined;
        break;
      case AppThemeMode.dark:
        icon = Icons.dark_mode_outlined;
        break;
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
            color: isSelected ? colorScheme.secondary : colorScheme.outline),
      ),
      child: InkWell(
        onTap: () => themeProvider.setThemeMode(mode),
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Icon(icon, color: foregroundColor),
              const SizedBox(width: 16),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: foregroundColor),
              ),
              const Spacer(),
              if (isSelected) Icon(Icons.check_circle, color: foregroundColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
