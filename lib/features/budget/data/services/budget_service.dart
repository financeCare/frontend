import 'dart:convert';
import '../../domain/models/budget_overview.dart';
import '../../domain/models/budget_response.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/config.dart';
import '../../../../features/auth/data/services/access_token_service.dart';

class BudgetService {
  final String url = '$baseUrl/api/budget';
  final storage = FlutterSecureStorage();

  Future<List<BudgetResponse>> getBudget() async {
    String? accessToken = await AccesstokenService().getAccessToken();
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );
    print("budget status code : ${response.statusCode}");
    print("budget body : ${response.body}");
    if (response.statusCode == 200) {
      if (response.body.isEmpty) return [];
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => BudgetResponse.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Authorization failed (401). Please log in again.');
    } else if (response.statusCode == 403) {
      throw Exception(
        'Forbidden (403). You do not have permission to access this resource.',
      );
    } else {
      String errorMessage =
          'Failed to load budget (Status ${response.statusCode})';
      try {
        final errorBody = json.decode(response.body);
        errorMessage = errorBody['message'] ?? errorMessage;
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }

  Future<List<BudgetOverview>> getAmountInBudget() async {
    String? accessToken = await AccesstokenService().getAccessToken();
    final response = await http.get(
      Uri.parse("$url/overview"),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );
    print("budget status code : ${response.statusCode}");
    print("budget body : ${response.body}");
    if (response.statusCode == 200) {
      if (response.body.isEmpty) return [];
      final List<dynamic> jsonList = json.decode(response.body);
      print(jsonList.map((json) => BudgetOverview.fromJson(json)).toList());
      return jsonList.map((json) => BudgetOverview.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Authorization failed (401). Please log in again.');
    } else if (response.statusCode == 403) {
      throw Exception(
        'Forbidden (403). You do not have permission to access this resource.',
      );
    } else {
      String errorMessage =
          'Failed to load budget (Status ${response.statusCode})';
      try {
        final errorBody = json.decode(response.body);
        errorMessage = errorBody['message'] ?? errorMessage;
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }

  Future<void> updateBudgetLimit(String budgetId, double newLimit) async {
    String? accessToken = await AccesstokenService().getAccessToken();
    final response = await http.put(
      Uri.parse("$url/$budgetId/amount/$newLimit"),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );
    print("budget id : $budgetId");
    print("new limit : $newLimit");
    print("update budget status code : ${response.statusCode}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("Budget updated successfully.");
    } else if (response.statusCode == 401) {
      throw Exception('Authorization failed (401). Please log in again.');
    } else if (response.statusCode == 403) {
      throw Exception(
        'Forbidden (403). You do not have permission to access this resource.',
      );
    } else {
      String errorMessage =
          'Failed to update budget (Status ${response.statusCode})';
      try {
        final errorBody = json.decode(response.body);
        errorMessage = errorBody['message'] ?? errorMessage;
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }

  Future<List<BudgetOverview>> getTransactionsOverview() async {
    String? accessToken = await AccesstokenService().getAccessToken();
    final response = await http.get(
      Uri.parse("$url/transactions-overview"),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );
    print("transactions-overview status code : ${response.statusCode}");
    print("transactions-overview body : ${response.body}");
    if (response.statusCode == 200) {
      if (response.body.isEmpty) return [];
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => BudgetOverview.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Authorization failed (401). Please log in again.');
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden (403).');
    } else {
      throw Exception(
        'Failed to load transaction overview (${response.statusCode})',
      );
    }
  }

  Future<double> getIncomeAmount() async {
    String? accessToken = await AccesstokenService().getAccessToken();
    final response = await http.get(
      Uri.parse("$url/income-amount"),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return double.tryParse(response.body.trim()) ?? 0.0;
    } else {
      return 0.0;
    }
  }
}
