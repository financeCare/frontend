import 'package:flutter/material.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'homepage.dart'; // Import HomePage
import 'expense_entry_screen.dart'; // NEW: Import หน้า ExpenseEntryScreen
import 'budget_per_month_screen.dart';

// เปลี่ยน Channel ID ของคุณให้ถูกต้อง
const String lineChannelId = "2008279064";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LineSDK.instance.setup(lineChannelId);
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
      ),
      // กำหนด Named Routes
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomePage(),
        '/home': (context) => const HomePage(),
        // NEW: เพิ่มเส้นทางสำหรับหน้าบันทึกค่าใช้จ่าย
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
    return Column(
      children: [
        Image.asset(
          'assets/logo_finance_care.png',
          height: 300,
          width: 300,
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

  void _navigateToHome() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  Future<void> _loginWithLine() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    bool success = false;

    try {
      await LineSDK.instance.login(scopes: ["profile", "openid", "email"]);
      success = true;
    } catch (e) {
      _showErrorDialog(e.toString());
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
      ),
      label: const Text('Login with LINE'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF06C755),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              const SizedBox(height: 20),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                _buildLineLoginButton(),

              const SizedBox(height: 20),
              const Divider(height: 40, thickness: 1),

              ElevatedButton(
                onPressed: _isLoading ? null : () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const EmailLoginPage()),
                  );
                },
                child: const Text('Login / Register with Email'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isRegisterMode = false;
  bool _isLoading = false;

  Future<void> _processAuth() async {
    if (_isRegisterMode && _passwordController.text != _confirmPasswordController.text) {
      _showErrorDialog('Passwords do not match.');
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).pushReplacementNamed('/home');
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LogoHeader(),
              const SizedBox(height: 30),

              TextField(
                controller: _emailController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _passwordController,
                enabled: !_isLoading,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 15),

              if (_isRegisterMode) ...[
                TextField(
                  controller: _confirmPasswordController,
                  enabled: !_isLoading,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 15),
              ],

              const SizedBox(height: 30),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _processAuth,
                  child: Text(_isRegisterMode ? 'CREATE ACCOUNT' : 'LOGIN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: _isLoading ? null : () {
                  setState(() {
                    _isRegisterMode = !_isRegisterMode;
                    _emailController.clear();
                    _passwordController.clear();
                    _confirmPasswordController.clear();
                  });
                },
                child: Text(
                  _isRegisterMode ? 'Already have an account? Login' : 'Don\'t have an account? Register',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}