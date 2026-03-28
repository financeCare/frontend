import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/config.dart'; // ไฟล์ config.dart ที่มี baseUrl
import 'package:jwt_decoder/jwt_decoder.dart';

class AccesstokenService {
  // TEMPORARY FIX: Disable encryption to bypass potential Keystore corruption
  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: false, // Changed from true to false
  );

  static const _storage = FlutterSecureStorage(aOptions: _androidOptions);

  static FlutterSecureStorage get sharedStorage => _storage;

  FlutterSecureStorage get storage => _storage;

  Future<String?> getAccessToken() async {
    try {
      String? accessToken = await storage.read(key: "accessToken");

      if (accessToken == null) {
        debugPrint("No accessToken found in storage");
        return null;
      }

      bool isTokenExpired;
      try {
        isTokenExpired = JwtDecoder.isExpired(accessToken);
      } catch (e) {
        debugPrint("!!! JWT DECODE ERROR: $e !!!");
        return null;
      }

      if (isTokenExpired) {
        String? refreshToken = await storage.read(key: "refreshToken");

        if (refreshToken == null) {
          debugPrint("No refreshToken found in storage");
          return null;
        }

        final response = await http.post(
          Uri.parse('$baseUrl/api/auth/refresh-token'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $refreshToken',
          },
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          String newAccessToken = responseData['accessToken'];
          await storage.write(key: "accessToken", value: newAccessToken);
          debugPrint('newAccessToken stored');
          return newAccessToken;
        } else {
          debugPrint("Refresh token failed: ${response.statusCode}");
          return null;
        }
      } else {
        return accessToken;
      }
    } catch (e) {
      debugPrint("!!! CRITICAL ERROR in getAccessToken: $e !!!");
      rethrow;
    }
  }
}
