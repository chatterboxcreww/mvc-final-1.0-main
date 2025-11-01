// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\core\utils\app_lifecycle_handler.dart

import 'package:flutter/widgets.dart';

class AppLifecycleHandler extends WidgetsBindingObserver {
  final VoidCallback onResume;
  final VoidCallback onSuspend;

  AppLifecycleHandler({
    required this.onResume,
    required this.onSuspend,
  });

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        onResume();
        break;
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        onSuspend();
        break;
    }
  }
}

