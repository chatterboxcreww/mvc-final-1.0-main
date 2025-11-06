# Glass Morphism Theme Guide

This guide explains how to use the glass-morphism components consistently across the Health-TRKD app.

## Core Components

### 1. GlassContainer
Basic glass-morphism container with blur effect.

```dart
GlassContainer(
  borderRadius: 20,
  blur: 10,
  opacity: 0.1,
  padding: EdgeInsets.all(16),
  gradientColors: [
    Colors.white.withOpacity(0.15),
    Colors.white.withOpacity(0.05),
  ],
  border: Border.all(
    color: Colors.white.withOpacity(0.2),
    width: 1.5,
  ),
  child: YourWidget(),
)
```

**Properties:**
- `borderRadius`: Corner radius (default: 20)
- `blur`: Blur intensity (default: 10)
- `opacity`: Background opacity (default: 0.1)
- `padding`: Internal padding
- `margin`: External margin
- `gradientColors`: Custom gradient colors
- `border`: Custom border
- `onTap`: Tap callback
- `shape`: BoxShape.rectangle or BoxShape.circle

### 2. GlassCard
Pre-styled card with elevation and glass effect.

```dart
GlassCard(
  child: Column(
    children: [
      Text('Title'),
      Text('Content'),
    ],
  ),
)
```

**Properties:**
- `borderRadius`: Corner radius (default: 24)
- `padding`: Internal padding (default: 20)
- `margin`: External margin
- `onTap`: Tap callback
- `elevation`: Shadow elevation (default: 8)

### 3. GlassButton
Glass-styled button with ripple effect.

```dart
GlassButton(
  text: 'Click Me',
  icon: Icons.check,
  onPressed: () {},
  isPrimary: true,
  isLoading: false,
)
```

**Properties:**
- `text`: Button text (required)
- `onPressed`: Tap callback
- `icon`: Optional icon
- `isPrimary`: Primary or secondary style (default: true)
- `isLoading`: Show loading indicator (default: false)
- `borderRadius`: Corner radius (default: 16)
- `padding`: Internal padding

### 4. GlassAppBar
Glass-styled app bar with blur effect.

```dart
Scaffold(
  appBar: GlassAppBar(
    title: 'Screen Title',
    actions: [
      IconButton(icon: Icon(Icons.settings), onPressed: () {}),
    ],
  ),
  body: YourContent(),
)
```

**Properties:**
- `title`: App bar title (required)
- `actions`: Action widgets
- `leading`: Leading widget
- `centerTitle`: Center the title (default: false)
- `elevation`: Shadow elevation (default: 0)

### 5. GlassBottomNavigationBar
Glass-styled bottom navigation bar.

```dart
GlassBottomNavigationBar(
  currentIndex: _currentIndex,
  onTap: (index) => setState(() => _currentIndex = index),
  items: [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
  ],
)
```

**Properties:**
- `currentIndex`: Current selected index (required)
- `onTap`: Index change callback (required)
- `items`: Navigation items (required)

### 6. GlassBackground
Animated background with floating orbs.

```dart
class MyScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlassBackground(
        animation: _animationController,
        orbColors: [
          Colors.blue,
          Colors.purple,
          Colors.pink,
        ],
        child: YourContent(),
      ),
    );
  }
}
```

**Properties:**
- `child`: Content widget (required)
- `animation`: Animation controller for orb movement
- `orbColors`: Custom orb colors

## Usage Patterns

### Pattern 1: Screen with Glass Background

