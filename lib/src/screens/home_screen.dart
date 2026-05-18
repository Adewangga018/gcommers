import 'package:flutter/material.dart';

import '../models/auth_models.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GCommers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 32,
              backgroundColor: AppTheme.primary,
              child: Icon(Icons.store_rounded, color: Colors.white, size: 34),
            ),
            const SizedBox(height: 20),
            Text(
              'Selamat datang, ${session.displayName}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              session.email,
              style: const TextStyle(color: AppTheme.muted),
            ),
            const SizedBox(height: 24),
            _InfoCard(
              title: 'Sistem autentikasi siap',
              subtitle: 'UI sudah terhubung ke alur login, lupa password, OTP, reset password, dan daftar kios.',
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              await sessionManager.clearSession();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x11000000), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: AppTheme.muted, height: 1.5)),
        ],
      ),
    );
  }
}
