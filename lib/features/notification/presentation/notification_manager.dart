import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/services/notification_service.dart';
import '../../auth/presentation/auth_manager.dart';

class NotificationManager {
  NotificationManager({
    required this.storage,
    required this.onOpenNotification,
  });

  final FlutterSecureStorage storage;

  // ให้ HomePage รับ callback เพื่อ “สลับแท็บ/นำทาง”
  final void Function({String? refType, String? refId}) onOpenNotification;

  late final NotificationService _service;

  Future<void> initialize() async {
    _service = NotificationService.instance;

    await _service.init(onTap: ({refType, refId}) {
      onOpenNotification(refType: refType, refId: refId);
    });

    final token = AuthManager.token;
    if (token != null && token.isNotEmpty) {
      await _service.registerTokenToBackend(accessToken: token);
    }
  }
}
