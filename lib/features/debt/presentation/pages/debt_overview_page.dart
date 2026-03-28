import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../features/simulator/data/services/repaymentTypeService.dart';
import '../../../../features/simulator/presentation/RepaymentSimulatorPage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/services/debt_service.dart';
import '../../domain/models/debt_response.dart';
import '../../domain/models/monthly_debt_status.dart';

class DebtOverviewPage extends StatefulWidget {
  final int unreadCount;
  const DebtOverviewPage({super.key, this.unreadCount = 0});

  @override
  State<DebtOverviewPage> createState() => _DebtOverviewPageState();
}

class _DebtOverviewPageState extends State<DebtOverviewPage> {
  final DebtService _debtService = DebtService();
  List<DebtResponse> _debtResponses = [];
  MonthlyDebtStatus? _monthlyStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final List<DebtResponse> responses = await _debtService.getAllDebt();
      final MonthlyStatus = await _debtService.getMonthlyDebtStatus();
      if (!mounted) return;
      setState(() {
        _debtResponses = responses;
        _monthlyStatus = MonthlyStatus;
      });
    } catch (e) {
      debugPrint("Error loading debts: $e");
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteDebt(DebtResponse debt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935), size: 28),
            const SizedBox(width: 8),
            Text(
              'ยืนยันการลบ',
              style: GoogleFonts.kanit(fontWeight: FontWeight.bold, color: const Color(0xFFE53935)),
            ),
          ],
        ),
        content: Text(
          'คุณแน่ใจหรือไม่ว่าต้องการลบรายการหนี้ "${debt.debtName}',
          style: GoogleFonts.kanit(fontSize: 15, color: Colors.black87),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'ยกเลิก',
              style: GoogleFonts.kanit(color: Colors.black54, fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text('ลบรายการ', style: GoogleFonts.kanit(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _debtService.deleteDebt(debt.debtId);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'ลบรายการหนี้สำเร็จ',
                      style: GoogleFonts.kanit(fontSize: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFE53935),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        debugPrint("Error deleting debt: $e");
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('ไม่สามารถลบรายการหนี้ได้ กรุณาตรวจสอบการเชื่อมต่อและลองใหม่อีกครั้ง')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeDebts = _debtResponses.where((d) => d.isActive).toList()
      ..sort((a, b) => a.principalOutstanding.compareTo(b.principalOutstanding));
    final closedDebts = _debtResponses.where((d) => !d.isActive).toList();

    double totalBalance = activeDebts.fold(
      0.0,
      (sum, d) => sum + d.totalRemaining,
    );
    double avgInterest = activeDebts.isEmpty
        ? 0.0
        : activeDebts.fold(0.0, (sum, d) => sum + d.interestRate) /
              activeDebts.length;
    double totalMinPayment = activeDebts.fold(
      0.0,
      (sum, d) => sum + d.minPayment,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFEB5757)),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    'assets/logo_finance_care.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'สวัสดี, ยินดีต้อนรับ',
                                        style: GoogleFonts.kanit(
                                          fontSize: 16,
                                          color: const Color(0xFF64748B),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'ภาพรวมหนี้สิน',
                                        style: GoogleFonts.kanit(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildNotificationBell(),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSummaryCard(
                        totalPrincipal: totalBalance,
                        activeCount: activeDebts.length,
                        totalCount: _debtResponses.length,
                        avgInterest: avgInterest,
                        minPayment: totalMinPayment,
                        monthlyStatus: _monthlyStatus,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'เมนูลัด',
                        style: GoogleFonts.kanit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildQuickMenu(),
                      const SizedBox(height: 24),
                      _buildJobSuggestionBanner(),
                      const SizedBox(height: 32),
                      _buildSectionHeader(
                        'หนี้ที่ใช้งานอยู่',
                        activeDebts.length,
                      ),
                      const SizedBox(height: 16),
                      if (activeDebts.isEmpty)
                        _buildEmptyState('ไม่มีรายการหนี้ที่ใช้งานอยู่')
                      else
                        ...activeDebts.map((debt) => _buildDebtCard(debt)),
                      const SizedBox(height: 32),
                      _buildSectionHeader(
                        'หนี้ที่ปิดการใช้งาน',
                        closedDebts.length,
                      ),
                      const SizedBox(height: 16),
                      if (closedDebts.isEmpty)
                        _buildEmptyState('ไม่มีรายการหนี้ที่ปิดการใช้งาน')
                      else
                        ...closedDebts.map(
                          (debt) => _buildClosedDebtCard(debt),
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required double totalPrincipal,
    required int activeCount,
    required int totalCount,
    required double avgInterest,
    required double minPayment,
    MonthlyDebtStatus? monthlyStatus,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEB5757),
            Color(0xFFD63D3D),
            Color(0xFFB32B2B),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEB5757).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'ยอดหนี้คงเหลือทั้งหมด',
                style: GoogleFonts.kanit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${NumberFormat('#,##0.00').format(totalPrincipal)} ฿',
            style: GoogleFonts.kanit(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _buildGlassMetric(
                  label: 'หนี้ที่ใช้งาน',
                  value: '$activeCount รายการ',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGlassMetric(
                  label: 'ดอกเบี้ยเฉลี่ย',
                  value: '${avgInterest.toStringAsFixed(1)}% ต่อปี',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, color: Colors.white, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.kanit(color: Colors.white, fontSize: 13),
                      children: [
                        const TextSpan(text: 'ยอดจ่ายขั้นต่ำรวม: '),
                        TextSpan(
                          text: '${NumberFormat('#,##0.00').format(minPayment)} ฿',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' /เดือน'),
                        if (monthlyStatus != null && monthlyStatus.remainingAmount > 0) ...[
                          const TextSpan(text: '\n'),
                          const TextSpan(text: 'คงเหลือที่ต้องจ่ายในเดือนนี้: '),
                          TextSpan(
                            text: '${NumberFormat('#,##0.00').format(monthlyStatus.remainingAmount)} ฿',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFCC00)),
                          ),
                        ] else if (monthlyStatus != null && monthlyStatus.remainingAmount <= 0) ...[
                          const TextSpan(text: '\n'),
                          TextSpan(
                            text: 'ชำระของเดือนนี้ครบถ้วนแล้ว ✨',
                            style: GoogleFonts.kanit(fontWeight: FontWeight.bold, color: const Color(0xFF4CAF50)),
                          ),
                        ],
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

  Widget _buildGlassMetric({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.kanit(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.kanit(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMenu() {
    final menus = [
      {
        'icon': Icons.add_business_outlined,
        'label': 'สร้างหนี้',
        'color': const Color(0xFFFFEDEC),
        'iconColor': const Color(0xFFF44336),
        'route': '/add_debt',
      },
      {
        'icon': Icons.insights_outlined,
        'label': 'กลยุทธ์ชำระ',
        'color': const Color(0xFFFFF7E6),
        'iconColor': const Color(0xFFFAAD14),
        'route': '/simulator',
      },
      {
        'icon': Icons.auto_awesome_motion_outlined,
        'label': 'ดูแผนของคุณ',
        'color': const Color(0xFFE6F7FF),
        'iconColor': const Color(0xFF1890FF),
        'route': '/simulator_results',
      },
      {
        'icon': Icons.payments_outlined,
        'label': 'ชำระหนี้',
        'color': const Color(0xFFE9F7F7),
        'iconColor': const Color(0xFF2D955F),
        'route': '/pay_debt',
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: menus.map((menu) {
          return Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () async {
                if (menu['route'] == '/simulator_results') {
                  setState(() => _isLoading = true);
                  try {
                    final overview = await RepaymentStrategyService()
                        .fetchStrategies();
                    if (!mounted) return;
                    final strategyId = overview.strategies.isNotEmpty
                        ? overview.strategies.first.strategyId
                        : "snowball";
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RepaymentSimulatorPage(
                          monthlyBudget: overview.monthlyBudget,
                          strategy: strategyId,
                          showConfirmButton: false,
                        ),
                      ),
                    );
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('ไม่พบข้อมูลแผนของคุณ: $e')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                } else {
                  Navigator.pushNamed(
                    context,
                    menu['route'] as String,
                  ).then((_) => _loadData());
                }
              },
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: menu['color'] as Color,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (menu['iconColor'] as Color).withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      menu['icon'] as IconData,
                      color: menu['iconColor'] as Color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 10),
                    Text(
                    menu['label'] as String,
                    style: GoogleFonts.kanit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildJobSuggestionBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2D955F).withOpacity(0.08),
            const Color(0xFF2D955F).withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF2D955F).withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () {
            Navigator.pushNamed(context, '/job_suggestion');
          },
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Transform.rotate(
                  angle: -0.2,
                  child: Icon(
                    Icons.rocket_launch_outlined,
                    size: 120,
                    color: const Color(0xFF2D955F).withOpacity(0.05),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D955F).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF2D955F)),
                          const SizedBox(width: 8),
                          Text(
                            'แนะนำอาชีพอัตโนมัติ',
                            style: GoogleFonts.kanit(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF2D955F),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'เร่งสปีดปลดหนี้ให้ไวขึ้น\nด้วยอาชีพเสริมที่เหมาะกับคุณ',
                      style: GoogleFonts.kanit(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'วิเคราะห์จากทักษะและเวลาว่างของคุณ',
                      style: GoogleFonts.kanit(
                        fontSize: 18,
                        color: const Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            '*คำนวณจากฐานข้อมูลตลาดแรงงานปี 2567',
                            style: GoogleFonts.kanit(
                              fontSize: 10,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D955F),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2D955F).withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'ดูคำแนะนำ',
                                style: GoogleFonts.kanit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ],
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
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            title,
            style: GoogleFonts.kanit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count รายการ',
          style: GoogleFonts.kanit(fontSize: 13, color: Colors.black26),
        ),
      ],
    );
  }

  Widget _buildDebtCard(DebtResponse debt) {
    final remainingDays = debt.endDate.difference(DateTime.now()).inDays;
    final totalDays = debt.endDate.difference(debt.startDate).inDays;
    final progress = totalDays > 0
        ? (1 - (remainingDays / totalDays)).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.pushNamed(
              context,
              '/add_debt',
              arguments: {'debt': debt, 'isViewOnly': true},
            ).then((value) {
              if (value == true) _loadData();
            }),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3F3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.credit_card_outlined,
                          color: Color(0xFFEB5757),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              debt.debtName,
                              style: GoogleFonts.kanit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: debt.principalOutstanding <= 0 ? const Color(0xFF2D955F) : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'เงินต้นทั้งหมด ${NumberFormat('#,##0.00').format(debt.principalAmount)} ฿',
                              style: GoogleFonts.kanit(
                                fontSize: 13,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Text(
                              '${debt.debtType.debtTypeName} • ${debt.repaymentType.typeName}',
                              style: GoogleFonts.kanit(
                                fontSize: 14,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.black26),
                        onSelected: (val) {
                          if (val == 'edit') {
                            Navigator.pushNamed(
                              context,
                              '/add_debt',
                              arguments: debt,
                            ).then((value) {
                              if (value == true) _loadData();
                            });
                          } else if (val == 'delete') {
                            _deleteDebt(debt);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_outlined, color: Color(0xFF2196F3), size: 20),
                                const SizedBox(width: 12),
                                Text('แก้ไข', style: GoogleFonts.kanit(color: const Color(0xFF0F172A), fontSize: 15)),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(height: 1),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_outline, color: Color(0xFFE53935), size: 20),
                                const SizedBox(width: 12),
                                Text('ลบ', style: GoogleFonts.kanit(color: const Color(0xFFE53935), fontSize: 15)),
                              ],
                            ),
                          ),
                        ],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        color: Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (debt.interestRemaining > 0 ||
                      debt.lateFeeRemaining > 0 ||
                      debt.penaltyInterestRemaining > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _buildBreakdownRow("เงินต้นคงเหลือ", debt.principalOutstanding, const Color(0xFF475569), false),
                          if (debt.interestRemaining > 0) ...[
                            const SizedBox(height: 8),
                            _buildBreakdownRow("ดอกเบี้ยคงค้าง", debt.interestRemaining, const Color(0xFFE53935), false),
                          ],
                          if (debt.lateFeeRemaining + debt.penaltyInterestRemaining > 0) ...[
                            const SizedBox(height: 8),
                            _buildBreakdownRow(
                              "ค่าธรรมเนียมและค่าปรับ",
                              debt.lateFeeRemaining + debt.penaltyInterestRemaining,
                              const Color(0xFFE53935),
                              false,
                            ),
                          ],
                          if (debt.interestRemainingMonth + debt.lateFeeRemainingMonth + debt.penaltyInterestRemainingMonth > 0) ...[
                            const SizedBox(height: 8),
                            _buildBreakdownRow(
                              "ส่วนที่ต้องชำระเฉพาะเดือนนี้",
                              debt.interestRemainingMonth + debt.lateFeeRemainingMonth + debt.penaltyInterestRemainingMonth,
                              const Color(0xFFE53935),
                              false,
                            ),
                          ],
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                          ),
                          _buildBreakdownRow("ยอดรวมทั้งหมด", debt.totalRemaining, const Color(0xFF0F172A), true),
                        ],
                      ),
                    ),
                  ] else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'เงินต้นคงเหลือ',
                              style: GoogleFonts.kanit(
                                fontSize: 14,
                                color: const Color(0xFF475569),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${NumberFormat('#,##0.00').format(debt.principalOutstanding)} ฿',
                              style: GoogleFonts.kanit(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: debt.principalOutstanding <= 0
                                    ? const Color(0xFF2D955F)
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'ดอกเบี้ย ${debt.interestRate}%',
                            style: GoogleFonts.kanit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 14, color: Colors.black26),
                          const SizedBox(width: 4),
                          Text(
                            'เหลืออีก $remainingDays วัน',
                            style: GoogleFonts.kanit(
                              fontSize: 13, 
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'เป้าหมาย: ${DateFormat('dd MMM yy', 'th').format(debt.endDate)}',
                        style: GoogleFonts.kanit(
                          fontSize: 13, 
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEB5757), Color(0xFFFF8585)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClosedDebtCard(DebtResponse debt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F4).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.02)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.block, color: Colors.black26, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debt.debtName,
                  style: GoogleFonts.kanit(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black45,
                  ),
                ),
                Text(
                  '${NumberFormat('#,##0.00').format(debt.principalAmount)} ฿ - ${debt.debtType.debtTypeName}',
                  style: GoogleFonts.kanit(fontSize: 12, color: Colors.black26),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'ปิดใช้งาน',
              style: GoogleFonts.kanit(fontSize: 11, color: Colors.black26),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double amount, Color color, bool isBold) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.kanit(
            fontSize: isBold ? 16 : 14,
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          '${NumberFormat('#,##0.00').format(amount)} ฿',
          style: GoogleFonts.kanit(
            fontSize: isBold ? 18 : 14,
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.02)),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 48, color: Colors.black12),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.kanit(color: Colors.black26, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationBell() {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/notify');
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_none_outlined,
              color: Color(0xFF2D955F),
              size: 24,
            ),
          ),
          if (widget.unreadCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFEB5757),
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  widget.unreadCount > 9 ? '9+' : '${widget.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
