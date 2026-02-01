import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// ต้องสร้างไฟล์ config.dart และมีตัวแปร baseUrl อยู่ในนั้น
import '../utils/config.dart' as Config;

// 🌟 URL ฐานสำหรับการเรียก API
const String _baseUrl = Config.baseUrl; // สมมติว่า Config.baseUrl ถูกกำหนดไว้ใน config.dart

class AuthService {

  /// ดึง Token จาก SharedPreferences
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('authToken');
    } catch (e) {
      print("Read token error: $e");
      return null;
    }
  }

  /// ล็อกอินด้วย Email/Password, เรียก API, และบันทึก Token
  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data["accessToken"]; // ปรับ key ตาม API ของคุณ

        // 🌟 บันทึก Token ลง SharedPreferences (สำคัญมาก)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', token);

        return true;
      } else {
        print("Login failed: Status ${response.statusCode}, Body: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error during login API call: $e");
      return false;
    }
  }
}