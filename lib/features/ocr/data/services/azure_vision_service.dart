import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/utils/logger_util.dart';

class AzureVisionService {
  final String endpoint = "https://vision-api-app.cognitiveservices.azure.com/";
  final String key = dotenv.env['AZURE_VISION_KEY'] ?? "";
  final String apiVersion = "2024-02-01";

  Future<String?> analyzeImage(File imageFile) async {
    final String url = "$endpoint/computervision/imageanalysis:analyze?api-version=$apiVersion&features=read";

    try {
      final bytes = await imageFile.readAsBytes();
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Ocp-Apim-Subscriptiogit merge release3n-Key': key,
          'Content-Type': 'application/octet-stream',
        },
        body: bytes,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _extractText(data);
      } else {
        print("Error analyzing image: HTTP ${response.statusCode} - ${response.body}");
        return "ERROR_API: ไม่สามารถวิเคราะห์ภาพได้ (HTTP ${response.statusCode})";
      }
    } on SocketException catch (_) {
      print("Network Error: No internet connection");
      return "ERROR_NETWORK: ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ Azure ได้ กรุณาตรวจสอบอินเทอร์เน็ต";
    } on TimeoutException catch (_) {
      print("Timeout Error: Request took too long");
      return "ERROR_TIMEOUT: หมดเวลาการเชื่อมต่อ กรุณาลองใหม่อีกครั้ง";
    } catch (e) {
      print("Exception analyzing image: $e");
      return "ERROR_UNKNOWN: เกิดข้อผิดพลาดที่ไม่รู้จัก ($e)";
    }
  }

  String _extractText(Map<String, dynamic> data) {
    StringBuffer sb = StringBuffer();
    if (data.containsKey('readResult') && data['readResult'].containsKey('blocks')) {
      for (var block in data['readResult']['blocks']) {
        if (block['lines'] != null) {
          for (var line in block['lines']) {
            sb.writeln(line['text']);
          }
        }
      }
    }
    return sb.toString().trim();
  }
}
