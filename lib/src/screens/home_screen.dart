import 'package:flutter/material.dart';

import '../models/auth_models.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import 'role_selection_screen.dart';

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
              style: AppTheme.title(size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              session.email,
              style: const TextStyle(color: AppTheme.muted),
            ),
            const SizedBox(height: 10),
            _RoleBadge(role: session.role),
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
                MaterialPageRoute<void>(builder: (_) => const RoleSelectionScreen()),
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

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  String get _label {
    switch (role.toLowerCase()) {
      case 'kiosk':
        return 'Kiosk';
      case 'transportir':
        return 'Transportir';
      case 'admin':
        return 'Admin Region';
      case 'superadmin':
        return 'Super Admin';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color.fromARGB(26, 47, 108, 63),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          _label,
          style: const TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
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
          Text(title, style: AppTheme.subtitle(size: 16)),
          const SizedBox(height: 8),
          Text(subtitle, style: AppTheme.body(size: 13, color: AppTheme.muted, height: 1.5)),
        ],
      ),
    );
  }
}
