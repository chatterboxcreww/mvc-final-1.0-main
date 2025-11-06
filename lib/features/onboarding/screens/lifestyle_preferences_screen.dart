// lib/features/onboarding/screens/lifestyle_preferences_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/fluid_page_transitions.dart';
import '../../../core/providers/user_data_provider.dart';
import '../../../core/models/app_enums.dart';
import '../widgets/info_collection_card.dart';
import 'health_info_screen.dart';
import 'dart:math' as math;

class LifestylePreferencesScreen extends StatefulWidget {
  final int suggestedSteps;
  final int suggestedWater;
  final int bmr;

  const LifestylePreferencesScreen({
    super.key,
    required this.suggestedSteps,
    required this.suggestedWater,
    required this.bmr,
  });

  @override
  State<LifestylePreferencesScreen> createState() => _LifestylePreferencesScreenState();
}

class _LifestylePreferencesScreenState extends State<LifestylePreferencesScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _floatingController;
  late AnimationController _pulseController;
  late AnimationController _bounceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;

  bool _isLoading = false;

  // Lifestyle preferences
  DietPreference? _selectedDietPreference;
  bool _prefersCoffee = false;
  bool _prefersTea = false;
  TimeOfDay? _sleepTime;
  TimeOfDay? _wakeupTime;

  @override
  void initState() {
    super.initState();
    // Set full screen immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.elasticOut));

    _floatingAnimation = Tween<double>(
      begin: -12.0,
      end: 12.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
    _floatingController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
    
    // Delayed bounce animation for cards
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _bounceController.forward();
    });
  }

  @override
  void dispose() {
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    _animationController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _continue() async {
    setState(() => _isLoading = true);
    
    // Add haptic feedback
    HapticFeedback.lightImpact();
    
    try {
      final userProvider = context.read<UserDataProvider>();
      
      final lifestyleData = userProvider.userData.copyWith(
        dietPreference: _selectedDietPreference,
        prefersCoffee: _prefersCoffee,
        prefersTea: _prefersTea,
        sleepTime: _sleepTime,
        wakeupTime: _wakeupTime,
      );
      
      print('LIFESTYLE DEBUG: Data to save: ${lifestyleData.toJson()}');
      
      final success = await userProvider.updateUserData(
        lifestyleData,
        isOnboarding: true, // Immediate Firebase sync during onboarding
      );
      
      if (!success) {
        print('LIFESTYLE DEBUG: ❌ Failed to save lifestyle data');
        _showError('Failed to save your preferences. Please try again.');
        setState(() => _isLoading = false);
        return;
      }
      
      print('LIFESTYLE DEBUG: ✅ Lifestyle data saved successfully');

      if (mounted) {
        Navigator.of(context).pushFluid(HealthInfoScreen(
          suggestedSteps: widget.suggestedSteps,
          suggestedWater: widget.suggestedWater,
          bmr: widget.bmr,
        ));
      }
    } catch (e) {
      print('Error saving lifestyle preferences: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _skip() {
    if (mounted) {
      Navigator.of(context).pushFluid(HealthInfoScreen(
        suggestedSteps: widget.suggestedSteps,
        suggestedWater: widget.suggestedWater,
        bmr: widget.bmr,
      ));
    }
  }
  
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _selectTime(BuildContext context, bool isSleepTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isSleepTime 
          ? (_sleepTime ?? const TimeOfDay(hour: 22, minute: 0))
          : (_wakeupTime ?? const TimeOfDay(hour: 6, minute: 0)),
      helpText: isSleepTime ? 'Select your usual bedtime' : 'Select your usual wake-up time',
    );
    
    if (picked != null) {
      setState(() {
        if (isSleepTime) {
          _sleepTime = picked;
        } else {
          _wakeupTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final colorScheme = Theme.of(context).colorScheme;
    final isSmallScreen = screenHeight < 700;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        children: [
          // Animated Background
          AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              return CustomPaint(
                painter: LifestyleBackgroundPainter(
                  animation: _floatingController,
                  colorScheme: colorScheme,
                ),
                size: Size.infinite,
              );
            },
          ),
          
          // Main Content
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Header with full screen support
                  Container(
                    height: MediaQuery.of(context).padding.top + 70,
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 10,
                      left: 20,
                      right: 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF667eea),
                          const Color(0xFF764ba2),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Lifestyle Preferences",
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: isSmallScreen ? 20 : 24,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextButton(
                            onPressed: _skip,
                            child: Text(
                              "Skip",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Content with full screen scrolling
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: isSmallScreen ? 16 : 24),
                            
                            // Animated Header
                            AnimatedBuilder(
                              animation: _floatingAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _floatingAnimation.value * 0.3),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              colorScheme.primary,
                                              colorScheme.secondary,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: colorScheme.primary.withOpacity(0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.tune_rounded,
                                          color: colorScheme.onPrimary,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Customize Your Experience",
                                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                fontSize: isSmallScreen ? 20 : 24,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Help us provide personalized recommendations",
                                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                color: colorScheme.onSurfaceVariant,
                                                fontSize: isSmallScreen ? 14 : 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            
                            SizedBox(height: isSmallScreen ? 24 : 32),
                            
                            // Dietary Preferences with Animation
                            Container(
                                      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            colorScheme.primaryContainer.withOpacity(0.3),
                                            colorScheme.secondaryContainer.withOpacity(0.2),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: colorScheme.outline.withOpacity(0.2),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: colorScheme.shadow.withOpacity(0.1),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.primary.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  Icons.restaurant_menu_rounded,
                                                  color: colorScheme.primary,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "Dietary Preference",
                                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: isSmallScreen ? 18 : 20,
                                                      ),
                                                    ),
                                                    Text(
                                                      "What type of diet do you follow?",
                                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                        color: colorScheme.onSurfaceVariant,
                                                        fontSize: isSmallScreen ? 13 : 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: isSmallScreen ? 16 : 20),
                                          _buildDietOption(DietPreference.vegetarian, "Vegetarian", "Plant-based with dairy", Icons.eco_outlined),
                                          const SizedBox(height: 12),
                                          _buildDietOption(DietPreference.vegan, "Vegan", "Strictly plant-based", Icons.eco),
                                          const SizedBox(height: 12),
                                          _buildDietOption(DietPreference.nonVegetarian, "Non-Vegetarian", "Includes meat, fish, and poultry", Icons.restaurant_outlined),
                                        ],
                                      ),
                                    ),
                            
                            SizedBox(height: isSmallScreen ? 20 : 24),
                            
                            // Beverage Preferences with Animation
                            Container(
                                      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            colorScheme.tertiaryContainer.withOpacity(0.3),
                                            colorScheme.primaryContainer.withOpacity(0.2),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: colorScheme.outline.withOpacity(0.2),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: colorScheme.shadow.withOpacity(0.1),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.tertiary.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  Icons.local_cafe_rounded,
                                                  color: colorScheme.tertiary,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "Beverage Preferences",
                                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: isSmallScreen ? 18 : 20,
                                                      ),
                                                    ),
                                                    Text(
                                                      "Do you enjoy coffee or tea?",
                                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                        color: colorScheme.onSurfaceVariant,
                                                        fontSize: isSmallScreen ? 13 : 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: isSmallScreen ? 16 : 20),
                                          _buildBeverageOption(
                                            "I prefer Coffee",
                                            "Get daily coffee reminders",
                                            Icons.coffee_rounded,
                                            _prefersCoffee,
                                            (value) => setState(() => _prefersCoffee = value ?? false),
                                          ),
                                          const SizedBox(height: 12),
                                          _buildBeverageOption(
                                            "I prefer Tea",
                                            "Get daily tea reminders",
                                            Icons.emoji_food_beverage_rounded,
                                            _prefersTea,
                                            (value) => setState(() => _prefersTea = value ?? false),
                                          ),
                                        ],
                                      ),
                                    ),
                            
                            SizedBox(height: isSmallScreen ? 20 : 24),
                            
                            // Sleep Schedule with Animation
                            Container(
                                      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            colorScheme.secondaryContainer.withOpacity(0.3),
                                            colorScheme.tertiaryContainer.withOpacity(0.2),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: colorScheme.outline.withOpacity(0.2),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: colorScheme.shadow.withOpacity(0.1),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.secondary.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  Icons.bedtime_rounded,
                                                  color: colorScheme.secondary,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "Sleep Schedule",
                                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: isSmallScreen ? 18 : 20,
                                                      ),
                                                    ),
                                                    Text(
                                                      "Help us track your sleep patterns",
                                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                        color: colorScheme.onSurfaceVariant,
                                                        fontSize: isSmallScreen ? 13 : 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: isSmallScreen ? 16 : 20),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _buildTimeSelector(
                                                  "Bedtime",
                                                  _sleepTime,
                                                  Icons.bedtime_outlined,
                                                  () => _selectTime(context, true),
                                                  isSmallScreen,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: _buildTimeSelector(
                                                  "Wake-up Time",
                                                  _wakeupTime,
                                                  Icons.wb_sunny_outlined,
                                                  () => _selectTime(context, false),
                                                  isSmallScreen,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (_sleepTime != null && _wakeupTime != null) ...[
                                            const SizedBox(height: 16),
                                            Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    colorScheme.primaryContainer.withOpacity(0.5),
                                                    colorScheme.primaryContainer.withOpacity(0.3),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: colorScheme.primary.withOpacity(0.3),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: colorScheme.primary.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Icon(
                                                      Icons.schedule_rounded,
                                                      color: colorScheme.primary,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          "Sleep Duration",
                                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                            color: colorScheme.onPrimaryContainer,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                        Text(
                                                          _calculateSleepDuration(),
                                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                            color: colorScheme.primary,
                                                            fontWeight: FontWeight.w700,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: _getSleepQualityColor().withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      _getSleepQualityText(),
                                                      style: TextStyle(
                                                        color: _getSleepQualityColor(),
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                            
                            const SizedBox(height: 32),
                            
                            // Continue Button with Animation
                            SizedBox(height: isSmallScreen ? 24 : 32),
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _isLoading ? 1.0 : _pulseAnimation.value,
                                  child: ModernButton(
                                    text: "Continue to Health Information",
                                    icon: Icons.arrow_forward_rounded,
                                    onPressed: _isLoading ? null : _continue,
                                    isLoading: _isLoading,
                                  ),
                                );
                              },
                            ),
                            
                            SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDietOption(DietPreference preference, String title, String description, IconData icon) {
    final isSelected = _selectedDietPreference == preference;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: isSelected 
            ? colorScheme.primaryContainer 
            : colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected 
              ? colorScheme.primary 
              : colorScheme.outline.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            print('Diet option tapped: $title');
            HapticFeedback.selectionClick();
            setState(() {
              _selectedDietPreference = preference;
              print('Selected diet preference: $_selectedDietPreference');
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isSelected 
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected 
                        ? colorScheme.primary 
                        : colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: isSelected 
                              ? colorScheme.primary 
                              : colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected 
                              ? colorScheme.onPrimaryContainer 
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: colorScheme.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBeverageOption(String title, String subtitle, IconData icon, bool value, Function(bool?) onChanged) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: value ? [
            colorScheme.primaryContainer.withOpacity(0.5),
            colorScheme.primaryContainer.withOpacity(0.3),
          ] : [
            colorScheme.surfaceContainerHighest.withOpacity(0.3),
            colorScheme.surfaceContainerHighest.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value 
              ? colorScheme.primary.withOpacity(0.5)
              : colorScheme.outline.withOpacity(0.3),
          width: value ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            print('Beverage option tapped: $title, current value: $value');
            HapticFeedback.selectionClick();
            onChanged(!value);
            print('New value: ${!value}');
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (value ? colorScheme.primary : colorScheme.onSurfaceVariant).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: value ? colorScheme.primary : colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: value ? colorScheme.primary : colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: value ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: value ? colorScheme.primary : Colors.transparent,
                    border: Border.all(
                      color: value ? colorScheme.primary : colorScheme.outline,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: value
                      ? Icon(
                          Icons.check,
                          color: colorScheme.onPrimary,
                          size: 16,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSelector(String label, TimeOfDay? time, IconData icon, VoidCallback onTap, bool isSmallScreen) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: time != null ? [
            colorScheme.primaryContainer.withOpacity(0.4),
            colorScheme.primaryContainer.withOpacity(0.2),
          ] : [
            colorScheme.surfaceContainerHighest.withOpacity(0.3),
            colorScheme.surfaceContainerHighest.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: time != null
              ? colorScheme.primary.withOpacity(0.5)
              : colorScheme.outline.withOpacity(0.3),
          width: time != null ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            print('Time selector tapped: $label');
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: time != null
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      size: isSmallScreen ? 18 : 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: isSmallScreen ? 13 : 14,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 6 : 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: time != null 
                        ? colorScheme.primary.withOpacity(0.1)
                        : colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    time != null 
                        ? time!.format(context)
                        : "Tap to select",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: time != null
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      fontWeight: time != null ? FontWeight.w700 : FontWeight.w500,
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _calculateSleepDuration() {
    if (_sleepTime == null || _wakeupTime == null) return "";
    
    // Calculate sleep duration
    int sleepMinutes = _sleepTime!.hour * 60 + _sleepTime!.minute;
    int wakeMinutes = _wakeupTime!.hour * 60 + _wakeupTime!.minute;
    
    int durationMinutes;
    if (wakeMinutes >= sleepMinutes) {
      // Same day
      durationMinutes = wakeMinutes - sleepMinutes;
    } else {
      // Next day
      durationMinutes = (24 * 60) - sleepMinutes + wakeMinutes;
    }
    
    int hours = durationMinutes ~/ 60;
    int minutes = durationMinutes % 60;
    
    if (minutes == 0) {
      return "${hours}h";
    } else {
      return "${hours}h ${minutes}m";
    }
  }

  Color _getSleepQualityColor() {
    if (_sleepTime == null || _wakeupTime == null) return Theme.of(context).colorScheme.primary;
    
    final duration = _getSleepDurationInHours();
    final colorScheme = Theme.of(context).colorScheme;
    
    if (duration >= 7 && duration <= 9) {
      return Colors.green; // Optimal
    } else if (duration >= 6 && duration < 7 || duration > 9 && duration <= 10) {
      return Colors.orange; // Acceptable
    } else {
      return Colors.red; // Poor
    }
  }

  String _getSleepQualityText() {
    if (_sleepTime == null || _wakeupTime == null) return "";
    
    final duration = _getSleepDurationInHours();
    
    if (duration >= 7 && duration <= 9) {
      return "Optimal";
    } else if (duration >= 6 && duration < 7 || duration > 9 && duration <= 10) {
      return "Good";
    } else {
      return "Needs Improvement";
    }
  }

  double _getSleepDurationInHours() {
    if (_sleepTime == null || _wakeupTime == null) return 0;
    
    int sleepMinutes = _sleepTime!.hour * 60 + _sleepTime!.minute;
    int wakeMinutes = _wakeupTime!.hour * 60 + _wakeupTime!.minute;
    
    int durationMinutes;
    if (wakeMinutes >= sleepMinutes) {
      durationMinutes = wakeMinutes - sleepMinutes;
    } else {
      durationMinutes = (24 * 60) - sleepMinutes + wakeMinutes;
    }
    
    return durationMinutes / 60.0;
  }
}

// Custom Painter for Animated Background
class LifestyleBackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  final ColorScheme colorScheme;

  LifestyleBackgroundPainter({
    required this.animation,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create gradient background
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF667eea),
        const Color(0xFF764ba2),
      ],
    );

    final backgroundPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height * 0.4),
      );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.4),
      backgroundPaint,
    );

    // Draw floating lifestyle-related shapes
    final shapePaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final progress = animation.value;
    
    // Animated food/lifestyle elements
    _drawLifestyleElements(canvas, size, shapePaint, progress);
  }

  void _drawLifestyleElements(Canvas canvas, Size size, Paint paint, double progress) {
    // Coffee cup shape
    final coffeeX = size.width * 0.15 + math.sin(progress * 2 * math.pi) * 15;
    final coffeeY = size.height * 0.2 + math.cos(progress * 2 * math.pi) * 10;
    
    final coffeePath = Path();
    coffeePath.addRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(coffeeX, coffeeY), width: 30, height: 35),
      const Radius.circular(8),
    ));
    // Add handle
    coffeePath.addOval(Rect.fromCenter(
      center: Offset(coffeeX + 20, coffeeY),
      width: 12,
      height: 20,
    ));
    canvas.drawPath(coffeePath, paint);

    // Leaf shape (for vegetarian/vegan)
    final leafX = size.width * 0.8 + math.cos(progress * 2 * math.pi + 1) * 20;
    final leafY = size.height * 0.15 + math.sin(progress * 2 * math.pi + 1) * 12;
    
    final leafPath = Path();
    leafPath.moveTo(leafX, leafY + 15);
    leafPath.quadraticBezierTo(leafX - 15, leafY, leafX, leafY - 15);
    leafPath.quadraticBezierTo(leafX + 15, leafY, leafX, leafY + 15);
    canvas.drawPath(leafPath, paint);

    // Moon shape (for sleep)
    final moonX = size.width * 0.9 + math.sin(progress * 2 * math.pi + 2) * 8;
    final moonY = size.height * 0.3 + math.cos(progress * 2 * math.pi + 2) * 6;
    
    canvas.drawCircle(Offset(moonX, moonY), 20, paint);
    canvas.drawCircle(Offset(moonX + 8, moonY - 8), 18, Paint()..color = const Color(0xFF667eea));

    // Decorative dots
    for (int i = 0; i < 8; i++) {
      final dotX = size.width * (0.1 + i * 0.1) + math.sin(progress * 2 * math.pi + i) * 5;
      final dotY = size.height * 0.05 + math.cos(progress * 2 * math.pi + i) * 3;
      canvas.drawCircle(Offset(dotX, dotY), 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
