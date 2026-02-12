class UserDeviceResponse {
  final String deviceId;        // UUID → String
  final bool isActive;
  final DateTime lastSeen;      // LocalDateTime → DateTime

  UserDeviceResponse({
    required this.deviceId,
    required this.isActive,
    required this.lastSeen,
  });

  /// JSON → Object
  factory UserDeviceResponse.fromJson(Map<String, dynamic> json) {
    return UserDeviceResponse(
      deviceId: json['deviceId'],
      isActive: json['isActive'],
      lastSeen: DateTime.parse(json['lastSeen']),
    );
  }

  /// Object → JSON
  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'isActive': isActive,
      'lastSeen': lastSeen.toIso8601String(),
    };
  }
}
