// lib/features/onboarding/screens/lifestyle_preferences_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/fluid_page_transitions.dart';
import '../../../core/providers/user_data_provider.dart';
import '../../../core/models/app_enums.dart';
import '../widgets/info_collection_card.dart';
import 'health_info_screen.dart';

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
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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

  void _continue() async {
    setState(() => _isLoading = true);
    
    final userProvider = context.read<UserDataProvider>();
    
    await userProvider.updateUserData(
      userProvider.userData.copyWith(
        dietPreference: _selectedDietPreference,
        prefersCoffee: _prefersCoffee,
        prefersTea: _prefersTea,
        sleepTime: _sleepTime,
        wakeupTime: _wakeupTime,
      ),
    );

    setState(() => _isLoading = false);
    
    if (mounted) {
      Navigator.of(context).pushFluid(HealthInfoScreen(
        suggestedSteps: widget.suggestedSteps,
        suggestedWater: widget.suggestedWater,
        bmr: widget.bmr,
      ));
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
    return Scaffold(
      body: GradientBackground(
        colors: [
          const Color(0xFF667eea),
          const Color(0xFF764ba2),
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
                            "Lifestyle Preferences",
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        TextButton(
                          onPressed: _skip,
                          child: Text(
                            "Skip",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
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
                              "Let's personalize your experience",
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "These preferences help us provide better nutrition recommendations and sleep insights.",
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Dietary Preferences
                            InfoCollectionCard(
                              title: "Dietary Preference",
                              subtitle: "What type of diet do you follow?",
                              children: [
                                _buildDietOption(DietPreference.vegetarian, "Vegetarian", "Plant-based with dairy", Icons.eco_outlined),
                                const SizedBox(height: 12),
                                _buildDietOption(DietPreference.vegan, "Vegan", "Strictly plant-based", Icons.eco),
                                const SizedBox(height: 12),
                                _buildDietOption(DietPreference.nonVegetarian, "Non-Vegetarian", "Includes meat, fish, and poultry", Icons.restaurant_outlined),
                                const SizedBox(height: 12),
                                _buildDietOption(DietPreference.pescatarian, "Pescatarian", "Fish and seafood with vegetables", Icons.restaurant),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Beverage Preferences
                            InfoCollectionCard(
                              title: "Beverage Preferences",
                              subtitle: "Do you enjoy coffee or tea?",
                              children: [
                                CheckboxListTile(
                                  title: const Text("I prefer Coffee"),
                                  subtitle: const Text("Get daily coffee reminders at 10:00 AM"),
                                  value: _prefersCoffee,
                                  onChanged: (value) {
                                    setState(() {
                                      _prefersCoffee = value ?? false;
                                    });
                                  },
                                  contentPadding: EdgeInsets.zero,
                                ),
                                CheckboxListTile(
                                  title: const Text("I prefer Tea"),
                                  subtitle: const Text("Get daily tea reminders at 3:00 PM"),
                                  value: _prefersTea,
                                  onChanged: (value) {
                                    setState(() {
                                      _prefersTea = value ?? false;
                                    });
                                  },
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Sleep Schedule
                            InfoCollectionCard(
                              title: "Sleep Schedule",
                              subtitle: "Help us track your sleep patterns",
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTimeSelector(
                                        "Bedtime",
                                        _sleepTime,
                                        Icons.bedtime_outlined,
                                        () => _selectTime(context, true),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTimeSelector(
                                        "Wake-up Time",
                                        _wakeupTime,
                                        Icons.wb_sunny_outlined,
                                        () => _selectTime(context, false),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_sleepTime != null && _wakeupTime != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Color.fromRGBO(Theme.of(context).colorScheme.primaryContainer.red, Theme.of(context).colorScheme.primaryContainer.green, Theme.of(context).colorScheme.primaryContainer.blue, 0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Theme.of(context).colorScheme.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            "Sleep duration: ${_calculateSleepDuration()}",
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Continue Button
                            Row(
                              children: [
                                Expanded(
                                  child: ModernButton(
                                    text: "Continue",
                                    icon: Icons.arrow_forward_rounded,
                                    onPressed: _continue,
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

  Widget _buildDietOption(DietPreference preference, String title, String description, IconData icon) {
    final isSelected = _selectedDietPreference == preference;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedDietPreference = preference),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primaryContainer 
              : Color.fromRGBO(Theme.of(context).colorScheme.surfaceContainerHighest.red, Theme.of(context).colorScheme.surfaceContainerHighest.green, Theme.of(context).colorScheme.surfaceContainerHighest.blue, 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary 
                : Color.fromRGBO(Theme.of(context).colorScheme.outline.red, Theme.of(context).colorScheme.outline.green, Theme.of(context).colorScheme.outline.blue, 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color.fromRGBO((isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant).red, (isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant).green, (isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant).blue, 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.onSurfaceVariant,
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
                          ? Theme.of(context).colorScheme.primary 
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.onPrimaryContainer 
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector(String label, TimeOfDay? time, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color.fromRGBO(Theme.of(context).colorScheme.surfaceContainerHighest.red, Theme.of(context).colorScheme.surfaceContainerHighest.green, Theme.of(context).colorScheme.surfaceContainerHighest.blue, 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: time != null
                ? Color.fromRGBO(Theme.of(context).colorScheme.primary.red, Theme.of(context).colorScheme.primary.green, Theme.of(context).colorScheme.primary.blue, 0.5)
                : Color.fromRGBO(Theme.of(context).colorScheme.outline.red, Theme.of(context).colorScheme.outline.green, Theme.of(context).colorScheme.outline.blue, 0.3),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: time != null
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              time != null 
                  ? time!.format(context)
                  : "Tap to select",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: time != null
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: time != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
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
}
