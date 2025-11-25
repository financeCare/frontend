import 'package:flutter/material.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:google_sign_in/google_sign_in.dart'; // **เพิ่ม: สำหรับ Google Login**
import 'package:flutter_application_1/main.dart'; // Import main เพื่อใช้ LogoHeader

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _isLoading = false;
  // **เพิ่ม: Google Sign In Instance**
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  void _navigateToHome() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  // **ฟังก์ชัน: ล็อกอินด้วย LINE**
  Future<void> _loginWithLine() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    bool success = false;

    try {
      await LineSDK.instance.login(scopes: ["profile", "openid", "email"]);
      success = true;
    } catch (e) {
      _showErrorDialog('LINE Login Failed: ${e.toString()}');
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

  // **ฟังก์ชัน: ล็อกอินด้วย Google**
  Future<void> _loginWithGoogle() async {
    if (mounted) setState(() => _isLoading = true);
    bool success = false;

    try {
      // Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        // ในแอปพลิเคชันจริง: ใช้ googleUser.authentication เพื่อยืนยันตัวตนกับ Backend/Firebase
        success = true;
      } else {
        // ผู้ใช้ยกเลิกการล็อกอิน
        success = false;
      }
    } catch (e) {
      _showErrorDialog('Google Login Failed: ${e.toString()}');
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
      // ใช้ Icon Placeholder (สมมติว่าเป็นไอคอนเดิม)
      icon: const Icon(Icons.person, color: Colors.white),
      label: const Text('Login with LINE'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF06C755), // สีเขียว LINE
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  // **ปุ่มล็อกอินด้วย Google**
  Widget _buildGoogleLoginButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _loginWithGoogle,
      icon: const Icon(Icons.person, color: Colors.white), // ใช้ไอคอน Placeholder
      label: const Text('Login with Google'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade700,
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
              const SizedBox(height: 40),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                // LINE Login
                _buildLineLoginButton(),
                const SizedBox(height: 15),

                // **Google Login ถูกเพิ่มกลับเข้ามา**
                _buildGoogleLoginButton(),
              ],


              const SizedBox(height: 20),
              const Divider(height: 40, thickness: 1),

              // Email Login
              ElevatedButton(
                onPressed: _isLoading ? null : () {
                  Navigator.of(context).pushNamed('/email_login');
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