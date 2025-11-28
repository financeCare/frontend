// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth/auth_manager.dart';
// ต้องมีการ import model นี้เพื่อแก้ compile error ที่พบก่อนหน้า
import '../models/budget_summary.dart';

class ApiService {
  // *** สำคัญ: เปลี่ยน Port จาก 8000 เป็น 8080
  // เพราะ Log แสดงว่า Spring Boot รันบน Port 8080
  // หากใช้ Android Emulator ให้ลองใช้ 'http://10.0.2.2:8080/api'
  static const String _baseUrl = 'http://192.168.1.100:8080/api';

  /// Getter สำหรับสร้าง HTTP Headers พร้อมแนบ Token
  Map<String, String> get _getHeaders {
    // กำหนด Headers พื้นฐาน
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // หากมี Token ให้เพิ่ม Authorization Header
    final token = AuthManager.token;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    } else {
      print('Warning: API call made without an Authorization Token.');
    }

    return headers;
  }

  // --- API Request Methods ---

  Future<dynamic> get(String endpoint) async {
    final uri = Uri.parse('$_baseUrl/$endpoint');
    try {
      final response = await http.get(uri, headers: _getHeaders);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('GET request failed: $e');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl/$endpoint');
    try {
      final response = await http.post(
        uri,
        headers: _getHeaders,
        body: json.encode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('POST request failed: $e');
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl/$endpoint');
    try {
      final response = await http.put(
        uri,
        headers: _getHeaders,
        body: json.encode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('PUT request failed: $e');
    }
  }

  Future<dynamic> delete(String endpoint) async {
    final uri = Uri.parse('$_baseUrl/$endpoint');
    try {
      final response = await http.delete(uri, headers: _getHeaders);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('DELETE request failed: $e');
    }
  }

  /// เมธอดสำหรับสร้างรายการธุรกรรมใหม่
  Future<dynamic> createTransaction(Map<String, dynamic> data) async {
    return post('transactions', data);
  }

  // เมธอด placeholder สำหรับ 'getBudgetSummary'
  Future<BudgetSummary> getBudgetSummary() async {
    final responseData = await get('budget/summary');
    // หากเชื่อมต่อสำเร็จจริง
    // return BudgetSummary.fromJson(responseData);

    // สำหรับตอนนี้ให้ใช้ Mock data หากยังไม่ได้เชื่อมต่อจริง
    return BudgetSummary(
      currentMonth: 'พฤศจิกายน 2568',
      totalBudget: 15000.0,
      totalSpent: 9500.0,
    );
  }

  // เมธอด placeholder สำหรับดึงรายการธุรกรรมทั้งหมด
  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final responseData = await get('transactions');
    // หากเชื่อมต่อสำเร็จจริง
    // return List<Map<String, dynamic>>.from(responseData);

    // สำหรับตอนนี้ให้ใช้ Mock data หากยังไม่ได้เชื่อมต่อจริง
    return [
      {'amount': 500.0, 'description': 'ค่าอาหารกลางวัน', 'category': 'อาหารและเครื่องดื่ม', 'type': 'expense', 'date': '2025-11-27'},
      {'amount': 1200.0, 'description': 'เงินเดือน', 'category': 'รายรับ', 'type': 'income', 'date': '2025-11-01'},
    ];
  }

  // --- Response Handler ---

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return {};
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized. Please log in again.');
    } else if (response.statusCode == 400 || response.statusCode == 422) {
      // 400 Bad Request หรือ 422 Unprocessable Entity (Validation Error)
      final errorBody = response.body.isNotEmpty
          ? json.decode(utf8.decode(response.bodyBytes))
          : 'Unknown error';
      throw Exception('Validation/Bad Request Error: $errorBody');
    }
    else {
      final errorBody = response.body.isNotEmpty
          ? json.decode(utf8.decode(response.bodyBytes))
          : 'Unknown error';
      throw Exception('API error: ${response.statusCode} - $errorBody');
    }
  }
}