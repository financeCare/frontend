import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/config/config.dart' as Config;
import 'package:flutter_application_1/features/auth/data/services/access_token_service.dart';
import 'package:flutter_application_1/features/notification/data/models/notification_log_item.dart';
import 'package:flutter_application_1/features/notification/data/services/notification_log_api.dart';
import 'package:flutter_application_1/features/notification/presentation/notification_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../settings/presentation/pages/user_settings_page.dart';

// Import เดิมของคุณ
import '../../../debt/presentation/pages/debt_overview_page.dart';
import '../../../budget/presentation/pages/budget_per_month_screen.dart';

// =========================================================
// 1. NOTIFICATION LIST SCREEN
// =========================================================
class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({
    super.key,
    this.refType,
    this.refId,
    required this.onConsumedOpenArgs,
    required this.unreadCount,
    required this.onRefreshCount,
  });

  final String? refType;
  final String? refId;
  final VoidCallback onConsumedOpenArgs;
  final int unreadCount;
  final VoidCallback onRefreshCount;

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

enum NotificationFilter { all, budget, debt }

class _NotificationListScreenState extends State<NotificationListScreen> {
  late final NotificationLogApi api;
  NotificationFilter _selectedFilter = NotificationFilter.all;
  List<NotificationLogItem> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    api = NotificationLogApi(baseUrl: Config.baseUrl);
    _loadLogs();
  }

  @override
  void didUpdateWidget(covariant NotificationListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refType != widget.refType ||
        oldWidget.refId != widget.refId) {
      _loadLogs();
    }
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    String? accessToken = await AccesstokenService().getAccessToken();
    if (accessToken == null || accessToken.isEmpty) return;

    String? refTypeFilter;
    if (_selectedFilter == NotificationFilter.budget) refTypeFilter = 'BUDGET';
    if (_selectedFilter == NotificationFilter.debt) refTypeFilter = 'DEBT';

    try {
      final items = await api.getLogs(
        accessToken: accessToken,
        page: 0,
        size: 50,
        refType: refTypeFilter ?? widget.refType,
      );

      // เคลียร์ args หลังใช้งาน
      if ((widget.refType?.isNotEmpty ?? false) ||
          (widget.refId?.isNotEmpty ?? false)) {
        widget.onConsumedOpenArgs();
      }

      if (mounted) {
        setState(() {
          _notifications = items;
          _isLoading = false;
        });
        widget.onRefreshCount();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
    return Column(
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
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 20, left: 24, right: 24, bottom: 30),
      decoration: const BoxDecoration(color: Color(0xFF2D955F)),
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
                '${widget.unreadCount} รายการที่ยังไม่ได้อ่าน',
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
                badgeCount: widget.unreadCount,
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
        _loadLogs();
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

// =========================================================
// 3. HOMEPAGE
// =========================================================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _notifTimer;
  bool _isFetchingNotifCount = false;
  int unreadNotificationCount = 0;

  int _selectedIndex = 0;

  final _storage = const FlutterSecureStorage();
  NotificationManager? _notificationManager;

  // ✅ เก็บตัวแปรไว้ให้หน้า Notify filter/highlight
  String? _openRefType;
  String? _openRefId;

  @override
  void initState() {
    super.initState();
    _initNotifications();

    _fetchUnreadCount(); // ยิงครั้งแรก
    _notifTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchUnreadCount();
    });
  }

  @override
  void dispose() {
    _notifTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchUnreadCount() async {
    if (!mounted) return;
    if (_isFetchingNotifCount) return; // กันยิงซ้ำซ้อน
    _isFetchingNotifCount = true;

    try {
      final token = await AccesstokenService().getAccessToken();
      if (token == null || token.isEmpty) return;

      final url = "${Config.baseUrl}/api/notifications/logs/unread-count";
      final res = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        // สมมติ backend ส่ง { "count": 5 }
        final count = int.tryParse(res.body.trim()) ?? 0;

        if (mounted) {
          setState(() => unreadNotificationCount = count);
        }
      } else if (res.statusCode == 401) {
        // token หมดอายุ -> อาจ trigger refresh token ตรงนี้
        debugPrint("Unauthorized (401) when fetching unread count");
      }
    } catch (e) {
      debugPrint("Fetch unread count failed: $e");
    } finally {
      _isFetchingNotifCount = false;
    }
  }

  Future<void> _initNotifications() async {
    try {
      _notificationManager = NotificationManager(
        storage: _storage,
        onOpenNotification: ({refType, refId}) {
          setState(() {
            _openRefType = refType;
            _openRefId = refId;
            _selectedIndex = 1; // ✅ สลับไปแท็บ Notify
          });
        },
      );

      await _notificationManager!.initialize();
    } catch (e) {
      debugPrint("Notification init failed: $e");
    }
  }

  List<Widget> _getWidgetOptions() {
    return [
      const DebtOverviewPage(),

      // ✅ ส่ง refType/refId ให้ NotificationListScreen
      NotificationListScreen(
        refType: _openRefType,
        refId: _openRefId,
        unreadCount: unreadNotificationCount,
        onRefreshCount: _fetchUnreadCount,
        onConsumedOpenArgs: () {
          setState(() {
            _openRefType = null;
            _openRefId = null;
          });
        },
      ),

      const BudgetPerMonthScreen(),
      UserSettingsPage(onBack: () => setState(() => _selectedIndex = 0)),
    ];
  }

  String? _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return null;
      case 1:
        return null; // ใช้ Header ตัวเอง
      case 2:
        return null; // hide AppBar for Budget screen
      case 3:
        return null; // หน้า Profile ใช้ AppBar ตัวเอง
      default:
        return 'Finance Care';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _getAppBarTitle(_selectedIndex);
    final widgetOptions = _getWidgetOptions();

    return Scaffold(
      appBar: title != null
          ? AppBar(
              title: Text(title),
              backgroundColor: const Color(0xFF00796B),
              foregroundColor: Colors.white,
            )
          : null,
      body: widgetOptions[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
            // Handle read-all for notifications if tab is selected
            if (index == 1) {
              _markNotificationsAsRead();
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF2D955F),
          unselectedItemColor: Colors.black45,
          selectedLabelStyle: GoogleFonts.kanit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: GoogleFonts.kanit(fontSize: 12),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'หน้าหลัก',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none_outlined),
                  if (unreadNotificationCount > 0)
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
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          unreadNotificationCount > 9
                              ? '9+'
                              : '$unreadNotificationCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              activeIcon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications),
                  if (unreadNotificationCount > 0)
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
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          unreadNotificationCount > 9
                              ? '9+'
                              : '$unreadNotificationCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              label: 'แจ้งเตือน',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'งบประมาณ',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_outlined),
              activeIcon: Icon(Icons.account_circle),
              label: 'ตั้งค่า',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markNotificationsAsRead() async {
    try {
      String url = "${Config.baseUrl}/api/notifications/logs/read-all";
      String? accessToken = await AccesstokenService().getAccessToken();
      if (accessToken == null) return;

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          unreadNotificationCount = 0;
        });
      }
    } catch (e) {
      debugPrint("Failed to mark notifications as read: $e");
    }
  }
}
