import 'package:flutter/material.dart';
import '../../models/finance_item.dart';
import '../../services/dashboard_service.dart';
import '../../services/simulator/repaymentTypeService.dart';
import '../../services/simulator/repaymentPlanService.dart';
import '../../models/repayment_strategy_response.dart';
import 'PlanDetailScreen.dart';
import '../../utils/config.dart' as Config;
import '../../services/debt_service.dart';



class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {


  final RepaymentStrategyService repaymentService =
  RepaymentStrategyService();

  final planService = RepaymentPlanService();
  final DebtService debtService = DebtService();


  List<RepaymentStrategyResponse> plans = [];
  List<FinanceItem> incomes = [];
  List<FinanceItem> debts = [];

  bool isLoading = true;
  bool isSubmitting = false;
  String? error;

  int? selectedIndex;
  int? expandedIndex;

  @override
  void initState() {
    super.initState();
    Future.microtask(loadData);
  }

  Future<void> loadData() async {
    try {
      final strategyList = await repaymentService.fetchStrategies();
      final fetchedDebts = await fetchDebtsFromCrud();

      debugPrint("===== SIMULATOR DATA =====");
      debugPrint("Debts from CRUD: ${fetchedDebts.length}");

      for (var d in fetchedDebts) {
        debugPrint("Debt: ${d.name} | ${d.amount}");
      }

      if (!mounted) return;

      setState(() {
        plans = strategyList;
        debts = fetchedDebts;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  Future<List<FinanceItem>> fetchDebtsFromCrud() async {
    final debtResponses = await debtService.getAllDebt();

    return debtResponses.map((d) {
      return FinanceItem(
        name: d.debtName,
        amount: d.principalAmount,
        interest: d.interestRate,
        type: d.debtType.debtTypeName,
      );
    }).toList();
  }



  Future<void> _startPlan() async {
    if (selectedIndex == null) return;

    final plan = plans[selectedIndex!];

    // รวมรายได้ทั้งหมด
    final totalIncome =
    incomes.fold(0.0, (sum, i) => sum + i.amount);

    final monthlyBudget = totalIncome * 0.3; // 30%

    setState(() => isSubmitting = true);

    debugPrint("===== DASHBOARD DATA =====");
    debugPrint("Incomes count: ${incomes.length}");
    debugPrint("Debts count: ${debts.length}");

    for (var d in debts) {
      debugPrint("Debt: ${d.name} | amount=${d.amount}");
    }

    try {
      await planService.createPlan(
        strategyId: plan.strategyId,
        monthlyBudget: monthlyBudget,
      );


      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlanDetailScreen(
            planName: plan.strategyName,
            description: plan.description,
            incomes: incomes,
            debts: debts,
            monthlyBudget: monthlyBudget,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("สร้างแผนไม่สำเร็จ: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  void _openNoPlan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlanDetailScreen(
          planName: "ไม่มีแผน",
          description: "จ่ายหนี้ตามใจ ไม่ใช้กลยุทธ์ใด ๆ",
          incomes: incomes,
          debts: debts,
          monthlyBudget: 1000,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Simulator Plans'),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Text(
            "โหลดข้อมูลไม่สำเร็จ\n$error",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือกแผนการจ่ายหนี้'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),

      bottomNavigationBar: selectedIndex != null
          ? Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            minimumSize: const Size(double.infinity, 52),
          ),
          onPressed: isSubmitting ? null : _startPlan,
          child: isSubmitting
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
            "เริ่มแผนนี้",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      )
          : null,

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...List.generate(plans.length, (index) {
            final plan = plans[index];
            final isExpanded = expandedIndex == index;

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    expandedIndex = null;
                    selectedIndex = null;
                  } else {
                    expandedIndex = index;
                    selectedIndex = index;
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color:
                  isExpanded ? Colors.green.shade50 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isExpanded
                        ? Colors.green.shade700
                        : Colors.grey.shade300,
                    width: isExpanded ? 2 : 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                        plan.strategyName,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      trailing: Icon(
                        isExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: Colors.green.shade700,
                      ),
                    ),
                    if (isExpanded)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            16, 0, 16, 12),
                        child: Text(plan.description),
                      ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          const Divider(),
          Card(
            color: Colors.grey.shade100,
            child: ListTile(
              leading:
              const Icon(Icons.sync_alt, color: Colors.grey),
              title: const Text(
                "จ่ายแบบไม่มีแผน",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle:
              const Text("เลือกจ่ายเอง ไม่ใช้กลยุทธ์ใด ๆ"),
              onTap: _openNoPlan,
            ),
          ),
        ],
      ),
    );
  }
}
