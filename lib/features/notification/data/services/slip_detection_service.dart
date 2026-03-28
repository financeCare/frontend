import 'package:flutter/services.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import '../../../../core/config/config.dart' as config;
import '../../../../features/auth/data/services/access_token_service.dart';
import '../../../budget/domain/models/transaction_response.dart';
import 'dart:convert';

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
    
    // ส่งไปยัง Backend API (ซึ่งจะส่งต่อให้ Python OCR อีกที)
    await _uploadToOcr(file);
  }

  Future<void> _uploadToOcr(File file) async {
    try {
      await processManualSlip(file);
    } catch (e) {
      print('SlipDetectionService: Error in _uploadToOcr: $e');
    }
  }

  Future<TransactionResponse?> processManualSlip(File file) async {
    try {
      final token = await AccesstokenService().getAccessToken();
      if (token == null) {
        throw Exception('No access token found');
      }

      final url = Uri.parse('${config.baseUrl}/api/slips/upload');
      final request = http.MultipartRequest('POST', url);
      
      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(
        await http.MultipartFile.fromPath(
          'files',
          file.path,
        ),
      );

      print('SlipDetectionService: Uploading to $url');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        if (jsonList.isNotEmpty) {
          final Map<String, dynamic> firstItem = jsonList.first;
          final Map<String, dynamic> dataToParse = firstItem.containsKey('slip') 
              ? firstItem['slip'] as Map<String, dynamic>
              : firstItem;
          final tx = TransactionResponse.fromJson(dataToParse);
          print('SlipDetectionService: OCR Success for ${tx.receiverName}, amount: ${tx.amount}');
          return tx;
        }
      } else {
        print('SlipDetectionService: OCR Upload Failed: ${response.statusCode} - ${response.body}');
        throw Exception('OCR processing failed with status ${response.statusCode}');
      }
    } catch (e) {
      print('SlipDetectionService: Error processing slip: $e');
      rethrow;
    }
    return null;
  }
}
