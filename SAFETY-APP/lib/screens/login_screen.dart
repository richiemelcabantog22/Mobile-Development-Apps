import 'package:flutter/material.dart';
import '../services/face_recognition_service.dart';
import 'monitoring_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;
  final FaceRecognitionService _service = FaceRecognitionService();

  Future<void> _login() async {
    setState(() => _loading = true);
    final ok = await _service.authenticate();
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MonitoringScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Face authentication failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Face Recognition Login")),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
                icon: const Icon(Icons.face),
                label: const Text("Login with Face"),
                onPressed: _login,
              ),
      ),
    );
  }
}