```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(title: 'My Screen'),
      body: Stack(
        children: [
          // Glass background
          Positioned.fill(
            child: CustomPaint(
              painter: GlassBackgroundPainter(
                animation: _controller,
                colorScheme: Theme.of(context).colorScheme,
              ),
            ),
          ),
          // Content
          SafeArea(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                GlassCard(
                  child: Text('Card 1'),
                ),
                GlassCard(
                  child: Text('Card 2'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### Pattern 2: List with Glass Cards

```dart
ListView.builder(
  padding: EdgeInsets.all(16),
  itemCount: items.length,
  itemBuilder: (context, index) {
    return GlassCard(
      margin: EdgeInsets.only(bottom: 12),
      onTap: () => handleTap(items[index]),
      child: Row(
        children: [
          Icon(items[index].icon),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(items[index].title),
                Text(items[index].subtitle),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios),
        ],
      ),
    );
  },
)
```

### Pattern 3: Form with Glass Inputs

```dart
GlassCard(
  child: Column(
    children: [
      TextField(
        decoration: InputDecoration(
          labelText: 'Name',
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
        ),
      ),
      SizedBox(height: 16),
      TextField(
        decoration: InputDecoration(
          labelText: 'Email',
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
        ),
      ),
      SizedBox(height: 24),
      GlassButton(
        text: 'Submit',
        onPressed: handleSubmit,
        isPrimary: true,
      ),
    ],
  ),
)
```

### Pattern 4: Stats Display

```dart
Row(
  children: [
    Expanded(
      child: GlassContainer(
        padding: EdgeInsets.all(16),
        borderRadius: 16,
        gradientColors: [
          Colors.blue.withOpacity(0.15),
          Colors.blue.withOpacity(0.05),
        ],
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
          width: 1,
        ),
        child: Column(
          children: [
            Icon(Icons.directions_walk, color: Colors.blue),
            SizedBox(height: 8),
            Text('10,000', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Steps'),
          ],
        ),
      ),
    ),
    SizedBox(width: 12),
    Expanded(
      child: GlassContainer(
        padding: EdgeInsets.all(16),
        borderRadius: 16,
        gradientColors: [
          Colors.green.withOpacity(0.15),
          Colors.green.withOpacity(0.05),
        ],
        border: Border.all(
          color: Colors.green.withOpacity(0.2),
          width: 1,
        ),
        child: Column(
          children: [
            Icon(Icons.water_drop, color: Colors.green),
            SizedBox(height: 8),
            Text('8', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Glasses'),
          ],
        ),
      ),
    ),
  ],
)
```

## Design Guidelines

### Opacity Levels
- **Light Mode**: 0.05 - 0.1 (subtle glass effect)
- **Dark Mode**: 0.1 - 0.2 (more pronounced glass effect)

### Blur Intensity
- **Subtle**: 5-10 (for small elements)
- **Medium**: 10-15 (for cards and containers)
- **Strong**: 15-20 (for backgrounds and overlays)

### Border Colors
- **Light Mode**: `Colors.white.withOpacity(0.1-0.2)`
- **Dark Mode**: `Colors.white.withOpacity(0.2-0.3)`

### Gradient Colors
Always use two colors with decreasing opacity:
```dart
gradientColors: [
  baseColor.withOpacity(0.15),
  baseColor.withOpacity(0.05),
]
```

### Color Coding
- **Primary Actions**: Blue/Primary color glass
- **Success**: Green glass
- **Warning**: Orange glass
- **Error**: Red glass
- **Info**: Purple/Indigo glass
- **Neutral**: White/Surface glass

## Accessibility

All glass components support:
- Semantic labels
- Touch target sizes (minimum 48x48)
- High contrast mode
- Screen reader compatibility

Example:
```dart
Semantics(
  label: 'Step tracker card. Current steps: 10000',
  button: true,
  child: GlassCard(
    onTap: () {},
    child: StepTrackerContent(),
  ),
)
```

## Performance Tips

1. **Use RepaintBoundary** for animated glass elements:
```dart
RepaintBoundary(
  child: GlassCard(child: AnimatedContent()),
)
```

2. **Limit blur on low-end devices**:
```dart
final blur = MediaQuery.of(context).size.width > 600 ? 15.0 : 10.0;
```

3. **Cache glass backgrounds**:
```dart
const GlassBackground(
  animation: animation,
  child: content,
)
```

## Migration from Old Components

### Card → GlassCard
```dart
// Before
Card(
  elevation: 4,
  child: Padding(
    padding: EdgeInsets.all(16),
    child: content,
  ),
)

// After
GlassCard(
  child: content,
)
```

### Container → GlassContainer
```dart
// Before
Container(
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.1),
    borderRadius: BorderRadius.circular(16),
  ),
  child: content,
)

// After
GlassContainer(
  borderRadius: 16,
  child: content,
)
```

### ElevatedButton → GlassButton
```dart
// Before
ElevatedButton(
  onPressed: () {},
  child: Text('Click Me'),
)

// After
GlassButton(
  text: 'Click Me',
  onPressed: () {},
)
```

## Examples in the App

Check these files for implementation examples:
- `lib/features/home/widgets/step_tracker_card.dart` - Glass card with stats
- `lib/features/home/widgets/water_tracker_card.dart` - Interactive glass card
- `lib/features/auth/screens/auth_screen.dart` - Glass buttons and containers
- `lib/features/profile/screens/achievements_screen.dart` - Glass background with cards

## Troubleshooting

### Issue: Glass effect not visible
**Solution**: Increase opacity or blur values, check if backdrop filter is supported

### Issue: Performance issues
**Solution**: Reduce blur intensity, use RepaintBoundary, limit animated elements

### Issue: Border not showing
**Solution**: Increase border opacity or width, ensure border color contrasts with background

### Issue: Text not readable
**Solution**: Add text shadows, increase background opacity, use higher contrast colors
