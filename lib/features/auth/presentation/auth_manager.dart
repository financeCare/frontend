import '../data/services/access_token_service.dart';

class AuthManager {
  static String? _token;

  static String? get token => _token;

  /// 1. เมธอดสำหรับเริ่มต้น (Initialization)
  /// โหลด Token ที่บันทึกไว้ทันทีที่แอปเปิด
  static Future<void> init() async {
    await loadToken();
  }

  /// บันทึก Token ลงในหน่วยความจำและ FlutterSecureStorage
  static Future<void> saveToken(String token) async {
    _token = token;
    final storage = AccesstokenService.sharedStorage;
    await storage.write(key: 'accessToken', value: token);
    print('Token saved successfully to SecureStorage.');
  }

  /// โหลด Token จาก FlutterSecureStorage เข้าสู่หน่วยความจำ
  static Future<void> loadToken() async {
    final storage = AccesstokenService.sharedStorage;
    _token = await storage.read(key: 'accessToken');
    print('Token loaded from SecureStorage: ${_token != null ? "Yes" : "No"}');
  }

  /// ลบ Token ออกจากหน่วยความจำและ FlutterSecureStorage
  static Future<void> clearToken() async {
    _token = null;
    final storage = AccesstokenService.sharedStorage;
    await storage.delete(key: 'accessToken');
    print('Token cleared successfully from SecureStorage.');
  }

  /// Logout: alias for clearToken (can be extended later)
  static Future<void> logout() async {
    await clearToken();
    final storage = AccesstokenService.sharedStorage;
    await storage.delete(key: 'refreshToken');
  }

  /// ตรวจสอบว่ามีการล็อกอินหรือไม่
  static bool get isLoggedIn => _token != null;
}