import 'package:flutter/material.dart';
import 'features/notification/data/services/push_service.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'features/notification/data/models/notification_api.dart';
import 'features/notification/data/services/notification_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/notification/data/services/slip_detection_service.dart';
import 'dart:io';

// 🚨 (1) เพิ่มการ Import ไฟล์ที่สร้างโดย FlutterFire CLI
import 'firebase_options.dart';

// <<<< เพิ่มการ Import AuthManager ที่นี่ >>>>
import 'features/auth/presentation/auth_manager.dart';

// Screens
import 'features/auth/presentation/welcome_page.dart';
import 'features/budget/presentation/pages/expense_entry_screen.dart';
import 'features/simulator/presentation/RepaymentStrategyScreen.dart';
import 'features/dashboard/presentation/pages/homepage.dart';
import 'features/notification/presentation/notification_screen.dart';
import 'features/debt/presentation/pages/debt_management_page.dart';
import 'features/debt/presentation/pages/debt_payment_page.dart';
import 'features/debt/domain/models/debt_response.dart';
import 'features/job/presentation/pages/job_suggestion_page.dart';
import 'core/config/config.dart' as Config;
import 'features/auth/data/services/access_token_service.dart';
import 'features/budget/presentation/pages/transaction_list_screen.dart';
import 'features/budget/presentation/pages/transaction_add_screen.dart';

// final storage = FlutterSecureStorage(); // Removed in favor of AccesstokenService.sharedStorage

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

  if (!kIsWeb && Platform.isAndroid) {
    SlipDetectionService().init();
  }

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

    NotificationService.initShared(
      api: NotificationApi(baseUrl: Config.baseUrl),
      storage: AccesstokenService.sharedStorage,
    );
    _notificationService = NotificationService.instance;

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
      try {
        print('!!! Booting notification registration...');
        await _notificationService.registerTokenToBackend(
          accessToken: accessToken,
        );
      } catch (e) {
        print('!!! Notification boot failed (Silent): $e');
        // ไม่ต้อง throw ต่อเพื่อให้แอปเปิดหน้าหลักได้ปกติแม้ระบบแจ้งเตือนจะขัดข้อง
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // !!! DEBUG: Temporarily forcing WelcomePage so you can see the redesign
    // final initialScreen = AuthManager.token != null
    //    ? const HomePage()
    //    : const WelcomePage();
    const initialScreen = WelcomePage();

    return MaterialApp(
      navigatorKey: _navKey,
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
        primaryColor: const Color(0xFF2D955F),
        textTheme: GoogleFonts.kanitTextTheme(ThemeData.light().textTheme),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D955F),
          primary: const Color(0xFF2D955F),
        ),
        useMaterial3: true,
      ),
      home: initialScreen, 
      routes: {
        '/home': (context) => const HomePage(),
        '/expense_entry': (context) => const ExpenseEntryScreen(),
        '/simulator': (context) => const RepaymentStrategyScreen(),
        '/notify': (context) => const NotificationScreen(),
        '/add_debt': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, dynamic>) {
            return AddDebtPage(
              debtToEdit: args['debt'] as DebtResponse?,
              isViewOnly: args['isViewOnly'] as bool? ?? false,
            );
          } else {
            return AddDebtPage(debtToEdit: args as DebtResponse?);
          }
        },
        '/pay_debt': (context) => const DebtPaymentPage(),
        '/job_suggestion': (context) => const JobSuggestionPage(),
        '/transactions': (context) => const TransactionListScreen(),
        '/add-transaction': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
          return TransactionAddScreen(ocrData: args);
        },
      },
    );
  }
}
