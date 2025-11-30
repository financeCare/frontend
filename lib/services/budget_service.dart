import 'dart:convert';
import 'package:financeCare/models/budgetOverview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../utils/config.dart'; 
import 'accessToken_service.dart';

class BudgetService {
  final String _budgetUrl = '$baseUrl/budget/overview';
  final storage = FlutterSecureStorage();

  Future<List<BudgetOverview>> getAmountInBudget() async {
  String? accessToken = await AccesstokenService().getAccessToken();
    final response = await http.get(
      Uri.parse(_budgetUrl),
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
      } catch (_) {
      }
      throw Exception(errorMessage);
    }
  }
}