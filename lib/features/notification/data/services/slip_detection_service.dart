import 'package:flutter/services.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import '../../../../core/config/config.dart' as config;
import '../../../../features/auth/data/services/access_token_service.dart';
import '../../../budget/domain/models/transaction_response.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class SlipDetectionService {
  static const _channel = MethodChannel('com.example.financeCare/slip_detector');
  
  Future<void> init() async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNewImage') {
        final String filePath = call.arguments;
        await _handleNewImage(filePath);
      }
    });

    // ตรวจสอบเเละขอ Permission ก่อนเริ่มทำงาน
    final hasPermission = await requestPermissions();
    if (hasPermission) {
      print('SlipDetectionService: Permission granted, starting scan...');
      // เริ่มต้นสแกนย้อนหลัง 10 วันเมื่อเปิดแอป
      scanPastImages(days: 10);
    } else {
      print('SlipDetectionService: Permission denied, auto-scan will not work');
    }
  }

  Future<bool> requestPermissions() async {
    if (!Platform.isAndroid) return false;

    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      
      if (androidInfo.version.sdkInt >= 33) {
        // Android 13+ (API 33+)
        PermissionStatus status = await Permission.photos.status;
        if (!status.isGranted) {
          status = await Permission.photos.request();
        }
        return status.isGranted;
      } else {
        // Android 12 and below
        PermissionStatus status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        return status.isGranted;
      }
    } catch (e) {
      print('SlipDetectionService: Error checking permissions: $e');
      return false;
    }
  }

  Future<void> scanPastImages({int days = 10}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastScanStr = prefs.getString('last_slip_scan_paths') ?? '[]';
      final List<String> processedPaths = List<String>.from(jsonDecode(lastScanStr));
      
      final List<dynamic>? filePaths = await _channel.invokeMethod('scanPastImages', {'days': days});
      
      if (filePaths != null && filePaths.isNotEmpty) {
        print('SlipDetectionService: Found ${filePaths.length} images from last $days days');
        
        final List<String> newPathsToProcess = [];
        for (final path in filePaths) {
          if (path is String && !processedPaths.contains(path)) {
            newPathsToProcess.add(path);
          }
        }

        if (newPathsToProcess.isNotEmpty) {
          print('SlipDetectionService: Processing ${newPathsToProcess.length} new images');
          for (final path in newPathsToProcess) {
            await _handleNewImage(path);
            processedPaths.add(path);
          }
          
          // เก็บเฉพาะ 100 รายการล่าสุดเพื่อไม่ให้ SharedPreferences ใหญ่เกินไป
          final listToSave = processedPaths.length > 100 
              ? processedPaths.sublist(processedPaths.length - 100)
              : processedPaths;
          await prefs.setString('last_slip_scan_paths', jsonEncode(listToSave));
        }
      }
    } catch (e) {
      print('SlipDetectionService: Error scanning past images: $e');
    }
  }

  Future<void> _handleNewImage(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return;

    // Filter by extension
    final ext = p.extension(filePath).toLowerCase();
    if (ext != '.jpg' && ext != '.jpeg' && ext != '.png') return;

    // Filter: Only process if it looks like a bank slip
    if (!isLikelyBankSlip(filePath)) {
      print('SlipDetectionService: Ignored non-slip image: $filePath');
      return;
    }

    print('SlipDetectionService: Detect new slip image: $filePath');
    
    // ส่งไปยัง Backend API (ซึ่งจะส่งต่อให้ Python OCR อีกที)
    await _uploadToOcr(file);
  }

  bool isLikelyBankSlip(String filePath) {
    final path = filePath.toLowerCase();
    
    // Common folders and keywords for Thai Bank Slips
    final slipKeywords = [
      'thaiqrpayment',
      'promptpay',
      'k-plus',
      'scb',
      'krungthai',
      'bualuang',
      'tmb',
      'tanachart',
      'uob',
      'gsb',
      'bay',
      'krungsri',
      'ttb',
      'transfer',
      'slip',
      'pay',
      'payment',
      'line',
      'gallery'
    ];

    // Check if path contains any of the keywords or screenshots folder
    for (final kw in slipKeywords) {
      if (path.contains(kw)) {
        return true;
      }
    }

    if (path.contains('screenshots')) {
      return true;
    }

    return false;
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
