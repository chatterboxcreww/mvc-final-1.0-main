// lib/features/onboarding/screens/health_info_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/fluid_page_transitions.dart';
import '../../../core/providers/user_data_provider.dart';
import '../widgets/info_collection_card.dart';
import 'health_goals_screen.dart';

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
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;

  // Health conditions
  bool? _hasDiabetes;
  bool? _isSkinnyFat;
  bool? _hasProteinDeficiency;

  // Diet and lifestyle
  final List<String> _allergies = [];
  final _allergyController = TextEditingController();

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
    _allergyController.dispose();
    super.dispose();
  }

  void _continue() async {
    setState(() => _isLoading = true);
    
    final userProvider = context.read<UserDataProvider>();
    
    await userProvider.updateUserData(
      userProvider.userData.copyWith(
        hasDiabetes: _hasDiabetes,
        isSkinnyFat: _isSkinnyFat,
        hasProteinDeficiency: _hasProteinDeficiency,
        allergies: _allergies.isNotEmpty ? _allergies : null,
      ),
    );

    setState(() => _isLoading = false);
    
    if (mounted) {
      Navigator.of(context).pushFluid(HealthGoalsScreen(
        suggestedSteps: widget.suggestedSteps,
        suggestedWater: widget.suggestedWater,
        bmr: widget.bmr,
      ));
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
                            "Health Information",
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
                              "Help us understand your health",
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "This information helps us provide personalized health recommendations. All data is kept confidential.",
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Health Conditions
                            InfoCollectionCard(
                              title: "Health Conditions",
                              subtitle: "Select any conditions that apply to you",
                              children: [
                                _buildHealthConditionTile(
                                  "Diabetes",
                                  "Blood sugar management condition",
                                  Icons.bloodtype_outlined,
                                  _hasDiabetes,
                                  (value) => setState(() => _hasDiabetes = value),
                                ),
                                _buildHealthConditionTile(
                                  "Skinny Fat",
                                  "Low muscle mass despite normal weight",
                                  Icons.fitness_center_outlined,
                                  _isSkinnyFat,
                                  (value) => setState(() => _isSkinnyFat = value),
                                ),
                                _buildHealthConditionTile(
                                  "Protein Deficiency",
                                  "Insufficient protein intake",
                                  Icons.restaurant_outlined,
                                  _hasProteinDeficiency,
                                  (value) => setState(() => _hasProteinDeficiency = value),
                                ),
                              ],
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
                                        decoration: InputDecoration(
                                          labelText: "Add an allergy or intolerance",
                                          prefixIcon: const Icon(Icons.warning_amber_outlined),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
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

  Widget _buildHealthConditionTile(
    String title,
    String description,
    IconData icon,
    bool? currentValue,
    ValueChanged<bool?> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
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
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: isSelected 
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
