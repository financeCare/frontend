import 'package:flutter/material.dart';

// =========================================================
// SIMULATOR SCREEN: หน้าจอสำหรับใส่ Simulate
// =========================================================

class SimulatorScreen extends StatelessWidget {
  const SimulatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulator Page'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.trending_up, size: 80, color: Colors.blueAccent),
              SizedBox(height: 20),
              Text(
                'Simulation / Forecasting',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'หน้านี้ใช้สำหรับใส่ค่ารายรับ รายจ่าย เพื่อคำนวณและจำลองงบประมาณ (ตามที่ร้องขอ)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              // สามารถเพิ่มฟอร์มและกราฟสำหรับ Simulator ที่นี่
            ],
          ),
        ),
      ),
    );
  }
}