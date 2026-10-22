import 'package:flutter/material.dart';

/// true เมื่อมีคำขอไปยัง backend ที่ใช้เวลานานผิดปกติ (น่าจะกำลัง cold start)
final ValueNotifier<bool> coldStartNotifier = ValueNotifier<bool>(false);

/// แถบแจ้งผู้ใช้ว่า backend กำลังตื่น (Render free tier) แสดงทับด้านบนของแอป
class ColdStartBanner extends StatelessWidget {
  const ColdStartBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: coldStartNotifier,
      builder: (context, visible, _) {
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: AnimatedSlide(
              offset: visible ? Offset.zero : const Offset(0, -1),
              duration: const Duration(milliseconds: 250),
              child: AnimatedOpacity(
                opacity: visible ? 1 : 0,
                duration: const Duration(milliseconds: 250),
                child: SafeArea(
                  child: Material(
                    color: const Color(0xFF2D955F),
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'กำลังปลุกเซิร์ฟเวอร์ อาจใช้เวลาประมาณ 30-60 วินาที กรุณารอสักครู่',
                              style: TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
