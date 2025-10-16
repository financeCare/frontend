import 'package:flutter/material.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Setup LINE SDK ด้วย Channel ID จริง
  await LineSDK.instance.setup("2008279064");
  runApp(const FinanceCareApp());
}

class FinanceCareApp extends StatelessWidget {
  const FinanceCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance Care PoC',
      home: const LineLoginPage(),
    );
  }
}

class LineLoginPage extends StatefulWidget {
  const LineLoginPage({super.key});

  @override
  State<LineLoginPage> createState() => _LineLoginPageState();
}

class _LineLoginPageState extends State<LineLoginPage> {
  Map<String, dynamic>? _lineUser;
  bool _isLoading = false;

  Future<void> _loginWithLine() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await LineSDK.instance.login(
        scopes: ["profile", "openid", "email"],
      );

      final user = {
        'userId': result.userProfile?.userId,
        'displayName': result.userProfile?.displayName,
        'pictureUrl': result.userProfile?.pictureUrl,
        'statusMessage': result.userProfile?.statusMessage,
        'accessToken': result.accessToken?.value,
      };

      setState(() {
        _lineUser = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _lineUser = {'error': e.toString()};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login with LINE')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                const Text("Logging in with LINE..."),
              ] else if (_lineUser != null) ...[
                const Text(
                  "LINE User JSON:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  _lineUser.toString(),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await LineSDK.instance.logout();
                    setState(() => _lineUser = null);
                  },
                  child: const Text("Logout"),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: _loginWithLine,
                  icon: const Icon(Icons.chat),
                  label: const Text(
                    'Login with LINE',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06C755),
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
