import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/config.dart';
import '../../../../core/services/location_service.dart';
import '../../../../features/auth/data/services/access_token_service.dart';
import '../models/job_model.dart';

class JobService {
  final LocationService _locationService = LocationService();

  Future<List<JobModel>> getSuggestedJobs({String? keywords, String? location, double? extraIncomeNeeded}) async {
    try {
      String? province = location ?? await _locationService.getCurrentProvince();
      String? accessToken = await AccesstokenService().getAccessToken();

      final response = await http.post(
        Uri.parse('$baseUrl/jobs/suggest'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'keywords': keywords ?? 'part-time',
          'location': province ?? 'ประเทศไทย',
          'extraIncomeNeeded': extraIncomeNeeded ?? 0.0,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => JobModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch jobs: ${response.statusCode}');
      }
    } catch (e) {
      print('JobService Error: $e');
      // If error occurs, we can still show some static fallback or empty list
      return [];
    }
  }
}
