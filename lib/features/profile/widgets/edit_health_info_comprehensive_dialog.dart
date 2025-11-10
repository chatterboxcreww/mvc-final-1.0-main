// lib/features/profile/widgets/edit_health_info_comprehensive_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/user_data.dart';
import '../../../core/models/app_enums.dart';
import '../../../core/providers/user_data_provider.dart';

class EditHealthInfoComprehensiveDialog extends StatefulWidget {
  const EditHealthInfoComprehensiveDialog({super.key});

  @override
  State<EditHealthInfoComprehensiveDialog> createState() => _EditHealthInfoComprehensiveDialogState();
}

class _EditHealthInfoComprehensiveDialogState extends State<EditHealthInfoComprehensiveDialog> {
  final _formKey = GlobalKey<FormState>();
  final _allergiesController = TextEditingController();
  
  // Health conditions
  bool? _hasDiabetes;
  bool? _hasHighBloodPressure;
  bool? _hasHighCholesterol;
  bool? _isUnderweight;
  bool? _hasAnxiety;
  bool? _hasLowEnergyLevels;
  bool? _isSkinnyFat;
  bool? _hasProteinDeficiency;
  
  // Diet preference
  DietPreference? _dietPreference;

  @override
  void initState() {
    super.initState();
    // Load current user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userData = Provider.of<UserDataProvider>(context, listen: false).userData;
      setState(() {
        _hasDiabetes = userData.hasDiabetes;
        _hasHighBloodPressure = userData.hasHighBloodPressure;
        _hasHighCholesterol = userData.hasHighCholesterol;
        _isUnderweight = userData.isUnderweight;
        _hasAnxiety = userData.hasAnxiety;
        _hasLowEnergyLevels = userData.hasLowEnergyLevels;
        _isSkinnyFat = userData.isSkinnyFat;
        _hasProteinDeficiency = userData.hasProteinDeficiency;
        _dietPreference = userData.dietPreference;
        _allergiesController.text = userData.allergies?.join(', ') ?? '';
      });
    });
  }

  @override
  void dispose() {
    _allergiesController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final userDataProvider = Provider.of<UserDataProvider>(context, listen: false);
      final currentData = userDataProvider.userData;

      // Parse allergies from comma-separated string
      final allergiesList = _allergiesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final updatedData = UserData.fromJson(currentData.toJson())
        ..hasDiabetes = _hasDiabetes
        ..hasHighBloodPressure = _hasHighBloodPressure
        ..hasHighCholesterol = _hasHighCholesterol
        ..isUnderweight = _isUnderweight
        ..hasAnxiety = _hasAnxiety
        ..hasLowEnergyLevels = _hasLowEnergyLevels
        ..isSkinnyFat = _isSkinnyFat
        ..hasProteinDeficiency = _hasProteinDeficiency
        ..dietPreference = _dietPreference
        ..allergies = allergiesList;

      await userDataProvider.updateUserData(updatedData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Health information updated successfully!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.health_and_safety_outlined, color: colorScheme.primary),
          const SizedBox(width: 12),
          const Expanded(child: Text('Health Information')),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Diet Preference Section
              Text(
                'Diet Preference',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<DietPreference>(
                    value: _dietPreference,
                    isExpanded: true,
                    hint: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Select diet preference'),
                    ),
                    items: DietPreference.values.map((diet) {
                      return DropdownMenuItem(
                        value: diet,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(_getDietLabel(diet)),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _dietPreference = value;
                      });
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Health Conditions Section
              Text(
                'Health Conditions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select any conditions that apply to you:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildCheckboxTile(
                'Diabetes',
                _hasDiabetes,
                (value) => setState(() => _hasDiabetes = value),
                Icons.bloodtype_outlined,
                Colors.red,
              ),
              _buildCheckboxTile(
                'High Blood Pressure',
                _hasHighBloodPressure,
                (value) => setState(() => _hasHighBloodPressure = value),
                Icons.favorite_outlined,
                Colors.red,
              ),
              _buildCheckboxTile(
                'High Cholesterol',
                _hasHighCholesterol,
                (value) => setState(() => _hasHighCholesterol = value),
                Icons.monitor_heart_outlined,
                Colors.orange,
              ),
              _buildCheckboxTile(
                'Underweight',
                _isUnderweight,
                (value) => setState(() => _isUnderweight = value),
                Icons.trending_up_outlined,
                Colors.green,
              ),
              _buildCheckboxTile(
                'Anxiety',
                _hasAnxiety,
                (value) => setState(() => _hasAnxiety = value),
                Icons.psychology_outlined,
                Colors.purple,
              ),
              _buildCheckboxTile(
                'Low Energy Levels',
                _hasLowEnergyLevels,
                (value) => setState(() => _hasLowEnergyLevels = value),
                Icons.battery_charging_full_outlined,
                Colors.amber,
              ),
              _buildCheckboxTile(
                'Skinny Fat (Low Muscle Mass)',
                _isSkinnyFat,
                (value) => setState(() => _isSkinnyFat = value),
                Icons.fitness_center_outlined,
                Colors.blue,
              ),
              _buildCheckboxTile(
                'Protein Deficiency',
                _hasProteinDeficiency,
                (value) => setState(() => _hasProteinDeficiency = value),
                Icons.food_bank_outlined,
                Colors.teal,
              ),
              
              const SizedBox(height: 20),
              
              // Allergies Section
              Text(
                'Allergies',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _allergiesController,
                decoration: InputDecoration(
                  labelText: 'List your allergies',
                  hintText: 'e.g., Peanuts, Shellfish, Dairy',
                  helperText: 'Separate multiple allergies with commas',
                  prefixIcon: const Icon(Icons.warning_amber_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _saveChanges,
          icon: const Icon(Icons.save),
          label: const Text('Save Changes'),
        ),
      ],
    );
  }

  Widget _buildCheckboxTile(
    String title,
    bool? value,
    Function(bool?) onChanged,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: value == true 
              ? color.withOpacity(0.5) 
              : Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(8),
        color: value == true 
            ? color.withOpacity(0.1) 
            : null,
      ),
      child: CheckboxListTile(
        title: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: value == true ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
        value: value ?? false,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }

  String _getDietLabel(DietPreference diet) {
    switch (diet) {
      case DietPreference.vegetarian:
        return 'Vegetarian';
      case DietPreference.vegan:
        return 'Vegan';
      case DietPreference.nonVegetarian:
        return 'Non-Vegetarian';
      case DietPreference.pescatarian:
        return 'Pescatarian';
    }
  }
}
