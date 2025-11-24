import 'package:flutter/material.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
// NOTE: ในการใช้งานจริงต้องเพิ่ม dependency 'google_sign_in' ใน pubspec.yaml
import 'package:google_sign_in/google_sign_in.dart';

import 'api_service.dart'; // ยังคง import ไว้
import 'homepage.dart'; // Import HomePage
import 'expense_entry_screen.dart'; // Import หน้า ExpenseEntryScreen
import 'budget_per_month_screen.dart';
import './pages/crud_page.dart'; // CrudPage (ใช้เป็น Dashboard)

// เปลี่ยน Channel ID ของคุณให้ถูกต้อง
const String lineChannelId = "2008279064";

// =========================================================
// 0. Placeholder สำหรับ AuthService (เพื่อให้โค้ด Login ทำงานได้)
// =========================================================
class AuthService {
  // จำลองการ Login
  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    // ในการใช้งานจริง ควรมีการตรวจสอบ email/password กับ API/Backend
    return true; // จำลองว่า Login สำเร็จเสมอ
  }
}
// =========================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ตรวจสอบและ setup LINE SDK เฉพาะเมื่อ Channel ID ถูกตั้งค่า
  if (lineChannelId.isNotEmpty) {
    await LineSDK.instance.setup(lineChannelId);
  }
  runApp(const FinanceCareApp());
}

class FinanceCareApp extends StatelessWidget {
  const FinanceCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance Care PoC',
      theme: ThemeData(
        primaryColor: const Color(0xFF06C755), // LINE Green
        useMaterial3: true,
        textTheme: const TextTheme(
          // กำหนดขนาด Font เริ่มต้นให้ใหญ่ขึ้นทั่วทั้งแอป
          headlineLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 16.0), // Main body text
          bodyMedium: TextStyle(fontSize: 14.0),
          labelLarge: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
        ),
      ),
      // กำหนด Named Routes
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomePage(),
        '/home': (context) => const HomePage(),
        '/expense_entry': (context) => const ExpenseEntryScreen(),
        '/budget_per_month': (context) => const BudgetPerMonthScreen(),
      },
    );
  }
}

// =========================================================
// Logo Header Widget (วิดเจ็ตสำหรับแสดงโลโก้)
// =========================================================
class LogoHeader extends StatelessWidget {
  const LogoHeader({super.key});

  @override
  Widget build(BuildContext context) {
    // โค้ดที่นี่สมมติว่าไฟล์ logo_finance_care.png มีอยู่จริง
    return Column(
      children: [
        Image.asset(
          'assets/logo_finance_care.png',
          height: 300,
          width: 300,
          errorBuilder: (context, error, stackTrace) {
            // แสดงข้อความแทนถ้าหาไฟล์รูปภาพไม่เจอ
            return const SizedBox(
              height: 300,
              child: Center(child: Text('Logo Placeholder', style: TextStyle(fontSize: 24, color: Colors.grey))),
            );
          },
        ),
      ],
    );
  }
}

// =========================================================
// 1. WELCOME PAGE: หน้าจอเริ่มต้นให้เลือก LINE หรือ Email
// =========================================================

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _isLoading = false;
  // 🟢 ประกาศตัวแปร _googleSignIn ไว้ใน WelcomePage
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);


  void _navigateToHome() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  // ------------------------------------------
  // Login with Google
  // ------------------------------------------
  Future<void> _loginWithGoogle() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    bool success = false;

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser != null) {
        // ในการใช้งานจริง: ควรนำ idToken หรือ accessToken ไปยืนยันกับ Backend/Firebase
        print('Google Sign-In successful for user: ${googleUser.displayName}');
        success = true;
      } else {
        // ผู้ใช้ยกเลิกการ Login
        success = false;
      }

    } catch (error) {
      _showErrorDialog("Google Login Failed: $error");
      success = false;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      await Future.delayed(const Duration(milliseconds: 500));

      if (success && mounted) {
        _navigateToHome();
      }
    }
  }

  // ------------------------------------------
  // Login with LINE
  // ------------------------------------------
  Future<void> _loginWithLine() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    bool success = false;

    try {
      await LineSDK.instance.login(scopes: ["profile", "openid", "email"]);
      final accessToken = await LineSDK.instance.currentAccessToken;
      success = accessToken != null && accessToken.value.isNotEmpty;

    } catch (e) {
      _showErrorDialog("LINE Login Failed: $e");
      success = false;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      await Future.delayed(const Duration(milliseconds: 500));

      if (success && mounted) {
        _navigateToHome();
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildLineLoginButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _loginWithLine,
      icon: Image.asset(
        'assets/line_icon.png',
        height: 24,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.forum, color: Colors.white),
      ),
      label: Text('Login with LINE', style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF06C755),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 55), // เพิ่มขนาดปุ่ม
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Build Google Login Button
  Widget _buildGoogleLoginButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _loginWithGoogle,
      icon: Image.asset(
        'assets/google_icon.png', // สมมติว่ามีไฟล์ google_icon.png
        height: 24,
        errorBuilder: (context, error, stackTrace) => Image.network( // Fallback เป็นรูปจาก URL
          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/480px-Google_%22G%22_logo.svg.png',
          height: 24,
          width: 24,
        ),
      ),
      label: Text('Login with Google', style: Theme.of(context).textTheme.labelLarge),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white, // สีพื้นหลังเป็นสีขาว
        foregroundColor: Colors.black, // สีตัวอักษรเป็นสีดำ
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colors.grey, width: 0.5), // ขอบสีเทา
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LogoHeader(),
              const SizedBox(height: 30),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                // ปุ่ม Google
                _buildGoogleLoginButton(),
                const SizedBox(height: 15),
                // ปุ่ม LINE
                _buildLineLoginButton(),
              ],

              const SizedBox(height: 25),
              const Divider(height: 40, thickness: 1),

              // ปุ่ม Login / Register with Email
              ElevatedButton(
                onPressed: _isLoading ? null : () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const EmailLoginPage()),
                  );
                },
                child: Text('Login / Register with Email', style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55), // เพิ่มขนาดปุ่ม
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================
// 2. EMAIL LOGIN PAGE: หน้าจอ Login ด้วย Email/Password
// =========================================================

