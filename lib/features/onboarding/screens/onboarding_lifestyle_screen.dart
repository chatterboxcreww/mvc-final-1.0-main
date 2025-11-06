// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\onboarding\screens\onboarding_lifestyle_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/app_enums.dart';
import '../../../core/providers/user_data_provider.dart';
import '../../../shared/widgets/fluid_page_route.dart';
import 'onboarding_health_stepper_screen.dart';

class OnboardingLifestyleScreen extends StatefulWidget {
  const OnboardingLifestyleScreen({super.key, this.isEditing = false});
  final bool isEditing;

  @override
  State<OnboardingLifestyleScreen> createState() =>
      _OnboardingLifestyleScreenState();
}

class _OnboardingLifestyleScreenState
    extends State<OnboardingLifestyleScreen> {
  final List<DietPreference> _diets = const [
    DietPreference.vegetarian,
    DietPreference.nonVegetarian,
  ];
  DietPreference? _diet;
  TimeOfDay? _sleep, _wake;
  String? _activity;
  int _water = 8;
  bool _coffee = false, _tea = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) _prefill();
  }

  void _prefill() {
    final u = context.read<UserDataProvider>().userData;
    _diet = u.dietPreference;
    _sleep = u.sleepTime;
    _wake = u.wakeupTime;
    _activity = u.activityLevel;
    _water = u.dailyWaterGoal ?? 8;
    _coffee = u.prefersCoffee ?? false;
    _tea = u.prefersTea ?? false;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_diet == null ||
        _sleep == null ||
        _wake == null ||
        _activity == null) {
      _error('Please complete all fields');
      return;
    }

    setState(() => _saving = true);
    final prov = context.read<UserDataProvider>();
    final ok = await prov.updateUserData(
      prov.userData.copyWith(
        dietPreference: _diet,
        sleepTime: _sleep,
        wakeupTime: _wake,
        activityLevel: _activity,
        dailyWaterGoal: _water,
        prefersCoffee: _coffee,
        prefersTea: _tea,
      ),
      isOnboarding: true, // Immediate Firebase sync during onboarding
    );

    if (!mounted) return;
    if (ok) {
      widget.isEditing
          ? Navigator.pop(context)
          : Navigator.push(
        context,
        FluidPageRoute(page: const OnboardingHealthStepperScreen()),
      );
    } else {
      _error('Save failed. Try again');
    }
    setState(() => _saving = false);
  }

  void _error(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _pickTime(bool isSleep) async {
    final t = await showTimePicker(
      context: context,
      initialTime: isSleep
          ? (_sleep ?? const TimeOfDay(hour: 22, minute: 0))
          : (_wake ?? const TimeOfDay(hour: 7, minute: 0)),
    );
    if (t != null) setState(() => isSleep ? _sleep = t : _wake = t);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title:
        Text(widget.isEditing ? 'Edit Lifestyle' : 'Lifestyle & Preferences'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle('Diet Preference'),
            Wrap(
              spacing: 8,
              children: _diets
                  .map((d) => ChoiceChip(
                label: Text(d.name),
                selected: _diet == d,
                selectedColor: Theme.of(context).chipTheme.selectedColor,
                onSelected: (_) => setState(() => _diet = d),
              ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            _sectionTitle('Beverage Preferences'),
            CheckboxListTile(
              title: const Text('I prefer coffee'),
              value: _coffee,
              onChanged: (v) => setState(() => _coffee = v ?? false),
            ),
            CheckboxListTile(
              title: const Text('I prefer tea'),
              value: _tea,
              onChanged: (v) => setState(() => _tea = v ?? false),
            ),
            const SizedBox(height: 24),
            _sectionTitle('Sleep Schedule'),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.bedtime_outlined),
                    title: Text(_sleep?.format(context) ?? 'Sleep Time'),
                    onTap: () => _pickTime(true),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.wb_sunny_outlined),
                    title: Text(_wake?.format(context) ?? 'Wake-up Time'),
                    onTap: () => _pickTime(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _sectionTitle('Activity Level'),
            Column(
              children: ['Sedentary', 'Moderate', 'Very Active']
                  .map(
                    (l) => RadioListTile(
                  title: Text(l),
                  value: l,
                  groupValue: _activity,
                  onChanged: (v) => setState(() => _activity = v!),
                ),
              )
                  .toList(),
            ),
            const SizedBox(height: 24),
            _sectionTitle('Daily Water Goal'),
            Row(
              children: [
                IconButton(
                  onPressed: _water > 4 ? () => setState(() => _water--) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$_water glasses',
                    style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  onPressed: _water < 15 ? () => setState(() => _water++) : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
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
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.bold)),
  );
}

