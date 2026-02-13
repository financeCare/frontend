import 'dart:convert';
import 'package:flutter_application_1/features/simulator/data/models/repayment_strategy_response.dart';
import 'package:flutter_application_1/features/simulator/data/models/repayment_simulation_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../../../core/config/config.dart' as Config;
import '../../../../features/auth/data/services/access_token_service.dart';

class RepaymentStrategiesOverview {
  final double monthlyBudget;
  final List<RepaymentStrategyResponse> strategies;

  RepaymentStrategiesOverview({
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
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List strategiesJson = data['repaymentStrategyList'] ?? [];
      final double budget = (data['monthlyBudget'] as num?)?.toDouble() ?? 0.0;

      final strategies = strategiesJson
          .map((e) => RepaymentStrategyResponse.fromJson(e))
          .toList();

      return RepaymentStrategiesOverview(
        monthlyBudget: budget,
        strategies: strategies,
      );
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

  Future<RepaymentSimulationResponse> getSimulationResults(
    double budget,
    String strategy,
  ) async {
    final token = await AccesstokenService().getAccessToken();
    // Assuming the API expects query parameters for budget and strategy based on the GET spec
    // Config.baseUrl/api/repayment-plans/simulate (GET)
    final url = Uri.parse("${Config.baseUrl}/api/repayment-plans/simulate")
        .replace(
          queryParameters: {
            "monthlyBudget": budget.toString(),
            "strategy": strategy,
          },
        );

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
