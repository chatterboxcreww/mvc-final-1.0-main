// lib/features/onboarding/screens/personal_info_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/fluid_page_transitions.dart';
import '../../../core/providers/user_data_provider.dart';
import '../../../core/models/app_enums.dart';
import '../../../core/models/activity_level.dart';
import '../widgets/info_collection_card.dart';
import 'lifestyle_preferences_screen.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  Gender? _selectedGender;
  ActivityLevel _selectedActivityLevel = ActivityLevel.moderate;
  bool _isLoading = false;
  
  // Date of Birth dropdowns
  int? _selectedDay;
  int? _selectedMonth;
  int? _selectedYear;

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
    
    // Pre-fill email from authentication
    _loadUserEmail();
    
    _animationController.forward();
  }

  void _loadUserEmail() {
    final userProvider = context.read<UserDataProvider>();
    final user = userProvider.getCurrentUser();
    if (user?.email != null) {
      _emailController.text = user!.email!;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in all required fields correctly'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    
    // Check if gender is selected
    if (_selectedGender == null) {
      debugPrint('Gender not selected');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select your gender'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    
    debugPrint('All validations passed, proceeding...');
    setState(() => _isLoading = true);
    
    try {
      final userProvider = context.read<UserDataProvider>();
      
      // Calculate age from date of birth
      if (_selectedDay == null || _selectedMonth == null || _selectedYear == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your complete date of birth')),
        );
        return;
      }
      
      final birthDate = DateTime(_selectedYear!, _selectedMonth!, _selectedDay!);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      
      // Calculate BMR and suggested daily goals
      final height = double.parse(_heightController.text);
      final weight = double.parse(_weightController.text);
      
      final bmr = _calculateBMR(weight, height, age, _selectedGender!);
      final suggestedSteps = _calculateSuggestedSteps(_selectedActivityLevel);
      final suggestedWater = _calculateSuggestedWater(weight);
      
      print('Calculated values - BMR: $bmr, Steps: $suggestedSteps, Water: $suggestedWater');
      
      await userProvider.updateUserData(
        userProvider.userData.copyWith(
          name: _nameController.text,
          email: _emailController.text,
          age: age,
          height: height,
          weight: weight,
          bmr: bmr,
          gender: _selectedGender,
          activityLevel: _selectedActivityLevel.name,
          dailyStepGoal: suggestedSteps,
          dailyWaterGoal: suggestedWater,
        ),
      );

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                            "Personal Information",
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
                        child: Form(
                          key: _formKey,
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
                                "This information helps us calculate your personalized health metrics and recommendations.",
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                              
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
                                  const SizedBox(height: 16),
                                  _buildDateOfBirthDropdowns(),
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
                              
                              // Continue Button
                              Row(
                                children: [
                                  Expanded(
                                    child: ModernButton(
                                      text: "Continue",
                                      icon: Icons.arrow_forward_rounded,
                                      onPressed: _isLoading ? null : _continue,
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateOfBirthDropdowns() {
    final colorScheme = Theme.of(context).colorScheme;
    final currentYear = DateTime.now().year;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.cake_outlined, color: colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Date of Birth',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Day Dropdown
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outline),
                  color: colorScheme.surface,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedDay,
                    hint: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Day', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                    ),
                    isExpanded: true,
                    items: List.generate(31, (index) => index + 1).map((day) {
                      return DropdownMenuItem<int>(
                        value: day,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(day.toString()),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDay = value;
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Month Dropdown
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outline),
                  color: colorScheme.surface,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedMonth,
                    hint: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Month', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                    ),
                    isExpanded: true,
                    items: [
                      {'value': 1, 'name': 'January'},
                      {'value': 2, 'name': 'February'},
                      {'value': 3, 'name': 'March'},
                      {'value': 4, 'name': 'April'},
                      {'value': 5, 'name': 'May'},
                      {'value': 6, 'name': 'June'},
                      {'value': 7, 'name': 'July'},
                      {'value': 8, 'name': 'August'},
                      {'value': 9, 'name': 'September'},
                      {'value': 10, 'name': 'October'},
                      {'value': 11, 'name': 'November'},
                      {'value': 12, 'name': 'December'},
                    ].map((month) {
                      return DropdownMenuItem<int>(
                        value: month['value'] as int,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(month['name'] as String),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMonth = value;
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Year Dropdown
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outline),
                  color: colorScheme.surface,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedYear,
                    hint: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Year', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                    ),
                    isExpanded: true,
                    items: List.generate(100, (index) => currentYear - index).map((year) {
                      return DropdownMenuItem<int>(
                        value: year,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(year.toString()),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedYear = value;
                      });
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_selectedDay != null && _selectedMonth != null && _selectedYear != null) ...[
          const SizedBox(height: 8),
          Text(
            'Age: ${_calculateAge(_selectedDay!, _selectedMonth!, _selectedYear!)} years',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
  
  int _calculateAge(int day, int month, int year) {
    final birthDate = DateTime(year, month, day);
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
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
            color: colorScheme.shadow.withValues(alpha: 0.05),
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
              color: colorScheme.primary.withValues(alpha: 0.1),
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
            borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
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
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = gender),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? Theme.of(context).colorScheme.primary 
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLevelOption(ActivityLevel level) {
    final isSelected = _selectedActivityLevel == level;
    final data = _getActivityLevelData(level);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => setState(() => _selectedActivityLevel = level),
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
              Icon(
                data['icon'],
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.onSurfaceVariant,
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
                            ? Theme.of(context).colorScheme.primary 
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      data['description'],
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
