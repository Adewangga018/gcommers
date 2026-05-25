import 'package:flutter/material.dart';

import '../models/auth_models.dart';
import '../services/session_manager.dart';

class TransportirProfilePage extends StatelessWidget {
  const TransportirProfilePage({super.key, this.session});

  final AuthSession? session;

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF4A3AFF);
    final displayName = (session?.displayName.trim().isNotEmpty ?? false) ? session!.displayName : 'Nama Transportir';
    final email = session?.email ?? 'you@domain.tld';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profil Transportir', style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.grey),
            onPressed: () => Navigator.of(context).pushNamed('/notifications'),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 54,
                      backgroundColor: Colors.grey[200],
                      child: Icon(Icons.person, size: 64, color: Colors.grey[400]),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: primary, shape: BoxShape.circle),
                        child: const Icon(Icons.edit, color: Colors.white, size: 16),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: primary.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Text('Transportir', style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const SizedBox(height: 18),

              // Contact card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.email_outlined, color: Color(0xFF4A3AFF)),
                      title: const Text('Email'),
                      subtitle: Text(email),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.info_outline, color: Color(0xFF4A3AFF)),
                      title: const Text('Peran'),
                      subtitle: Text(session?.role ?? '-'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Actions
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await sessionManager.clearSession();
                    if (!context.mounted) return;
                    Navigator.of(context).pushNamedAndRemoveUntil('/role-selection', (_) => false);
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text('Keluar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
