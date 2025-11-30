import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../utils/config.dart';

class AuthService {

  Future<File> get _tokenFile async {
    final directory = await Directory.systemTemp.createTemp();
    return File("${directory.path}/token.txt");
  }

  Future<bool> login(String email, String password) async {
    print('try to login');
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data["accessToken"];
       
        final file = await _tokenFile;
        await file.writeAsString(token);

        return true;
      } else {
        print("Login failed: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error: $e");
      return false;
    }
  }

  // ดึง token กลับมา
  Future<String?> getToken() async {
    try {
      final file = await _tokenFile;

      if (await file.exists()) {
        return await file.readAsString();
      } else {
        return null;
      }
    } catch (e) {
      print("Read token error: $e");
      return null;
    }
  }
}
