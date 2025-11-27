import 'package:flutter/material.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:google_sign_in/google_sign_in.dart';
// import 'package:flutter_application_1/main.dart'; // ไม่จำเป็นต้อง import main.dart

// =========================================================
// 0. Placeholder สำหรับ AuthService
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
    // ใช้ Named Route /home ที่กำหนดใน main.dart
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
        print('${googleUser.authentication}');
        print('${googleUser.authHeaders}');
        print('${googleUser.displayName}');
        print('${googleUser.email}');
        print('${googleUser.hashCode}');
        print('${googleUser.id}');
        print('${googleUser.photoUrl}');
        print('${googleUser.serverAuthCode}');
        success = true;
      } else {
        // ผู้ใช้ยกเลิกการ Login
        success = false;
      }

    } catch (error) {
      // ❗️ สำคัญ: หากเกิด ApiException: 10 ให้ตรวจสอบ SHA-1 และ google-services.json
      print("Google Login Failed: $error");
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
    print('a1');
    if (mounted) setState(() => _isLoading = true);
    bool success = false;

    try {
      final result = await LineSDK.instance.login(scopes: ["profile", "openid", "email"]);

      print("LINE LOGIN CALLBACK HIT!");
      print("AccessToken: ${result.accessToken.value}");
      print("UserID: ${result.userProfile?.userId}");
      print("DisplayName: ${result.userProfile?.displayName}");

      success = true;
    } catch (e) {
      print("LINE login error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
      if (success && mounted) _navigateToHome();
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
    print('b1');
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
    print('c1');
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
      // ใช้ Named Route /home ที่กำหนดใน main.dart
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