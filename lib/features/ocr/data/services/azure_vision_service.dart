import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AzureVisionService {
  final String endpoint = "https://vision-api-app.cognitiveservices.azure.com/";
  final String key = "E7nG31gyrAlsm7Z2kFum6ccey2g7H81RjMYDjYzw3nRwgtVfKS0bJQQJ99CCACqBBLyXJ3w3AAAFACOGS57l";
  final String apiVersion = "2024-02-01";

  Future<String?> analyzeImage(File imageFile) async {
    final String url = "$endpoint/computervision/imageanalysis:analyze?api-version=$apiVersion&features=read";

    try {
      final bytes = await imageFile.readAsBytes();
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Ocp-Apim-Subscription-Key': key,
          'Content-Type': 'application/octet-stream',
        },
        body: bytes,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _extractText(data);
      } else {
        print("Error analyzing image: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception analyzing image: $e");
      return null;
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
