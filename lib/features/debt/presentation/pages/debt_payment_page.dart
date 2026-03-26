import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/services/debt_service.dart';
import '../../domain/models/debt_response.dart';

class DebtPaymentPage extends StatefulWidget {
  const DebtPaymentPage({super.key});

  @override
  State<DebtPaymentPage> createState() => _DebtPaymentPageState();
}

class _DebtPaymentPageState extends State<DebtPaymentPage> {
  final DebtService _debtService = DebtService();
  List<DebtResponse> _activeDebts = [];
  DebtResponse? _selectedDebt;
  bool _isLoading = true;
  bool _isSubmitting = false;

  final TextEditingController _amountController = TextEditingController(
    text: '0.00',
  );
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    setState(() => _isLoading = true);
    try {
      final responses = await _debtService.getAllDebt();
      if (!mounted) return;
      setState(() {
        _activeDebts = responses.where((d) => d.isActive).toList();
        if (_activeDebts.isNotEmpty) {
          _selectedDebt = _activeDebts.first;
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading debts: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitPayment() async {
    if (_selectedDebt == null) return;

    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาระบุจำนวนเงินที่ต้องการชำระ')),
      );
      return;
    }

    if (amount > _selectedDebt!.principalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ยอดชำระเกินยอดคงเหลือ (คงเหลือ ${NumberFormat('#,##0.00').format(_selectedDebt!.principalAmount)} ฿)',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final paidAt = DateFormat('yyyy-MM-dd').format(_selectedDate);
      await _debtService.payDebt(_selectedDebt!.debtId, amount, paidAt);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ชำระหนี้สำเร็จ')));
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Error paying debt: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _onShortcutPressed(double amount) {
    setState(() {
      _amountController.text = NumberFormat('#,###.00').format(amount);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ชำระหนี้',
              style: GoogleFonts.kanit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              'บันทึกรายการชำระหนี้ของคุณ',
              style: GoogleFonts.kanit(fontSize: 12, color: Colors.black45),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF27AE60)),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'เลือกรายการหนี้',
                      style: GoogleFonts.kanit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDebtSelector(),
                    const SizedBox(height: 24),
                    if (_selectedDebt != null) ...[
                      _buildSummaryCard(_selectedDebt!),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'จำนวนเงินที่ต้องการชำระ',
                            style: GoogleFonts.kanit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _onShortcutPressed(
                              _selectedDebt!.principalAmount,
                            ),
                            child: Text(
                              'ชำระทั้งหมด',
                              style: GoogleFonts.kanit(
                                color: const Color(0xFF27AE60),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildAmountInput(),
                      const SizedBox(height: 16),
                      _buildShortcuts(),
                      const SizedBox(height: 32),
                      Text(
                        'วันที่ชำระ',
                        style: GoogleFonts.kanit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDatePicker(),
                      const SizedBox(height: 48),
                      _buildSubmitButton(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDebtSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF27AE60), width: 2),
      ),
      child: ListTile(
        onTap: _showDebtSelectionModal,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.credit_card_outlined,
            color: Color(0xFF27AE60),
            size: 24,
          ),
        ),
        title: Text(
          _selectedDebt?.debtName ?? 'เลือกรายการหนี้',
          style: GoogleFonts.kanit(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          _selectedDebt != null
              ? '${_selectedDebt!.debtType.debtTypeName} / ${_selectedDebt!.repaymentType.typeName} | คงเหลือ ${NumberFormat('#,##0.00').format(_selectedDebt!.principalAmount)} ฿'
              : 'แตะเพื่อเลือกหนี้',
          style: GoogleFonts.kanit(fontSize: 12, color: Colors.black45),
        ),
        trailing: const Icon(Icons.keyboard_arrow_down, color: Colors.black26),
      ),
    );
  }

  void _showDebtSelectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'เลือกรายการหนี้',
                style: GoogleFonts.kanit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _activeDebts.length,
                  itemBuilder: (context, index) {
                    final debt = _activeDebts[index];
                    final isSelected = _selectedDebt?.debtId == debt.debtId;
                    return ListTile(
                      onTap: () {
                        setState(() {
                          _selectedDebt = debt;
                          _amountController.text = '0.00';
                        });
                        Navigator.pop(context);
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF27AE60)
                              : const Color(0xFFF1F3F4),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.credit_card,
                          color: isSelected ? Colors.white : Colors.black26,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        debt.debtName,
                        style: GoogleFonts.kanit(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        'คงเหลือ ${NumberFormat('#,##0.00').format(debt.principalAmount)} ฿',
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: Color(0xFF27AE60),
                            )
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(DebtResponse debt) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF27AE60),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF27AE60).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ยอดหนี้คงเหลือ',
            style: GoogleFonts.kanit(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${NumberFormat('#,##0.00').format(debt.principalAmount)} ฿',
            style: GoogleFonts.kanit(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'ดอกเบี้ย ${debt.interestRate}%',
                style: GoogleFonts.kanit(color: Colors.white, fontSize: 13),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(width: 1, height: 12, color: Colors.white24),
              ),
              Text(
                'ครบกำหนด ${DateFormat('yyyy-MM-dd').format(debt.endDate)}',
                style: GoogleFonts.kanit(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Text(
            '฿',
            style: GoogleFonts.kanit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: GoogleFonts.kanit(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '0.00',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcuts() {
    final amounts = [1000.0, 5000.0, 10000.0, 50000.0];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: amounts.map((amount) {
        return GestureDetector(
          onTap: () => _onShortcutPressed(amount),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Text(
              '${NumberFormat('#,##0').format(amount)} ฿',
              style: GoogleFonts.kanit(fontSize: 13, color: Colors.black54),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF27AE60),
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          setState(() => _selectedDate = date);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              color: Color(0xFF27AE60),
              size: 20,
            ),
            const SizedBox(width: 16),
            Text(
              DateFormat('MM/dd/yyyy').format(_selectedDate),
              style: GoogleFonts.kanit(fontSize: 16, color: Colors.black87),
            ),
            const Spacer(),
            const Icon(Icons.event, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF27AE60),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ชำระเงิน',
                    style: GoogleFonts.kanit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
