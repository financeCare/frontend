import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  static const String _deviceKeyStorageKey = 'device_key';
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Gets the existing device ID or creates a new one if it doesn't exist.
  /// This ensures the ID is generated only once per installation.
  static Future<String> getOrCreateDeviceId() async {
    String? deviceId = await _storage.read(key: _deviceKeyStorageKey);

    if (deviceId == null || deviceId.isEmpty) {
      // 🔄 Migrate from old naming convention if it exists
      final oldId = await _storage.read(key: 'deviceKey');
      if (oldId != null && oldId.isNotEmpty) {
        deviceId = oldId;
        await _storage.write(key: _deviceKeyStorageKey, value: deviceId);
      } else {
        deviceId = const Uuid().v4();
        await _storage.write(key: _deviceKeyStorageKey, value: deviceId);
      }
    }

    return deviceId;
  }

  /// Gets basic model and platform info of the device.
  static Future<Map<String, String>> getDeviceInfo() async {
    if (Platform.isAndroid) {
      final android = await _deviceInfo.androidInfo;
      return {
        "platform": "android",
        "deviceName": "${android.manufacturer} ${android.model}",
        "brand": android.brand,
        "model": android.model,
        "osVersion": android.version.release,
      };
    } else if (Platform.isIOS) {
      final ios = await _deviceInfo.iosInfo;
      return {
        "platform": "ios",
        "deviceName": ios.name,
        "model": ios.utsname.machine,
        "systemVersion": ios.systemVersion,
      };
    }
    return {"platform": "unknown", "deviceName": "unknown"};
  }
}
