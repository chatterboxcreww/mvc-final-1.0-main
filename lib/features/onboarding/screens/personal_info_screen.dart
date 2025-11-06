// lib/features/onboarding/screens/personal_info_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/fluid_page_transitions.dart';
import '../../../core/providers/user_data_provider.dart';
import '../../../core/models/app_enums.dart';
import '../../../core/models/activity_level.dart';
import '../widgets/info_collection_card.dart';
import 'lifestyle_preferences_screen.dart';
import '../../../core/utils/date_utils.dart';
import 'dart:math' as math;

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _floatingController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _pulseAnimation;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  Gender? _selectedGender;
  ActivityLevel _selectedActivityLevel = ActivityLevel.moderate;
  bool _isLoading = false;
  
  // Date of Birth from Age Gate Screen
  DateTime? _dateOfBirth;
  int? _userAge;

  @override
  void initState() {
    super.initState();
    // Set full screen immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    _initializeAnimations();
    _loadUserData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
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
      begin: -8.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    _floatingController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
  }

  Future<void> _loadUserData() async {
    // Load email from authentication
    final userProvider = context.read<UserDataProvider>();
    final user = userProvider.getCurrentUser();
    print('PersonalInfoScreen: Current user email: ${user?.email}');
    
    // Try multiple sources for email
    String? email = user?.email ?? userProvider.userData.email;
    
    if (email != null && email.isNotEmpty) {
      _emailController.text = email;
      print('PersonalInfoScreen: Email loaded: ${_emailController.text}');
    } else {
      print('PersonalInfoScreen: No email found from any source');
    }

    // Load date of birth from Age Gate Screen
    try {
      final prefs = await SharedPreferences.getInstance();
      final birthdateString = prefs.getString('user_birthdate');
      
      if (birthdateString != null) {
        _dateOfBirth = DateTime.parse(birthdateString);
        // Calculate age dynamically from birthdate using utility function
        _userAge = AppDateUtils.getAge(_dateOfBirth!);
        
        // Debug: Let's check the calculation step by step
        final now = DateTime.now();
        print('PersonalInfoScreen: Current date: $now');
        print('PersonalInfoScreen: Birth date: $_dateOfBirth');
        print('PersonalInfoScreen: Year difference: ${now.year - _dateOfBirth!.year}');
        print('PersonalInfoScreen: Month check: now.month=${now.month}, birth.month=${_dateOfBirth!.month}');
        print('PersonalInfoScreen: Day check: now.day=${now.day}, birth.day=${_dateOfBirth!.day}');
        
        setState(() {});
        print('PersonalInfoScreen: Loaded DOB: $_dateOfBirth, Calculated Age: $_userAge');
      }
    } catch (e) {
      print('PersonalInfoScreen: Error loading birthdate: $e');
    }
  }



  @override
  void dispose() {
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    _animationController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _continue() async {
    debugPrint('Continue button pressed');
    
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      debugPrint('Form validation failed');
      _showErrorSnackBar('Please fill in all required fields correctly');
      return;
    }
    
    // Check if gender is selected
    if (_selectedGender == null) {
      debugPrint('Gender not selected');
      _showErrorSnackBar('Please select your gender');
      return;
    }
    
    // Check if we have date of birth from Age Gate Screen
    if (_dateOfBirth == null) {
      debugPrint('Date of birth not available');
      _showErrorSnackBar('Date of birth information is missing. Please restart the onboarding process.');
      return;
    }
    
    // Calculate current age dynamically using utility function
    final currentAge = AppDateUtils.getAge(_dateOfBirth!);
    
    debugPrint('All validations passed, proceeding...');
    setState(() => _isLoading = true);
    
    // Add haptic feedback
    HapticFeedback.lightImpact();
    
    try {
      final userProvider = context.read<UserDataProvider>();
      
      // Calculate BMR and suggested daily goals using dynamically calculated age
      final height = double.parse(_heightController.text);
      final weight = double.parse(_weightController.text);
      
      final bmr = _calculateBMR(weight, height, currentAge, _selectedGender!);
      final suggestedSteps = _calculateSuggestedSteps(_selectedActivityLevel);
      final suggestedWater = _calculateSuggestedWater(weight);
      
      // Calculate daily calorie goal based on BMR and activity level
      final dailyCalorieGoal = _calculateDailyCalorieGoal(bmr, _selectedActivityLevel);
      
      print('Calculated values - BMR: $bmr, Steps: $suggestedSteps, Water: $suggestedWater, Calories: $dailyCalorieGoal');
      print('Input values - Name: ${_nameController.text}, Email: ${_emailController.text}');
      print('Input values - Age: $currentAge, Height: $height, Weight: $weight');
      print('Input values - Gender: $_selectedGender, Activity: ${_selectedActivityLevel.name}');
      
      // Verify calculations
      print('BMR calculation check: (10 * $weight) + (6.25 * $height) - (5 * $currentAge) + ${_selectedGender == Gender.male ? 5 : -161} = $bmr');
      print('Calorie goal calculation check: $bmr * ${_getActivityMultiplier(_selectedActivityLevel)} = $dailyCalorieGoal');
      
      final personalInfoData = userProvider.userData.copyWith(
        name: _nameController.text,
        email: _emailController.text.isNotEmpty ? _emailController.text : userProvider.userData.email,
        age: currentAge, // Use dynamically calculated age
        height: height,
        weight: weight,
        bmr: bmr,
        gender: _selectedGender,
        activityLevel: _selectedActivityLevel.name,
        dailyStepGoal: suggestedSteps,
        dailyWaterGoal: suggestedWater,
        dailyCalorieGoal: dailyCalorieGoal,
        sleepGoalHours: userProvider.userData.sleepGoalHours ?? 8, // Default 8 hours
        allergies: userProvider.userData.allergies ?? [], // Default empty list
      );
      
      print('PERSONAL INFO DEBUG: Data to save: ${personalInfoData.toJson()}');
      
      final success = await userProvider.updateUserData(
        personalInfoData,
        isOnboarding: true, // Immediate Firebase sync during onboarding
      );

      if (!success) {
        print('PERSONAL INFO DEBUG: ❌ Failed to save personal info data');
        final errorDetails = userProvider.lastError ?? 'Unknown error';
        print('PERSONAL INFO DEBUG: Error details: $errorDetails');
        _showErrorSnackBar('Failed to save: $errorDetails');
        setState(() => _isLoading = false);
        return;
      }
      
      print('PERSONAL INFO DEBUG: ✅ Personal info data saved successfully');
      print('User data updated, navigating to lifestyle preferences...');
      
      if (mounted) {
        Navigator.of(context).pushFluid(LifestylePreferencesScreen(
          suggestedSteps: suggestedSteps,
          suggestedWater: suggestedWater,
          bmr: bmr.round(),
        ));
      }
    } catch (e) {
      print('Error in continue: $e');
      _showErrorSnackBar('An error occurred: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
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

  double _calculateBMR(double weight, double height, int age, Gender gender) {
    // Mifflin-St Jeor Equation
    if (gender == Gender.male) {
      return (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      return (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }
  }

  int _calculateSuggestedSteps(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 6000;
      case ActivityLevel.light:
        return 8000;
      case ActivityLevel.moderate:
        return 10000;
      case ActivityLevel.active:
        return 12000;
      case ActivityLevel.veryActive:
        return 15000;
    }
  }

  int _calculateSuggestedWater(double weight) {
    // 35ml per kg of body weight
    return ((weight * 35) / 250).round(); // Convert to glasses (250ml each)
  }

  int _calculateDailyCalorieGoal(double bmr, ActivityLevel activityLevel) {
    // Apply activity multiplier to BMR
    double multiplier = _getActivityMultiplier(activityLevel);
    return (bmr * multiplier).round();
  }

  double _getActivityMultiplier(ActivityLevel activityLevel) {
    switch (activityLevel) {
      case ActivityLevel.sedentary:
        return 1.2; // Little to no exercise
      case ActivityLevel.light:
        return 1.375; // Light exercise 1-3 days/week
      case ActivityLevel.moderate:
        return 1.55; // Moderate exercise 3-5 days/week
      case ActivityLevel.active:
        return 1.725; // Hard exercise 6-7 days/week
      case ActivityLevel.veryActive:
        return 1.9; // Physical job + exercise
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
                painter: PersonalInfoBackgroundPainter(
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
                            "Personal Information",
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: isSmallScreen ? 20 : 24,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48),
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: isSmallScreen ? 16 : 24),
                              
                              // Animated Header
                              AnimatedBuilder(
                                animation: _floatingAnimation,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(0, _floatingAnimation.value * 0.5),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
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
                                                Icons.person_rounded,
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
                                                    "Let's personalize your experience",
                                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                                      fontWeight: FontWeight.w800,
                                                      fontSize: isSmallScreen ? 20 : 24,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    "Help us calculate your personalized health metrics",
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
                                      ],
                                    ),
                                  );
                                },
                              ),
                              
                              SizedBox(height: isSmallScreen ? 24 : 32),
                              
                              // Date of Birth Display (from Age Gate Screen)
                              if (_dateOfBirth != null)
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  margin: const EdgeInsets.only(bottom: 24),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        colorScheme.primaryContainer.withOpacity(0.3),
                                        colorScheme.secondaryContainer.withOpacity(0.2),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: colorScheme.outline.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.cake_rounded,
                                          color: colorScheme.primary,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Date of Birth",
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}",
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
                                          color: colorScheme.primary,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          "Age: ${AppDateUtils.getAge(_dateOfBirth!)}",
                                          style: TextStyle(
                                            color: colorScheme.onPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              
                              // Basic Info
                              InfoCollectionCard(
                                title: "Basic Information",
                                children: [
                                  _buildTextField(
                                    controller: _nameController,
                                    label: "Full Name",
                                    icon: Icons.person_outline_rounded,
                                    validator: (value) => value?.isEmpty == true ? "Please enter your name" : null,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _emailController,
                                    label: "Email Address",
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    readOnly: true,
                                    validator: (value) {
                                      if (value?.isEmpty == true) return "Please enter your email";
                                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                                        return "Please enter a valid email";
                                      }
                                      return null;
                                    },
                                  ),

                                ],
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Physical Info
                              InfoCollectionCard(
                                title: "Physical Measurements",
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          controller: _heightController,
                                          label: "Height (cm)",
                                          icon: Icons.height_rounded,
                                          keyboardType: TextInputType.number,
                                          validator: (value) {
                                            if (value?.isEmpty == true) return "Required";
                                            final height = double.tryParse(value!);
                                            if (height == null || height < 100 || height > 250) {
                                              return "Invalid height";
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildTextField(
                                          controller: _weightController,
                                          label: "Weight (kg)",
                                          icon: Icons.monitor_weight_outlined,
                                          keyboardType: TextInputType.number,
                                          validator: (value) {
                                            if (value?.isEmpty == true) return "Required";
                                            final weight = double.tryParse(value!);
                                            if (weight == null || weight < 30 || weight > 300) {
                                              return "Invalid weight";
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  // Gender Selection
                                  Text(
                                    "Gender",
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildGenderOption(Gender.male, "Male", Icons.male_rounded),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildGenderOption(Gender.female, "Female", Icons.female_rounded),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Activity Level
                              InfoCollectionCard(
                                title: "Activity Level",
                                subtitle: "This helps us calculate your daily calorie needs",
                                children: [
                                  ...ActivityLevel.values.map((level) => 
                                    _buildActivityLevelOption(level)
                                  ).toList(),
                                ],
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
                                      text: "Continue to Lifestyle Preferences",
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        readOnly: readOnly,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: readOnly ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.error, width: 2),
          ),
          filled: true,
          fillColor: readOnly 
              ? Color.fromRGBO(colorScheme.surfaceContainerHighest.red, colorScheme.surfaceContainerHighest.green, colorScheme.surfaceContainerHighest.blue, 0.3)
              : colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixIcon: readOnly 
              ? Icon(Icons.lock_outline, color: colorScheme.onSurfaceVariant, size: 20)
              : null,
        ),
      ),
    );
  }

  Widget _buildGenderOption(Gender gender, String label, IconData icon) {
    final isSelected = _selectedGender == gender;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
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
            print('Gender option tapped: $label');
            HapticFeedback.selectionClick();
            setState(() {
              _selectedGender = gender;
              print('Selected gender: $_selectedGender');
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected 
                      ? colorScheme.primary 
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isSelected 
                        ? colorScheme.primary 
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityLevelOption(ActivityLevel level) {
    final isSelected = _selectedActivityLevel == level;
    final data = _getActivityLevelData(level);
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            print('Activity level tapped: ${data['title']}');
            HapticFeedback.selectionClick();
            setState(() {
              _selectedActivityLevel = level;
              print('Selected activity level: $_selectedActivityLevel');
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  data['icon'],
                  color: isSelected 
                      ? colorScheme.primary 
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'],
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: isSelected 
                              ? colorScheme.primary 
                              : colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        data['description'],
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

  Map<String, dynamic> _getActivityLevelData(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return {
          'title': 'Sedentary',
          'description': 'Little to no exercise, desk job',
          'icon': Icons.chair_outlined,
        };
      case ActivityLevel.light:
        return {
          'title': 'Lightly Active',
          'description': 'Light exercise 1-3 days/week',
          'icon': Icons.directions_walk_outlined,
        };
      case ActivityLevel.moderate:
        return {
          'title': 'Moderately Active',
          'description': 'Moderate exercise 3-5 days/week',
          'icon': Icons.directions_run_outlined,
        };
      case ActivityLevel.active:
        return {
          'title': 'Very Active',
          'description': 'Hard exercise 6-7 days/week',
          'icon': Icons.fitness_center_outlined,
        };
      case ActivityLevel.veryActive:
        return {
          'title': 'Extremely Active',
          'description': 'Physical job + exercise',
          'icon': Icons.sports_gymnastics_outlined,
        };
    }
  }
}

// Custom Painter for Animated Background
class PersonalInfoBackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  final ColorScheme colorScheme;

  PersonalInfoBackgroundPainter({
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

    // Draw floating geometric shapes
    final shapePaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Animated circles
    final progress = animation.value;
    
    // Circle 1
    final circle1X = size.width * 0.1 + math.sin(progress * 2 * math.pi) * 20;
    final circle1Y = size.height * 0.15 + math.cos(progress * 2 * math.pi) * 15;
    canvas.drawCircle(Offset(circle1X, circle1Y), 30, shapePaint);

    // Circle 2
    final circle2X = size.width * 0.8 + math.cos(progress * 2 * math.pi + 1) * 25;
    final circle2Y = size.height * 0.25 + math.sin(progress * 2 * math.pi + 1) * 20;
    canvas.drawCircle(Offset(circle2X, circle2Y), 20, shapePaint);

    // Draw decorative lines
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.1);
    path.quadraticBezierTo(
      size.width * 0.5, size.height * 0.2,
      size.width * 0.8, size.height * 0.15,
    );
    canvas.drawPath(path, linePaint);

    // Draw health-related icons as background elements
    final iconPaint = Paint()
      ..color = Colors.white.withOpacity(0.03);

    // Draw simple health symbols
    _drawHealthSymbols(canvas, size, iconPaint, progress);
  }

  void _drawHealthSymbols(Canvas canvas, Size size, Paint paint, double progress) {
    // Draw a simple heart shape
    final heartPath = Path();
    final heartSize = 40.0;
    final heartX = size.width * 0.9 + math.sin(progress * 2 * math.pi) * 10;
    final heartY = size.height * 0.1 + math.cos(progress * 2 * math.pi) * 8;

    heartPath.moveTo(heartX, heartY + heartSize * 0.3);
    heartPath.cubicTo(
      heartX - heartSize * 0.5, heartY - heartSize * 0.1,
      heartX - heartSize * 0.5, heartY + heartSize * 0.3,
      heartX, heartY + heartSize * 0.7,
    );
    heartPath.cubicTo(
      heartX + heartSize * 0.5, heartY + heartSize * 0.3,
      heartX + heartSize * 0.5, heartY - heartSize * 0.1,
      heartX, heartY + heartSize * 0.3,
    );

    canvas.drawPath(heartPath, paint);

    // Draw a simple plus symbol
    final plusSize = 25.0;
    final plusX = size.width * 0.15 + math.cos(progress * 2 * math.pi + 2) * 15;
    final plusY = size.height * 0.3 + math.sin(progress * 2 * math.pi + 2) * 12;

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(plusX, plusY),
        width: plusSize,
        height: plusSize * 0.3,
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(plusX, plusY),
        width: plusSize * 0.3,
        height: plusSize,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
