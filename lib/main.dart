import 'package:flutter/material.dart';
import 'features/notification/data/services/push_service.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'features/notification/data/models/notification_api.dart';
import 'features/notification/data/services/notification_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

// 🚨 (1) เพิ่มการ Import ไฟล์ที่สร้างโดย FlutterFire CLI
import 'firebase_options.dart';

// <<<< เพิ่มการ Import AuthManager ที่นี่ >>>>
import 'features/auth/presentation/auth_manager.dart';

// Screens
import 'features/auth/presentation/welcome_page.dart';
import 'features/budget/presentation/pages/expense_entry_screen.dart';
import 'features/debt/presentation/pages/simulator/simulator_screen.dart';
import 'features/auth/presentation/pages/email_login_page.dart';
import 'features/dashboard/presentation/pages/homepage.dart';
import 'features/notification/presentation/notification_screen.dart';
import 'features/debt/presentation/pages/debt_management_page.dart';
import 'core/config/config.dart' as Config;

final storage = FlutterSecureStorage();

// 🚨 ฟังก์ชัน main() ต้องเป็น async และรวมการเริ่มต้น (Initialization) ของทั้งสองบริการ
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      await Firebase.initializeApp();
    }
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      Firebase.app();
    } else {
      rethrow;
    }
  }

  await AuthManager.init();
  await LineSDK.instance.setup('2008279064');
  await PushService().init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navKey = GlobalKey<NavigatorState>();
  late final NotificationService _notificationService;

  @override
  void initState() {
    super.initState();

    _notificationService = NotificationService(
      api: NotificationApi(baseUrl: Config.baseUrl), // ✅ ใช้ baseUrl ของคุณ
      storage: storage,
    );

    _bootNotification();
  }

  Future<void> _bootNotification() async {
    await _notificationService.init(
      onTap: ({refType, refId}) {
        // เวลา user กดแจ้งเตือน -> ไปหน้า notify
        _navKey.currentState?.pushNamed(
          '/notify',
          arguments: {'refType': refType, 'refId': refId},
        );
      },
    );

    // ถ้ามี token (login แล้ว) -> ส่ง token ขึ้น backend
    final accessToken = AuthManager.token;
    if (accessToken != null && accessToken.isNotEmpty) {
      await _notificationService.registerTokenToBackend(
        accessToken: accessToken,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialScreen = AuthManager.token != null
        ? const HomePage()
        : const WelcomePage();

    return MaterialApp(
      navigatorKey: _navKey, // ✅ สำคัญ
      debugShowCheckedModeBanner: false,
      title: 'FINANCE CARE FC App',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('th', 'TH'), Locale('en', 'US')],
      locale: const Locale('th', 'TH'),
      theme: ThemeData(
        primaryColor: const Color(0xFF00796B),
        textTheme: GoogleFonts.kanitTextTheme(ThemeData.light().textTheme),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00796B),
          primary: const Color(0xFF00796B),
        ),
        useMaterial3: true,
      ),
      home: initialScreen, // ✅ ใช้ home แทน initialRoute จะตรงกว่า
      routes: {
        '/email_login': (context) => const EmailLoginPage(),
        '/home': (context) => const HomePage(),
        '/expense_entry': (context) => const ExpenseEntryScreen(),
        '/simulator': (context) => const SimulatorScreen(),
        '/notify': (context) => const NotificationScreen(),
        '/add_debt': (context) => const AddDebtPage(),
      },
    );
  }
}
