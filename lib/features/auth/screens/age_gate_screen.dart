// lib/features/auth/screens/age_gate_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'permission_gate_screen.dart';
import 'dart:math' as math;

/// Neutral Age Gate Screen - Required for Google Play Families Policy
/// This screen collects the user's birthdate to determine age-appropriate content
class AgeGateScreen extends StatefulWidget {
  const AgeGateScreen({super.key});

  @override
  State<AgeGateScreen> createState() => _AgeGateScreenState();
}

class _AgeGateScreenState extends State<AgeGateScreen> with SingleTickerProviderStateMixin {
  DateTime? _selectedDate;
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 120, 1, 1); // 120 years ago
    final lastDate = now; // Today
    
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25, now.month, now.day), // Default to 25 years ago
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select your date of birth',
      cancelText: 'Cancel',
      confirmText: 'Select',
      builder: (context, child) {
        final colorScheme = Theme.of(context).colorScheme;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: colorScheme,
            datePickerTheme: DatePickerThemeData(
              backgroundColor: colorScheme.surface,
              headerBackgroundColor: colorScheme.primary,
              headerForegroundColor: colorScheme.onPrimary,
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return colorScheme.onPrimary;
                }
                return colorScheme.onSurface;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return colorScheme.primary;
                }
                return null;
              }),
              todayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return colorScheme.onPrimary;
                }
                return colorScheme.primary;
              }),
              todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return colorScheme.primary;
                }
                return null;
              }),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      setState(() {
        _selectedDate = selectedDate;
        _errorMessage = null;
      });
    }
  }

  Future<void> _verifyAge() async {
    if (_selectedDate == null) {
      setState(() {
        _errorMessage = 'Please select your date of birth';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final birthDate = _selectedDate!;
      final now = DateTime.now();

      // Calculate age accurately
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month || 
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }

      // Store age and birthdate for content filtering with error handling
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_age', age);
        await prefs.setString('user_birthdate', birthDate.toIso8601String());
        await prefs.setBool('age_verified', true);

        // Determine content filter level
        final isChild = age < 13;
        await prefs.setBool('child_mode', isChild);

        print('AgeGateScreen: Age verification complete - Age: $age, Child mode: $isChild');

        if (mounted) {
          // Navigate to permission gate screen to check permissions
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const PermissionGateScreen(),
            ),
          );
        }
      } catch (storageError) {
        print('AgeGateScreen: Error saving age data: $storageError');
        setState(() {
          _errorMessage = 'Failed to save age information. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('AgeGateScreen: Error in age verification: $e');
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;
    final isVerySmallScreen = size.height < 600;
    final screenWidth = size.width;
    
    // Responsive sizing
    final logoSize = isVerySmallScreen ? 70.0 : (isSmallScreen ? 85.0 : 100.0);
    final horizontalPadding = screenWidth < 360 ? 16.0 : (screenWidth < 400 ? 20.0 : 24.0);
    final cardPadding = isVerySmallScreen ? 16.0 : (isSmallScreen ? 20.0 : 24.0);
    final verticalSpacing = isVerySmallScreen ? 16.0 : (isSmallScreen ? 24.0 : 32.0);
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF833AB4), // Instagram purple
              const Color(0xFFFD1D1D), // Instagram red
              const Color(0xFFFCAF45), // Instagram orange/yellow
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated medical icons background
            ...List.generate(6, (index) {
              final iconTypes = [
                Icons.favorite_rounded,
                Icons.local_hospital_rounded,
                Icons.medical_services_rounded,
                Icons.health_and_safety_rounded,
                Icons.monitor_heart_rounded,
                Icons.medication_rounded,
              ];
              return Positioned(
                left: (index % 3) * size.width / 3,
                top: (index ~/ 3) * size.height / 2,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        math.sin(_animationController.value * 2 * math.pi + index) * 20,
                        math.cos(_animationController.value * 2 * math.pi + index) * 20,
                      ),
                      child: Opacity(
                        opacity: 0.15,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          child: Icon(
                            iconTypes[index],
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: isVerySmallScreen ? 12 : 16,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - 
                      MediaQuery.of(context).padding.top - 
                      MediaQuery.of(context).padding.bottom - 
                      (isVerySmallScreen ? 24 : 32),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Logo/Icon
                      Container(
                        width: logoSize,
                        height: logoSize,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF833AB4),
                              const Color(0xFFFD1D1D),
                              const Color(0xFFFCAF45),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.favorite_rounded,
                          size: logoSize * 0.5,
                          color: Colors.white,
                        ),
                      ),
                      
                      SizedBox(height: verticalSpacing),
                      
                      // Title
                      Text(
                        'Welcome to Health-TRKD',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: isVerySmallScreen ? 20 : (isSmallScreen ? 24 : null),
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.2),
                              offset: const Offset(0, 4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: isVerySmallScreen ? 8 : 12),
                      
                      // Subtitle
                      Text(
                        'To provide you with age-appropriate content,\nplease select your date of birth',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: isVerySmallScreen ? 13 : (isSmallScreen ? 15 : null),
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: isVerySmallScreen ? 24 : (isSmallScreen ? 32 : 48)),
                      
                      // Birthdate Input Card
                      Container(
                        padding: EdgeInsets.all(cardPadding),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(
                          'Date of Birth',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: isVerySmallScreen ? 18 : (isSmallScreen ? 20 : null),
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        
                        SizedBox(height: isVerySmallScreen ? 6 : 8),
                        
                        Text(
                          'Select your birthdate using the calendar',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: isVerySmallScreen ? 13 : null,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        
                        SizedBox(height: isVerySmallScreen ? 16 : 24),
                        
                        // Date Selection Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _selectDate,
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: isVerySmallScreen ? 16 : 20,
                                horizontal: isVerySmallScreen ? 12 : 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: BorderSide(
                                color: _selectedDate != null 
                                    ? colorScheme.primary 
                                    : colorScheme.outline.withOpacity(0.5),
                                width: _selectedDate != null ? 2 : 1,
                              ),
                              backgroundColor: _selectedDate != null 
                                  ? colorScheme.primaryContainer.withOpacity(0.1)
                                  : null,
                            ),
                            icon: Icon(
                              Icons.calendar_today_rounded,
                              color: _selectedDate != null 
                                  ? colorScheme.primary 
                                  : colorScheme.onSurfaceVariant,
                              size: 24,
                            ),
                            label: Text(
                              _selectedDate != null
                                  ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                  : 'Select Date of Birth',
                              style: TextStyle(
                                fontSize: isVerySmallScreen ? 14 : 16,
                                fontWeight: FontWeight.w600,
                                color: _selectedDate != null 
                                    ? colorScheme.primary 
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                          
                        if (_errorMessage != null) ...[
                          SizedBox(height: isVerySmallScreen ? 12 : 16),
                          Container(
                            padding: EdgeInsets.all(isVerySmallScreen ? 10 : 12),
                            decoration: BoxDecoration(
                              color: colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: colorScheme.onErrorContainer,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: colorScheme.onErrorContainer,
                                      fontSize: isVerySmallScreen ? 12 : 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                          
                        SizedBox(height: isVerySmallScreen ? 16 : 24),
                        
                        // Continue Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (_isLoading || _selectedDate == null) ? null : _verifyAge,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              disabledBackgroundColor: colorScheme.surfaceContainerHighest,
                              disabledForegroundColor: colorScheme.onSurfaceVariant,
                              padding: EdgeInsets.symmetric(vertical: isVerySmallScreen ? 14 : 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        colorScheme.onPrimary,
                                      ),
                                    ),
                                  )
                                : Text(
                                    'Continue',
                                    style: TextStyle(
                                      fontSize: isVerySmallScreen ? 14 : 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        
                        SizedBox(height: isVerySmallScreen ? 12 : 16),
                        
                        // Privacy Notice
                        Container(
                          padding: EdgeInsets.all(isVerySmallScreen ? 10 : 12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: colorScheme.primary,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'We collect your date of birth to ensure age-appropriate content and comply with privacy regulations. Your information is kept private and secure.',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: isVerySmallScreen ? 11 : 12,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
