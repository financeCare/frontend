// ไฟล์: lib/widgets/logo_header.dart

import 'package:flutter/material.dart';

class LogoHeader extends StatelessWidget {
  const LogoHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      // จัดให้ Widget ตรงกลาง Column
      children: [
        // 1. Image.asset: โหลดรูปภาพจากโฟลเดอร์ assets
        Image.asset(
          'assets/logo_finance_care.png',
          height: 100,
          fit: BoxFit.contain,
          // 2. errorBuilder: จัดการเมื่อหารูปภาพไม่เจอ
          errorBuilder: (context, error, stackTrace) {
            // แสดงข้อความแทนถ้าหาไฟล์รูปภาพไม่เจอ
            return const SizedBox(
              height: 300,
              width: 300,
              child: Center(
                child: Text(
                  'Logo Placeholder',
                  style: TextStyle(fontSize: 24, color: Colors.grey),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
