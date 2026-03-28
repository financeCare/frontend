import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../data/models/debt_priority_model.dart';
import '../data/services/repaymentTypeService.dart';
import 'RepaymentSimulatorPage.dart';

class DebtPriorityScreen extends StatefulWidget {
  final double monthlyBudget;
  final String strategyId;
  final String strategyName;

  const DebtPriorityScreen({
    super.key,
    required this.monthlyBudget,
    required this.strategyId,
    required this.strategyName,
  });

  @override
  State<DebtPriorityScreen> createState() => _DebtPriorityScreenState();
}

class _DebtPriorityScreenState extends State<DebtPriorityScreen> {
  final RepaymentStrategyService _service = RepaymentStrategyService();
  List<DebtPriorityResponse> _debts = [];
  bool _isLoading = true;
  bool _isSaving = false;
  final NumberFormat _currencyFormat = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _loadPriorities();
  }

  Future<void> _loadPriorities() async {
    try {
      final debts = await _service.fetchDebtPriorities();
      if (!mounted) return;
      setState(() {
        _debts = debts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถดึงข้อมูลลำดับหนี้ได้ กรุณาลองใหม่อีกครั้ง')),
      );
    }
  }

  Future<void> _saveAndNext() async {
    setState(() => _isSaving = true);
    try {
      final updates = _debts.asMap().entries.map((entry) {
        return DebtPriorityUpdateRequest(
          debtId: entry.value.debtId,
          priority: entry.key + 1,
        );
      }).toList();

      await _service.updateDebtPriorities(updates);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RepaymentSimulatorPage(
            monthlyBudget: widget.monthlyBudget,
            strategy: widget.strategyId,
            showConfirmButton: true,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกลำดับไม่สำเร็จ กรุณาลองใหม่อีกครั้ง')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D955F)))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(),
                  const SizedBox(height: 32),
                  _buildInstructionTitle(),
                  const SizedBox(height: 12),
                  _buildInstructionDescription(),
                  const SizedBox(height: 32),
                  _buildHowItWorksBox(),
                  const SizedBox(height: 32),
                  _buildStatsRow(),
                  const SizedBox(height: 16),
                  _buildFirstToPayOffBox(),
                  const SizedBox(height: 32),
                  _buildListHeader(),
                  const SizedBox(height: 16),
                  _buildReorderableList(),
                  const SizedBox(height: 32),
                  _buildViewPlanFooter(),
                  const SizedBox(height: 32),
                  _buildFooterTip(),
                ],
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black54),
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
            child: const Icon(Icons.shield_outlined, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Text(
            'FinanceCare',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: const Color(0xFF1A1C1E),
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, size: 8, color: Color(0xFF2D955F)),
                const SizedBox(width: 6),
                Text(
                  'Step 2 of 3',
                  style: GoogleFonts.kanit(
                    fontSize: 12,
                    color: const Color(0xFF2D955F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey.shade100, height: 1),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.format_list_bulleted_rounded, color: Color(0xFF2D955F), size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          'Customize Priority',
          style: GoogleFonts.kanit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D955F),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionTitle() {
    return Text(
      'Adjust Your Repayment Order',
      style: GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1A1C1E),
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildInstructionDescription() {
    return Text(
      'Drag and drop to customize which debts you want to pay off first. Your selected strategy has set an initial order, but you can adjust it to fit your needs.',
      style: GoogleFonts.kanit(
        fontSize: 16,
        color: Colors.grey.shade600,
        height: 1.5,
      ),
    );
  }

  Widget _buildHowItWorksBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.info_outline, color: Color(0xFF2D955F), size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How does priority work?',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Debts at the top of the list will receive extra payments first after all minimum payments are made. This helps you clear debts faster based on your preference.',
                  style: GoogleFonts.kanit(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    double totalPrincipal = _debts.fold(0, (sum, item) => sum + item.principalAmount);
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Total Debts', '${_debts.length}'),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard('Total Principal', '฿${_currencyFormat.format(totalPrincipal)}'),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.kanit(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1C1E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirstToPayOffBox() {
    String firstDebt = _debts.isNotEmpty ? _debts.first.debtName : 'No debts added';
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'First to Pay Off',
            style: GoogleFonts.kanit(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            firstDebt,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D955F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Debt Priority Order',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1C1E),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF2D955F)),
              const SizedBox(width: 4),
              Text(
                widget.strategyName,
                style: GoogleFonts.kanit(
                  fontSize: 11,
                  color: const Color(0xFF2D955F),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReorderableList() {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _debts.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final item = _debts.removeAt(oldIndex);
          _debts.insert(newIndex, item);
        });
      },
      itemBuilder: (context, index) {
        final debt = _debts[index];
        return _buildDebtItem(debt, index);
      },
    );
  }

  Widget _buildDebtItem(DebtPriorityResponse debt, int index) {
    return Container(
      key: ValueKey(debt.debtId),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            const Icon(Icons.drag_indicator, color: Colors.grey, size: 24),
            const SizedBox(width: 16),
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF2D955F),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    debt.debtName,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: const Color(0xFF1A1C1E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.payments_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Principal: ฿${_currencyFormat.format(debt.principalAmount)}',
                        style: GoogleFonts.kanit(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewPlanFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready to see your repayment plan?',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Continue to view the detailed repayment timeline.',
                      style: GoogleFonts.kanit(
                        fontSize: 13,
                        color: const Color(0xFF1B5E20).withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveAndNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D955F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'View Plan',
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
          ),
        ],
      ),
    );
  }

  Widget _buildFooterTip() {
    return Center(
      child: Text(
        'Tip: Drag the grip icon on the left to reorder your debts.',
        style: GoogleFonts.kanit(
          fontSize: 12,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }
}
