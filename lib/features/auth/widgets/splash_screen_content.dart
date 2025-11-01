// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\auth\widgets\splash_screen_content.dart

// lib/features/auth/widgets/splash_screen_content.dart
import 'package:flutter/material.dart';

class SplashScreenContent extends StatelessWidget {
  final String message;
  const SplashScreenContent({super.key, this.message = 'Loading...' });

  @override
  Widget build(BuildContext context){
    Color splashBackgroundColor = Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).scaffoldBackgroundColor
        : Theme.of(context).primaryColor;
    Color splashElementsColor = Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.onSurface
        : Colors.white;
    Color splashSecondaryElementsColor = Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70
        : Colors.white70;

    return Scaffold(
      backgroundColor: splashBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.healing_rounded,
              color: splashElementsColor,
              size: 100.0,
            ),
            const SizedBox(height: 20),
            Text(
              'Health-TRKD',
              style: TextStyle(
                fontSize: 48.0,
                fontWeight: FontWeight.bold,
                color: splashElementsColor,
              ),
            ),
            const SizedBox(height: 30),
            Text(message, style: TextStyle(color: splashSecondaryElementsColor, fontSize: 16)),
            const SizedBox(height: 15),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(splashSecondaryElementsColor),
            ),
          ],
        ),
      ),
    );
  }
}
