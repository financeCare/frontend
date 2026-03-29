import 'dart:async';
import 'dart:convert';
import 'dart:core';
import '../../domain/models/debt_type_response.dart';
import '../../domain/models/debt_dto.dart';
import '../../domain/models/debt_response.dart';
import '../../domain/models/repayment_type_response.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/config.dart';
import '../../../../features/auth/data/services/access_token_service.dart';
import '../../domain/models/debt_request.dart';
import '../../domain/models/monthly_debt_status.dart';
import '../../domain/models/debt_transaction_response.dart';


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
      } catch (_) {}
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
      return jsonList
          .map((json) => RepaymentTypeResponse.fromJson(json))
          .toList();
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
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }

  Future<int> mapNameToRepaymentId(String name) async {
    List<RepaymentTypeResponse> repaymentTypeList = await getRepaymentType();
    for (RepaymentTypeResponse repaymentType in repaymentTypeList) {
      if (repaymentType.typeName == name) {
        return repaymentType.typeId;
      }
    }
    return 0;
  }

  Future<int> mapNameToDebtTypeId(String name) async {
    List<DebtTypeResponse> debtTypeResponseList = await getDebtType();
    for (DebtTypeResponse debtType in debtTypeResponseList) {
      if (debtType.debtTypeName == name) {
        return debtType.debtTypeId;
      }
    }
    return 0;
  }

  Future<List<DebtResponse>> getAllDebt() async {
    String? accessToken = await AccesstokenService().getAccessToken();
    print("AccessToken in debt service: $accessToken");
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
          'Failed to load debts (Status ${response.statusCode})';
      try {
        final errorBody = json.decode(response.body);
        errorMessage = errorBody['message'] ?? errorMessage;
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }

  Future<DebtResponse> getDebtDetail(String id) async {
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

  Future<void> deleteDebt(String debtId) async {
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
          'Failed to delete debt (Status ${response.statusCode})';
      try {
        final errorBody = json.decode(response.body);
        errorMessage = errorBody['message'] ?? errorMessage;
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }

  Future<void> createDebt(DebtRequest debtRequest) async {
    print("Creating debt : ${debtRequest.dueDay}");
    String? accessToken = await AccesstokenService().getAccessToken();
    final response = await http.post(
      Uri.parse("$url"),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(debtRequest.toJson()),
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
          'Failed to create debt (Status ${response.statusCode})';
      try {
        final errorBody = json.decode(response.body);
        errorMessage = errorBody['message'] ?? errorMessage;
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }

  Future<void> updateDebt(String id, DebtRequest debtRequest) async {
    print("Editing debt id: $id");

    final accessToken = await AccesstokenService().getAccessToken();

    final response = await http.put(
      Uri.parse('$baseUrl/api/debts/$id'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(debtRequest.toJson()),
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

  Future<void> payDebt(String debtId, double amount, String paidAt, {int? slipId}) async {
    String? accessToken = await AccesstokenService().getAccessToken();
    final response = await http.post(
      Uri.parse('$baseUrl/api/debts/pays'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'debtId': debtId,
        'paymentAmount': amount,
        'paymentDate': paidAt,
        'slipId': slipId,
      }),
    );

    print("Pay debt status code : ${response.statusCode}");
    print("Pay debt body : ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("Debt paid successfully.");
    } else if (response.statusCode == 401) {
      throw Exception('Authorization failed (401). Please log in again.');
    } else if (response.statusCode == 403) {
      throw Exception(
        'Forbidden (403). You do not have permission to access this resource.',
      );
    } else {
      String errorMessage =
          'Failed to pay debt (Status ${response.statusCode})';
      try {
        final errorBody = json.decode(response.body);
        errorMessage = errorBody['message'] ?? errorMessage;
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }

  Future<List<DebtTransactionResponse>> getDebtHistory(String debtId) async {
    String? accessToken = await AccesstokenService().getAccessToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/debts/$debtId/history'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      if (response.body.isEmpty) return [];
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => DebtTransactionResponse.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load debt history (Status ${response.statusCode})');
    }
  }

  Future<MonthlyDebtStatus> getMonthlyDebtStatus() async {
    String? accessToken = await AccesstokenService().getAccessToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/debts/monthly-status'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    print("Monthly Debt Status code : ${response.statusCode}");
    print("Monthly Debt Status body : ${response.body}");

    if (response.statusCode == 200) {
      if (response.body.isEmpty) return MonthlyDebtStatus(totalAmount: 0, paidAmount: 0, remainingAmount: 0, actualMinPayment: 0, requiredMinPayment: 0, isBudgetInsufficient: false);
      final Map<String, dynamic> jsonMap = json.decode(response.body);
      return MonthlyDebtStatus.fromJson(jsonMap);
    } else {
      // คืนค่าว่างถ้าไม่พบแผนการจ่ายเงินหรือเกิดข้อผิดพลาด
      return MonthlyDebtStatus(totalAmount: 0, paidAmount: 0, remainingAmount: 0, actualMinPayment: 0, requiredMinPayment: 0, isBudgetInsufficient: false);
    }
  }
}
