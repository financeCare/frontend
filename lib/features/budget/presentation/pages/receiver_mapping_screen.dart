import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../domain/models/receiver_mapping.dart';
import '../../domain/models/mapping_request.dart';
import '../../domain/models/category.dart';
import '../../domain/models/transaction_response.dart';
import '../../data/services/receiver_mapping_service.dart';
import '../../data/services/category_service.dart';
import '../../data/services/transaction_service.dart';

class ReceiverMappingScreen extends StatefulWidget {
  const ReceiverMappingScreen({super.key});

  @override
  State<ReceiverMappingScreen> createState() => _ReceiverMappingScreenState();
}

class _ReceiverMappingScreenState extends State<ReceiverMappingScreen> {
  final ReceiverMappingService _mappingService = ReceiverMappingService();
  final CategoryService _categoryService = CategoryService();
  final TransactionService _transactionService = TransactionService();

  String _searchQuery = '';
  String _selectedTab = 'Pending'; // Pending or Matched
  bool _isLoading = true;

  List<ReceiverMapping> _mappings = [];
  List<Categories> _categories = [];
  List<Map<String, dynamic>> _pendingReceivers = [];
  List<TransactionResponse> _allTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _mappingService.getAllMappings(),
        _categoryService.getCategories(),
        _transactionService.getOwnTransactions(),
      ]);

      _mappings = results[0] as List<ReceiverMapping>;
      _categories = results[1] as List<Categories>;
      _allTransactions = results[2] as List<TransactionResponse>;
      
      _processPendingReceivers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _processPendingReceivers() {
    // ผู้รับที่ถูกจับคู่แล้ว (ชื่อผู้รับ)
    final mappedNames = _mappings.map((m) => m.receiverName.toLowerCase()).toSet();

    // ค้นหาผู้รับจากธุรกรรมที่ยังไม่ได้จับคู่
    final Map<String, Map<String, dynamic>> pendingMap = {};

    for (var tx in _allTransactions) {
      final name = tx.receiverName;
      if (name == null || name.isEmpty) continue;
      
      if (!mappedNames.contains(name.toLowerCase())) {
        if (!pendingMap.containsKey(name)) {
          pendingMap[name] = {
            'name': name,
            'count': 0,
            'amount': 0.0,
          };
        }
        pendingMap[name]!['count'] += 1;
        pendingMap[name]!['amount'] += tx.amount;
      }
    }

    _pendingReceivers = pendingMap.values.toList();
    _pendingReceivers.sort((a, b) => b['count'].compareTo(a['count']));
  }

  List<Map<String, dynamic>> get _filteredPending => _pendingReceivers
      .where((r) => r['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();

  List<ReceiverMapping> get _filteredMatched => _mappings
      .where((r) => r.receiverName.toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();

  Future<void> _saveMapping(String receiverName, int categoryId) async {
    try {
      await _mappingService.saveMapping(
        MappingRequest(receiverName: receiverName, categoryId: categoryId),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกการจับคู่เรียบร้อยแล้ว')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถบันทึกข้อมูลได้: $e')),
        );
      }
    }
  }

  Future<void> _deleteMapping(int id) async {
    try {
      await _mappingService.deleteMapping(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบการจับคู่เรียบร้อยแล้ว')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถลบข้อมูลได้: $e')),
        );
      }
    }
  }

  void _showCategoryPicker(String receiverName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'เลือกหมวดหมู่ให้ $receiverName',
              style: GoogleFonts.kanit(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _categories.map((cat) => _buildCategoryOption(receiverName, cat)).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryOption(String receiverName, Categories category) {
    IconData icon = Icons.category_outlined;
    Color color = const Color(0xFF2D955F);

    final name = category.categoryName.toLowerCase();
    if (name.contains('food')) { icon = Icons.restaurant; color = const Color(0xFFEB5757); }
    else if (name.contains('transport')) { icon = Icons.directions_car; color = const Color(0xFF00B0FF); }
    else if (name.contains('entertainment')) { icon = Icons.videogame_asset; color = const Color(0xFFFF9100); }
    else if (name.contains('bill')) { icon = Icons.receipt_long; color = const Color(0xFF2979FF); }
    else if (name.contains('shop')) { icon = Icons.shopping_bag; color = const Color(0xFF9C27B0); }
    else if (name.contains('health')) { icon = Icons.medical_services; color = const Color(0xFF00BFA5); }

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _saveMapping(receiverName, category.categoryId);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(category.categoryName, style: GoogleFonts.kanit(color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _filteredPending;
    final matched = _filteredMatched;
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2D955F))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          DateFormat('MMMM yyyy').format(DateTime.now()),
          style: GoogleFonts.kanit(color: Colors.black45, fontSize: 14),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFF2D955F),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'จับคู่ผู้รับ-หมวดหมู่',
                style: GoogleFonts.kanit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 20),
              _buildSummaryCard(),
              const SizedBox(height: 16),
              _buildStatsRow(),
              const SizedBox(height: 24),
              _buildSearchAndFilter(),
              const SizedBox(height: 16),
              _buildTabs(),
              const SizedBox(height: 20),
              if (_selectedTab == 'Pending') ...[
                _buildPendingNotice(pending.length),
                const SizedBox(height: 16),
                ...pending.map((r) => _buildPendingReceiverItem(r)).toList(),
              ] else ...[
                _buildMatchedHeader(matched.length),
                const SizedBox(height: 12),
                ...matched.map((r) => _buildMatchedReceiverItem(r)).toList(),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final total = _mappings.length + _pendingReceivers.length;
    final matched = _mappings.length;
    final percent = total > 0 ? matched / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ครอบคลุมแล้ว',
                  style: GoogleFonts.kanit(color: Colors.black45, fontSize: 13),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$matched',
                        style: GoogleFonts.kanit(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D955F),
                        ),
                      ),
                      TextSpan(
                        text: '/$total รายการ',
                        style: GoogleFonts.kanit(
                          fontSize: 18,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildMiniLegend(const Color(0xFF2D955F), 'จับคู่แล้ว'),
                    const SizedBox(width: 12),
                    _buildMiniLegend(Colors.orange, 'รอจับคู่'),
                  ],
                ),
              ],
            ),
          ),
          _buildProgressCircle(percent),
        ],
      ),
    );
  }

  Widget _buildProgressCircle(double percent) {
    return Container(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: percent,
              strokeWidth: 10,
              backgroundColor: const Color(0xFFF1F3F4),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2D955F)),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            '${(percent * 100).toInt()}%',
            style: GoogleFonts.kanit(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.kanit(color: Colors.black54, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatBox(const Color(0xFFFFF3E0), Colors.orange, Icons.warning_amber_rounded, '${_pendingReceivers.length}', 'รอจับคู่'),
        const SizedBox(width: 12),
        _buildStatBox(const Color(0xFFE8F5E9), const Color(0xFF2D955F), Icons.check_circle_outline, '${_mappings.length}', 'จับคู่แล้ว'),
        const SizedBox(width: 12),
        _buildStatBox(const Color(0xFFE3F2FD), const Color(0xFF1E88E5), Icons.local_offer_outlined, '${_categories.length}', 'หมวดหมู่'),
      ],
    );
  }

  Widget _buildStatBox(Color bg, Color color, IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.kanit(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: GoogleFonts.kanit(color: Colors.black45, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'ค้นหาผู้รับ...',
                hintStyle: GoogleFonts.kanit(color: Colors.grey[400], fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildTabItem('Pending', 'รอจับคู่', _pendingReceivers.length),
          _buildTabItem('Matched', 'จับคู่แล้ว', _mappings.length),
        ],
      ),
    );
  }

  Widget _buildTabItem(String code, String label, int count) {
    bool isSelected = _selectedTab == code;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = code),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected 
              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]
              : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                code == 'Pending' ? Icons.info_outline : Icons.check_circle_outline,
                size: 16,
                color: isSelected ? (code == 'Pending' ? Colors.orange : const Color(0xFF2D955F)) : Colors.black38,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.kanit(
                  color: isSelected ? Colors.black87 : Colors.black45,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? (code == 'Pending' ? Colors.orange : const Color(0xFF2D955F))
                    : Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black45,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingNotice(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'มีผู้รับที่ยังไม่ได้จับคู่ $count รายการ',
                  style: GoogleFonts.kanit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.brown[800]),
                ),
                Text(
                  'กดที่รายการเพื่อเลือกหมวดหมู่ได้เลย',
                  style: GoogleFonts.kanit(fontSize: 11, color: Colors.brown[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchedHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'รายการจับคู่ทั้งหมด',
          style: GoogleFonts.kanit(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          '$count รายการ',
          style: GoogleFonts.kanit(fontSize: 12, color: Colors.black45),
        ),
      ],
    );
  }

  Widget _buildPendingReceiverItem(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showCategoryPicker(data['name']),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.info_outline, color: Colors.orange, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name'],
                      style: GoogleFonts.kanit(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '${data['count']} รายการ | ฿${NumberFormat('#,###').format(data['amount'])}',
                      style: GoogleFonts.kanit(color: Colors.black45, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchedReceiverItem(ReceiverMapping mapping) {
    IconData icon = Icons.category_outlined;
    Color color = const Color(0xFF2D955F);

    final catName = mapping.category.categoryName.toLowerCase();
    if (catName.contains('food')) { icon = Icons.restaurant; color = const Color(0xFFEB5757); }
    else if (catName.contains('transport')) { icon = Icons.directions_car; color = const Color(0xFF00B0FF); }
    else if (catName.contains('entertainment')) { icon = Icons.videogame_asset; color = const Color(0xFFFF9100); }
    else if (catName.contains('bill')) { icon = Icons.receipt_long; color = const Color(0xFF2979FF); }
    else if (catName.contains('shop')) { icon = Icons.shopping_bag; color = const Color(0xFF9C27B0); }
    else if (catName.contains('health')) { icon = Icons.medical_services; color = const Color(0xFF00BFA5); }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(mapping.id.toString()),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (direction) => _deleteMapping(mapping.id),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mapping.receiverName,
                      style: GoogleFonts.kanit(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      mapping.category.categoryName,
                      style: GoogleFonts.kanit(color: color, fontSize: 12),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'edit') _showCategoryPicker(mapping.receiverName);
                  if (val == 'delete') _deleteMapping(mapping.id);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('แก้ไข')),
                  const PopupMenuItem(value: 'delete', child: Text('ลบ')),
                ],
                icon: const Icon(Icons.more_vert, color: Colors.black26),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
