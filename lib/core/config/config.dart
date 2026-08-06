import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// ฟังก์ชันสลับ baseUrl อัตโนมัติตามสภาพแวดล้อมที่รัน
/// เพื่อรองรับทั้ง Android Emulator, iOS Simulator, Web และ Desktop
String _determineBaseUrl() {
  if (kIsWeb) {
    // รันบน Web Browser (เชื่อมตรงเข้า Spring Boot Backend พอร์ต 8080)
    return 'http://localhost:8080';
  }
  try {
    if (Platform.isAndroid) {
      // Android Emulator มอง localhost ของเครื่อง host เป็น 10.0.2.2
      // เชื่อมตรงเข้า Spring Boot Backend (พอร์ต 8080)
      return 'http://10.0.2.2:8080';
    } else if (Platform.isIOS || Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      // iOS Simulator หรือ Desktop
      // เชื่อมตรงเข้า Spring Boot Backend (พอร์ต 8080)
      return 'http://localhost:8080';
    }
  } catch (_) {}
  return 'http://localhost:8080';
}

// ค่า baseUrl ที่ถูกเลือกใช้งานปัจจุบัน
final String baseUrl = _determineBaseUrl();

// ==========================================
// ตัวเลือกสำหรับการทดสอบเพิ่มเติม (เปิดคอมเมนต์เพื่อใช้งาน)
// ==========================================

// 1. เชื่อมต่อผ่าน Nginx Proxy (พอร์ต 80) - จำเป็นต้องรัน container nginx-proxy (ช่วยให้ใช้งานระบบอัปโหลดรูป MinIO ได้)
// final String baseUrl = 'http://10.0.2.2'; // สำหรับ Android Emulator (Nginx Port 80)
// final String baseUrl = 'http://localhost'; // สำหรับ iOS Simulator / Web / Desktop (Nginx Port 80)

// 2. เชื่อมต่อผ่าน IP เครื่องคอมพิวเตอร์ของคุณ (เหมาะสำหรับทดสอบผ่าน Physical Device โทรศัพท์จริงบนวง Wi-Fi เดียวกัน)
// IP เครื่องของคุณปัจจุบัน: 192.168.1.51
// final String baseUrl = 'http://192.168.1.51'; // ต่อผ่าน Nginx Proxy (พอร์ต 80)
// final String baseUrl = 'http://192.168.1.51:8080'; // ต่อตรงเข้า Spring App (พอร์ต 8080)

// 3. เชื่อมต่อกับระบบ Production/Staging บน SIT Server
// final String baseUrl = 'https://bscit.sit.kmutt.ac.th/capstone25/cp25ms2';

