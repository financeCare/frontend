import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:google_sign_in/google_sign_in.dart';
// 🌟 เพิ่ม Firebase Auth เพื่อใช้ในการสร้าง Session หลัง Google Sign-In สำเร็จ
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
// 🌟 Import จากที่อยู่ใหม่
import '../auth//logo_header.dart';
import '../pages/email_login_page.dart'; // 🌟 Import EmailLoginPage ที่ถูกแยกออกไป
import '../utils/config.dart' as Config;

const String _baseUrl = "${Config.baseUrl}/auth"; // สมมติว่า Config.baseUrl ถูกกำหนดไว้ใน config.dart

// =========================================================
// 1. WELCOME PAGE: หน้าจอเริ่มต้นให้เลือก LINE หรือ Email
// UI ถูกเก็บไว้ครบถ้วน
// =========================================================

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _isLoading = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);


  void _navigateToHome() {
    Navigator.of(context).pushReplacementNamed('/home');
  }


  // ------------------------------------------
  // Login with Google (แก้ไขให้เชื่อมต่อกับ Firebase Auth)
  // ------------------------------------------
  Future<void> _loginWithGoogle() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    bool success = false;

    try {
      // 1. เริ่มต้นการ Sign-In ผ่าน Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser != null) {
        try {

        print('Google Sign-In successful for user: ${googleUser.displayName}');

        // 2. รับ Auth Credentials จาก Google
        final GoogleSignInAuthentication? googleAuth = await googleUser.authentication;

        // 3. สร้าง Firebase Credential
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth?.accessToken,
          idToken: googleAuth?.idToken,
        );

        // 4. *** ขั้นตอนสำคัญ: ลงชื่อเข้าใช้ Firebase ด้วย Credential ที่ได้รับ ***
        await FirebaseAuth.instance.signInWithCredential(credential);
        final body = {
          'idToken': googleAuth?.idToken,
        };

        final res = await http.post(
          Uri.parse("$_baseUrl/login/google"),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(body),
        );
          if (res.statusCode == 200 || res.statusCode == 201) {
            print('Created: ${res.body}');
          } else {
            print('Google login error: ${res.statusCode} ${res.body}');
          }
        // ถ้าถึงบรรทัดนี้แปลว่า Sign-In สำเร็จทั้ง Google และ Firebase
        print('Firebase Sign-In Successful!');
        success = true;
        } catch (firebaseError) {
          print('Firebase Sign-In Failed: $firebaseError');
          _showErrorDialog("Firebase Sign-In Failed: $firebaseError");
          success = false;
        }
      } else {
        // ผู้ใช้ยกเลิกการ Sign-In
        success = false;
        print('Google Sign-In cancelled by user.');
      }

    } catch (error) {
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
  // Login with LINE (Logic เดิม)
  // ------------------------------------------
  Future<void> _loginWithLine() async {
    if (mounted) setState(() => _isLoading = true);
    bool success = false;

    try {
      final result = await LineSDK.instance.login(scopes: ["profile", "openid", "email"]);
      print("LINE LOGIN CALLBACK HIT!");
      print("AccessToken: ${result.accessToken.value}");
      print("id token : ${result.accessToken.idToken}");
      final jwtIdToken = result.data["id_token"];
      print("raw id token: ${result.accessToken.idTokenRaw}");
        final body = {
          'idToken': result.accessToken.idTokenRaw,
        };

        final res = await http.post(
          Uri.parse("$_baseUrl/login/line"),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(body),
        );
          if (res.statusCode == 200 || res.statusCode == 201) {
            print('Created: ${res.body}');
            success = true;
          } else {
            print('LINE login error: ${res.statusCode} ${res.body}');
            success = false;
          }
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
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildGoogleLoginButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _loginWithGoogle,
      icon: Image.asset(
        'assets/google_icon.png',
        height: 24,
        errorBuilder: (context, error, stackTrace) => Image.network(
          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/480px-Google_%22G%22_logo.svg.png',
          height: 24,
          width: 24,
        ),
      ),
      label: Text('Login with Google', style: Theme.of(context).textTheme.labelLarge),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colors.grey, width: 0.5),
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
              // LogoHeader ถูกย้ายไปที่ไฟล์ auth/logo_header.dart
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
                  // 🌟 นำทางไป EmailLoginPage ที่ถูกแยกไฟล์
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const EmailLoginPage()),
                  );
                },
                child: Text('Login / Register with Email', style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
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