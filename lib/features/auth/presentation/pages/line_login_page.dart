import 'package:flutter/material.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:flutter_application_1/features/dashboard/presentation/pages/homepage.dart';

class LineLoginPage extends StatefulWidget {
  const LineLoginPage({super.key});

  @override
  State<LineLoginPage> createState() => _LineLoginPageState();
}

class _LineLoginPageState extends State<LineLoginPage> {
  bool _isLoading = false;
  Map<String, dynamic>? _lineUser;

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      final result = await LineSDK.instance.login(scopes: ["profile"]);

      setState(() {
        _lineUser = {
          "name": result.userProfile?.displayName,
          "picture": result.userProfile?.pictureUrl,
        };
        _isLoading = false;
      });

      // เมื่อ login สำเร็จ → ไปหน้า CRUD
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _lineUser = {"error": e.toString()};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login with LINE")),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _login,
                child: const Text("Login with LINE"),
              ),
      ),
    );
  }
}
