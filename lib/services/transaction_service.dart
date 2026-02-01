import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart'; // 🚨 ต้องมี Package นี้
import '../models/transaction.dart';
import '../utils/config.dart' as Config;


class TransactionService {
  // *** 🚨 สำคัญมาก: กรุณาแก้ไข URL จริงของคุณที่นี่ ***
  // ปัญหาส่วนใหญ่คือการใช้ URL ที่ไม่ถูกต้อง (เช่น "your-api-domain.com")
  // ทำให้เซิร์ฟเวอร์ส่งหน้า HTML Error (404/500) กลับมาแทน JSON
  final String _baseUrl = Config.baseUrl; // ใช้ URL จาก config.dart
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<dynamic> getOwnTransactions() async {
    // 1. ดึง Token จาก Firebase Auth
    final user = _auth.currentUser;
    final String? token = await user?.getIdToken();

    // **🚨 จุดตรวจสอบ Token**
    if (token == null || token.isEmpty) {
      print('Error: No authentication token found (User: ${user?.uid}).');
      return null;
    }

    print('Auth Token successfully retrieved (Partial view: ${token.substring(0, 30)}...)');

    // 2. กำหนด HTTP Headers พร้อม Token
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      // นำ Token ใส่ในรูปแบบ Bearer
      'Authorization': 'Bearer $token',
    };

    // 3. ทำการเรียก API
    final uri = Uri.parse('$_baseUrl/transactions');
    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        // API success
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList;
      } else {
        // API call failed (เช่น 401 Unauthorized, 404 Not Found, 500 Server Error)
        // 🚨 ถ้าเกิด Status Code อื่นที่ไม่ใช่ 200 และ Server ตอบกลับเป็น HTML
        // จะเกิด FormatException ใน CrudPage (ซึ่งเรา Handle ไว้แล้ว)
        print('API Error (Status ${response.statusCode}): ${response.body}');
        return null;
      }
    } catch (e) {
      // 🚨 Network level error (เช่น ไม่สามารถเชื่อมต่อกับโฮสต์ได้)
      print('Network Error: $e');
      return null;
    }
  }
}