// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\profile\widgets\edit_personal_details_dialog.dart

// lib/features/profile/widgets/edit_personal_details_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/user_data.dart';
import '../../../core/providers/user_data_provider.dart';

class EditPersonalDetailsDialog extends StatefulWidget {
  const EditPersonalDetailsDialog({super.key});

  @override
  State<EditPersonalDetailsDialog> createState() => _EditPersonalDetailsDialogState();
}

class _EditPersonalDetailsDialogState extends State<EditPersonalDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    final userData = Provider.of<UserDataProvider>(context, listen: false).userData;
    _nameController = TextEditingController(text: userData.name);
    _ageController = TextEditingController(text: userData.age?.toString() ?? '');
    _heightController = TextEditingController(text: userData.height?.toString() ?? '');
    _weightController = TextEditingController(text: userData.weight?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final userDataProvider = Provider.of<UserDataProvider>(context, listen: false);
      final currentData = userDataProvider.userData;

      final updatedData = UserData.fromJson(currentData.toJson())
        ..name = _nameController.text.trim()
        ..age = int.tryParse(_ageController.text.trim())
        ..height = double.tryParse(_heightController.text.trim())
        ..weight = double.tryParse(_weightController.text.trim());

      await userDataProvider.updateUserData(updatedData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Personal info updated!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Personal Info'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person_outline)), validator: (value) => value!.isEmpty ? 'Please enter your name' : null,),
              const SizedBox(height: 16),
              TextFormField(controller: _ageController, decoration: const InputDecoration(labelText: 'Age', prefixIcon: Icon(Icons.cake_outlined)), keyboardType: TextInputType.number, validator: (value) { if (value!.isEmpty) return 'Please enter your age'; if (int.tryParse(value) == null || int.parse(value) <= 0) return 'Please enter a valid age'; return null; },),
              const SizedBox(height: 16),
              TextFormField(controller: _heightController, decoration: const InputDecoration(labelText: 'Height (cm)', prefixIcon: Icon(Icons.height)), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (value) { if (value!.isEmpty) return 'Please enter your height'; if (double.tryParse(value) == null || double.parse(value) <= 0) return 'Please enter a valid height'; return null; },),
              const SizedBox(height: 16),
              TextFormField(controller: _weightController, decoration: const InputDecoration(labelText: 'Weight (kg)', prefixIcon: Icon(Icons.scale_outlined)), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (value) { if (value!.isEmpty) return 'Please enter your weight'; if (double.tryParse(value) == null || double.parse(value) <= 0) return 'Please enter a valid weight'; return null; },),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'),),
        ElevatedButton(onPressed: _saveChanges, child: const Text('Save Changes'),),
      ],
    );
  }
}
