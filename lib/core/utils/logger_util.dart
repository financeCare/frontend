import 'package:flutter/foundation.dart';

class Logger {
  static void info(dynamic message) {
    if (kDebugMode) {
      print("[INFO] $message");
    }
  }

  static void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print("[ERROR] $message");
      if (error != null) print(error);
      if (stackTrace != null) print(stackTrace);
    }
  }

  static void debug(dynamic message) {
    if (kDebugMode) {
      print("[DEBUG] $message");
    }
  }
}
