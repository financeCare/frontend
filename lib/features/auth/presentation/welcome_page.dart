import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'pages/otp_page.dart';
import 'auth_widget.dart';
import '../../../core/config/config.dart' as Config;
import '../data/services/access_token_service.dart';
import '../data/services/device_service.dart';

final storage = AccesstokenService.sharedStorage;

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _isLoading = false;
  bool _isLoginMode = true;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final AuthService _authService = AuthService();
  final String _baseUrl = "${Config.baseUrl}/api/auth";

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    bool success = false;
    try {
      GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId:
            "756271821434-vpmof8n9b53p89osfrfeibtk83tvqo1h.apps.googleusercontent.com",
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication auth = await googleUser.authentication;
        final response = await http.post(
          Uri.parse('$_baseUrl/login/google'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"idToken": auth.idToken}),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          await storage.write(key: "accessToken", value: data['accessToken']);
          await storage.write(key: "refreshToken", value: data['refreshToken']);
          success = true;
        }
      }
    } catch (error) {
      debugPrint("Google Login Failed: $error");
      // _showErrorDialog("Google Login Failed: $error");
    } finally {
      setState(() => _isLoading = false);
      if (success) _navigateToHome();
    }
  }

  Future<void> _loginWithLine() async {
    setState(() => _isLoading = true);
    bool success = false;
    try {
      final result = await LineSDK.instance.login(
        scopes: ["profile", "openid", "email"],
      );
      final res = await http.post(
        Uri.parse("$_baseUrl/login/line"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': result.accessToken.idTokenRaw}),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        await storage.write(key: "accessToken", value: data['accessToken']);
        await storage.write(key: "refreshToken", value: data['refreshToken']);
        success = true;
      }
    } catch (e) {
      debugPrint("LINE Login Failed: $e");
      // _showErrorDialog("LINE Login Failed: $e");
    } finally {
      setState(() => _isLoading = false);
      if (success) _navigateToHome();
    }
  }

  Future<void> _processAuth() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isLoginMode &&
        _passwordController.text != _confirmPasswordController.text) {
      _showErrorDialog('รหัสผ่านไม่ตรงกัน');
      return;
    }

    setState(() => _isLoading = true);
    bool success = false;
    try {
      if (_isLoginMode) {
        success = await _authService.login(
          _emailController.text,
          _passwordController.text,
        );
      } else {
        success = await _authService.register(
          _emailController.text,
          _passwordController.text,
        );
        if (success && mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OtpPage(
                email: _emailController.text,
                password: _passwordController.text,
              ),
            ),
          );
          setState(() => _isLoading = false);
          return;
        }
      }
    } catch (e) {
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      if (errorMessage.contains('Email already exists')) {
        errorMessage = 'อีเมลนี้ถูกใช้งานไปแล้ว กรุณาใช้อีเมลอื่น';
      }
      _showErrorDialog(errorMessage);
    } finally {
      setState(() => _isLoading = false);
      if (success && _isLoginMode)
        _navigateToHome();
      else if (!success && _isLoginMode)
        _showErrorDialog("อีเมลหรือรหัสผ่านไม่ถูกต้อง");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ข้อผิดพลาด', style: GoogleFonts.kanit()),
        content: Text(message, style: GoogleFonts.kanit()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ตกลง', style: GoogleFonts.kanit()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 60),
                Text(
                  'ยินดีต้อนรับ',
                  style: GoogleFonts.kanit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLoginMode
                      ? 'เข้าสู่ระบบเพื่อใช้งานต่อ'
                      : 'สร้างบัญชีใหม่เพื่อเริ่มต้นใช้งาน',
                  style: GoogleFonts.kanit(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 32),
                _buildAuthCard(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildTabToggle(),
            const SizedBox(height: 24),
            _buildSocialButtons(),
            const SizedBox(height: 24),
            _buildSeparator(),
            const SizedBox(height: 24),
            _buildTextField(
              label: 'อีเมล',
              controller: _emailController,
              icon: Icons.email_outlined,
              hint: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'รหัสผ่าน',
              controller: _passwordController,
              icon: Icons.lock_outline,
              hint: _isLoginMode ? 'กรอกรหัสผ่านของคุณ' : 'สร้างรหัสผ่าน',
              isPassword: true,
              showPassword: _isPasswordVisible,
              onTogglePassword: () =>
                  setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
            if (!_isLoginMode) ...[
              const SizedBox(height: 16),
              _buildTextField(
                label: 'ยืนยันรหัสผ่าน',
                controller: _confirmPasswordController,
                icon: Icons.lock_outline,
                hint: 'ยืนยันรหัสผ่านของคุณ',
                isPassword: true,
                showPassword: _isConfirmPasswordVisible,
                onTogglePassword: () => setState(
                  () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
                ),
              ),
            ],
            const SizedBox(height: 32),
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              'เข้าสู่ระบบ',
              _isLoginMode,
              () => setState(() => _isLoginMode = true),
            ),
          ),
          Expanded(
            child: _buildTabButton(
              'สมัครสมาชิก',
              !_isLoginMode,
              () => setState(() => _isLoginMode = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.kanit(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.black87 : Colors.black38,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButtons() {
    return Column(
      children: [
        _buildSocialBtn(
          label: 'ดำเนินการต่อด้วย LINE',
          icon: 'assets/line_icon.png',
          onTap: _loginWithLine,
          color: const Color(0xFF06C755),
        ),
        const SizedBox(height: 12),
        _buildSocialBtn(
          label: 'ดำเนินการต่อด้วย Google',
          icon: 'assets/google_icon.png',
          onTap: _loginWithGoogle,
          isGoogle: true,
        ),
      ],
    );
  }

  Widget _buildSocialBtn({
    required String label,
    required String icon,
    required VoidCallback onTap,
    Color? color,
    bool isGoogle = false,
  }) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.1)),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isGoogle)
              Image.network(
                'https://developers.google.com/identity/images/g-logo.png',
                height: 20,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.account_circle,
                  size: 20,
                  color: Colors.blue,
                ),
              )
            else
              Image.asset(
                icon,
                height: 20,
                errorBuilder: (_, __, ___) => const Icon(Icons.forum, size: 20),
              ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.kanit(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeparator() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.black.withOpacity(0.1))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            _isLoginMode
                ? 'หรือเข้าสู่ระบบด้วยอีเมล'
                : 'หรือสมัครสมาชิกด้วยอีเมล',
            style: GoogleFonts.kanit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black26,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.black.withOpacity(0.1))),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool isPassword = false,
    bool showPassword = false,
    VoidCallback? onTogglePassword,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.kanit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (suffix != null) suffix,
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword && !showPassword,
          keyboardType: keyboardType,
          style: GoogleFonts.kanit(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.kanit(color: Colors.black26, fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.black26, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      showPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.black26,
                      size: 20,
                    ),
                    onPressed: onTogglePassword,
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2D955F), width: 1),
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'กรุณากรอกข้อมูล';
            if (label == 'อีเมล' &&
                !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v))
              return 'อีเมลไม่ถูกต้อง';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _processAuth,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2D955F),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                _isLoginMode ? 'เข้าสู่ระบบ' : 'สร้างบัญชี',
                style: GoogleFonts.kanit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
