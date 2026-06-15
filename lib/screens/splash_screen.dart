import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.2),
                border: Border.all(
                  color: AppColors.accent.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.eco,
                color: AppColors.accent,
                size: 56,
              ),
            ),
            const SizedBox(height: 24),
            const Text('EcoTrack', style: AppText.heading),
            const SizedBox(height: 8),
            const Text(
              'Track. Improve. Impact.',
              style: AppText.body,
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: AppColors.accent,
              strokeWidth: 2,
            ),
            const SizedBox(height: 16),
            const Text(
              'Loading your eco journey...',
              style: AppText.body,
            ),
          ],
        ),
      ),
    );
  }
}