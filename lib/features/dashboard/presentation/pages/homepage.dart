import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:finance_care/core/config/config.dart' as Config;
import 'package:finance_care/features/auth/data/services/access_token_service.dart';
import 'package:finance_care/features/notification/presentation/notification_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../settings/presentation/pages/user_settings_page.dart';

// Import เดิมของคุณ
import '../../../ocr/presentation/pages/ocr_screen.dart';
import '../../../debt/presentation/pages/debt_overview_page.dart';
import '../../../budget/presentation/pages/budget_per_month_screen.dart';

// =========================================================
// 3. HOMEPAGE
// =========================================================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  Timer? _notifTimer;
  bool _isFetchingNotifCount = false;
  int unreadNotificationCount = 0;

  final _storage = const FlutterSecureStorage();
  NotificationManager? _notificationManager;

  @override
  void initState() {
    print('!!! HomePage: initState');
    super.initState();
    _initNotifications();

    _fetchUnreadCount();
    print('!!! HomePage: Setting up notification timer');
    _notifTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchUnreadCount();
    });
  }

  @override
  void dispose() {
    print('!!! HomePage: dispose');
    _notifTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchUnreadCount() async {
    if (!mounted) return;
    if (_isFetchingNotifCount) return;
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
        final count = int.tryParse(res.body.trim()) ?? 0;
        if (mounted) {
          setState(() => unreadNotificationCount = count);
        }
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
          print('!!! HomePage: onOpenNotification ($refType, $refId)');
          Navigator.pushNamed(
            context,
            '/notify',
            arguments: {'refType': refType, 'refId': refId},
          );
        },
      );

      print('!!! HomePage: Initializing NotificationManager');
      await _notificationManager!.initialize();
      print('!!! HomePage: NotificationManager initialized');
    } catch (e) {
      debugPrint("Notification init failed: $e");
    }
  }

  List<Widget> _getWidgetOptions() {
    return [
      DebtOverviewPage(unreadCount: unreadNotificationCount),
      OCRScreen(),
      const BudgetPerMonthScreen(),
      UserSettingsPage(onBack: () => setState(() => _selectedIndex = 0)),
    ];
  }

  String? _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return null;
      case 1:
        return null;
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

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('ยืนยันการปิดแอป'),
            content: const Text('คุณทำงานเสร็จแล้วใช่ไหม?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('ยังก่อน'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('ใช่'),
              ),
            ],
          ),
        );
        if (shouldPop ?? false) {
           // ignore: use_build_context_synchronously
           if (context.mounted) {
             // SystemNavigator.pop() isn't working on all versions, 
             // but 'Navigator.pop' with 'canPop: true' would work if we changed state.
             // For now, let's just close it if confirmed.
             Navigator.of(context).pop(); 
           }
        }
      },
      child: Scaffold(
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
            if (index == 1) {
              // OCR selected
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
            const BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt_outlined),
              activeIcon: Icon(Icons.camera_alt),
              label: 'สแกน OCR',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'งบประมาณ',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'ตั้งค่า',
            ),

          ],
        ),
      ),
    ));
    
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
