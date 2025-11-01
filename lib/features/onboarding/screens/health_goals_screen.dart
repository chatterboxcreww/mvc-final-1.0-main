// lib/features/onboarding/screens/health_goals_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/fluid_page_transitions.dart';
import '../../../core/providers/user_data_provider.dart';
import '../../../core/services/storage_service.dart';
import '../../auth/screens/auth_wrapper.dart';
import '../widgets/goal_adjustment_card.dart';
import '../widgets/health_metric_card.dart' as dedicated;

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
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late int _stepGoal;
  late int _waterGoal;
  late int _calorieGoal;
  late int _sleepGoal = 8; // hours
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _stepGoal = widget.suggestedSteps;
    _waterGoal = widget.suggestedWater;
    _calorieGoal = widget.bmr + 500; // BMR + activity calories
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _finishOnboarding() async {
    setState(() => _isLoading = true);
    
    final userProvider = context.read<UserDataProvider>();
    final storageService = StorageService();
    
    try {
      print('HEALTH GOALS DEBUG: Starting onboarding completion process');
      
      // Update user data with health goals
      final result = await userProvider.updateUserData(
        userProvider.userData.copyWith(
          dailyStepGoal: _stepGoal,
          dailyWaterGoal: _waterGoal,
          dailyCalorieGoal: _calorieGoal,
          sleepGoalHours: _sleepGoal,
        ),
      );
      
      if (!result) {
        print('HEALTH GOALS DEBUG: Failed to save health goals');
        _showError('Failed to save health goals. Please try again.');
        setState(() => _isLoading = false);
        return;
      }
      
      print('HEALTH GOALS DEBUG: Health goals saved: Steps=$_stepGoal, Water=$_waterGoal');
      
      // Explicitly call completeOnboarding method which performs validation
      // and sets the onboarding flag
      final onboardingCompleted = await userProvider.completeOnboarding();
      print('HEALTH GOALS DEBUG: completeOnboarding result: $onboardingCompleted');
      
      if (!onboardingCompleted) {
        print('HEALTH GOALS DEBUG: Failed to complete onboarding process');
        _showError('Failed to complete setup. Please try again.');
        setState(() => _isLoading = false);
        return;
      }
      
      // Double check that onboarding flag is set
      await storageService.setOnboardingComplete(true);
      
      // Verify onboarding is complete
      final isComplete = await storageService.isOnboardingComplete();
      print('HEALTH GOALS DEBUG: Final onboarding completion status check: $isComplete');
      
      setState(() => _isLoading = false);
      
      if (mounted) {
        // Use a delay to ensure storage is updated before checking
        print('HEALTH GOALS DEBUG: Waiting before navigation to ensure updates are saved');
        await Future.delayed(Duration(milliseconds: 500));
        print('HEALTH GOALS DEBUG: Navigating to AuthWrapper');
        Navigator.of(context).pushReplacement(
          FluidPageRoute(page: const AuthWrapper()),
        );
      }
    } catch (e) {
      print('HEALTH GOALS DEBUG: Error during onboarding completion: $e');
      _showError('An error occurred. Please try again.');
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
    return Scaffold(
      body: GradientBackground(
        colors: [
          const Color(0xFF4facfe),
          const Color(0xFF00f2fe),
          Theme.of(context).colorScheme.surface,
        ],
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                        ),
                        Expanded(
                          child: Text(
                            "Set Your Goals",
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  
                  // Content
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(top: 20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            
                            Text(
                              "Personalized Health Goals",
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Based on your information, we've calculated personalized goals. You can adjust them anytime.",
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Health Metrics Overview
                            Column(
                              children: [
                                dedicated.HealthMetricCard(
                                  title: "BMR",
                                  value: "${widget.bmr}",
                                  unit: "cal/day",
                                  icon: Icons.local_fire_department_rounded,
                                  description: "Calories burned at rest",
                                ),
                                const SizedBox(height: 16),
                                dedicated.HealthMetricCard(
                                  title: "Ideal BMI",
                                  value: "18.5-24.9",
                                  unit: "",
                                  icon: Icons.monitor_weight_outlined,
                                  description: "Healthy weight range",
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
                            
                            GoalAdjustmentCard(
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
                            ),
                            
                            const SizedBox(height: 16),
                            
                            GoalAdjustmentCard(
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
                            ),
                            
                            const SizedBox(height: 16),
                            
                            GoalAdjustmentCard(
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
                            ),
                            
                            const SizedBox(height: 16),
                            
                            GoalAdjustmentCard(
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
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Info Card
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
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
                            
                            // Finish Button
                            Row(
                              children: [
                                Expanded(
                                  child: ModernButton(
                                    text: "Start My Journey",
                                    icon: Icons.rocket_launch_rounded,
                                    onPressed: _finishOnboarding,
                                    isLoading: _isLoading,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
