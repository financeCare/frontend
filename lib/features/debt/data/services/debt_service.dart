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
import '../../../../core/utils/app_logger.dart';
import '../../../../features/auth/data/services/access_token_service.dart';
import '../../domain/models/debt_request.dart';
import '../../domain/models/monthly_debt_status.dart';


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
    AppLog.d("getDebtType: ${response.statusCode}");
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
    AppLog.d("getRepaymentType: ${response.statusCode}");
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
    final response = await http.get(
      Uri.parse('$baseUrl/api/debts'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );
    AppLog.d("getAllDebt: ${response.statusCode}");
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
    AppLog.d("getDebtDetail: ${response.statusCode}");
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
    final response = await http.delete(
      Uri.parse('$baseUrl/api/debts/$debtId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );
    AppLog.d("deleteDebt: ${response.statusCode}");
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
    String? accessToken = await AccesstokenService().getAccessToken();
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(debtRequest.toJson()),
    );
    AppLog.d("createDebt: ${response.statusCode}");
    if (response.statusCode == 200 || response.statusCode == 201) {
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
    final accessToken = await AccesstokenService().getAccessToken();
    final response = await http.put(
      Uri.parse('$baseUrl/api/debts/$id'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(debtRequest.toJson()),
    );
    AppLog.d("updateDebt: ${response.statusCode}");
    if (response.statusCode == 200 || response.statusCode == 201) {
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
        if (slipId != null) 'paymentSlipId': slipId,
      }),
    );
    AppLog.d("payDebt: ${response.statusCode}");
    if (response.statusCode == 200 || response.statusCode == 201) {
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

  Future<MonthlyDebtStatus> getMonthlyDebtStatus() async {
    try {
      String? accessToken = await AccesstokenService().getAccessToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/debts/monthly-status'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );
      
      AppLog.d("getMonthlyDebtStatus: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return MonthlyDebtStatus(
            totalAmount: 0,
            paidAmount: 0,
            remainingAmount: 0,
            requiredMinPayment: 0,
            isBudgetInsufficient: false,
          );
        }
        final Map<String, dynamic> jsonMap = json.decode(response.body);
        return MonthlyDebtStatus.fromJson(jsonMap);
      } else {
        throw Exception('Failed to load monthly status');
      }
    } catch (e) {
      AppLog.e('getMonthlyDebtStatus Error: $e');
      return MonthlyDebtStatus(
        totalAmount: 0,
        paidAmount: 0,
        remainingAmount: 0,
        requiredMinPayment: 0,
        isBudgetInsufficient: false,
      );
    }
  }
}
