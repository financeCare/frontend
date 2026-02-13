import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../utils/config.dart' as Config;
import '../accessToken_service.dart';

class RepaymentSimulatorService {
  Future<Map<String, dynamic>> simulate() async {
    final token = await AccesstokenService().getAccessToken();

    final url =
    Uri.parse("${Config.baseUrl}/api/repayment-plans/simulate");

    debugPrint("====== SIMULATE API ======");
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
      final decoded = jsonDecode(response.body);

      debugPrint("====== PARSED RESULT ======");
      const encoder = JsonEncoder.withIndent("  ");
      debugPrint(encoder.convert(decoded));

      return decoded;
    } else {
      throw Exception(
          "Simulate failed: ${response.statusCode} ${response.body}");
    }
  }
}
