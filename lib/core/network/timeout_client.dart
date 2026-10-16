import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/config.dart' as config;
import 'cold_start_notifier.dart';

/// http.Client ที่ใส่ timeout ให้ทุกคำขอ ป้องกันหน้าจอหมุนค้างตอน backend
/// (Render free tier) กำลัง cold start หรือไม่ตอบกลับ
class TimeoutClient extends http.BaseClient {
  TimeoutClient({
    http.Client? inner,
    this.timeout = const Duration(seconds: 60),
  }) : _inner = inner ?? http.Client();

  final http.Client _inner;
  final Duration timeout;

  /// ถ้าคำขอไป backend ค้างเกินเวลานี้ ให้ถือว่า backend กำลัง cold start
  static const _coldStartThreshold = Duration(seconds: 4);
  static int _slowPending = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    var flagged = false;
    Timer? timer;
    if (request.url.host == Uri.parse(config.baseUrl).host) {
      timer = Timer(_coldStartThreshold, () {
        flagged = true;
        _slowPending++;
        coldStartNotifier.value = true;
      });
    }
    try {
      return await _inner.send(request).timeout(
            timeout,
            onTimeout: () => throw TimeoutException(
              'เซิร์ฟเวอร์ไม่ตอบกลับภายใน ${timeout.inSeconds} วินาที: ${request.url}',
              timeout,
            ),
          );
    } finally {
      timer?.cancel();
      if (flagged && --_slowPending == 0) coldStartNotifier.value = false;
    }
  }

  @override
  void close() => _inner.close();
}
