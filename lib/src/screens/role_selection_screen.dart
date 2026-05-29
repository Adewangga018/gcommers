import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'transportir_login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.navy,
                Color(0xFF161330),
                Color(0xFFF5F2FF),
              ],
              stops: [0.0, 0.56, 1.0],
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const _BrandHeader(),
              const SizedBox(height: 28),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7F4FF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih Role',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Masuk sesuai peran Anda agar alur login dan dashboard tetap tepat.',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          height: 1.4,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _RoleCard(
                              icon: Icons.store_rounded,
                              title: 'Kiosk',
                              description: 'Login untuk akun kiosk dan akses dashboard operasional.',
                              accent: AppTheme.primary,
                              borderTint: const Color.fromARGB(36, 74, 58, 255),
                              fillTint: const Color.fromARGB(31, 74, 58, 255),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _RoleCard(
                              icon: Icons.local_shipping_rounded,
                              title: 'Transportir',
                              description: 'Login untuk akun transportir yang terdaftar.',
                              accent: const Color(0xFF1F9D8A),
                              borderTint: const Color.fromARGB(36, 31, 157, 138),
                              fillTint: const Color.fromARGB(31, 31, 157, 138),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(builder: (_) => const TransportirLoginScreen()),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _LogoCircle(size: 92),
        SizedBox(height: 16),
        Text(
          'GCommers',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Platform E-Commerce GCS',
          style: TextStyle(color: Color(0xFFC9C4E7), fontSize: 15),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
    required this.borderTint,
    required this.fillTint,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final Color borderTint;
  final Color fillTint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderTint),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: fillTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(color: Colors.grey.shade700, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.arrow_forward_ios_rounded, size: 18, color: accent),
            ],
          ),
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
      child: const Icon(Icons.store_rounded, size: 44, color: AppTheme.primary),
    );
  }
}
