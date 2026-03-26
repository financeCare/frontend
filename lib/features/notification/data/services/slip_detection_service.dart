import 'package:flutter/services.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import '../../../../core/config/config.dart' as config;

class SlipDetectionService {
  static const _channel = MethodChannel('com.example.financeCare/slip_detector');
  
  void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNewImage') {
        final String filePath = call.arguments;
        await _handleNewImage(filePath);
      }
    });
  }

  Future<void> _handleNewImage(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return;

    // Filter by extension
    final ext = p.extension(filePath).toLowerCase();
    if (ext != '.jpg' && ext != '.jpeg' && ext != '.png') return;

    // Optional: Only process if from common bank slip folders
    // if (!filePath.contains('ThaiQrPayment') && !filePath.contains('Screenshots')) return;

    print('SlipDetectionService: Detect new image: $filePath');
    
    // Send to Python OCR API
    await _uploadToOcr(file);
  }

  Future<void> _uploadToOcr(File file) async {
    try {
      final url = Uri.parse('${config.baseUrl}/api/ocr/process-slip');
      final request = http.MultipartRequest('POST', url);
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
        ),
      );

      print('SlipDetectionService: Uploading to $url');
      final response = await request.send();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final resBody = await response.stream.bytesToString();
        print('SlipDetectionService: OCR Upload Tech Success: $resBody');
      } else {
        print('SlipDetectionService: OCR Upload Failed: ${response.statusCode}');
      }
    } catch (e) {
      print('SlipDetectionService: Error uploading to OCR: $e');
    }
  }
}
