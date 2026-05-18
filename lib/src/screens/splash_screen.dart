import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: SafeArea(
        child: Stack(
          children: [
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LogoCircle(size: 96),
                  SizedBox(height: 18),
                  Text(
                    'GCommers',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Platform E-Commerce GCS',
                    style: TextStyle(color: Color(0xFFB6B2D2), fontSize: 16),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 28,
              right: 28,
              bottom: 28,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: const LinearProgressIndicator(
                  value: 0.34,
                  minHeight: 6,
                  backgroundColor: Color(0xFF5A5677),
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoCircle extends StatelessWidget {
  const _LogoCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.store_rounded, size: 46, color: AppTheme.primary),
    );
  }
}
