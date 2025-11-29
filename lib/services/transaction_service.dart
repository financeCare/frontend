import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/transaction.dart';
import '../utils/config.dart'; 
import 'accessToken_service.dart';

class TransactionService {
  final String _transactionsUrl = '$baseUrl/api/transactions';
  final storage = FlutterSecureStorage();

  Future<List<Transaction>> getOwnTransactions() async {
  String? accessToken = await AccesstokenService().getAccessToken();
    final response = await http.get(
      Uri.parse(_transactionsUrl),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );
    print("transaction status code : ${response.statusCode}");
    print("transaction body : ${response.body}");
    if (response.statusCode == 200) {
      if (response.body.isEmpty) return [];
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Transaction.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Authorization failed (401). Please log in again.');
    } else if (response.statusCode == 403) {
      throw Exception(
        'Forbidden (403). You do not have permission to access this resource.',
      );
    } else {
      // 6. จัดการ Error อื่น ๆ
      String errorMessage =
          'Failed to load transactions (Status ${response.statusCode})';
      try {
        final errorBody = json.decode(response.body);
        errorMessage = errorBody['message'] ?? errorMessage;
      } catch (_) {
        // Do nothing if body is not JSON
      }
      throw Exception(errorMessage);
    }
  }

  Future<List<Transaction>> createTransaction () async {
  String? accessToken = await AccesstokenService().getAccessToken();
    final response = await http.get(
      Uri.parse("$_transactionsUrl"),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );
    print("transaction status code : ${response.statusCode}");
    print("transaction body : ${response.body}");
    if (response.statusCode == 200) {
      if (response.body.isEmpty) return [];
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Transaction.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      // Token หมดอายุ หรือไม่ถูกต้อง
      throw Exception('Authorization failed (401). Please log in again.');
    } else if (response.statusCode == 403) {
      // Token มีสิทธิ์ไม่พอ
      throw Exception(
        'Forbidden (403). You do not have permission to access this resource.',
      );
    } else {
      // 6. จัดการ Error อื่น ๆ
      String errorMessage =
          'Failed to load transactions (Status ${response.statusCode})';
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
