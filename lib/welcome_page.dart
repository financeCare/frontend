import 'package:flutter/material.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'main.dart'; // Import main เพื่อใช้ LogoHeader และ Routing

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
    // ไปหน้า Home และล้าง Navigation Stack (ใช้ named route)
    Navigator.of(context).pushReplacementNamed('/home');
  }

  Future<void> _loginWithLine() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    bool success = false;

    try {
      // เรียกใช้ LINE SDK สำหรับ Login
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
      icon: const Icon(
        Icons.comment, // ใช้ไอคอนพื้นฐานแทน Image.asset เพื่อให้โค้ดรันได้ง่าย
        color: Colors.white,
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
              const SizedBox(height: 40),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                _buildLineLoginButton(),

              const SizedBox(height: 20),
              const Divider(height: 40, thickness: 1),

              ElevatedButton(
                onPressed: _isLoading ? null : () {
                  // ใช้ named route ไปหน้า Email Login
                  Navigator.of(context).pushNamed('/login_email');
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