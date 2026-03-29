import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/config.dart';
import '../../../../features/auth/data/services/access_token_service.dart';
import '../../domain/models/receiver_mapping.dart';
import '../../domain/models/mapping_request.dart';

class ReceiverMappingService {
  final String _baseUrl = '$baseUrl/api/receiver-mappings';

  Future<List<ReceiverMapping>> getAllMappings() async {
    String? accessToken = await AccesstokenService().getAccessToken();
    final response = await http.get(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(utf8.decode(response.bodyBytes));
      return jsonList.map((json) => ReceiverMapping.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load receiver mappings: ${response.statusCode}');
    }
  }

  Future<ReceiverMapping> saveMapping(MappingRequest request) async {
    String? accessToken = await AccesstokenService().getAccessToken();
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return ReceiverMapping.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to save receiver mapping: ${response.statusCode}');
    }
  }

  Future<void> deleteMapping(int id) async {
    String? accessToken = await AccesstokenService().getAccessToken();
    final response = await http.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete receiver mapping: ${response.statusCode}');
    }
  }
}
