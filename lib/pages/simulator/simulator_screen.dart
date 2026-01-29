import 'package:flutter/material.dart';
import '../../models/debt_plan_model.dart';
import '../../models/debt_plans/snowball.dart';
import '../../models/debt_plans/avalanche.dart';
import '../../services/dashboard_service.dart';
import 'PlanDetailScreen.dart';
import '../../models/finance_item.dart';

// ประกาศแผนใหม่เพิ่มตรงนี้ (หรือถ้าแยกไฟล์ไว้ ให้ทำการ import เข้ามาครับ)
final DebtPlan fastTrackPlan = DebtPlan(
  id: 'fast_track',
  name: 'Fast Track',
  description: 'จ่ายหนี้ทั้งหมดเร็วที่สุดเท่าที่ทำได้ โดยเน้นการโปะเงินสูงสุดในแต่ละเดือน',
  pros: ['หมดหนี้เร็วที่สุด', 'ลดดอกเบี้ยจ่ายรวมได้มหาศาล'],
  cons: ['ต้องรัดเข็มขัดอย่างหนัก', 'กระทบสภาพคล่องรายเดือน'],
);

final DebtPlan minimumPaymentPlan = DebtPlan(
  id: 'minimum_payment',
  name: 'Minimum Payment Plan',
  description: 'เน้นจ่ายขั้นต่ำตามรอบบิล เพื่อรักษาสภาพคล่องทางการเงินให้ได้มากที่สุด',
  pros: ['มีเงินเหลือใช้รายเดือนมากขึ้น', 'ง่ายต่อการจัดการกระแสเงินสด'],
  cons: ['ใช้เวลานานมากในการปลดหนี้', 'เสียดอกเบี้ยสะสมสูงมาก'],
);

class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  final DashboardService dashboardService =
  DashboardService(baseUrl: 'https://your-api.com'); // เปลี่ยนเป็น URL จริง

  // เพิ่ม fastTrackPlan และ minimumPaymentPlan เข้าไปใน List นี้
  List<DebtPlan> debtPlans = [
    snowballPlan,
    avalanchePlan,
    fastTrackPlan,
    minimumPaymentPlan
  ];

  List<FinanceItem> incomes = [];
  List<FinanceItem> debts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    final data = await dashboardService.fetchDashboardData();
    setState(() {
      incomes = data['incomes'] ?? [];
      debts = data['debts'] ?? [];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulator'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: debtPlans.length,
          itemBuilder: (context, index) {
            final plan = debtPlans[index];
            return Card(
              color: Colors.teal.shade50,
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        )),
                    const SizedBox(height: 8),
                    Text(plan.description),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlanDetailScreen(
                                plan: plan,
                                incomes: incomes,
                                debts: debts,
                                monthlyBudget: 1000, // สามารถปรับเป็นตัวแปรที่รับค่าจาก User ได้
                              ),
                            ),
                          );
                        },
                        child: const Text('เลือกแผนนี้'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}