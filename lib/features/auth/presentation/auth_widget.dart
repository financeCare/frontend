import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/config.dart' as Config;
import '../data/services/access_token_service.dart';
import 'auth_manager.dart';

final storage = AccesstokenService.sharedStorage;
// 🌟 URL ฐานสำหรับการเรียก API
const String _baseUrl =
    Config.baseUrl; // สมมติว่า Config.baseUrl ถูกกำหนดไว้ใน config.dart

class AuthService {
  Future<bool> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/api/auth/login');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );
    print("login status : ${response.statusCode}");
    print("login body : ${response.body}");
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String accessToken = data['accessToken'];
      String refreshToken = data['refreshToken'];
      await AuthManager.saveToken(accessToken);
      await storage.write(key: "refreshToken", value: refreshToken);
    } else {
      return false;
    }
    return true;
  }

  Future<bool> sendOTP(String email) async {
    final url = Uri.parse('$_baseUrl/api/auth/send-otp/$email');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
    );
    print("login status : ${response.statusCode}");
    print("login body : ${response.body}");
    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> verifyOTP(String email, String otp, String password) async {
    final url = Uri.parse('$_baseUrl/api/auth/verify-otp');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "otp": otp}),
    );
    print("login status : ${response.statusCode}");
    print("login body : ${response.body}");
    if (response.statusCode == 200) {
      await login(email, password);
      return true;
    } else {
      return false;
    }
  }

  Future<bool> register(String email, String password, {String? name}) async {
    final url = Uri.parse('$_baseUrl/api/auth/register');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": name ?? email,
        "email": email,
        "password": password,
      }),
    );
    print("login status : ${response.statusCode}");
    print("login body : ${response.body}");
    if (response.statusCode == 201) {
      await sendOTP(email);
    } else {
      String errorMessage = "Registration failed";
      try {
        final data = jsonDecode(response.body);
        errorMessage = data['message'] ?? data['error'] ?? errorMessage;
      } catch (_) {
        errorMessage = response.body.isNotEmpty ? response.body : errorMessage;
      }
      throw Exception(errorMessage);
    }
    return true;
  }
}
