import 'dart:convert';
import 'package:financeCare/models/budgetOverview.dart';
import 'package:financeCare/models/category.dart';
import 'package:financeCare/models/finance_item.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../utils/config.dart'; 
import 'accessToken_service.dart';

class CategoryService {
  final String _url = '$baseUrl/categories';
  final storage = FlutterSecureStorage();

  Future<List<Categories>> getCategories() async {
  String? accessToken = await AccesstokenService().getAccessToken();
    final response = await http.get(
      Uri.parse(_url),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );
    print("category status code : ${response.statusCode}");
    print("category body : ${response.body}");
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
          'Failed to load budget (Status ${response.statusCode})';
      try {
        final errorBody = json.decode(response.body);
        errorMessage = errorBody['message'] ?? errorMessage;
      } catch (_) {
      }
      throw Exception(errorMessage);
    }
  }  

    Future<Categories?> getCategoryById(int categoryId) async {
    try {
      String? accessToken = await AccesstokenService().getAccessToken();

      final response = await http.get(
        Uri.parse("$_url/$categoryId"),
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
      } 
      else if (response.statusCode == 401) {
        throw Exception("Unauthorized (401). Please login again.");
      } 
      else if (response.statusCode == 403) {
        throw Exception("Forbidden (403). No permission.");
      } 
      else {
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

  Future<List<FinanceItem>> mapCategoryIncomeToFinanceItem() async {
    try {
      final categories = await getCategories();

      List<FinanceItem> incomeItem = categories
          .where((c) => c.type == 'Income')
          .map(
            (c) => FinanceItem(
              name: c.categoryName,
              amount: 0,
              createdAt: DateTime.now(),
            ),
          )
          .toList();

      return incomeItem;
    } catch (error) {
      print("Error fetching categories: $error");
      return []; // return ค่าเผื่อ error
    }
  }


}