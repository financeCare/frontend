class UserSettingOverview {
  final UserSetting userSetting;
  final List<UserDevice> devices;

  UserSettingOverview({required this.userSetting, required this.devices});

  factory UserSettingOverview.fromJson(Map<String, dynamic> json) {
    return UserSettingOverview(
      userSetting: UserSetting.fromJson(json['userSettingList']),
      devices: (json['userDeviceList'] as List)
          .map((e) => UserDevice.fromJson(e))
          .toList(),
    );
  }
}

class UserSetting {
  final String userId;
  final bool notificationsEnabled;
  final bool pushEnabled;
  final int defaultRemindDaysBefore;
  final String defaultNotifyTime;
  final String timezone;
  final DateTime createdAt;
  final DateTime updatedAt;

  final String? skills;

  UserSetting({
    required this.userId,
    required this.notificationsEnabled,
    required this.pushEnabled,
    required this.defaultRemindDaysBefore,
    required this.defaultNotifyTime,
    required this.timezone,
    required this.createdAt,
    required this.updatedAt,
    this.skills,
  });

  factory UserSetting.fromJson(Map<String, dynamic> json) {
    return UserSetting(
      userId: json['userId'],
      notificationsEnabled: json['notificationsEnabled'] ?? false,
      pushEnabled: json['pushEnabled'] ?? false,
      defaultRemindDaysBefore: json['defaultRemindDaysBefore'] ?? 1,
      defaultNotifyTime: json['defaultNotifyTime'] ?? "00:00:00",
      timezone: json['timezone'] ?? "Asia/Bangkok",
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      skills: json['skills'],
    );
  }
}

class UserDevice {
  final String deviceId;
  final String deviceName;
  final String platform;
  final DateTime lastSeen;

  UserDevice({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.lastSeen,
  });

  factory UserDevice.fromJson(Map<String, dynamic> json) {
    return UserDevice(
      deviceId: json['deviceId'],
      deviceName: json['deviceName'],
      platform: json['platform'],
      lastSeen: DateTime.parse(json['lastSeen']),
    );
  }
}
