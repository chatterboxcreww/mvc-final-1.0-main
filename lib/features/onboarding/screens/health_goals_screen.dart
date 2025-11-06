// lib/features/onboarding/screens/health_goals_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/fluid_page_transitions.dart';
import '../../../core/providers/user_data_provider.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/auth_service.dart';
import '../../auth/screens/auth_wrapper.dart';
import '../../home/screens/home_page.dart';
import '../widgets/goal_adjustment_card.dart';
import '../widgets/health_metric_card.dart' as dedicated;
import 'dart:math' as math;

class HealthGoalsScreen extends StatefulWidget {
  final int suggestedSteps;
  final int suggestedWater;
  final int bmr;

  const HealthGoalsScreen({
    super.key,
    required this.suggestedSteps,
    required this.suggestedWater,
    required this.bmr,
  });

  @override
  State<HealthGoalsScreen> createState() => _HealthGoalsScreenState();
}

class _HealthGoalsScreenState extends State<HealthGoalsScreen>
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

  late int _stepGoal;
  late int _waterGoal;
  late int _calorieGoal;
  late int _sleepGoal = 8; // hours
  
  bool _isLoading = false;
  
  // User data for calculations
  double? _userHeight;
  double? _userWeight;
  String? _userGender;
  int? _userAge;

  @override
  void initState() {
    super.initState();
    // Set full screen immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    _stepGoal = widget.suggestedSteps;
    _waterGoal = widget.suggestedWater;
    _calorieGoal = widget.bmr + 500; // BMR + activity calories
    
    _loadUserData();
    _initializeAnimations();
  }

  void _loadUserData() {
    final userProvider = context.read<UserDataProvider>();
    final userData = userProvider.userData;
    
    _userHeight = userData.height;
    _userWeight = userData.weight;
    _userGender = userData.gender?.name;
    _userAge = userData.age;
    
    print('HealthGoals: Loaded user data - Height: $_userHeight, Weight: $_userWeight, Gender: $_userGender, Age: $_userAge');
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

  void _showGoalInfo(String title, String description, String calculation, String additionalInfo) {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.info_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "What is it?",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                "How it's calculated:",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  calculation,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (additionalInfo.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  "Good to know:",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  additionalInfo,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Got it',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateBMI() {
    if (_userHeight == null || _userWeight == null) return 0.0;
    final heightInMeters = _userHeight! / 100;
    return _userWeight! / (heightInMeters * heightInMeters);
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return "Underweight";
    if (bmi < 25) return "Normal";
    if (bmi < 30) return "Overweight";
    return "Obese";
  }

  String _getBMRCalculationFormula() {
    if (_userGender == null || _userHeight == null || _userWeight == null || _userAge == null) {
      return "BMR calculation requires complete user data";
    }
    
    if (_userGender!.toLowerCase() == 'male') {
      return "Men: BMR = (10 × ${_userWeight}kg) + (6.25 × ${_userHeight}cm) - (5 × ${_userAge}years) + 5\n"
             "BMR = ${(10 * _userWeight! + 6.25 * _userHeight! - 5 * _userAge! + 5).round()} calories/day";
    } else {
      return "Women: BMR = (10 × ${_userWeight}kg) + (6.25 × ${_userHeight}cm) - (5 × ${_userAge}years) - 161\n"
             "BMR = ${(10 * _userWeight! + 6.25 * _userHeight! - 5 * _userAge! - 161).round()} calories/day";
    }
  }

  void _finishOnboarding() async {
    setState(() => _isLoading = true);
    
    final userProvider = context.read<UserDataProvider>();
    final storageService = StorageService();
    
    try {
      print('HEALTH GOALS DEBUG: Starting onboarding completion process');
      print('HEALTH GOALS DEBUG: Current user data BEFORE update: ${userProvider.userData.toJson()}');
      
      // Update user data with health goals
      final updatedUserData = userProvider.userData.copyWith(
        dailyStepGoal: _stepGoal,
        dailyWaterGoal: _waterGoal,
        dailyCalorieGoal: _calorieGoal,
        sleepGoalHours: _sleepGoal,
      );
      
      print('HEALTH GOALS DEBUG: Updating with goals - Steps: $_stepGoal, Water: $_waterGoal, Calories: $_calorieGoal, Sleep: $_sleepGoal');
      print('HEALTH GOALS DEBUG: Complete data AFTER copyWith: ${updatedUserData.toJson()}');
      
      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Saving your data to server...'),
                  SizedBox(height: 8),
                  Text(
                    'Please wait, this may take a moment',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      
      // CRITICAL: Update with isOnboarding flag - this handles BOTH local AND Firebase sync
      bool result = false;
      try {
        print('HEALTH GOALS DEBUG: 🔥 Saving to local storage and Firebase...');
        result = await userProvider.updateUserData(updatedUserData, isOnboarding: true);
      } catch (e) {
        print('HEALTH GOALS DEBUG: ❌ Exception during save: $e');
        if (mounted) Navigator.of(context).pop(); // Close loading dialog
        _showError('Error saving health goals: ${e.toString()}');
        setState(() => _isLoading = false);
        return;
      }
      
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      if (!result) {
        print('HEALTH GOALS DEBUG: ❌ Failed to save health goals');
        final errorMsg = userProvider.lastError ?? 'Unknown error';
        print('HEALTH GOALS DEBUG: Error details: $errorMsg');
        
        // Determine error type and show appropriate message
        String userFriendlyMessage;
        if (errorMsg.contains('Validation')) {
          userFriendlyMessage = 'Please check your information:\n$errorMsg';
        } else if (errorMsg.contains('timeout') || errorMsg.contains('connection') || errorMsg.contains('network')) {
          userFriendlyMessage = 'Connection timeout. Please check your internet connection and try again.';
        } else if (errorMsg.contains('server') || errorMsg.contains('Firebase')) {
          userFriendlyMessage = 'Server error. Please try again in a moment.';
        } else if (errorMsg.contains('authenticated')) {
          userFriendlyMessage = 'Authentication error. Please sign in again.';
        } else {
          userFriendlyMessage = 'Failed to save your data: $errorMsg';
        }
        
        // Show specific error message with retry option
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                  SizedBox(width: 8),
                  Text('Save Failed'),
                ],
              ),
              content: Text(userFriendlyMessage),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() => _isLoading = false);
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _finishOnboarding(); // Retry
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        setState(() => _isLoading = false);
        return;
      }
      
      print('HEALTH GOALS DEBUG: ✅✅✅ Health goals saved to local storage AND Firebase successfully!');
      
      // Mark onboarding as complete
      await storageService.setOnboardingComplete(true);
      print('HEALTH GOALS DEBUG: Onboarding marked as complete');
      
      // Verify onboarding is complete
      final isComplete = await storageService.isOnboardingComplete();
      print('HEALTH GOALS DEBUG: Onboarding completion verified: $isComplete');
      
      if (!isComplete) {
        print('HEALTH GOALS DEBUG: Warning - onboarding flag not set properly, retrying...');
        await storageService.setOnboardingComplete(true);
        final retryCheck = await storageService.isOnboardingComplete();
        print('HEALTH GOALS DEBUG: Retry verification: $retryCheck');
      }
      
      // Verify the data was actually saved
      final verifyData = userProvider.userData;
      print('HEALTH GOALS DEBUG: Verifying saved data:');
      print('  - Name: ${verifyData.name}');
      print('  - Age: ${verifyData.age}');
      print('  - Height: ${verifyData.height}');
      print('  - Weight: ${verifyData.weight}');
      print('  - Gender: ${verifyData.gender}');
      print('  - Step Goal: ${verifyData.dailyStepGoal}');
      print('  - Water Goal: ${verifyData.dailyWaterGoal}');
      print('  - Calorie Goal: ${verifyData.dailyCalorieGoal}');
      print('  - Sleep Goal: ${verifyData.sleepGoalHours}');
      print('  - isProfileComplete: ${verifyData.isProfileComplete}');
      
      setState(() => _isLoading = false);
      
      if (mounted) {
        print('HEALTH GOALS DEBUG: Navigating to home screen');
        // Navigate to home page directly instead of AuthWrapper
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      }
    } catch (e, stackTrace) {
      print('HEALTH GOALS DEBUG: Error during onboarding completion: $e');
      print('HEALTH GOALS DEBUG: Stack trace: $stackTrace');
      _showError('An error occurred: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final colorScheme = Theme.of(context).colorScheme;
    final isSmallScreen = screenHeight < 700;
    final userBMI = _calculateBMI();
    
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
                painter: GoalsBackgroundPainter(
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
                          const Color(0xFF4facfe),
                          const Color(0xFF00f2fe),
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
                            "Set Your Goals",
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
                                          Icons.flag_rounded,
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
                                              "Personalized Health Goals",
                                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                fontSize: isSmallScreen ? 20 : 24,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Calculated just for you, adjustable anytime",
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
                            
                            // Health Metrics Overview with Animation
                            Column(
                                      children: [
                                        _buildEnhancedMetricCard(
                                          title: "BMR (Basal Metabolic Rate)",
                                          value: "${widget.bmr}",
                                          unit: "cal/day",
                                          icon: Icons.local_fire_department_rounded,
                                          description: "Calories burned at rest",
                                          color: Colors.orange,
                                          onInfoTap: () => _showGoalInfo(
                                            "BMR (Basal Metabolic Rate)",
                                            "BMR is the number of calories your body needs to maintain basic physiological functions like breathing, circulation, and cell production while at rest.",
                                            _getBMRCalculationFormula(),
                                            "This is the minimum energy your body needs daily. Your total daily energy expenditure (TDEE) includes BMR plus calories burned through activity and digestion.",
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        _buildEnhancedMetricCard(
                                          title: "Your BMI",
                                          value: userBMI > 0 ? userBMI.toStringAsFixed(1) : "N/A",
                                          unit: userBMI > 0 ? _getBMICategory(userBMI) : "",
                                          icon: Icons.monitor_weight_outlined,
                                          description: "Your current body mass index",
                                          color: _getBMIColor(userBMI),
                                          onInfoTap: () => _showGoalInfo(
                                            "BMI (Body Mass Index)",
                                            "BMI is a measure of body fat based on height and weight. It's used as a screening tool to identify potential weight-related health problems.",
                                            userBMI > 0 
                                                ? "BMI = Weight(kg) ÷ Height(m)²\nYour BMI = ${_userWeight}kg ÷ (${(_userHeight! / 100).toStringAsFixed(2)}m)² = ${userBMI.toStringAsFixed(1)}"
                                                : "BMI calculation requires height and weight data",
                                            "BMI Categories:\n• Underweight: Below 18.5\n• Normal: 18.5-24.9\n• Overweight: 25-29.9\n• Obese: 30 and above\n\nNote: BMI doesn't distinguish between muscle and fat mass.",
                                          ),
                                        ),
                                      ],
                                    ),
                            
                            const SizedBox(height: 24),
                            
                            // Goal Adjustments
                            Text(
                              "Adjust Your Daily Goals",
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            _buildEnhancedGoalCard(
                              title: "Daily Steps",
                              description: "Recommended based on your activity level",
                              value: _stepGoal,
                              unit: "steps",
                              min: 5000,
                              max: 20000,
                              step: 1000,
                              icon: Icons.directions_walk_rounded,
                              color: Colors.blue,
                              onChanged: (value) => setState(() => _stepGoal = value),
                              onInfoTap: () => _showGoalInfo(
                                "Daily Steps Goal",
                                "Walking is one of the simplest and most effective forms of exercise. Regular walking improves cardiovascular health, strengthens bones, and helps maintain a healthy weight.",
                                "Recommended steps by activity level:\n• Sedentary: 5,000-6,000 steps\n• Lightly active: 7,000-8,000 steps\n• Moderately active: 9,000-10,000 steps\n• Very active: 11,000-12,000 steps\n• Extremely active: 13,000+ steps",
                                "Fun fact: Approximately 2,000 steps = 1 kilometer (0.6 miles). The average person's stride length is about 0.5 meters, so 10,000 steps equals roughly 5 kilometers of walking!",
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            _buildEnhancedGoalCard(
                              title: "Water Intake",
                              description: "Based on your body weight (35ml/kg)",
                              value: _waterGoal,
                              unit: "glasses",
                              min: 6,
                              max: 15,
                              step: 1,
                              icon: Icons.water_drop_rounded,
                              color: Colors.cyan,
                              onChanged: (value) => setState(() => _waterGoal = value),
                              onInfoTap: () => _showGoalInfo(
                                "Daily Water Intake",
                                "Proper hydration is essential for every bodily function. Water helps regulate body temperature, transport nutrients, remove waste, and maintain healthy skin.",
                                _userWeight != null 
                                    ? "Calculation: 35ml × ${_userWeight}kg = ${(_userWeight! * 35).round()}ml per day\nIn glasses: ${(_userWeight! * 35 / 250).round()} glasses (250ml each)\nYour current goal: $_waterGoal glasses = ${_waterGoal * 250}ml"
                                    : "General recommendation: 35ml per kg of body weight\n1 glass = 250ml (8.5 fl oz)",
                                "Signs of good hydration: Light yellow urine, moist lips, elastic skin. Increase intake during exercise, hot weather, or illness. Coffee and tea count toward fluid intake but water is best!",
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            _buildEnhancedGoalCard(
                              title: "Daily Calories",
                              description: "Total daily energy expenditure",
                              value: _calorieGoal,
                              unit: "calories",
                              min: widget.bmr,
                              max: widget.bmr + 1000,
                              step: 100,
                              icon: Icons.local_fire_department_rounded,
                              color: Colors.orange,
                              onChanged: (value) => setState(() => _calorieGoal = value),
                              onInfoTap: () => _showGoalInfo(
                                "Daily Calorie Goal",
                                "Your Total Daily Energy Expenditure (TDEE) includes calories burned through basic body functions (BMR) plus physical activity, digestion, and thermogenesis.",
                                "TDEE = BMR × Activity Factor\n• Sedentary (BMR × 1.2): ${(widget.bmr * 1.2).round()} cal\n• Light activity (BMR × 1.375): ${(widget.bmr * 1.375).round()} cal\n• Moderate (BMR × 1.55): ${(widget.bmr * 1.55).round()} cal\n• Very active (BMR × 1.725): ${(widget.bmr * 1.725).round()} cal\n• Extremely active (BMR × 1.9): ${(widget.bmr * 1.9).round()} cal",
                                "For weight maintenance: Eat your TDEE calories\nFor weight loss: Eat 300-500 calories below TDEE\nFor weight gain: Eat 300-500 calories above TDEE\n\n1 pound of fat ≈ 3,500 calories",
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            _buildEnhancedGoalCard(
                              title: "Sleep Duration",
                              description: "Recommended 7-9 hours for adults",
                              value: _sleepGoal,
                              unit: "hours",
                              min: 6,
                              max: 10,
                              step: 1,
                              icon: Icons.bedtime_rounded,
                              color: Colors.indigo,
                              onChanged: (value) => setState(() => _sleepGoal = value),
                              onInfoTap: () => _showGoalInfo(
                                "Sleep Duration Goal",
                                "Quality sleep is crucial for physical recovery, mental health, immune function, and overall well-being. During sleep, your body repairs tissues, consolidates memories, and releases important hormones.",
                                "Sleep recommendations by age:\n• Adults (18-64): 7-9 hours\n• Older adults (65+): 7-8 hours\n• Quality matters as much as quantity",
                                "Sleep stages include:\n• Light sleep (50%): Easy to wake, body starts to relax\n• Deep sleep (25%): Physical recovery, immune system boost\n• REM sleep (25%): Memory consolidation, dreaming\n\nConsistent sleep schedule helps regulate your circadian rhythm!",
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Info Card
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: colorScheme.primary.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline_rounded,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Pro Tip",
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Start with achievable goals and gradually increase them. Consistency is more important than perfection!",
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Finish Button with Animation
                            SizedBox(height: isSmallScreen ? 24 : 32),
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _isLoading ? 1.0 : _pulseAnimation.value,
                                  child: ModernButton(
                                    text: "Start My Health Journey",
                                    icon: Icons.rocket_launch_rounded,
                                    onPressed: _isLoading ? null : _finishOnboarding,
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

  Widget _buildEnhancedMetricCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required String description,
    required Color color,
    required VoidCallback onInfoTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onInfoTap,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.info_outline,
                          color: color,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    if (unit.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          unit,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: color.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedGoalCard({
    required String title,
    required String description,
    required int value,
    required String unit,
    required int min,
    required int max,
    required int step,
    required IconData icon,
    required Color color,
    required Function(int) onChanged,
    required VoidCallback onInfoTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GoalAdjustmentCard(
        title: title,
        description: description,
        value: value,
        unit: unit,
        min: min,
        max: max,
        step: step,
        icon: icon,
        color: color,
        onChanged: onChanged,
        onInfoTap: onInfoTap,
      ),
    );
  }

  Color _getBMIColor(double bmi) {
    if (bmi == 0) return Colors.grey;
    if (bmi < 18.5) return Colors.blue; // Underweight
    if (bmi < 25) return Colors.green; // Normal
    if (bmi < 30) return Colors.orange; // Overweight
    return Colors.red; // Obese
  }
}

// Custom Painter for Animated Background
class GoalsBackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  final ColorScheme colorScheme;

  GoalsBackgroundPainter({
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
        const Color(0xFF4facfe),
        const Color(0xFF00f2fe),
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

    // Draw floating goal-related shapes
    final shapePaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final progress = animation.value;
    
    // Animated goal elements
    _drawGoalElements(canvas, size, shapePaint, progress);
  }

  void _drawGoalElements(Canvas canvas, Size size, Paint paint, double progress) {
    // Target/bullseye shape (for goals)
    final targetX = size.width * 0.2 + math.sin(progress * 2 * math.pi) * 15;
    final targetY = size.height * 0.15 + math.cos(progress * 2 * math.pi) * 10;
    
    // Draw concentric circles for target
    for (int i = 3; i > 0; i--) {
      canvas.drawCircle(
        Offset(targetX, targetY),
        i * 8.0,
        Paint()
          ..color = Colors.white.withOpacity(0.05 * i)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Trophy shape (for achievements)
    final trophyX = size.width * 0.8 + math.cos(progress * 2 * math.pi + 1) * 20;
    final trophyY = size.height * 0.2 + math.sin(progress * 2 * math.pi + 1) * 12;
    
    final trophyPath = Path();
    trophyPath.addOval(Rect.fromCenter(center: Offset(trophyX, trophyY - 5), width: 20, height: 15));
    trophyPath.addRect(Rect.fromCenter(center: Offset(trophyX, trophyY + 5), width: 8, height: 10));
    trophyPath.addRect(Rect.fromCenter(center: Offset(trophyX, trophyY + 12), width: 16, height: 4));
    canvas.drawPath(trophyPath, paint);

    // Progress bars (for tracking)
    for (int i = 0; i < 3; i++) {
      final barX = size.width * 0.1 + i * (size.width * 0.3);
      final barY = size.height * 0.08 + math.sin(progress * 2 * math.pi + i) * 5;
      
      // Background bar
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(barX, barY), width: 40, height: 6),
          const Radius.circular(3),
        ),
        Paint()..color = Colors.white.withOpacity(0.05),
      );
      
      // Progress fill
      final progressWidth = 40 * (0.3 + 0.4 * math.sin(progress * 2 * math.pi + i));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barX - 20, barY - 3, progressWidth, 6),
          const Radius.circular(3),
        ),
        paint,
      );
    }

    // Floating stars (for motivation)
    for (int i = 0; i < 5; i++) {
      final starX = size.width * (0.15 + i * 0.15) + math.sin(progress * 2 * math.pi + i * 0.5) * 8;
      final starY = size.height * 0.05 + math.cos(progress * 2 * math.pi + i * 0.5) * 4;
      
      _drawStar(canvas, Offset(starX, starY), 4, paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi / 5) - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      
      // Inner point
      final innerAngle = angle + math.pi / 5;
      final innerRadius = radius * 0.4;
      final innerX = center.dx + innerRadius * math.cos(innerAngle);
      final innerY = center.dy + innerRadius * math.sin(innerAngle);
      path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