class EmailLoginPage extends StatefulWidget {
  const EmailLoginPage({super.key});

  @override
  State<EmailLoginPage> createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends State<EmailLoginPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isRegisterMode = false;
  bool _isLoading = false;

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _processAuth() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    if (_isRegisterMode &&
        _passwordController.text != _confirmPasswordController.text) {
      _showErrorDialog('Passwords do not match.');
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    final authService = AuthService(); // ใช้ AuthService ที่เราสร้าง Placeholder ไว้

    bool success = false;

    if (_isRegisterMode) {
      _showErrorDialog("Register API is not implemented yet.");
    } else {
      // 🟢 Login Mode
      success = await authService.login(
        _emailController.text,
        _passwordController.text,
      );
    }

    if (mounted) setState(() => _isLoading = false);
    // 3. ถ้า login สำเร็จ → ไปหน้า Home (มี Navbar)
    if (success && mounted) {
      print('Login success. Navigating to /home.');
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (mounted && !_isRegisterMode) {
      _showErrorDialog("Email or password is incorrect (Simulated).");
    }
  }


  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isRegisterMode ? 'Register' : 'Email Login', style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const LogoHeader(),
                const SizedBox(height: 30),

                TextFormField(
                  controller: _emailController,
                  enabled: !_isLoading,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    labelStyle: Theme.of(context).textTheme.bodyLarge,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email address.';
                    }
                    if (!_isValidEmail(value)) {
                      return 'Please enter a valid email address.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _passwordController,
                  enabled: !_isLoading,
                  obscureText: true,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: Theme.of(context).textTheme.bodyLarge,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password.';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                if (_isRegisterMode) ...[
                  TextFormField(
                    controller: _confirmPasswordController,
                    enabled: !_isLoading,
                    obscureText: true,
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      labelStyle: Theme.of(context).textTheme.bodyLarge,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.lock),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password.';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                ],

                const SizedBox(height: 30),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _processAuth,
                    child: Text(_isRegisterMode ? 'CREATE ACCOUNT' : 'LOGIN', style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55), // เพิ่มขนาดปุ่ม
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                const SizedBox(height: 20),

                TextButton(
                  onPressed: _isLoading ? null : () {
                    setState(() {
                      _isRegisterMode = !_isRegisterMode;
                      _formKey.currentState?.reset();
                      _emailController.clear();
                      _passwordController.clear();
                      _confirmPasswordController.clear();
                    });
                  },
                  child: Text(
                    _isRegisterMode ? 'Already have an account? Login' : 'Don\'t have an account? Register',
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Theme.of(context).primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================
// 3. WIDGETS สำหรับหน้าจอ Placeholder (Notification/Setting)
// =========================================================

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(title, style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: Colors.grey)),
    );
  }
}

// =========================================================
// 4. HOMEPAGE: หน้าจอหลักพร้อม Bottom Navigation Bar
// =========================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // Index ที่เลือกปัจจุบัน (เริ่มต้นที่ Home/Dashboard)
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);


  // รายชื่อหน้าจอทั้งหมดใน Navbar (ยกเว้น Calculate ที่เป็น FAB)
  late final List<Widget> _widgetOptions;

  // ตั้งค่า List of Widgets ใน initState
  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      const CrudPage(), // Index 0: Home (Dashboard)
      const PlaceholderScreen(title: 'Notifications (แจ้งเตือน)'), // Index 1: Notification
      const PlaceholderScreen(title: 'Calculate (Placeholder)'), // Index 2: Calculate (ไม่ควรถูกเลือก แต่ต้องมีใน List เพื่อความปลอดภัย)
      const BudgetPerMonthScreen(), // Index 3: Budget
      const PlaceholderScreen(title: 'Settings (ตั้งค่า)'), // Index 4: Setting
    ];
  }

  void _onItemTapped(int index) {
    // Index 2 ถูกสงวนไว้สำหรับปุ่มกลาง (Calculate)
    if (index != 2) {
      setState(() {
        _selectedIndex = index;
      });
    }
    // หากแตะปุ่มกลาง (Calculate) จะไปเรียก Modal แทนการเปลี่ยนหน้าจอหลัก
    if (index == 2) {
      _showCalculateModal(context);
    }
  }

  // Modal สำหรับปุ่ม Calculate/บันทึกค่าใช้จ่าย
  void _showCalculateModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          // ปรับความสูงให้เหมาะสม
          height: MediaQuery.of(context).size.height * 0.45,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'บันทึกและคำนวณ',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const Divider(height: 20),
              // ปุ่มที่จะนำทางไปยังหน้า ExpenseEntryScreen
              ElevatedButton.icon(
                icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                label: Text('บันทึกรายรับ/รายจ่าย', style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Colors.white)),
                onPressed: () {
                  Navigator.pop(context); // ปิด Modal
                  // นำทางไปยังหน้าบันทึกค่าใช้จ่าย
                  Navigator.of(context).pushNamed('/expense_entry');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600, // สีแดงให้เด่น
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 15),
              // ปุ่มสำหรับ Budget (เผื่ออยากให้เข้าถึงจาก FAB ได้ง่าย)
              ElevatedButton.icon(
                icon: const Icon(Icons.show_chart, color: Colors.white),
                label: Text('จัดการงบประมาณต่อเดือน', style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Colors.white)),
                onPressed: () {
                  Navigator.pop(context); // ปิด Modal
                  // นำทางไปยังหน้า Budget
                  Navigator.of(context).pushNamed('/budget_per_month');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('ปิด', style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Theme.of(context).primaryColor)),
              )
            ],
          ),
        );
      },
    );
  }

  // 🟢 การแก้ไข: เปลี่ยนจาก _buildNavItem ที่ใช้ Material/InkWell ไปใช้ TextButton
  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? Colors.white : Colors.white70;

    return Expanded(
      child: TextButton(
        onPressed: () => _onItemTapped(index),
        style: TextButton.styleFrom(
          foregroundColor: color, // ใช้สีตามสถานะที่เลือก
          minimumSize: const Size(48, 48), // กำหนดขนาดขั้นต่ำ
          padding: const EdgeInsets.symmetric(vertical: 7.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24),
            Text(label, style: TextStyle(fontSize: 12.0)),
          ],
        ),
      ),
    );
  }

  // ฟังก์ชันหาชื่อ Title ที่เหมาะสมสำหรับ AppBar
  String _getAppBarTitle(int index) {
    switch(index) {
      case 0:
        return 'Dashboard (หน้าหลัก)';
      case 1:
        return 'แจ้งเตือน';
      case 3:
        return 'งบประมาณต่อเดือน';
      case 4:
        return 'ตั้งค่า';
      default:
        return 'Finance Care';
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle(_selectedIndex), style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // ออกจากระบบ LINE SDK ด้วย
              try {
                await LineSDK.instance.logout();
                // ออกจากระบบ Google ด้วย
                await _googleSignIn.signOut();
              } catch (e) {
                print("Logout failed: $e");
              }
              Navigator.of(context).pushReplacementNamed('/'); // กลับไปหน้า Welcome
            },
          ),
        ],
      ),

      // เนื้อหาของหน้าจอปัจจุบัน
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),

      // ----------------------------------------------------
      // Floating Action Button (ปุ่ม Calculate ที่โดดเด่น)
      // ----------------------------------------------------
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCalculateModal(context),
        // ทำให้ปุ่มเด่นด้วยสีที่แตกต่าง
        backgroundColor: Colors.redAccent.shade700,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 4.0,
        child: const Icon(Icons.calculate_outlined, size: 30), // เปลี่ยน icon ให้ดูเกี่ยวกับการเพิ่มรายการ
      ),
      // กำหนดตำแหน่งปุ่มให้อยู่ตรงกลางของ Bottom Navigation Bar
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ----------------------------------------------------
      // Bottom Navigation Bar
      // ----------------------------------------------------
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(), // ทำให้มีรอยเว้าสำหรับปุ่มกลาง
        notchMargin: 6.0,
        color: Theme.of(context).primaryColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            // 1. Home
            _buildNavItem(0, Icons.home, 'Home'),
            // 2. Notification
            _buildNavItem(1, Icons.notifications, 'Notify'),
            // ช่องว่างสำหรับปุ่มกลาง (Calculate) - ต้องมี 2 Expanded เพื่อจัดให้ช่องไฟเท่ากัน
            const Expanded(child: SizedBox(height: 1)),
            // 4. Budget
            _buildNavItem(3, Icons.account_balance_wallet, 'Budget'),
            // 5. Setting
            _buildNavItem(4, Icons.settings, 'Setting'),
          ],
        ),
      ),
    );
  }
}