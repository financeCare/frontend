import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'pages/otp_page.dart';
import 'auth_manager.dart';
import 'auth_widget.dart';
import '../../../core/config/config.dart' as Config;
import '../data/services/access_token_service.dart';


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
        serverClientId: "756271821434-vpmof8n9b53p89osfrfeibtk83tvqo1h.apps.googleusercontent.com",
      );
      print('!!! Starting googleSignIn.signIn()...');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication auth = await googleUser.authentication;
        print('!!! Received Google Auth tokens. idToken length: ${auth.idToken?.length}');
        print('!!! Received Google Auth tokens');
        
        final response = await http.post(
          Uri.parse('$_baseUrl/login/google'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"idToken": auth.idToken}),
        );
        
        print('Google login response status: ${response.statusCode}');
        print('Google login response body: ${response.body}');
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          await AuthManager.saveToken(data['accessToken']);
          await storage.write(key: "refreshToken", value: data['refreshToken']);
          
          // ✅ Register device after login - MOVED TO HomePage


          print('!!! Tokens saved successfully');
          success = true;
        } else {
          _showErrorDialog('Server error (${response.statusCode}): ${response.body}');
        }
      }
    } catch (error) {
      print('!!! Google login error: $error');
      _showErrorDialog("Google Login Failed: $error");
    } finally {
      if (!mounted) {
        print('!!! WelcomePage unmounted during login');
        return;
      }
      setState(() => _isLoading = false);
      print('!!! Login flow finished. success=$success');
      if (success) {
        print('!!! Navigating to home...');
        _navigateToHome();
      }
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
        await AuthManager.saveToken(data['accessToken']);
        await storage.write(key: "refreshToken", value: data['refreshToken']);

        // ✅ Register device after login - MOVED TO HomePage


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
      if (success && _isLoginMode) {
        // ✅ Register device after login - MOVED TO HomePage
        _navigateToHome();
      }
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Top green header section
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 280,
              decoration: const BoxDecoration(
                color: Color(0xFF2D955F),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
            ),
          ),
          // Decorative subtle circle on top-right
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // App Logo on green background
                    Hero(
                      tag: 'app_logo',
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2D955F).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/logo_finance_care.png',
                          height: 72,
                          width: 72,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.account_balance,
                                  size: 56, color: Color(0xFF2D955F)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'FINANCE CARE',
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isLoginMode
                          ? 'ดูแลเรื่องเงินของคุณอย่างมืออาชีพ'
                          : 'เริ่มต้นจัดการการเงินของคุณวันนี้',
                      style: GoogleFonts.kanit(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildAuthCard(),
                    const SizedBox(height: 16),
                    // Debug Logout (Temporary)
                    if (AuthManager.token != null)
                      TextButton(
                        onPressed: () async {
                          await AuthManager.logout();
                          if (mounted) setState(() {});
                        },
                        child: Text(
                          'Logout (Debug)',
                          style: TextStyle(color: Colors.grey.withOpacity(0.6)),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
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
            const SizedBox(height: 20),
            _buildSeparator(),
            const SizedBox(height: 20),
            _buildTextField(
              label: 'อีเมล',
              controller: _emailController,
              icon: Icons.email_outlined,
              hint: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
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
              const SizedBox(height: 20),
              _buildTextField(
                label: 'ยืนยันรหัสผ่าน',
                controller: _confirmPasswordController,
                icon: Icons.lock_outline,
                hint: 'ยืนยันรหัสผ่านของคุณ',
                isPassword: true,
                showPassword: _isConfirmPasswordVisible,
                onTogglePassword: () => setState(
                  () =>
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
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
              Image.asset(
                'assets/google_icon.png',
                height: 22,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.g_mobiledata,
                  color: Color(0xFF4285F4),
                  size: 28,
                ),
              )
            else
              Image.asset(
                icon,
                height: 20,
                errorBuilder: (_, __, ___) => const Icon(Icons.forum, size: 20),
              ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.kanit(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEB5757), width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEB5757), width: 1.5),
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
              return 'รูปแบบอีเมลไม่ถูกต้อง เช่น email@example.com';
            if (label == 'รหัสผ่าน' && v.length < 8)
              return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
            if (label == 'ยืนยันรหัสผ่าน' &&
                v != _passwordController.text)
              return 'รหัสผ่านไม่ตรงกัน กรุณาตรวจสอบอีกครั้ง';
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
