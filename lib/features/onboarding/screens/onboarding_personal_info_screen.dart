// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\onboarding\screens\onboarding_personal_info_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/app_enums.dart';
import '../../../core/providers/user_data_provider.dart';
import '../../../shared/widgets/fluid_page_route.dart';
import 'onboarding_lifestyle_screen.dart';

class OnboardingPersonalInfoScreen extends StatefulWidget {
  const OnboardingPersonalInfoScreen({super.key, this.isEditing = false});
  final bool isEditing;

  @override
  State<OnboardingPersonalInfoScreen> createState() =>
      _OnboardingPersonalInfoScreenState();
}

class _OnboardingPersonalInfoScreenState
    extends State<OnboardingPersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _dailyGoal = TextEditingController(text: '10000');
  Gender? _gender;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) _prefill();
  }

  void _prefill() {
    final u = context.read<UserDataProvider>().userData;
    _name.text = u.name ?? '';
    _age.text = u.age?.toString() ?? '';
    _height.text = u.height?.toString() ?? '';
    _weight.text = u.weight?.toString() ?? '';
    _dailyGoal.text = u.dailyStepGoal?.toString() ?? '10000';
    _gender = u.gender;
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    _dailyGoal.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final prov = context.read<UserDataProvider>();
    final ok = await prov.updateUserData(
      prov.userData.copyWith(
        name: _name.text.trim(),
        age: int.tryParse(_age.text),
        height: double.tryParse(_height.text),
        weight: double.tryParse(_weight.text),
        gender: _gender,
        dailyStepGoal: int.tryParse(_dailyGoal.text) ?? 10000,
      ),
      isOnboarding: true, // Immediate Firebase sync during onboarding
    );

    if (!mounted) return;
    if (ok) {
      widget.isEditing
          ? Navigator.pop(context)
          : Navigator.push(
        context,
        FluidPageRoute(page: const OnboardingLifestyleScreen()),
      );
    } else {
      _error('Could not save. Please try again.');
    }
    setState(() => _isSaving = false);
  }

  void _error(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Personal Info' : 'Personal Info'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                v == null || v.trim().length < 2 ? 'Enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _age,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  suffixText: 'years',
                  prefixIcon: Icon(Icons.cake_outlined),
                ),
                validator: (v) {
                  final age = int.tryParse(v ?? '');
                  return (age == null || age < 1 || age > 120)
                      ? 'Enter valid age'
                      : null;
                },
              ),
              const SizedBox(height: 16),
              _genderChips(cs),
              const SizedBox(height: 16),
              _numField(_height, 'Height', 'cm', Icons.height_outlined, 100, 250),
              const SizedBox(height: 16),
              _numField(
                  _weight, 'Weight', 'kg', Icons.monitor_weight_outlined, 30, 200),
              const SizedBox(height: 16),
              _numField(_dailyGoal, 'Daily Step Goal', 'steps',
                  Icons.directions_walk_outlined, 1000, 50000),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text(widget.isEditing ? 'Save Changes' : 'Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _genderChips(ColorScheme cs) => Wrap(
    spacing: 8,
    children: Gender.values.map((g) {
      final sel = _gender == g;
      return ChoiceChip(
        label: Text(g.name),
        selected: sel,
        selectedColor: Theme.of(context).chipTheme.selectedColor,
        onSelected: (_) => setState(() => _gender = g),
      );
    }).toList(),
  );

  Widget _numField(TextEditingController c, String label, String suffix,
      IconData icon, num min, num max) {
    return TextFormField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        prefixIcon: Icon(icon),
      ),
      validator: (v) {
        final n = num.tryParse(v ?? '');
        return (n == null || n < min || n > max) ? 'Enter valid $label' : null;
      },
    );
  }
}

