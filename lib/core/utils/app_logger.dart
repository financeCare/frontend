import 'package:flutter/foundation.dart';

/// Production-safe logger.
/// All messages are suppressed in release builds.
class AppLog {
  AppLog._();

  static void d(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print(message);
    }
  }

  static void e(String message, [Object? error]) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[ERROR] $message${error != null ? ': $error' : ''}');
    }
  }
}
