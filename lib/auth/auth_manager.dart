import 'package:shared_preferences/shared_preferences.dart';

class AuthManager {
  static String? _token;

  static String? get token => _token;

  /// 1. เมธอดสำหรับเริ่มต้น (Initialization)
  /// โหลด Token ที่บันทึกไว้ทันทีที่แอปเปิด
  static Future<void> init() async {
    await loadToken();
  }

  /// บันทึก Token ลงในหน่วยความจำและ SharedPreferences
  static Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
    print('Token saved successfully.');
  }

  /// โหลด Token จาก SharedPreferences เข้าสู่หน่วยความจำ
  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('authToken');
    print('Token loaded: ${_token != null ? "Yes" : "No"}');
  }

  /// ลบ Token ออกจากหน่วยความจำและ SharedPreferences
  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    print('Token cleared successfully.');
  }

  /// ตรวจสอบว่ามีการล็อกอินหรือไม่
  static bool get isLoggedIn => _token != null;
}