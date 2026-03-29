import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/features/simulator/data/models/repayment_strategy_response.dart';
import 'package:flutter_application_1/features/simulator/data/services/repaymentTypeService.dart';
import 'DebtPriorityScreen.dart';


class RepaymentStrategyScreen extends StatefulWidget {
  const RepaymentStrategyScreen({super.key});

  @override
  State<RepaymentStrategyScreen> createState() =>
      _RepaymentStrategyScreenState();
}

class _RepaymentStrategyScreenState extends State<RepaymentStrategyScreen> {
  final TextEditingController _budgetController = TextEditingController();
  String _selectedStrategy = "";
  double _monthlyBudget = 0.0;
  List<RepaymentStrategyResponse> _strategies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    debugPrint("Entering RepaymentStrategyScreen");
    _loadStrategies();
  }

  Future<void> _loadStrategies() async {
    try {
      debugPrint("fetchStrategies started");
      final overview = await RepaymentStrategyService().fetchStrategies();
      debugPrint("fetchStrategies finished");
      if (!mounted) return;
      setState(() {
        _strategies = overview.strategies;
        _monthlyBudget = overview.monthlyBudget;
        if (_strategies.isNotEmpty) {
          _selectedStrategy = _strategies.first.strategyId;
          if (_monthlyBudget > 0) {
            _budgetController.text = _monthlyBudget.round().toString();
          }
        }
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint("-------------------------------");
      debugPrint("CRITICAL EXCEPTION in _loadStrategies");
      debugPrint("Error: $e");
      debugPrint("Type: ${e.runtimeType}");
      debugPrint("StackTrace: $stackTrace");
      debugPrint("-------------------------------");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ไม่สามารถดึงข้อมูลกลยุทธ์ได้ กรุณาลองใหม่อีกครั้ง")),
        );
      }
    }
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double annualCapacity =
        (double.tryParse(_budgetController.text) ?? 0.0) * 12;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2D955F),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'FinanceCare',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2D955F),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'ขั้นตอนที่ 1 จาก 3',
                      style: GoogleFonts.kanit(

                        fontSize: 11,
                        color: const Color(0xFF2D955F),
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'เลือกยุทธวิธีการชำระหนี้ของคุณ',
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1C1E),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'ตั้งงบประมาณรายเดือนและเลือกกลยุทธ์ที่เหมาะกับไลฟ์สไตล์ของคุณ เราจะสร้างแผนการชำระหนี้ที่เหมาะกับคุณโดยเฉพาะ',
                  style: GoogleFonts.kanit(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                _buildMonthlyBudgetSection(annualCapacity),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Text(
                      'เลือกกลยุทธ์',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1C1E),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'เลือกแล้ว',
                        style: GoogleFonts.kanit(
                          fontSize: 12,
                          color: const Color(0xFF00796B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_strategies.isEmpty)
                  Center(
                    child: Text(
                      'ไม่พบข้อมูลกลยุทธ์',
                      style: GoogleFonts.kanit(color: Colors.grey),
                    ),
                  )
                else
                  ..._strategies.map(
                    (strategy) => _buildStrategyCard(
                      id: strategy.strategyId,
                      title: _translateStrategyName(strategy.strategyName),
                      description: strategy.description,
                      tags: strategy.tags,
                      icon: _getStrategyIcon(strategy.strategyName),
                      badge: _getStrategyBadge(strategy.strategyName),
                      isSelected: _selectedStrategy == strategy.strategyId,
                    ),
                  ),
                const SizedBox(height: 120), // Space for bottom summary
              ],
            ),
          ),
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: _buildPlanSummaryFooter(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyBudgetSection(double annualCapacity) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.attach_money_rounded,
                  color: Color(0xFF2D955F),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'งบประมาณรายเดือน',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'คุณสามารถชำระหนี้ได้เท่าไหร่ในแต่ละเดือน?',
                      style: GoogleFonts.kanit(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Text(
                  '฿',
                  style: GoogleFonts.kanit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (val) => setState(() {}),
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: "0",
                      hintStyle: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
                Text(
                  '/ เดือน',
                  style: GoogleFonts.kanit(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9).withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 8, color: Color(0xFF2D955F)),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.kanit(
                        fontSize: 14,
                        color: const Color(0xFF1B5E20),
                      ),
                      children: [
                        const TextSpan(
                          text: 'งบประมาณรายเดือนขั้นต่ำที่ต้องใช้: ',
                        ),
                        TextSpan(
                          text: '฿${_monthlyBudget.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyCard({
    required String id,
    required String title,
    required String description,
    required List<String> tags,
    required IconData icon,
    String? badge,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStrategy = id;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2D955F)
                      : Colors.grey.shade200,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: const Color(0xFF2D955F).withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFF1F4F2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          icon,
                          color: const Color(0xFF2D955F),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              description,
                              style: GoogleFonts.kanit(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF2D955F)
                                : Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: isSelected
                            ? const Center(
                                child: Icon(
                                  Icons.check_circle,
                                  size: 22,
                                  color: Color(0xFF2D955F),
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFF1F4F2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tag,
                              style: GoogleFonts.kanit(
                                fontSize: 12,
                                color: isSelected
                                    ? const Color(0xFF2D955F)
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                top: -12,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D955F),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.kanit(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanSummaryFooter() {
    if (_isLoading || _strategies.isEmpty) return const SizedBox.shrink();

    final selectedStrategyObj = _strategies.firstWhere(
      (s) => s.strategyId == _selectedStrategy,
      orElse: () => _strategies.first,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2D955F).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'สรุปแผนของคุณ',
                  style: GoogleFonts.kanit(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      color: Colors.black,
                    ),
                    children: [
                      TextSpan(
                        text: '฿${_budgetController.text}/เดือน',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ' ด้วย '),
                      TextSpan(
                        text: _translateStrategyName(selectedStrategyObj.strategyName),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_selectedStrategy.isEmpty) return;
              final budget = double.tryParse(_budgetController.text) ?? 0.0;

              if (budget < _monthlyBudget) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'งบประมาณต้องไม่น้อยกว่าค่าขั้นต่ำ (฿${_monthlyBudget.toInt()})',
                    ),
                  ),
                );
                return;
              }

              try {
                // Call createPlan as requested by user on Continue
                await RepaymentStrategyService().createPlan(
                  monthlyBudget: budget,
                  strategyId: _selectedStrategy,
                );

                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DebtPriorityScreen(
                      monthlyBudget: budget,
                      strategyId: _selectedStrategy,
                      strategyName: _translateStrategyName(selectedStrategyObj.strategyName),
                    ),
                  ),
                );

              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ไม่สามารถสร้างแผนได้ในขณะนี้ กรุณาลองใหม่อีกครั้ง')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D955F),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'ถัดไป',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStrategyIcon(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('snowball')) return Icons.track_changes_outlined;
    if (lowerName.contains('avalanche')) return Icons.trending_down_outlined;
    if (lowerName.contains('minimum')) return Icons.vertical_align_bottom_outlined;
    if (lowerName.contains('optimal')) return Icons.lightbulb_outline;
    return Icons.layers_outlined;
  }

  String? _getStrategyBadge(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('snowball')) return "ยอดนิยม";
    if (lowerName.contains('avalanche')) return "แนะนำ";
    if (lowerName.contains('optimal')) return "คุ้มสุด";
    return null;
  }

  String _translateStrategyName(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('snowball')) return 'สโนว์บอล (Snowball)';
    if (lowerName.contains('avalanche')) return 'แอฟวาลานซ์ (Avalanche)';
    if (lowerName.contains('minimum')) return 'จ่ายขั้นต่ำเท่านั้น';
    if (lowerName.contains('optimal')) return 'ต้นทุนต่ำสุด (Optimal)';
    return name;
  }
}
