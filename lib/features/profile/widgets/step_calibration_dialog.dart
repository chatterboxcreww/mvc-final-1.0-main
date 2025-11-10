// lib/features/profile/widgets/step_calibration_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/improved_step_counter_provider.dart';

class StepCalibrationDialog extends StatefulWidget {
  const StepCalibrationDialog({Key? key}) : super(key: key);

  @override
  State<StepCalibrationDialog> createState() => _StepCalibrationDialogState();
}

class _StepCalibrationDialogState extends State<StepCalibrationDialog> {
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _strideLengthController = TextEditingController();
  final _manualAdjustmentController = TextEditingController();
  
  bool _useAutoCalibration = true;
  
  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _strideLengthController.dispose();
    _manualAdjustmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.tune, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 12),
                  const Text(
                    'Step Tracking Calibration',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Auto vs Manual Calibration Toggle
              SwitchListTile(
                title: const Text('Automatic Calibration'),
                subtitle: const Text('Calculate stride based on height and weight'),
                value: _useAutoCalibration,
                onChanged: (value) {
                  if (mounted) {
                    setState(() {
                      _useAutoCalibration = value;
                    });
                  }
                },
              ),
              
              const SizedBox(height: 16),
              
              if (_useAutoCalibration) ...[
                // Auto Calibration Fields
                TextField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Height (cm)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.height),
                    helperText: 'Your height in centimeters',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.monitor_weight),
                    helperText: 'Your weight in kilograms',
                  ),
                ),
              ] else ...[
                // Manual Calibration Field
                TextField(
                  controller: _strideLengthController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Stride Length (meters)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.straighten),
                    helperText: 'Average: 0.762m (measure by walking 10 steps)',
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'How to measure stride length:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. Mark a starting point\n'
                        '2. Walk 10 normal steps\n'
                        '3. Measure the distance\n'
                        '4. Divide by 10',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              
              // Manual Step Adjustment
              const Text(
                'Manual Step Adjustment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Adjust today\'s step count if you notice an error',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _manualAdjustmentController,
                keyboardType: TextInputType.numberWithOptions(signed: true),
                decoration: const InputDecoration(
                  labelText: 'Adjustment (+/-)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit),
                  helperText: 'Enter positive or negative number (e.g., +100 or -50)',
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saveCalibration,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveCalibration() async {
    final provider = Provider.of<ImprovedStepCounterProvider>(
      context,
      listen: false,
    );
    
    try {
      // Apply calibration
      if (_useAutoCalibration) {
        final height = double.tryParse(_heightController.text);
        final weight = double.tryParse(_weightController.text);
        
        if (height != null && weight != null && height > 0 && weight > 0) {
          await provider.updateUserCalibration(
            height: height,
            weight: weight,
          );
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Calibration saved successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enter valid height and weight'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      } else {
        final strideLength = double.tryParse(_strideLengthController.text);
        
        if (strideLength != null && strideLength > 0 && strideLength < 2) {
          await provider.calibrateStride(strideLength);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Stride length calibrated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enter a valid stride length (0.5-2.0m)'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }
      
      // Apply manual adjustment if provided
      final adjustment = int.tryParse(_manualAdjustmentController.text);
      if (adjustment != null && adjustment != 0) {
        await provider.adjustSteps(adjustment);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Steps adjusted by $adjustment'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving calibration: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Helper function to show the dialog
void showStepCalibrationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const StepCalibrationDialog(),
  );
}
