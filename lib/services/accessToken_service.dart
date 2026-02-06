import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../utils/config.dart'; // ไฟล์ config.dart ที่มี baseUrl
import 'package:jwt_decoder/jwt_decoder.dart';

class AccesstokenService {
  final storage = FlutterSecureStorage();

Future<String?> getAccessToken() async {
  String? accessToken = await storage.read(key: "accessToken");
  print('accessToken from storage : $accessToken');
  if (accessToken == null) {
        return null;
  }
  print('accessToken before check expiry : $accessToken');
  bool isTokenExpired = JwtDecoder.isExpired(accessToken);
  print('isTokenExpired : $isTokenExpired');
  if (isTokenExpired) {
    String? refreshToken = await storage.read(key: "refreshToken");

    if (refreshToken == null) {
      return null;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/refresh-token'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $refreshToken',
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      String newAccessToken = responseData['accessToken'];
      await storage.write(key: "accessToken", value: newAccessToken);
      print('newAccessToken : $newAccessToken');
      return newAccessToken;
    } else {
      return null;
    }
  } else {
    print('accesss : $accessToken');
    return accessToken;
  }
}

}