import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../data/models/notification_log_item.dart';
import '../data/services/notification_log_api.dart';
import '../../auth/data/services/access_token_service.dart';
import '../../../core/config/config.dart' as Config;

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

enum NotificationFilter { all, budget, debt }

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationLogApi _api = NotificationLogApi(baseUrl: Config.baseUrl);
  NotificationFilter _selectedFilter = NotificationFilter.all;
  List<NotificationLogItem> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      if (args != null && args['refType'] != null) {
        final refType = args['refType'].toString();
        if (refType == 'BUDGET') {
          setState(() => _selectedFilter = NotificationFilter.budget);
        } else if (refType == 'DEBT') {
          setState(() => _selectedFilter = NotificationFilter.debt);
        }
      }
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final accessToken = await AccesstokenService().getAccessToken();
      if (accessToken == null) return;

      // Fetch notifications based on filter
      String? refTypeFilter;
      if (_selectedFilter == NotificationFilter.budget)
        refTypeFilter = 'BUDGET';
      if (_selectedFilter == NotificationFilter.debt) refTypeFilter = 'DEBT';

      final logs = await _api.getLogs(
        accessToken: accessToken,
        refType: refTypeFilter,
      );

      // Fetch unread count
      final countUrl = "${Config.baseUrl}/api/notifications/logs/unread-count";
      final countRes = await http.get(
        Uri.parse(countUrl),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      int unread = 0;
      if (countRes.statusCode == 200) {
        unread = int.tryParse(countRes.body.trim()) ?? 0;
      }

      setState(() {
        _notifications = logs;
        _unreadCount = unread;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading notifications: $e");
      setState(() => _isLoading = false);
    }
  }

  Map<String, List<NotificationLogItem>> _groupNotifications() {
    final Map<String, List<NotificationLogItem>> groups = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var item in _notifications) {
      final date = DateTime(
        item.sentAt.year,
        item.sentAt.month,
        item.sentAt.day,
      );
      String key;
      if (date == today) {
        key = "วันนี้";
      } else if (date == yesterday) {
        key = "เมื่อวาน";
      } else {
        key = DateFormat('d MMM yyyy', 'th').format(date);
      }

      if (!groups.containsKey(key)) {
        groups[key] = [];
      }
      groups[key]!.add(item);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2D955F)),
                  )
                : _notifications.isEmpty
                ? _buildEmptyState()
                : _buildNotificationList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(
        top: statusBarHeight + 70,
        left: 24,
        right: 24,
        bottom: 30,
      ),
      decoration: const BoxDecoration(color: Color.fromARGB(255, 45, 149, 95)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'การแจ้งเตือน',
                style: GoogleFonts.kanit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '$_unreadCount รายการที่ยังไม่ได้อ่าน',
                style: GoogleFonts.kanit(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildHeaderIcon(
                icon: Icons.notifications_none_outlined,
                badgeCount: _unreadCount,
              ),
              const SizedBox(width: 12),
              _buildHeaderIcon(icon: Icons.settings_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon({required IconData icon, int badgeCount = 0}) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        if (badgeCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFFEB5757),
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                badgeCount > 9 ? '9+' : '$badgeCount',
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
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Row(
        children: [
          _buildFilterChip('ทั้งหมด', NotificationFilter.all),
          const SizedBox(width: 12),
          _buildFilterChip('งบประมาณ', NotificationFilter.budget),
          const SizedBox(width: 12),
          _buildFilterChip('หนี้สิน', NotificationFilter.debt),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, NotificationFilter filter) {
    bool isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
        _loadData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2D955F) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.kanit(
            color: isSelected ? Colors.white : Colors.black54,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationList() {
    final grouped = _groupNotifications();
    final keys = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final dateKey = keys[index];
        final items = grouped[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 15),
              child: Row(
                children: [
                  Text(
                    dateKey,
                    style: GoogleFonts.kanit(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${items.length} รายการ',
                    style: GoogleFonts.kanit(
                      color: Colors.black38,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(child: Divider(indent: 8)),
                ],
              ),
            ),
            ...items.map((item) => _buildNotificationCard(item, dateKey)),
          ],
        );
      },
    );
  }

  Widget _buildNotificationCard(NotificationLogItem item, String dateKey) {
    bool isBudget = item.refType == 'BUDGET';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(
          left: BorderSide(
            color: isBudget ? const Color(0xFFF2994A) : const Color(0xFFEB5757),
            width: 8,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    (isBudget
                            ? const Color(0xFFF2994A)
                            : const Color(0xFFEB5757))
                        .withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isBudget
                    ? Icons.warning_amber_rounded
                    : Icons.calendar_today_rounded,
                color: isBudget
                    ? const Color(0xFFF2994A)
                    : const Color(0xFFEB5757),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          item.title,
                          style: GoogleFonts.kanit(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        DateFormat('HH:mm').format(item.sentAt.toLocal()),
                        style: GoogleFonts.kanit(
                          color: Colors.black38,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    style: GoogleFonts.kanit(
                      color: Colors.black54,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E0).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          dateKey,
                          style: GoogleFonts.kanit(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right, color: Colors.black26),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'ไม่มีการแจ้งเตือน',
            style: GoogleFonts.kanit(fontSize: 18, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
