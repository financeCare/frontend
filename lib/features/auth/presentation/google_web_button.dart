// ปุ่ม Google Sign-In ของ GIS (renderButton) ใช้ได้เฉพาะบน web
// บน Android/iOS จะได้ stub ที่ไม่ render อะไร
export 'google_web_button_stub.dart'
    if (dart.library.js_interop) 'google_web_button_web.dart';
