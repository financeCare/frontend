import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/finance_item.dart';

class DashboardService {
  final String baseUrl;

  DashboardService({required this.baseUrl});

  /// ดึงข้อมูลรายได้และหนี้จาก BE
  Future<Map<String, List<FinanceItem>>> fetchDashboardData() async {
    final url = Uri.parse('$baseUrl/api/dashboard');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<FinanceItem> incomes = (data['incomes'] as List)
            .map((i) => FinanceItem.fromJson(i))
            .toList();
        List<FinanceItem> debts = (data['debts'] as List)
            .map((d) => FinanceItem.fromJson(d))
            .toList();
        return {'incomes': incomes, 'debts': debts};
      } else {
        throw Exception('Failed to fetch dashboard: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching dashboard data: $e');
      return {'incomes': [], 'debts': []};
    }
  }

  /// ส่งรายได้และหนี้ไปยัง BE
  Future<bool> sendDashboardData({
    required List<FinanceItem> incomes,
    required List<FinanceItem> debts,
  }) async {
    final url = Uri.parse('$baseUrl/api/dashboard');
    try {
      final body = jsonEncode({
        'incomes': incomes.map((i) => i.toJson()).toList(),
        'debts': debts.map((d) => d.toJson()).toList(),
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true; // ส่งสำเร็จ
      } else {
        print('Failed to send data: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending data: $e');
      return false;
    }
  }
}
