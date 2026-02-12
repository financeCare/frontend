import 'dart:convert';
import '../../domain/models/transaction_response.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../domain/models/transaction_request.dart';
import '../../../../core/config/config.dart'; 
import '../../../../features/auth/data/services/access_token_service.dart';

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
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => TransactionResponse.fromJson(json)).toList();
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

Future<List<TransactionResponse>> getSalaryTransactions() async {
  // ดึงรายการทั้งหมดก่อน
  final allTransactions = await getOwnTransactions();
  
  // Filter เฉพาะ categoryName = "salary"
  final salaryTransactions = allTransactions
      .where((tx) => tx.categoryId == "salary")
      .toList();

  return salaryTransactions;
}


  Future <void> createTransaction(TransactionRequest transaction) async {
  String? accessToken = await AccesstokenService().getAccessToken();

  final response = await http.post(
    Uri.parse("$_transactionsUrl"),
    headers: {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({ 
      'categoryId': transaction.categoryId,
      'amount': transaction.amount,
      'transactionDate': transaction.transactionDate.toIso8601String(),
      'description': transaction.description,
    }),
  );

  print("transaction status code : ${response.statusCode}");
  print("transaction body : ${response.body}");

  if (response.statusCode == 200 || response.statusCode == 201) {
    print("Transaction created successfully.");
  }
  else if (response.statusCode == 401) {
    throw Exception('Authorization failed (401). Please log in again.');
  } else if (response.statusCode == 403) {
    throw Exception('Forbidden (403). You do not have permission to access this resource.');
  } else {
    String errorMessage = 'Failed to create transaction (Status ${response.statusCode})';
    try {
      final errorBody = json.decode(response.body);
      errorMessage = errorBody['message'] ?? errorMessage;
    } catch (_) {}
    throw Exception(errorMessage);
  }
}

  
}