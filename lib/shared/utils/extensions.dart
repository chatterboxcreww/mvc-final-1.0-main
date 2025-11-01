// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\shared\utils\extensions.dart

// lib/shared/utils/extensions.dart

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

extension DateTimeExtension on DateTime {
  String monthName() {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return monthNames[month - 1];
  }
}
