import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import '../../../../core/config/config.dart' as config;
import '../../../../features/auth/data/services/access_token_service.dart';

class RepaymentPlanService {
  final String baseUrl = config.baseUrl;

  // Future<Map<String, dynamic>> createPlan({
  //   required double monthlyBudget,
  //   required String strategyId,
  // }) async {
  //   final token = await AccesstokenService().getAccessToken();

  //   final url = Uri.parse("$baseUrl/api/repayment-plans");

  //   final body = jsonEncode({
  //     "monthlyBudget": monthlyBudget,
  //     "strategyId": strategyId,
  //   });

  //   debugPrint("====== CREATE PLAN ======");
  //   debugPrint("URL => $url");
  //   debugPrint("BODY => $body");

  //   final response = await http.post(
  //     url,
  //     headers: {
  //       "Content-Type": "application/json",
  //       "Authorization": "Bearer $token",
  //     },
  //     body: body,
  //   );

  //   debugPrint("STATUS => ${response.statusCode}");
  //   debugPrint("RAW BODY => ${response.body}");

  //   if (response.statusCode == 200 || response.statusCode == 201) {
  //     return jsonDecode(response.body);
  //   } else {
  //     throw Exception(
  //       "Create plan failed: ${response.statusCode} ${response.body}",
  //     );
  //   }
  // }

  // Future<List<dynamic>> getPlans() async {
  //   final token = await AccesstokenService().getAccessToken();
  //   final url = Uri.parse("$baseUrl/api/repayment-plans");

  //   debugPrint("====== GET PLANS ======");
  //   debugPrint("URL => $url");

  //   final response = await http.get(
  //     url,
  //     headers: {
  //       "Content-Type": "application/json",
  //       "Authorization": "Bearer $token",
  //     },
  //   );

  //   debugPrint("STATUS => ${response.statusCode}");
  //   debugPrint("RAW BODY => ${response.body}");

  //   if (response.statusCode == 200) {
  //     return jsonDecode(response.body);
  //   } else {
  //     throw Exception(
  //       "Get plans failed: ${response.statusCode} ${response.body}",
  //     );
  //   }
  // }

  Future<Map<String, dynamic>> getPlanById(String planId) async {
    final token = await AccesstokenService().getAccessToken();
    final url = Uri.parse("$baseUrl/api/repayment-plans/$planId");

    debugPrint("====== GET PLAN BY ID ======");
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
      return jsonDecode(response.body);
    } else {
      throw Exception(
        "Get plan failed: ${response.statusCode} ${response.body}",
      );
    }
  }

  Future<void> deletePlan(String planId) async {
    final token = await AccesstokenService().getAccessToken();
    final url = Uri.parse("$baseUrl/api/repayment-plans/$planId");

    debugPrint("====== DELETE PLAN ======");
    debugPrint("URL => $url");

    final response = await http.delete(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    debugPrint("STATUS => ${response.statusCode}");
    debugPrint("RAW BODY => ${response.body}");

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        "Delete plan failed: ${response.statusCode} ${response.body}",
      );
    }
  }

  Future<Map<String, dynamic>> simulatePlan() async {
    final token = await AccesstokenService().getAccessToken();
    final url = Uri.parse("$baseUrl/api/repayment-plans/simulate");

    debugPrint("====== SIMULATE PLAN ======");
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
      return jsonDecode(response.body);
    } else {
      throw Exception(
        "Simulate plan failed: ${response.statusCode} ${response.body}",
      );
    }
  }
}
