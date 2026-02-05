import 'dart:async';
import 'dart:convert';
import 'dart:core';
import '../models/debtType_response.dart';
import '../models/debtDto.dart';
import '../models/debt_response.dart';
import '../models/repaymentType_response.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../utils/config.dart';
import 'accessToken_service.dart';
import '../models/debt_request.dart';

class DebtService {
  final String url = '$baseUrl/api/debts';
  final storage = FlutterSecureStorage();
  Future<List<DebtTypeResponse>> getDebtType() async {
    String? accessToken = await AccesstokenService().getAccessToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/debt-types'),
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
      return jsonList.map((json) => DebtTypeResponse.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Authorization failed (401). Please log in again.');
    } else if (response.statusCode == 403) {
      throw Exception(
        'Forbidden (403). You do not have permission to access this resource.',
      );
    } else {
      String errorMessage =
          'Failed to load transactions (Status ${response.statusCode})';
      try {
        final errorBody = json.decode(response.body);
        errorMessage = errorBody['message'] ?? errorMessage;
      } catch (_) {
      }
      throw Exception(errorMessage);
    }
  }

  Future<List<RepaymentTypeResponse>> getRepaymentType() async {
    String? accessToken = await AccesstokenService().getAccessToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/repayment-types'),
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
      return jsonList.map((json) => RepaymentTypeResponse.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Authorization failed (401). Please log in again.');
    } else if (response.statusCode == 403) {
      throw Exception(
        'Forbidden (403). You do not have permission to access this resource.',
      );
    } else {
      String errorMessage =
          'Failed to load transactions (Status ${response.statusCode})';
      try {
        final errorBody = json.decode(response.body);
        errorMessage = errorBody['message'] ?? errorMessage;
      } catch (_) {
      }
      throw Exception(errorMessage);
    }
  }

  Future<int> mapNameToRepaymentId(String name) async {
    List<RepaymentTypeResponse> repaymentTypeList = await getRepaymentType();
    for (RepaymentTypeResponse repaymentType in repaymentTypeList){
      if (repaymentType == name){
          return repaymentType.typeId;
      }
    }
    return 0;
  }

    Future<int> mapNameToDebtTypeId(String name) async {
    List<DebtTypeResponse> debtTypeResponseList = await getDebtType();
    for (DebtTypeResponse repaymentType in debtTypeResponseList){
      if (repaymentType == name){
          return repaymentType.debtTypeId;
      }
    }
    return 0;
  }

  Future<List<DebtResponse>> getAllDebt() async {
    String? accessToken = await AccesstokenService().getAccessToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/debts'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );
    print("Debt status code : ${response.statusCode}");
    print("Debt body : ${response.body}");
    if (response.statusCode == 200) {
      if (response.body.isEmpty) return [];
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => DebtResponse.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Authorization failed (401). Please log in again.');
    } else if (response.statusCode == 403) {
      throw Exception(
        'Forbidden (403). You do not have permission to access this resource.',
      );
    } else {
      String errorMessage =
          'Failed to load transactions (Status ${response.statusCode})';
      try {
        final errorBody = json.decode(response.body);
        errorMessage = errorBody['message'] ?? errorMessage;
      } catch (_) {
      }
      throw Exception(errorMessage);
    }
  }

Future<DebtResponse> getDebtDetail(int id) async {
  String? accessToken = await AccesstokenService().getAccessToken();
  final response = await http.get(
    Uri.parse('$baseUrl/api/debts/$id'),
    headers: {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    },
  );
  print("Debt status code : ${response.statusCode}");
  print("Debt body : ${response.body}");

  if (response.statusCode == 200) {
    if (response.body.isEmpty) {
      throw Exception('Debt not found or empty response');
    }
    final Map<String, dynamic> jsonMap = json.decode(response.body);
    return DebtResponse.fromJson(jsonMap);
  } else if (response.statusCode == 401) {
    throw Exception('Authorization failed (401). Please log in again.');
  } else if (response.statusCode == 403) {
    throw Exception(
      'Forbidden (403). You do not have permission to access this resource.',
    );
  } else {
    String errorMessage =
        'Failed to load debt (Status ${response.statusCode})';
    try {
      final errorBody = json.decode(response.body);
      errorMessage = errorBody['message'] ?? errorMessage;
    } catch (_) {}
    throw Exception(errorMessage);
  }
}

    Future<void> deleteDebt(int debtId) async {
    String? accessToken = await AccesstokenService().getAccessToken();
    print(debtId);
    final response = await http.delete(
      Uri.parse('$baseUrl/api/debts/$debtId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );
    print("Debt status code : ${response.statusCode}");
    print("Debt body : ${response.body}");
    if (response.statusCode == 200) {
    } else if (response.statusCode == 401) {
      throw Exception('Authorization failed (401). Please log in again.');
    } else if (response.statusCode == 403) {
      throw Exception(
        'Forbidden (403). You do not have permission to access this resource.',
      );
    } else {
      String errorMessage =
          'Failed to load transactions (Status ${response.statusCode})';
      try {
        final errorBody = json.decode(response.body);
        errorMessage = errorBody['message'] ?? errorMessage;
      } catch (_) {
      }
      throw Exception(errorMessage);
    }
  }


  Future<void> createDebt(DebtRequest debtRequest) async {
    String? accessToken = await AccesstokenService().getAccessToken();

    final response = await http.post(
      Uri.parse("$url"),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'principalAmount': debtRequest.principalAmount,
        'interestRate': debtRequest.interestRate,
        'repaymentTypeId': debtRequest.repaymentTypeId,
        'startDate': debtRequest.startDate.toIso8601String(),
        'endDate': debtRequest.endDate.toIso8601String(),
        'isActive': debtRequest.isActive,
        'priority': debtRequest.priority,
        'debtTypeId': debtRequest.debtTypeId,
        'debtName': debtRequest.debtName,
      }),
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

  Future<void> updateDebt(int id, DebtRequest debtRequest) async {
    print("Editing debt id: $id");

    String? accessToken = await AccesstokenService().getAccessToken();
    print("AccessToken: $accessToken");

    final body = {
      'debtName': debtRequest.debtName,
      'principalAmount': debtRequest.principalAmount,
      'interestRate': debtRequest.interestRate,
      'debtTypeId': debtRequest.debtTypeId,
      'repaymentTypeId': debtRequest.repaymentTypeId,
      'startDate': debtRequest.startDate.toIso8601String(),
      'endDate': debtRequest.endDate.toIso8601String(),
      'priority': debtRequest.priority,
      'isActive': debtRequest.isActive,
    };
    print("Request body: $body");

    final response = await http.put(
      Uri.parse('$baseUrl/api/debts/$id'), // <- ใช้ id ไม่ใช่ debtId
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    print("transaction status code : ${response.statusCode}");
    print("transaction body : ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("Debt updated successfully.");
    } else if (response.statusCode == 401) {
      throw Exception('Authorization failed (401). Please log in again.');
    } else if (response.statusCode == 403) {
      throw Exception(
        'Forbidden (403). You do not have permission to access this resource.',
      );
    } else {
      String errorMessage =
          'Failed to update debt (Status ${response.statusCode})';
      try {
        final errorBody = json.decode(response.body);
        errorMessage = errorBody['message'] ?? errorMessage;
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }


}