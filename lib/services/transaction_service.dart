import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/transaction.dart'; // โมเดล Transaction ของคุณ
import '../utils/config.dart';       // ไฟล์ config.dart ที่มี baseUrl
import '../services/api_service.dart';       // 🌟 Import AuthService เพื่อดึง Token (ตรวจสอบ path ให้ถูกต้อง)


class TransactionService {

  // 1. กำหนด Base URL จาก config.dart
  static const String _basePath = baseUrl;
  final String _transactionsUrl = '$_basePath/api/transactions';

  // 2. สร้าง Instance ของ AuthService เพื่อใช้ดึง Token
  final AuthService _authService = AuthService();


  /// ฟังก์ชันสำหรับดึงรายการธุรกรรมทั้งหมดของผู้ใช้
  Future<List<Transaction>> getOwnTransactions() async {
  
    // 3. ดึง Token จาก AuthService
    final String? authToken = await _authService.getToken();
print(authToken);
if
    (authToken == null) {
      // โยน Exception หากไม่มี Token (ทำให้ FutureBuilder แสดง Error)
      throw Exception('Authentication token is missing. Please log in.');
    }

    // 4. สร้าง HTTP Request โดยใส่ Authorization Header
    final response = await http.get(
      Uri.parse(_transactionsUrl),
      headers: {
        // 🌟 นี่คือส่วนที่ทำให้ Token "ทำงาน" ได้
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json', // Optional สำหรับ GET
      },
    );

    if (response.statusCode == 200) {
      // 5. แปลง JSON Array เป็น List<Transaction>
      if (response.body.isEmpty) return [];

      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Transaction.fromJson(json)).toList();

    } else if (response.statusCode == 401) {
      // Token หมดอายุ หรือไม่ถูกต้อง
      throw Exception('Authorization failed (401). Please log in again.');
    } else if (response.statusCode == 403) {
      // Token มีสิทธิ์ไม่พอ
      throw Exception('Forbidden (403). You do not have permission to access this resource.');
    } else {
      // 6. จัดการ Error อื่น ๆ
      String errorMessage = 'Failed to load transactions (Status ${response.statusCode})';
      try {
        final errorBody = json.decode(response.body);
        errorMessage = errorBody['message'] ?? errorMessage;
      } catch (_) {
        // Do nothing if body is not JSON
      }
      throw Exception(errorMessage);
    }
  }
}