class UserDeviceRequest {
  final String deviceKey;
  final String fcmToken;
  final String platform;
  final String deviceName; // UUID จาก backend ใช้ String ใน Flutter

  UserDeviceRequest({
    required this.deviceKey,
    required this.fcmToken,
    required this.platform,
    required this.deviceName,
  });

  /// แปลงจาก JSON → Object
  factory UserDeviceRequest.fromJson(Map<String, dynamic> json) {
    return UserDeviceRequest(
      deviceKey: json['deviceKey'],
      fcmToken: json['fcmToken'],
      platform: json['platform'],
      deviceName: json['deviceName'],
    );
  }

  /// แปลง Object → JSON (เอาไว้ส่ง API)
  Map<String, dynamic> toJson() {
    return {
      'deviceKey': deviceKey,
      'fcmToken': fcmToken,
      'platform': platform,
      'deviceName': deviceName,
    };
  }
}
