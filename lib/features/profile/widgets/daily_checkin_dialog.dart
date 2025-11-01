// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\profile\widgets\daily_checkin_dialog.dart

// f:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\profile\widgets\daily_checkin_dialog.dart

import 'package:flutter/material.dart';

class DailyCheckinDialog extends StatelessWidget {
  const DailyCheckinDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Daily Check-in'),
      content: const Text('Have you completed your daily goals today?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('No'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Yes'),
        ),
      ],
    );
  }
}

