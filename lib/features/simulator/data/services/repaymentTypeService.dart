import 'dart:convert';
import 'package:finance_care/features/simulator/data/models/repayment_strategy_response.dart';
import 'package:finance_care/features/simulator/data/models/repayment_simulation_model.dart';
import 'package:finance_care/features/simulator/data/models/debt_priority_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../../../core/config/config.dart' as Config;
import '../../../../features/auth/data/services/access_token_service.dart';

class RepaymentStrategiesOverview {
  final double actualMinPayment;
  final double safeMinSum;
  final double monthlyBudget;
  final List<RepaymentStrategyResponse> strategies;

  RepaymentStrategiesOverview({
    required this.actualMinPayment,
    required this.safeMinSum,
    required this.monthlyBudget,
    required this.strategies,
  });
}

class RepaymentStrategyService {
  Future<RepaymentStrategiesOverview> fetchStrategies() async {
    final token = await AccesstokenService().getAccessToken();
    final url = Uri.parse("${Config.baseUrl}/api/repayment-plans/strategies");

    debugPrint("====== STRATEGY API ======");
    debugPrint("URL => $url");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    debugPrint("STATUS => ${response.statusCode}");
    debugPrint("RAW BODY => ${response.body}");

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List strategiesJson = data['repaymentStrategyList'] ?? [];
        final double actualMin =
            (data['actualMinPayment'] as num?)?.toDouble() ?? 0.0;
        final double safeMin =
            (data['safeMinSum'] as num?)?.toDouble() ?? 0.0;
        final double budget =
            (data['monthlyBudget'] as num?)?.toDouble() ?? 0.0;

        final strategies = strategiesJson
            .map(
              (e) =>
                  RepaymentStrategyResponse.fromJson(e as Map<String, dynamic>),
            )
            .toList();

        debugPrint("Parsed ${strategies.length} strategies, actualMin: $actualMin, budget: $budget");

        return RepaymentStrategiesOverview(
          actualMinPayment: actualMin,
          safeMinSum: safeMin,
          monthlyBudget: budget,
          strategies: strategies,
        );
      } catch (parseError, stackTrace) {
        debugPrint("PARSE ERROR in fetchStrategies: $parseError");
        debugPrint("STACKTRACE: $stackTrace");
        throw Exception("Failed to parse strategy data: $parseError");
      }
    } else {
      throw Exception("Strategy API failed: ${response.statusCode}");
    }
  }

  Future<void> createPlan({
    required double monthlyBudget,
    required String strategyId,
  }) async {
    final token = await AccesstokenService().getAccessToken();

    final url = Uri.parse("${Config.baseUrl}/api/repayment-plans");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "monthlyBudget": monthlyBudget,
        "strategyId": strategyId,
      }),
    );

    debugPrint("CREATE STATUS => ${response.statusCode}");
    debugPrint("CREATE BODY => ${response.body}");
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception("Create plan failed");
    }
  }

  Future<List<DebtPriorityResponse>> fetchDebtPriorities() async {
    final token = await AccesstokenService().getAccessToken();
    final url = Uri.parse("${Config.baseUrl}/api/debts/priorities");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => DebtPriorityResponse.fromJson(e)).toList();
    } else {
      throw Exception("Failed to fetch debt priorities");
    }
  }

  Future<void> updateDebtPriorities(
    List<DebtPriorityUpdateRequest> priorities,
  ) async {
    final token = await AccesstokenService().getAccessToken();
    final url = Uri.parse("${Config.baseUrl}/api/debts/priorities");

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(priorities.map((e) => e.toJson()).toList()),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Failed to update debt priorities");
    }
  }

  Future<RepaymentSimulationResponse> getSimulationResults(
    double budget,
    String strategy,
  ) async {
    final token = await AccesstokenService().getAccessToken();
    // Assuming the API expects query parameters for budget and strategy based on the GET spec
    // Config.baseUrl/api/repayment-plans/simulate (GET)
    final url = Uri.parse("${Config.baseUrl}/api/repayment-plans");

    debugPrint("SIMULATE URL => $url");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    debugPrint("SIMULATE STATUS => ${response.statusCode}");
    if (response.statusCode == 200) {
      debugPrint("SIMULATE BODY => ${response.body}");
      return RepaymentSimulationResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Simulation failed: ${response.statusCode}");
    }
  }
}
