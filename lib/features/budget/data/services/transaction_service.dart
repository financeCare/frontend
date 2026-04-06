import 'dart:convert';
import '../../domain/models/transaction_response.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../domain/models/transaction_request.dart';
import '../../../../core/config/config.dart';
import '../../../../features/auth/data/services/access_token_service.dart';
import '../../domain/models/transaction_detail.dart';

class TransactionService {
  final String _transactionsUrl = '$baseUrl/api/transactions';
  final storage = FlutterSecureStorage();

  Future<List<TransactionResponse>> getOwnTransactions() async {
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
      final List<dynamic> jsonList = json.decode(utf8.decode(response.bodyBytes));
      return jsonList
          .map((json) => TransactionResponse.fromJson(json))
          .toList();
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
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        errorMessage = errorBody['message'] ?? errorMessage;
      } catch (_) {
        // Do nothing if body is not JSON
      }
      throw Exception(errorMessage);
    }
  }

  Future<List<TransactionResponse>> getSalaryTransactions() async {
    // ดึงรายการทั้งหมดก่อน
    final allTransactions = await getOwnTransactions();

    // Filter เฉพาะ categoryName = "salary"
    final salaryTransactions = allTransactions
        .where((tx) => tx.category.categoryName.toLowerCase() == "salary")
        .toList();

    return salaryTransactions;
  }

  Future<List<TransactionResponse>> getPendingTransactions() async {
    // ดึงรายการทั้งหมดก่อน
    final allTransactions = await getOwnTransactions();

    // Filter เฉพาะรายการที่ยังไม่ได้ยืนยัน (สมมติว่าเช็คจาก categoryName = "pending")
    // และรายการที่มี slipId หรือ imagePath (รายการที่มาจาก OCR)
    final pendingTransactions = allTransactions
        .where((tx) => (tx.category.categoryName.toLowerCase() == "pending" || tx.category.categoryName == "Unknown"))
        .toList();

    return pendingTransactions;
  }

  Future<List<TransactionDetail>> getTransactionsByCategory(
    int categoryId,
  ) async {
    String? accessToken = await AccesstokenService().getAccessToken();
    final url = '$_transactionsUrl/category/$categoryId';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    print("transactions by category status: ${response.statusCode}");
    print("transactions by category body: ${response.body}");

    if (response.statusCode == 200) {
      if (response.body.isEmpty) return [];
      final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));

      // Page<Transaction> typically has a 'content' field
      final List<dynamic> content = data['content'] ?? [];
      return content.map((json) => TransactionDetail.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load transactions for category $categoryId');
    }
  }

  Future<void> createTransaction(TransactionRequest transaction) async {
    String? accessToken = await AccesstokenService().getAccessToken();

    final response = await http.post(
      Uri.parse(_transactionsUrl),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(transaction.toJson()),
    );

    print("transaction status code : ${response.statusCode}");
    print("transaction body : ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("Transaction created successfully.");
    } else if (response.statusCode == 401) {
      throw Exception('Authorization failed (401). Please log in again.');
    } else if (response.statusCode == 403) {
      throw Exception(
        'Forbidden (403). You do not have permission to access this resource.',
      );
    } else {
      String errorMessage =
          'Failed to create transaction (Status ${response.statusCode})';
      try {
        final errorBody = json.decode(response.body);
        errorMessage = errorBody['message'] ?? errorMessage;
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }

  Future<void> updateTransaction(String id, TransactionRequest transaction) async {
    String? accessToken = await AccesstokenService().getAccessToken();
    final url = '$_transactionsUrl/$id';

    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(transaction.toJson()),
    );

    print("update transaction status: ${response.statusCode}");

    if (response.statusCode != 200) {
      String errorMessage = 'Failed to update transaction';
      try {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        errorMessage = errorBody['message'] ?? errorMessage;
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }

  Future<void> deleteTransaction(String id) async {
    String? accessToken = await AccesstokenService().getAccessToken();
    final url = '$_transactionsUrl/$id';

    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    print("delete transaction status: ${response.statusCode}");

    if (response.statusCode != 200 && response.statusCode != 204) {
      String errorMessage = 'Failed to delete transaction';
      try {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        errorMessage = errorBody['message'] ?? errorMessage;
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }
}
