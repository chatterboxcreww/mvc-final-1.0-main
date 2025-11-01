// lib/features/auth/screens/age_gate_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/widgets/gradient_background.dart';
import 'permission_gate_screen.dart';

/// Neutral Age Gate Screen - Required for Google Play Families Policy
/// This screen collects the user's birthdate to determine age-appropriate content
class AgeGateScreen extends StatefulWidget {
  const AgeGateScreen({super.key});

  @override
  State<AgeGateScreen> createState() => _AgeGateScreenState();
}

class _AgeGateScreenState extends State<AgeGateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dayController = TextEditingController();
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _verifyAge() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final day = int.parse(_dayController.text.trim());
      final month = int.parse(_monthController.text.trim());
      final year = int.parse(_yearController.text.trim());

      // Additional validation for date components
      if (day < 1 || day > 31 || month < 1 || month > 12) {
        setState(() {
          _errorMessage = 'Please enter a valid date';
          _isLoading = false;
        });
        return;
      }

      // Validate date exists (handles leap years, etc.)
      DateTime birthDate;
      try {
        birthDate = DateTime(year, month, day);
      } catch (e) {
        setState(() {
          _errorMessage = 'Please enter a valid date';
          _isLoading = false;
        });
        return;
      }

      final now = DateTime.now();
      
      // Check if date is in the future
      if (birthDate.isAfter(now)) {
        setState(() {
          _errorMessage = 'Birthdate cannot be in the future';
          _isLoading = false;
        });
        return;
      }

      // Check if date is too far in the past (reasonable age limit)
      final maxAge = 120;
      if (now.year - birthDate.year > maxAge) {
        setState(() {
          _errorMessage = 'Please enter a valid birthdate';
          _isLoading = false;
        });
        return;
      }

      // Calculate age accurately
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month || 
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }

      // Store age and birthdate for content filtering with error handling
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_age', age);
        await prefs.setString('user_birthdate', birthDate.toIso8601String());
        await prefs.setBool('age_verified', true);

        // Determine content filter level
        final isChild = age < 13;
        await prefs.setBool('child_mode', isChild);

        print('AgeGateScreen: Age verification complete - Age: $age, Child mode: $isChild');

        if (mounted) {
          // Navigate to permission gate screen to check permissions
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const PermissionGateScreen(),
            ),
          );
        }
      } catch (storageError) {
        print('AgeGateScreen: Error saving age data: $storageError');
        setState(() {
          _errorMessage = 'Failed to save age information. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('AgeGateScreen: Error in age verification: $e');
      setState(() {
        _errorMessage = 'Please enter a valid date';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: GradientBackground(
        colors: [
          const Color(0xFF667eea),
          const Color(0xFF764ba2),
        ],
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo/Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Title
                  Text(
                    'Welcome to Health-TRKD',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Subtitle
                  Text(
                    'To provide you with age-appropriate content,\nplease enter your date of birth',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Birthdate Input Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date of Birth',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          Text(
                            'Enter your birthdate below',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Date Input Fields
                          Row(
                            children: [
                              // Day
                              Expanded(
                                flex: 2,
                                child: _buildDateField(
                                  controller: _dayController,
                                  label: 'Day',
                                  hint: 'DD',
                                  maxLength: 2,
                                  validator: (value) {
                                    if (value?.isEmpty == true) return 'Required';
                                    final day = int.tryParse(value!);
                                    if (day == null || day < 1 || day > 31) {
                                      return 'Invalid';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              
                              const SizedBox(width: 12),
                              
                              // Month
                              Expanded(
                                flex: 2,
                                child: _buildDateField(
                                  controller: _monthController,
                                  label: 'Month',
                                  hint: 'MM',
                                  maxLength: 2,
                                  validator: (value) {
                                    if (value?.isEmpty == true) return 'Required';
                                    final month = int.tryParse(value!);
                                    if (month == null || month < 1 || month > 12) {
                                      return 'Invalid';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              
                              const SizedBox(width: 12),
                              
                              // Year
                              Expanded(
                                flex: 3,
                                child: _buildDateField(
                                  controller: _yearController,
                                  label: 'Year',
                                  hint: 'YYYY',
                                  maxLength: 4,
                                  validator: (value) {
                                    if (value?.isEmpty == true) return 'Required';
                                    final year = int.tryParse(value!);
                                    final currentYear = DateTime.now().year;
                                    if (year == null || year < 1900 || year > currentYear) {
                                      return 'Invalid';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: colorScheme.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                        color: colorScheme.error,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 24),
                          
                          // Continue Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _verifyAge,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          colorScheme.onPrimary,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      'Continue',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Privacy Notice
                          Text(
                            'We collect your date of birth to ensure age-appropriate content and comply with privacy regulations. Your information is kept private and secure.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
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

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required int maxLength,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      maxLength: maxLength,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
      validator: validator,
      onChanged: (value) {
        // Auto-advance to next field
        if (value.length == maxLength) {
          FocusScope.of(context).nextFocus();
        }
      },
    );
  }
}
