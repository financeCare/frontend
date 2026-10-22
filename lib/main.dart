import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'core/network/timeout_client.dart';
import 'core/network/cold_start_notifier.dart';
import 'features/notification/data/services/push_service.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'features/notification/data/models/notification_api.dart';
import 'features/notification/data/services/notification_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/notification/data/services/slip_detection_service.dart';
import 'dart:io';
import 'core/utils/navigator_key.dart';
import 'core/utils/app_logger.dart';


import 'firebase_options.dart';


import 'features/auth/presentation/auth_manager.dart';


import 'features/auth/presentation/welcome_page.dart';
import 'features/budget/presentation/pages/expense_entry_screen.dart';
import 'features/simulator/presentation/repayment_strategy_screen.dart';
import 'features/dashboard/presentation/pages/homepage.dart';
import 'features/notification/presentation/notification_screen.dart';
import 'features/debt/presentation/pages/debt_management_page.dart';
import 'features/debt/presentation/pages/debt_payment_page.dart';
import 'features/debt/domain/models/debt_response.dart';
import 'features/job/presentation/pages/job_suggestion_page.dart';
import 'core/config/config.dart' as config;
import 'features/auth/data/services/access_token_service.dart';
import 'features/budget/presentation/pages/transaction_list_screen.dart';
import 'features/budget/presentation/pages/transaction_add_screen.dart';
import 'features/ocr/presentation/pages/ocr_screen.dart';


// final storage = FlutterSecureStorage(); // Removed in favor of AccesstokenService.sharedStorage

// 🚨 ฟังก์ชัน main() ต้องเป็น async และรวมการเริ่มต้น (Initialization) ของทั้งสองบริการ
Future<void> main() async {
  // ทุกคำขอ http.get/post/... จะผ่าน TimeoutClient (zone-scoped)
  await http.runWithClient(_bootstrap, () => TimeoutClient());
}

Future<void> _bootstrap() async {
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

  if (!kIsWeb) {
    try {
      await LineSDK.instance.setup('2008279064');
    } catch (e) {
      AppLog.e('LineSDK setup failed: $e');
    }
    await PushService().init();

    if (Platform.isAndroid) {
      await SlipDetectionService().init();
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final NotificationService _notificationService;

  @override
  void initState() {
    super.initState();

    NotificationService.initShared(
      api: NotificationApi(baseUrl: config.baseUrl),
      storage: AccesstokenService.sharedStorage,
    );
    _notificationService = NotificationService.instance;

    _bootNotification();
  }

  Future<void> _bootNotification() async {
    if (kIsWeb) return;
    try {
      await _notificationService.init(
        onTap: ({refType, refId}) {
          // เวลา user กดแจ้งเตือน -> ไปหน้า notify
          navigatorKey.currentState?.pushNamed(
            '/notify',
            arguments: {'refType': refType, 'refId': refId},
          );
        },
      );
    } catch (e) {
      AppLog.e('NotificationService init error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // !!! DEBUG: Temporarily forcing WelcomePage so you can see the redesign
    final initialScreen = AuthManager.isLoggedIn
        ? const HomePage()
        : const WelcomePage();

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'FINANCE CARE FC App',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('th', 'TH'), Locale('en', 'US')],
      locale: const Locale('th', 'TH'),
      // แอปออกแบบสำหรับมือถือ: บนจอกว้าง (เว็บ/เดสก์ท็อป) จำกัดความกว้างและจัดกึ่งกลาง
      builder: (context, child) {
        const maxAppWidth = 480.0;
        final media = MediaQuery.of(context);
        Widget app = child ?? const SizedBox();
        if (child != null && media.size.width > 600) {
          app = ColoredBox(
            color: const Color(0xFFE9EEEB),
            child: Center(
              child: ClipRect(
                child: SizedBox(
                  width: maxAppWidth,
                  child: MediaQuery(
                    data: media.copyWith(size: Size(maxAppWidth, media.size.height)),
                    child: child,
                  ),
                ),
              ),
            ),
          );
        }
        return Stack(
          children: [
            Positioned.fill(child: app),
            const ColdStartBanner(),
          ],
        );
      },
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
        '/welcome': (context) => const WelcomePage(),
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
        '/pay_debt': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, dynamic>) {
            return DebtPaymentPage(
              slipId: args['slipId'] as int?,
              initialDebt: args['initialDebt'] as DebtResponse?,
            );
          } else if (args is int) {
            return DebtPaymentPage(slipId: args);
          } else if (args is DebtResponse) {
            return DebtPaymentPage(initialDebt: args);
          }
          return const DebtPaymentPage();
        },
        '/job_suggestion': (context) => const JobSuggestionPage(),
        '/transactions': (context) => const TransactionListScreen(),
        '/add-transaction': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
          return TransactionAddScreen(ocrData: args);
        },
        '/ocr': (context) => const OCRScreen(),
      },
    );
  }
}
