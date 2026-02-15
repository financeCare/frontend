import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth_widget.dart';

class OtpPage extends StatefulWidget {
  final String email;
  final String password;
  const OtpPage({super.key, required this.email, required this.password});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  int _resendTimer = 60;
  String get otpCode => _otpControllers.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendTimer > 0) {
        setState(() => _resendTimer--);
        _startResendTimer();
      }
    });
  }

  @override
  void dispose() {
    for (var c in _otpControllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (otpCode.length != 6) return;

    setState(() => _isLoading = true);
    final authService = AuthService();
    bool success = await authService.verifyOTP(
      widget.email,
      otpCode,
      widget.password,
    );
    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      _showError("รหัส OTP ไม่ถูกต้อง โปรดลองอีกครั้ง");
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildVerifyIcon(),
            const SizedBox(height: 32),
            Text(
              "ยืนยันอีเมลของคุณ",
              style: GoogleFonts.kanit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.kanit(fontSize: 14, color: Colors.black54),
                children: [
                  const TextSpan(text: "เราได้ส่งรหัสยืนยัน 6 หลักไปที่\n"),
                  TextSpan(
                    text: widget.email,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildOtpInputs(),
            const SizedBox(height: 40),
            _buildVerifyButton(),
            const SizedBox(height: 32),
            _buildResendPrompt(),
            const SizedBox(height: 16),
            _buildBackToRegistration(),
            const SizedBox(height: 40),
            Text(
              "โปรดตรวจสอบในกล่องจดหมายและโฟลเดอร์สแปมสำหรับรหัสยืนยัน",
              textAlign: TextAlign.center,
              style: GoogleFonts.kanit(fontSize: 12, color: Colors.black38),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyIcon() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2D955F).withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.verified_user_outlined,
        size: 48,
        color: Color(0xFF2D955F),
      ),
    );
  }

  Widget _buildOtpInputs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [for (int i = 0; i < 6; i++) _buildDigitBox(i)],
    );
  }

  Widget _buildDigitBox(int index) {
    return Container(
      width: 50,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: GoogleFonts.kanit(fontSize: 24, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
        ),
        onChanged: (v) {
          if (v.isNotEmpty && index < 5) _focusNodes[index + 1].requestFocus();
          if (v.isEmpty && index > 0) _focusNodes[index - 1].requestFocus();
          if (otpCode.length == 6) _verifyOtp();
        },
      ),
    );
  }

  Widget _buildVerifyButton() {
    bool isComplete = otpCode.length == 6;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: (_isLoading || !isComplete) ? null : _verifyOtp,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(
            0xFF2D955F,
          ).withOpacity(isComplete ? 1.0 : 0.4),
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
                "ยืนยันและดำเนินการต่อ",
                style: GoogleFonts.kanit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildResendPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "ไม่ได้รับรหัสใช่หรือไม่? ",
          style: GoogleFonts.kanit(fontSize: 13, color: Colors.black54),
        ),
        if (_resendTimer > 0)
          Text(
            "ส่งอีกครั้งใน ${_resendTimer} วินาที",
            style: GoogleFonts.kanit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          )
        else
          GestureDetector(
            onTap: () {
              setState(() => _resendTimer = 60);
              _startResendTimer();
              // Add actual resend logic here
              AuthService().sendOTP(widget.email);
            },
            child: Text(
              "ส่งรหัสอีกครั้ง",
              style: GoogleFonts.kanit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D955F),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBackToRegistration() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.arrow_back, size: 16, color: Colors.black38),
          const SizedBox(width: 8),
          Text(
            "กลับไปหน้าสมัครสมาชิก",
            style: GoogleFonts.kanit(fontSize: 13, color: Colors.black38),
          ),
        ],
      ),
    );
  }
}
