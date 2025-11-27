import 'package:flutter/material.dart';
import '../../models/debt_plan_model.dart';
import '../../models/debt_plans/snowball.dart';
import '../../models/debt_plans/avalanche.dart';
import '../../services/dashboard_service.dart';
import 'PlanDetailScreen.dart';
import '../../models/finance_item.dart';

class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  final DashboardService dashboardService =
  DashboardService(baseUrl: 'https://your-api.com'); // เปลี่ยนเป็น URL จริง

  List<DebtPlan> debtPlans = [snowballPlan, avalanchePlan]; // ตัวอย่างแผน
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
                                monthlyBudget: 1000, // เปลี่ยนตาม user input

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
