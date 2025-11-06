// lib/features/onboarding/screens/health_info_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/fluid_page_transitions.dart';
import '../../../core/providers/user_data_provider.dart';
import '../widgets/info_collection_card.dart';
import 'health_goals_screen.dart';
import 'dart:math' as math;

class HealthInfoScreen extends StatefulWidget {
  final int suggestedSteps;
  final int suggestedWater;
  final int bmr;

  const HealthInfoScreen({
    super.key,
    required this.suggestedSteps,
    required this.suggestedWater,
    required this.bmr,
  });

  @override
  State<HealthInfoScreen> createState() => _HealthInfoScreenState();
}

class _HealthInfoScreenState extends State<HealthInfoScreen>
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

  // Health conditions (expanded list) - Initialize with false defaults
  bool? _hasDiabetes = false;
  bool? _isSkinnyFat = false;
  bool? _hasProteinDeficiency = false;
  bool? _hasHighBloodPressure = false;
  bool? _hasHighCholesterol = false;
  bool? _isUnderweight = false;
  bool? _hasAnxiety = false;
  bool? _hasLowEnergyLevels = false;

  // Diet and lifestyle
  final List<String> _allergies = [];
  final _allergyController = TextEditingController();

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
      duration: const Duration(milliseconds: 4000),
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
      begin: -10.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.06,
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
    Future.delayed(const Duration(milliseconds: 700), () {
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
    _allergyController.dispose();
    super.dispose();
  }

  void _continue() async {
    setState(() => _isLoading = true);
    
    // Add haptic feedback
    HapticFeedback.lightImpact();
    
    try {
      final userProvider = context.read<UserDataProvider>();
      
      final healthInfoData = userProvider.userData.copyWith(
        // Ensure all health conditions have explicit boolean values (never null)
        hasDiabetes: _hasDiabetes ?? false,
        isSkinnyFat: _isSkinnyFat ?? false,
        hasProteinDeficiency: _hasProteinDeficiency ?? false,
        hasHighBloodPressure: _hasHighBloodPressure ?? false,
        hasHighCholesterol: _hasHighCholesterol ?? false,
        isUnderweight: _isUnderweight ?? false,
        hasAnxiety: _hasAnxiety ?? false,
        hasLowEnergyLevels: _hasLowEnergyLevels ?? false,
        allergies: _allergies.isNotEmpty ? _allergies : [],
      );
      
      print('HEALTH INFO DEBUG: Data to save: ${healthInfoData.toJson()}');
      
      final success = await userProvider.updateUserData(
        healthInfoData,
        isOnboarding: true, // Immediate Firebase sync during onboarding
      );
      
      if (!success) {
        print('HEALTH INFO DEBUG: ❌ Failed to save health info data');
        _showError('Failed to save your health information. Please try again.');
        setState(() => _isLoading = false);
        return;
      }
      
      print('HEALTH INFO DEBUG: ✅ Health info data saved successfully');

      if (mounted) {
        Navigator.of(context).pushFluid(HealthGoalsScreen(
          suggestedSteps: widget.suggestedSteps,
          suggestedWater: widget.suggestedWater,
          bmr: widget.bmr,
        ));
      }
    } catch (e) {
      print('Error saving health info: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving health information: ${e.toString()}'),
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
      Navigator.of(context).pushFluid(HealthGoalsScreen(
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
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _addAllergy() {
    if (_allergyController.text.trim().isNotEmpty) {
      setState(() {
        final newAllergy = _allergyController.text.trim();
        if (!_allergies.map((a) => a.toLowerCase()).contains(newAllergy.toLowerCase())) {
          _allergies.add(newAllergy);
        }
        _allergyController.clear();
      });
    }
  }

  void _removeAllergy(int index) {
    setState(() {
      _allergies.removeAt(index);
    });
  }

  void _showConditionInfo(String condition, String description, String howAppHelps) {
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
                condition,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
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
              "How Health-TRKD helps:",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              howAppHelps,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
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
                painter: HealthInfoBackgroundPainter(
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
                            "Health Information",
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
                                          Icons.health_and_safety_rounded,
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
                                              "Help us understand your health",
                                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                fontSize: isSmallScreen ? 20 : 24,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Personalized recommendations, kept confidential",
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
                            
                            // Health Conditions with Animation
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
                                                  Icons.medical_services_rounded,
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
                                                      "Health Conditions",
                                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: isSmallScreen ? 18 : 20,
                                                      ),
                                                    ),
                                                    Text(
                                                      "Select any conditions that apply to you",
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
                                          _buildHealthConditionTile(
                                            "Diabetes",
                                            "Blood sugar management condition",
                                            Icons.bloodtype_outlined,
                                            _hasDiabetes,
                                            (value) => setState(() => _hasDiabetes = value),
                                            "A condition where blood sugar levels are consistently high due to the body's inability to produce or properly use insulin.",
                                            "Track daily activity levels, monitor water intake, and maintain consistent meal timing to help manage blood sugar levels naturally.",
                                          ),
                                          _buildHealthConditionTile(
                                            "High Blood Pressure",
                                            "Elevated blood pressure levels",
                                            Icons.favorite_rounded,
                                            _hasHighBloodPressure,
                                            (value) => setState(() => _hasHighBloodPressure = value),
                                            "A condition where the force of blood against artery walls is consistently too high, increasing risk of heart disease and stroke.",
                                            "Regular step tracking and activity monitoring help lower blood pressure. Water intake tracking and stress management through consistent routines also contribute to better cardiovascular health.",
                                          ),
                                          _buildHealthConditionTile(
                                            "High Cholesterol",
                                            "Elevated cholesterol levels in blood",
                                            Icons.water_drop_rounded,
                                            _hasHighCholesterol,
                                            (value) => setState(() => _hasHighCholesterol = value),
                                            "A condition where there are high levels of cholesterol in the blood, which can lead to heart disease and stroke.",
                                            "Track daily physical activity to help raise good cholesterol (HDL) and lower bad cholesterol (LDL). Monitor hydration and maintain consistent exercise routines for heart health.",
                                          ),
                                          _buildHealthConditionTile(
                                            "Skinny Fat",
                                            "Low muscle mass despite normal weight",
                                            Icons.fitness_center_outlined,
                                            _isSkinnyFat,
                                            (value) => setState(() => _isSkinnyFat = value),
                                            "A condition where someone appears thin but has a high body fat percentage and low muscle mass, leading to poor metabolic health.",
                                            "Track daily activity to build muscle mass through consistent movement. Monitor protein intake timing and ensure adequate hydration for muscle development and recovery.",
                                          ),
                                          _buildHealthConditionTile(
                                            "Underweight",
                                            "Below normal healthy weight range",
                                            Icons.trending_up_rounded,
                                            _isUnderweight,
                                            (value) => setState(() => _isUnderweight = value),
                                            "A condition where body weight is below the healthy range for height and age, which can indicate nutritional deficiencies or underlying health issues.",
                                            "Track daily activity levels to build healthy muscle mass. Monitor hydration and meal timing to support healthy weight gain and ensure proper nutrient absorption.",
                                          ),
                                          _buildHealthConditionTile(
                                            "Protein Deficiency",
                                            "Insufficient protein intake",
                                            Icons.restaurant_outlined,
                                            _hasProteinDeficiency,
                                            (value) => setState(() => _hasProteinDeficiency = value),
                                            "A condition where the body doesn't get enough protein to maintain muscle mass, immune function, and overall health.",
                                            "Track meal timing and water intake to optimize protein absorption. Monitor daily activity to ensure protein is being used effectively for muscle maintenance and recovery.",
                                          ),
                                          _buildHealthConditionTile(
                                            "Anxiety",
                                            "Persistent worry and nervousness",
                                            Icons.psychology_rounded,
                                            _hasAnxiety,
                                            (value) => setState(() => _hasAnxiety = value),
                                            "A mental health condition characterized by persistent worry, nervousness, and fear that can interfere with daily activities.",
                                            "Regular physical activity tracking helps reduce anxiety through endorphin release. Consistent sleep schedules and hydration monitoring support mental well-being and stress management.",
                                          ),
                                          _buildHealthConditionTile(
                                            "Low Energy Levels",
                                            "Persistent fatigue and tiredness",
                                            Icons.battery_2_bar_rounded,
                                            _hasLowEnergyLevels,
                                            (value) => setState(() => _hasLowEnergyLevels = value),
                                            "A condition characterized by persistent fatigue, tiredness, and lack of energy that affects daily activities and quality of life.",
                                            "Track daily activity patterns to identify energy peaks and dips. Monitor sleep quality, hydration levels, and meal timing to optimize natural energy levels throughout the day.",
                                          ),
                                        ],
                                      ),
                                    ),
                            
                            const SizedBox(height: 24),
                            
                            // Allergies Section
                            InfoCollectionCard(
                              title: "Food Allergies & Intolerances",
                              subtitle: "Help us avoid recommending foods that don't work for you",
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _allergyController,
                                        textCapitalization: TextCapitalization.words,
                                        decoration: InputDecoration(
                                          labelText: "Add an allergy or intolerance",
                                          hintText: "e.g., Peanuts, Dairy, Gluten",
                                          prefixIcon: const Icon(Icons.warning_amber_outlined),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                              color: Theme.of(context).colorScheme.primary,
                                              width: 2,
                                            ),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        ),
                                        onSubmitted: (_) => _addAllergy(),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    IconButton(
                                      onPressed: _addAllergy,
                                      icon: const Icon(Icons.add_circle),
                                      iconSize: 32,
                                    ),
                                  ],
                                ),
                                if (_allergies.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _allergies.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final allergy = entry.value;
                                      return Chip(
                                        label: Text(allergy),
                                        deleteIcon: const Icon(Icons.close, size: 18),
                                        onDeleted: () => _removeAllergy(index),
                                        backgroundColor: Theme.of(context).colorScheme.errorContainer,
                                        deleteIconColor: Theme.of(context).colorScheme.onErrorContainer,
                                      );
                                    }).toList(),
                                  ),
                                ],
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
                                    text: "Continue to Health Goals",
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

  Widget _buildHealthConditionTile(
    String title,
    String description,
    IconData icon,
    bool? currentValue,
    ValueChanged<bool?> onChanged,
    String fullDescription,
    String howAppHelps,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: currentValue == true ? [
            colorScheme.primaryContainer.withOpacity(0.4),
            colorScheme.primaryContainer.withOpacity(0.2),
          ] : [
            colorScheme.surfaceContainerHighest.withOpacity(0.3),
            colorScheme.surfaceContainerHighest.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: currentValue == true 
              ? colorScheme.primary.withOpacity(0.5)
              : colorScheme.outline.withOpacity(0.2),
          width: currentValue == true ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: currentValue == true 
                                  ? colorScheme.primary 
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showConditionInfo(title, fullDescription, howAppHelps),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.info_outline,
                              color: colorScheme.primary,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: currentValue == true 
                            ? colorScheme.onPrimaryContainer 
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildYesNoButton("No", currentValue == false, () => onChanged(false)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildYesNoButton("Yes", currentValue == true, () => onChanged(true)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYesNoButton(String text, bool isSelected, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected ? LinearGradient(
              colors: [
                colorScheme.primary,
                colorScheme.primary.withOpacity(0.8),
              ],
            ) : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? colorScheme.primary
                  : colorScheme.outline.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected)
                Icon(
                  text == "Yes" ? Icons.check_circle : Icons.cancel,
                  color: colorScheme.onPrimary,
                  size: 16,
                ),
              if (isSelected) const SizedBox(width: 4),
              Text(
                text,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: isSelected 
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Painter for Animated Background
class HealthInfoBackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  final ColorScheme colorScheme;

  HealthInfoBackgroundPainter({
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

    // Draw floating health-related shapes
    final shapePaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final progress = animation.value;
    
    // Animated health elements
    _drawHealthElements(canvas, size, shapePaint, progress);
  }

  void _drawHealthElements(Canvas canvas, Size size, Paint paint, double progress) {
    // Heart shape (for cardiovascular health)
    final heartX = size.width * 0.2 + math.sin(progress * 2 * math.pi) * 15;
    final heartY = size.height * 0.15 + math.cos(progress * 2 * math.pi) * 10;
    
    final heartPath = Path();
    final heartSize = 25.0;
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

    // Medical cross
    final crossX = size.width * 0.8 + math.cos(progress * 2 * math.pi + 1) * 20;
    final crossY = size.height * 0.2 + math.sin(progress * 2 * math.pi + 1) * 12;
    
    final crossSize = 20.0;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(crossX, crossY),
        width: crossSize,
        height: crossSize * 0.3,
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(crossX, crossY),
        width: crossSize * 0.3,
        height: crossSize,
      ),
      paint,
    );

    // DNA helix (simplified)
    final dnaX = size.width * 0.1 + math.sin(progress * 2 * math.pi + 2) * 8;
    final dnaY = size.height * 0.3 + math.cos(progress * 2 * math.pi + 2) * 6;
    
    final dnaPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final dnaPath = Path();
    for (int i = 0; i < 3; i++) {
      final y = dnaY + i * 15;
      dnaPath.moveTo(dnaX - 10, y);
      dnaPath.quadraticBezierTo(dnaX, y - 8, dnaX + 10, y);
      dnaPath.quadraticBezierTo(dnaX, y + 8, dnaX - 10, y + 15);
    }
    canvas.drawPath(dnaPath, dnaPaint);

    // Floating pills/capsules
    for (int i = 0; i < 4; i++) {
      final pillX = size.width * (0.15 + i * 0.2) + math.sin(progress * 2 * math.pi + i) * 8;
      final pillY = size.height * 0.08 + math.cos(progress * 2 * math.pi + i) * 5;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(pillX, pillY), width: 12, height: 6),
          const Radius.circular(3),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
