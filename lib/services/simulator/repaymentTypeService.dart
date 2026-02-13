import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/accessToken_service.dart';
import '../../models/repayment_strategy_response.dart';
import '../../utils/config.dart' as Config;

class RepaymentStrategyService {
  Future<List<RepaymentStrategyResponse>> fetchStrategies() async {
    final token = await AccesstokenService().getAccessToken();
    final url = Uri.parse(
        "${Config.baseUrl}/api/repayment-plans/strategies");

    debugPrint("====== STRATEGY API ======");
    debugPrint("URL => $url");
    debugPrint("TOKEN => $token");

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
      final List data = jsonDecode(response.body);
      debugPrint("PARSED COUNT => ${data.length}");

      return data
          .map((e) => RepaymentStrategyResponse.fromJson(e))
          .toList();
    } else {
      throw Exception(
          "Strategy API failed: ${response.statusCode}");
    }
  }
  Future<void> createPlan() async {
    final token = await AccesstokenService().getAccessToken();

    final url = Uri.parse("${Config.baseUrl}/api/repayment-plans");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    debugPrint("CREATE STATUS => ${response.statusCode}");
    debugPrint("CREATE BODY => ${response.body}");

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception("Create plan failed");
    }
  }

}
