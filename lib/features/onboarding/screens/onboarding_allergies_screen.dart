// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\onboarding\screens\onboarding_allergies_screen.dart

// lib/features/onboarding/screens/onboarding_allergies_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/user_data.dart';
import '../../../core/providers/user_data_provider.dart';
import '../widgets/onboarding_progress_indicator.dart';
import 'onboarding_beverage_preferences_screen.dart';

class OnboardingAllergiesScreen extends StatefulWidget {
  final bool isEditing;
  const OnboardingAllergiesScreen({super.key, this.isEditing = false});

  @override
  State<OnboardingAllergiesScreen> createState() => _OnboardingAllergiesScreenState();
}

class _OnboardingAllergiesScreenState extends State<OnboardingAllergiesScreen> {
  final TextEditingController _allergyController = TextEditingController();
  List<String> _allergies = [];
  final FocusNode _allergyFocusNode = FocusNode();
  
  // Error handling
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _allergies = List.from(Provider.of<UserDataProvider>(context, listen: false).userData.allergies ?? []);
  }

  @override
  void dispose() {
    _allergyController.dispose();
    _allergyFocusNode.dispose();
    super.dispose();
  }

  void _addAllergy() {
    if (_allergyController.text.trim().isNotEmpty) {
      if(mounted){
        setState(() {
          final newAllergy = _allergyController.text.trim();
          if(!_allergies.map((a) => a.toLowerCase()).contains(newAllergy.toLowerCase())) {
            _allergies.add(newAllergy);
          }
          _allergyController.clear();
          _allergyFocusNode.requestFocus();
        });
      }
    }
  }

  void _removeAllergy(int index) {
    if(mounted){
      setState(() {
        _allergies.removeAt(index);
      });
    }
  }

  void _nextPage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    final userDataProvider = Provider.of<UserDataProvider>(context, listen: false);
    final updatedData = UserData.fromJson(userDataProvider.userData.toJson())
      ..allergies = _allergies;
    
    // Validate data before saving
    Map<String, String> validationErrors = updatedData.validate();
    if (validationErrors.isNotEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = validationErrors.values.join('\n');
      });
      _showErrorDialog(_errorMessage!);
      return;
    }
    
    // Update user data with error handling
    bool success = await userDataProvider.updateUserData(updatedData);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = userDataProvider.lastError;
      });
      
      if (!success) {
        _showErrorDialog(_errorMessage ?? 'Failed to update user data');
        return;
      }
      
      // Verify data integrity
      await userDataProvider.checkAndFixDataIntegrity();
      
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
            OnboardingBeveragePreferencesScreen(isEditing: widget.isEditing),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
          settings: RouteSettings(
            name: 'OnboardingBeveragePreferencesScreen${widget.isEditing ? "_Edit" : ""}',
          ),
        ),
      );
    }
  }
  
  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    
    // For progress indicator
    const int totalSteps = 4; // Personal Info, Lifestyle, Health, Allergies & Beverages
    const int currentProgressStep = 4; // Allergies is part of the fourth major step
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit: Allergies' : 'Food Allergies'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const OnboardingProgressIndicator(
              currentStep: currentProgressStep,
              totalSteps: totalSteps,
              stepLabels: ['Personal', 'Lifestyle', 'Health', 'Preferences'],
            ),
            const SizedBox(height: 24),
            Text(
              'List any food allergies',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold, 
                color: colorScheme.onSurface
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This helps us provide safer food recommendations. This step is optional.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _allergyController,
                    focusNode: _allergyFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Type allergy and press Add',
                      hintText: 'e.g., Peanuts, Gluten, Shellfish',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    onSubmitted: (_) => _addAllergy(),
                    textInputAction: TextInputAction.done,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _addAllergy,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(90, 56),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _allergies.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.no_food_outlined,
                            size: 64,
                            color: Color.fromRGBO(colorScheme.onSurfaceVariant.red, colorScheme.onSurfaceVariant.green, colorScheme.onSurfaceVariant.blue, 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No allergies added',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You can add them now or tap "Next" to continue',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic, 
                              color: Color.fromRGBO(colorScheme.onSurfaceVariant.red, colorScheme.onSurfaceVariant.green, colorScheme.onSurfaceVariant.blue, 0.7),
                            ),
                          ),
                        ],
                      ),
                    )
                  : AnimatedList(
                      initialItemCount: _allergies.length,
                      itemBuilder: (context, index, animation) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Icon(Icons.warning_amber_rounded, color: colorScheme.error),
                              title: Text(_allergies[index], style: TextStyle(color: colorScheme.onSurface)),
                              trailing: IconButton(
                                icon: Icon(Icons.remove_circle_outline, color: colorScheme.error),
                                onPressed: () => _removeAllergy(index),
                                tooltip: 'Remove allergy',
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (Navigator.canPop(context))
                  OutlinedButton.icon(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    label: const Text('Back'),
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                const Spacer(),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                  ),
                ElevatedButton.icon(
                  icon: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.arrow_forward_ios_rounded),
                  label: Text(widget.isEditing ? 'Save & Next' : 'Next'),
                  onPressed: _isLoading ? null : _nextPage,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
