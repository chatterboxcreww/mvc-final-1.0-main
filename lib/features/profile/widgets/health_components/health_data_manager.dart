// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\profile\widgets\health_components\health_data_manager.dart

// lib/features/profile/widgets/health_components/health_data_manager.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/user_data.dart';
import '../../../../core/providers/user_data_provider.dart';

/// Data class to hold health-related information
class HealthData {
  bool? hasDiabetes;
  bool? isSkinnyFat;
  bool? hasProteinDeficiency;
  List<String> allergies;

  HealthData({
    this.hasDiabetes,
    this.isSkinnyFat,
    this.hasProteinDeficiency,
    required this.allergies,
  });
}

/// Manages loading and saving health data
class HealthDataManager {
  /// Loads health data from the UserDataProvider
  static HealthData loadHealthData(BuildContext context) {
    final userData = Provider.of<UserDataProvider>(context, listen: false).userData;
    
    return HealthData(
      hasDiabetes: userData.hasDiabetes,
      isSkinnyFat: userData.isSkinnyFat,
      hasProteinDeficiency: userData.hasProteinDeficiency,
      allergies: List.from(userData.allergies ?? []),
    );
  }

  /// Saves health data to the UserDataProvider
  static Future<void> saveHealthData({
    required BuildContext context,
    required bool? hasDiabetes,
    required bool? isSkinnyFat,
    required bool? hasProteinDeficiency,
    required List<String> allergies,
  }) async {
    final userDataProvider = Provider.of<UserDataProvider>(context, listen: false);
    final currentData = userDataProvider.userData;
    
    final updatedData = UserData.fromJson(currentData.toJson())
      ..hasDiabetes = hasDiabetes
      ..isSkinnyFat = isSkinnyFat
      ..hasProteinDeficiency = hasProteinDeficiency
      ..allergies = allergies;

    await userDataProvider.updateUserData(updatedData);
  }

  /// Shows a success message after saving health data
  static void showSuccessMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Health info updated!'),
      ),
    );
  }
}
