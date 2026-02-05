import 'package:flutter/material.dart';
// 🌟 Import จากที่อยู่ใหม่
import '../auth/logo_header.dart';
// 🌟 Import AuthService ตัวจริง (ต้องสร้างไฟล์นี้ด้วย)
import '../auth/auth_widget.dart';

// =========================================================
// 2. EMAIL LOGIN PAGE: หน้าจอ Login ด้วย Email/Password
// UI ถูกเก็บไว้ครบถ้วน
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

  final AuthService _authService = AuthService(); // 🌟 ใช้ AuthService ตัวจริง

  bool _isRegisterMode = false;
  bool _isLoading = false;

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _processAuth() async {
  final form = _formKey.currentState;

  if (form == null || !form.validate()) return;

  if (_isRegisterMode &&
      _passwordController.text != _confirmPasswordController.text) {
    _showErrorDialog('Passwords do not match.');
    return;
  }

  setState(() => _isLoading = true);

  final authService = AuthService();
  bool success = false;

  final email = _emailController.text;
  final password = _passwordController.text;

  if (_isRegisterMode) {
    success = await authService.register(email, password);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpPage(
            email: email,
            password: password,
          ),
        ),
      );
      setState(() => _isLoading = false);
      return;
    }
  } else {
    success = await authService.login(email, password);
  }

  if (!mounted) return;

  setState(() => _isLoading = false);

  if (success) {
    print('Login success. Navigating to /home.');
    Navigator.of(context).pushReplacementNamed('/home');
  } else if (!_isRegisterMode) {
    _showErrorDialog("Email or password is incorrect");
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
  String get otpCode => _otpControllers.map((c) => c.text).join();

  @override
  void dispose() {
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // ฟังก์ชันส่ง verify OTP
  Future<void> _verifyOtp() async {
    if (otpCode.length != 6) {
      _showError("Please fill all 6 digits.");
      return;
    }

    setState(() => _isLoading = true);

    final authService = AuthService();
    bool success = await authService.verifyOTP(
      widget.email,
      otpCode,
      widget.password,
    );

    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      _showError("Invalid OTP. Please try again.");
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 50,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(fontSize: 24),
        decoration: const InputDecoration(
          counterText: "",
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          }
          if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify OTP")),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              "We sent a 6-digit OTP to:",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(widget.email, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 40),

            // OTP Boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, _buildOtpBox),
            ),

            const SizedBox(height: 40),

            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 55),
                    ),
                    child: const Text("VERIFY OTP"),
                  ),
          ],
        ),
      ),
    );
  }
}