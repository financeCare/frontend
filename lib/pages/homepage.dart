import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/accessToken_service.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

// Import เดิมของคุณ
import 'crud_page.dart';
import 'budget_per_month_screen.dart';
import '../notification/notification_manager.dart';
import '../services/notification_log_api.dart';
import '../models/notification_log_item.dart';
import '../utils/config.dart' as Config;

// =========================================================
// 1. NOTIFICATION LIST SCREEN
// =========================================================
class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({
    super.key,
    this.refType,
    this.refId,
    required this.onConsumedOpenArgs,
  });

  final String? refType;
  final String? refId;
  final VoidCallback onConsumedOpenArgs;

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  late final NotificationLogApi api;
  late Future<List<NotificationLogItem>> _future;

  @override
  void initState() {
    super.initState();
    api = NotificationLogApi(baseUrl: Config.baseUrl);
    _future = _loadLogs();
  }

  @override
  void didUpdateWidget(covariant NotificationListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ถ้ามี refType/refId ใหม่เข้ามาจากการกดแจ้งเตือน -> reload ได้
    final changed =
        oldWidget.refType != widget.refType || oldWidget.refId != widget.refId;
    if (changed) {
      setState(() => _future = _loadLogs());
    }
  }

  Future<List<NotificationLogItem>> _loadLogs() async {
    String? accessToken = await AccesstokenService().getAccessToken();
    if (accessToken == null || accessToken.isEmpty) return [];

    final items = await api.getLogs(
      accessToken: accessToken,
      page: 0,
      size: 50,
      refType: widget.refType,
      refId: widget.refId,
    );

    // เคลียร์ args หลังใช้งาน เพื่อไม่ให้กรองค้าง
    if ((widget.refType?.isNotEmpty ?? false) ||
        (widget.refId?.isNotEmpty ?? false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onConsumedOpenArgs();
      });
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NotificationLogItem>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('โหลดแจ้งเตือนไม่ได้: ${snap.error}'));
        }

        final items = snap.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('ไม่มีการแจ้งเตือน'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final n = items[index];
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.orangeAccent,
                child: Icon(Icons.notifications_active, color: Colors.white),
              ),
              title: Text(n.title),
              subtitle: Text(n.body),
              trailing: Text(
                _timeText(n.sentAt),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              onTap: () {
                // TODO: ถ้าจะไปหน้าหนี้:
                // if (n.refType == 'DEBT') Navigator.pushNamed(context, '/debt_detail', arguments: n.refId);
              },
            );
          },
        );
      },
    );
  }

  String _timeText(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

// =========================================================
// 2. PROFILE SCREEN (หน้าโปรไฟล์ที่ปรับปรุงตามบรีฟ)
// =========================================================
class ProfileScreen extends StatelessWidget {
  final VoidCallback onBack;

  const ProfileScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // แถบสีเขียวด้านบนพร้อมปุ่ม Back ตามภาพที่ต้องการ
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack, // กดแล้วกลับไปหน้า Home (index 0)
        ),
        title: const Text('โปรไฟล์ผู้ใช้งาน'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: const BoxDecoration(
                color: Color(0xFF00796B),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      const CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 56,
                          backgroundImage: NetworkImage(
                            'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
                          ), // รูปตัวอย่าง
                        ),
                      ),
                      CircleAvatar(
                        backgroundColor: Colors.orangeAccent,
                        radius: 18,
                        child: IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: Colors.white,
                          ),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'สมชาย ใจดี',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'somchai.j@example.com',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildProfileItem(
                    Icons.person_outline,
                    'ชื่อ-นามสกุล',
                    'สมชาย ใจดี',
                  ),
                  _buildProfileItem(
                    Icons.phone_android,
                    'เบอร์โทรศัพท์',
                    '081-234-5678',
                  ),
                  _buildProfileItem(
                    Icons.cake_outlined,
                    'วันเกิด',
                    '12 มกราคม 2535',
                  ),
                  const Divider(height: 40),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text(
                      'ออกจากระบบ',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                    onTap: () {
                      // Logic logout เดิมของคุณ
                      Navigator.of(context).pushReplacementNamed('/');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF00796B)),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

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

  Future<void> _onItemTapped(int index) async {
    int targetIndex;
    if (index == 0)
      targetIndex = 0;
    else if (index == 1) {
      targetIndex = 1;
      String url = "${Config.baseUrl}/api/notifications/logs/read-all";
      String? accessToken = await AccesstokenService().getAccessToken();
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
      } else if (response.statusCode == 401) {
        throw Exception('Authorization failed (401). Please log in again.');
      } else if (response.statusCode == 403) {
        throw Exception(
          'Forbidden (403). You do not have permission to access this resource.',
        );
      } else {
        String errorMessage =
            'Failed to mark notifications as read (Status ${response.statusCode})';
        try {
          final errorBody = json.decode(response.body);
          errorMessage = errorBody['message'] ?? errorMessage;
        } catch (_) {
          // Do nothing if body is not JSON
        }
        throw Exception(errorMessage);
      }
    } else if (index == 3)
      targetIndex = 2;
    else if (index == 4)
      targetIndex = 3;
    else
      return;
    setState(() {
      _selectedIndex = targetIndex;
    });
  }

  List<Widget> _getWidgetOptions() {
    return [
      const CrudPage(),

      // ✅ ส่ง refType/refId ให้ NotificationListScreen
      NotificationListScreen(
        refType: _openRefType,
        refId: _openRefId,
        onConsumedOpenArgs: () {
          // กัน filter ค้าง: เมื่อหน้าเปิดแล้ว เคลียร์ค่า
          setState(() {
            _openRefType = null;
            _openRefId = null;
          });
        },
      ),

      const BudgetPerMonthScreen(),
      ProfileScreen(onBack: () => setState(() => _selectedIndex = 0)),
    ];
  }

  String? _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'การแจ้งเตือน';
      case 2:
        return 'งบประมาณต่อเดือน';
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
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    try {
                      await LineSDK.instance.logout();
                      await _googleSignIn.signOut();
                    } catch (e) {
                      debugPrint("Logout failed: $e");
                    }
                    Navigator.of(context).pushReplacementNamed('/');
                  },
                ),
              ],
            )
          : null,
      body: widgetOptions[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed('/simulator'),
        backgroundColor: Colors.redAccent.shade700,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.calculate_outlined, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        color: const Color(0xFF00796B),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavItem(0, Icons.home, 'Home'),
            _buildNavItem(1, Icons.notifications, 'Notify'),
            const SizedBox(width: 48),
            _buildNavItem(3, Icons.account_balance_wallet, 'Budget'),
            _buildNavItem(4, Icons.person, 'Profile'),
          ],
        ),
      ),
    );
  }

Widget _buildNavItem(int index, IconData icon, String label) {
  int targetIndex;
  if (index == 0) targetIndex = 0;
  else if (index == 1) targetIndex = 1;
  else if (index == 3) targetIndex = 2;
  else targetIndex = 3;

  final isSelected = _selectedIndex == targetIndex;
  final color = isSelected ? Colors.white : Colors.white60;

  final showBadge = index == 1 && unreadNotificationCount > 0;

  return InkWell(
    onTap: () => _onItemTapped(index),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: color, size: 24),
              if (showBadge)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unreadNotificationCount > 99 ? "99+" : "$unreadNotificationCount",
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
          Text(label, style: TextStyle(color: color, fontSize: 10)),
        ],
      ),
    ),
  );
}
}