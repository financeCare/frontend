import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/config.dart' as Config;
import '../../../../features/auth/data/services/access_token_service.dart';
import '../models/job_model.dart';
import '../models/occupation_model.dart';

class JobService {
  Future<List<OccupationModel>> getRecommendedOccupations() async {
    final url = Uri.parse("${Config.baseUrl}/api/jobs/occupations");
    final token = await AccesstokenService().getAccessToken();

    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => OccupationModel.fromJson(json)).toList();
    } else {
      print('DEBUG ERROR (Occupations): ${response.statusCode} - ${response.body}');
      throw Exception("Failed to load recommended occupations");
    }
  }

  Future<List<JobModel>> getSuggestedJobs({
    String? keywords,
    String? location,
    List<String>? skills,
  }) async {
    final token = await AccesstokenService().getAccessToken();
    final url = Uri.parse("${Config.baseUrl}/api/jobs/suggest");

    final Map<String, dynamic> body = {
      "keywords": (keywords == null || keywords.isEmpty) ? "part-time" : keywords,
      "location": (location == null || location.isEmpty) ? "Thailand" : location,
      "skills": skills,
    };

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => JobModel.fromJson(json)).toList();
    } else {
      print('DEBUG ERROR (SuggestedJobs): ${response.statusCode} - ${response.body}');
      throw Exception("Failed to load suggested jobs: ${response.statusCode}");
    }
  }

  Future<void> trackApplication({
    required String jobId,
    required String jobTitle,
    required String platform,
  }) async {
    final token = await AccesstokenService().getAccessToken();
    final url = Uri.parse("${Config.baseUrl}/api/jobs/track-application");

    await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "jobId": jobId,
        "jobTitle": jobTitle,
        "platform": platform,
      }),
    );
  }
}
