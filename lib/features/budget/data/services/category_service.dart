import 'dart:convert';
import 'package:flutter_application_1/features/budget/domain/models/budgetDto.dart';
import 'package:flutter_application_1/features/debt/domain/models/debt_dto.dart';

import '../../domain/models/category.dart';
import 'budget_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/config.dart';
import '../../../../features/auth/data/services/access_token_service.dart';

class CategoryService {
  final String _url = '$baseUrl/api/categories';
  
  Future<List<Categories>> getCategories() async {
    String? accessToken = await AccesstokenService().getAccessToken();
    
    final response = await http.get(
      Uri.parse(_url),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      if (response.body.isEmpty) return [];
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Categories.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Authorization failed (401). Please log in again.');
    } else if (response.statusCode == 403) {
      throw Exception(
        'Forbidden (403). You do not have permission to access this resource.',
      );
    } else {
      String errorMessage =
          'Failed to load categories (Status ${response.statusCode})';
      try {
        final errorBody = json.decode(response.body);
        errorMessage = errorBody['message'] ?? errorMessage;
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }

  Future<Categories?> getCategoryById(int categoryId) async {
    try {
      String? accessToken = await AccesstokenService().getAccessToken();
      final String finalUrl = "$_url/$categoryId";

      final response = await http.get(
        Uri.parse(finalUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      print("Category status code: ${response.statusCode}");
      print("Category body: ${response.body}");

      if (response.statusCode == 200) {
        if (response.body.isEmpty) return null;
        final jsonData = json.decode(response.body);
        return Categories.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception("Unauthorized (401). Please login again.");
      } else if (response.statusCode == 403) {
        throw Exception("Forbidden (403). No permission.");
      } else {
        String message = "Error loading category (${response.statusCode})";
        try {
          final errorBody = json.decode(response.body);
          message = errorBody["message"] ?? message;
        } catch (_) {}
        throw Exception(message);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<budgetDto>> mapCategoryIncomeToDebtDto() async {
    try {
      // ดึง budget list
      final budgets = await BudgetService().getBudget(); // List<BudgetResponse>
      final categories = await getCategories();

      // สมมติเราจะเอา budget[0] เป็นตัวอย่าง
      final budget = budgets.isNotEmpty ? budgets[0] : null;

      List<budgetDto> incomeItem = categories
          .where((c) => c.type == 'Income')
          .map(
            (c) => budgetDto(
              id: c.categoryId,
              name: c.categoryName.toString(),
              amount: budget?.amount ?? 0.0, // ถ้าไม่มี budget จะเป็น 0
              createdAt: DateTime.now(),
            ),
          )
          .toList();

      print("income length: ${incomeItem.length}");
      return incomeItem;
    } catch (error) {
      print("Error fetching categories: $error");
      return []; // return ค่าเผื่อ error
    }
  }
}
