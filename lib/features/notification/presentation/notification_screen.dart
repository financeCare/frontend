import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../data/models/notification_log_item.dart';
import '../data/services/notification_log_api.dart';
import '../../auth/data/services/access_token_service.dart';
import '../../../core/config/config.dart' as Config;

class NotificationScreen extends StatefulWidget {
  final bool showBackButton;
  const NotificationScreen({super.key, this.showBackButton = true});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

enum NotificationFilter { all, budget, debt }

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationLogApi _api = NotificationLogApi(baseUrl: Config.baseUrl);
  NotificationFilter _selectedFilter = NotificationFilter.all;
  List<NotificationLogItem> _notifications = [];
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

      setState(() {
        _notifications = logs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading notifications: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final accessToken = await AccesstokenService().getAccessToken();
      if (accessToken != null) {
        // เรียกใช้ API เพื่อ mark เป็นอ่านทั้งหมด
        final success = await _api.markAllAsRead(accessToken: accessToken);
        if (success) {
          debugPrint("NotificationScreen: Marked all as read successfully");
        }
      }
    } catch (e) {
      debugPrint("Error marking all as read: $e");
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
    return PopScope(
      onPopInvoked: (didPop) {
        if (didPop) {
          _markAllAsRead();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildFilters(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF2D955F),
                        ),
                      )
                    : _notifications.isEmpty
                        ? _buildEmptyState()
                        : _buildNotificationList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'การแจ้งเตือน',
                style: GoogleFonts.kanit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              if (widget.showBackButton)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
            ],
          ),
        ],
      ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2D955F) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2D955F).withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
          border: isSelected
              ? null
              : Border.all(color: Colors.grey.withOpacity(0.15)),
        ),
        child: Text(
          label,
          style: GoogleFonts.kanit(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
            fontSize: 14,
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
                  const SizedBox(width: 8),
                  const Expanded(child: SizedBox.shrink()),
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
    bool isUnread = item.status == 'SENT';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          final accessToken = await AccesstokenService().getAccessToken();
          if (accessToken != null) {
            await _api.markAsClicked(
              accessToken: accessToken,
              logId: item.logId,
            );
            _loadData(); // Refresh list to update UI
          }
          // Navigate if needed
          if (item.refType == 'BUDGET') {
            // Navigator.push...
          }
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isUnread
                  ? (isBudget
                            ? const Color(0xFF2D955F)
                            : const Color(0xFFEB5757))
                        .withOpacity(0.08)
                  : Colors.grey.withOpacity(0.05),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:
                        (isBudget
                                ? const Color(0xFF2D955F)
                                : const Color(0xFFEB5757))
                            .withOpacity(0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    isBudget
                        ? Icons.account_balance_wallet_outlined
                        : Icons.shield_moon_outlined,
                    color: isBudget
                        ? const Color(0xFF2D955F)
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: GoogleFonts.kanit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: const Color(0xFF1A1A1A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (isBudget
                                                ? const Color(0xFF2D955F)
                                                : const Color(0xFFEB5757))
                                            .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isBudget
                                            ? Icons.info_outline_rounded
                                            : Icons.credit_card_rounded,
                                        size: 10,
                                        color: isBudget
                                            ? const Color(0xFF2D955F)
                                            : const Color(0xFFEB5757),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isBudget ? 'งบประมาณ' : 'หนี้สิน',
                                        style: GoogleFonts.kanit(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: isBudget
                                              ? const Color(0xFF2D955F)
                                              : const Color(0xFFEB5757),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D955F),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF2D955F,
                                    ).withOpacity(0.4),
                                    blurRadius: 6,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.body,
                        style: GoogleFonts.kanit(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            DateFormat('d MMM yyyy').format(item.sentAt),
                            style: GoogleFonts.kanit(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: TextStyle(color: Colors.grey.shade300),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isUnread ? 'ยังไม่ได้อ่าน' : 'อ่านแล้ว',
                            style: GoogleFonts.kanit(
                              color: isUnread
                                  ? const Color(0xFF2D955F)
                                  : Colors.grey.shade400,
                              fontSize: 12,
                              fontWeight: isUnread
                                  ? FontWeight.bold
                                  : FontWeight.normal,
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
