import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/config.dart' as Config;
import 'package:finance_care/features/auth/data/services/access_token_service.dart';
import 'package:finance_care/features/auth/data/services/device_service.dart';
import 'package:finance_care/features/settings/data/models/user_setting_response.dart';

class UserSettingService {
  Future<UserSettingOverview> fetchUserSettings() async {
    final token = await AccesstokenService().getAccessToken();
    final url = Uri.parse("${Config.baseUrl}/api/user-setting");

    debugPrint("====== USER SETTING API ======");
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
    final deviceKey = await DeviceService.getOrCreateDeviceId();
    debugPrint("deviceKey => $deviceKey");
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return UserSettingOverview.fromJson(data);
    } else {
      throw Exception("User Setting API failed: ${response.statusCode}");
    }
  }

  Future<void> updateNotificationSettings({
    required bool enabled,
    required String time,
    required int daysBefore,
  }) async {
    final token = await AccesstokenService().getAccessToken();
    final url = Uri.parse("${Config.baseUrl}/api/user-setting");

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "notificationsEnabled": enabled,
        "defaultNotifyTime": time,
        "notify_due_days_before": daysBefore,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Failed to update settings: ${response.statusCode}");
    }
  }

  Future<void> deleteDevice(String deviceId) async {
    final token = await AccesstokenService().getAccessToken();
    final url = Uri.parse(
      "${Config.baseUrl}/api/notifications/devices/$deviceId",
    );

    final response = await http.delete(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Failed to delete device: ${response.statusCode}");
    }
  }

  Future<double> getSalary() async {
    final token = await AccesstokenService().getAccessToken();
    final url = Uri.parse("${Config.baseUrl}/api/budget/salary");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return double.tryParse(response.body) ?? 0.0;
    } else {
      throw Exception("Failed to get salary: ${response.statusCode}");
    }
  }

  Future<void> setSalary(double amount) async {
    final token = await AccesstokenService().getAccessToken();
    final url = Uri.parse("${Config.baseUrl}/api/budget/salary/$amount");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        "Failed to set salary: ${response.statusCode} ${response.body}",
      );
    }
  }

  Future<void> updateUserProfile({
    required String profession,
    required List<String> skills,
  }) async {
    final token = await AccesstokenService().getAccessToken();
    final url = Uri.parse("${Config.baseUrl}/api/user-setting");

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "currentProfession": profession,
        "skills": skills.join(','),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update user profile: ${response.statusCode}");
    }
  }
}
