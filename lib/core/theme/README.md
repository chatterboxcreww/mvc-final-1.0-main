# Material 3 Theme System

This directory contains the complete Material 3 theme implementation for the Health-TRKD app.

## Files Overview

### Core Theme Files

- **`theme.dart`** - Main theme configuration with light and dark themes
- **`colors.dart`** - Material 3 color schemes and semantic colors
- **`typography.dart`** - Material 3 text styles and typography scale
- **`shapes.dart`** - Material 3 shape system (border radius, shapes)

### Utilities

- **`animations.dart`** - Material 3 motion and animation constants
- **`responsive.dart`** - Responsive layout utilities and breakpoints
- **`accessibility.dart`** - WCAG AA accessibility helpers
- **`dynamic_color_helper.dart`** - Android 12+ dynamic color support

### Legacy Files

- **`performance_theme_config.dart`** - Legacy theme config (kept for reference)

## Usage

### Basic Theme Usage

```dart
import 'package:mvc/core/theme/theme.dart';

// In MaterialApp
MaterialApp(
  theme: AppTheme.light(),
  darkTheme: AppTheme.dark(),
  themeMode: ThemeMode.system,
)
```

### Using Colors

```dart
import 'package:mvc/core/theme/colors.dart';

// Access color scheme
final colorScheme = Theme.of(context).colorScheme;

// Use semantic colors
Container(
  color: colorScheme.primary,
  child: Text(
    'Hello',
    style: TextStyle(color: colorScheme.onPrimary),
  ),
)

// Use health-specific colors
Container(color: AppColors.waterBlue)
```

### Using Typography

```dart
import 'package:mvc/core/theme/typography.dart';

// Use Material 3 text styles
Text(
  'Headline',
  style: Theme.of(context).textTheme.headlineLarge,
)

// Use custom text styles
Text(
  '10,000',
  style: AppTypography.statsNumber(colorScheme),
)
```

### Using Shapes

```dart
import 'package:mvc/core/theme/shapes.dart';

// Use predefined shapes
Card(
  shape: AppShapes.cardShape,
  child: content,
)

// Use custom radius
Container(
  decoration: BoxDecoration(
    borderRadius: AppShapes.mediumRadius,
  ),
)
```

### Using Animations

```dart
import 'package:mvc/core/theme/animations.dart';

// Use Material 3 durations and curves
AnimatedContainer(
  duration: AppAnimations.medium2,
  curve: AppAnimations.emphasized,
)

// Use animation extensions
myWidget.fadeIn()
myWidget.scaleIn()
myWidget.slideInFromBottom()
```

### Responsive Layouts

```dart
import 'package:mvc/core/theme/responsive.dart';

// Check window size class
if (context.isCompact) {
  // Phone layout
} else if (context.isMedium) {
  // Tablet portrait
} else {
  // Tablet landscape / Desktop
}

// Get responsive values
final padding = Responsive.getPadding(context);
final columns = Responsive.getGridColumns(context);

// Use responsive extension
Container(
  padding: context.responsivePadding,
)
```

### Accessibility

```dart
import 'package:mvc/core/theme/accessibility.dart';

// Check contrast ratio
final ratio = AccessibilityHelper.contrastRatio(color1, color2);
final meetsAA = AccessibilityHelper.meetsContrastAA(color1, color2);

// Ensure touch target size
AccessibilityHelper.ensureTouchTarget(
  child: IconButton(...),
)

// Add semantic labels
myWidget.withSemanticLabel('Tap to continue')

// Announce to screen readers
AccessibilityHelper.announce(context, 'Task completed');
```

## Material 3 Components

The theme system supports all Material 3 components:

### Buttons
- `FilledButton` - High emphasis
- `ElevatedButton` - Medium emphasis
- `OutlinedButton` - Medium emphasis
- `TextButton` - Low emphasis
- `IconButton` - Icon actions

### Input
- `TextField` - Text input
- `OutlinedTextField` - Outlined text input
- `SearchBar` - Search input

### Containers
- `Card` - Content container
- `ElevatedCard` - Elevated container
- `OutlinedCard` - Outlined container

### Navigation
- `NavigationBar` - Bottom navigation
- `NavigationRail` - Side navigation
- `NavigationDrawer` - Drawer navigation

### Selection
- `Chip` - Compact element
- `FilterChip` - Filter selection
- `InputChip` - Input element
- `AssistChip` - Action element

### Dialogs
- `AlertDialog` - Alert messages
- `DropdownMenu` - Dropdown selection

### Progress
- `LinearProgressIndicator` - Linear progress
- `CircularProgressIndicator` - Circular progress
- `Slider` - Value selection

## Color System

### Light Theme Colors
- Primary: Blue (#1976D2)
- Secondary: Green (#4CAF50)
- Tertiary: Orange (#FF9800)

### Dark Theme Colors
- Primary: Blue (#4361EE)
- Secondary: Pink (#F72585)
- Tertiary: Purple (#7209B7)

### Health-Specific Colors
- Water: Blue
- Steps: Green
- Sleep: Purple
- Food: Orange
- Meditation: Indigo
- Energy: Yellow
- Heart: Red

## Typography Scale

### Display (Largest)
- displayLarge: 57sp
- displayMedium: 45sp
- displaySmall: 36sp

### Headline
- headlineLarge: 32sp
- headlineMedium: 28sp
- headlineSmall: 24sp

### Title
- titleLarge: 22sp
- titleMedium: 16sp
- titleSmall: 14sp

### Body
- bodyLarge: 16sp
- bodyMedium: 14sp
- bodySmall: 12sp

### Label
- labelLarge: 14sp
- labelMedium: 12sp
- labelSmall: 11sp

## Shape Scale

- Extra Small: 4dp
- Small: 8dp
- Medium: 12dp
- Large: 16dp
- Extra Large: 28dp
- Full: Fully rounded

## Animation Durations

- Short: 50-200ms
- Medium: 250-400ms
- Long: 450-600ms
- Extra Long: 700-1000ms

## Responsive Breakpoints

- Compact: < 600dp (Phones)
- Medium: 600-840dp (Tablets portrait)
- Expanded: > 840dp (Tablets landscape, Desktop)

## Accessibility Features

- WCAG AA contrast ratios (4.5:1 minimum)
- Minimum 48dp touch targets
- Semantic labels for screen readers
- Text scaling support (up to 200%)
- High contrast mode support
- Bold text support

## Best Practices

1. Always use `Theme.of(context).colorScheme` for colors
2. Use `Theme.of(context).textTheme` for text styles
3. Use Material 3 components instead of custom widgets
4. Ensure 48dp minimum touch targets
5. Test with text scaling enabled
6. Test in both light and dark modes
7. Use responsive utilities for adaptive layouts
8. Add semantic labels for accessibility
9. Use Material 3 motion curves and durations
10. Follow Material 3 elevation system

## Migration from Old Theme

The old theme system has been replaced with this Material 3 implementation. Key changes:

1. Color schemes now use Material 3 tokens
2. Typography uses Material 3 scale
3. Shapes use Material 3 border radius
4. All components updated to Material 3 variants
5. Added responsive layout support
6. Added accessibility helpers
7. Added animation constants

All existing functionality remains the same - only the visual appearance has been updated to Material 3.
