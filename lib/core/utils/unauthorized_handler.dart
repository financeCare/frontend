import 'navigator_key.dart';
import 'app_logger.dart';
import 'package:flutter/material.dart';
import '../../features/auth/data/services/access_token_service.dart';

class UnauthorizedHandler {
  static bool _isRedirecting = false;

  /// Centralized handling for 401 Unauthorized to avoid Circular Dependency
  static Future<void> handleUnauthorized() async {
    if (_isRedirecting) {
      AppLog.d('Unauthorized already being handled. Skipping...');
      return;
    }
    _isRedirecting = true;

    AppLog.d('!!! Unauthorized (401) detected. Redirecting to Login...');

    // 1. Wipe state (Internal storage wipe)
    final storage = AccesstokenService.sharedStorage;
    await storage.deleteAll();
    
    AppLog.d('Cleared all storage via UnauthorizedHandler.');

    // 2. Immediate navigation to Welcome page (clearing stack)
    Future.microtask(() {
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/welcome', (route) => false);
    });

    // Reset flag after a while to allow new redirects in next sessions
    Future.delayed(const Duration(seconds: 5), () {
      _isRedirecting = false;
    });
  }
}
