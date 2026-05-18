import 'package:flutter/material.dart';

import '../models/auth_models.dart';
import '../services/session_manager.dart';
import 'splash_screen.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final session = await sessionManager.getSession();
    if (!mounted) return;

    if (session != null) {
      Navigator.of(context).pushReplacementNamed(
        '/home',
        arguments: session,
      );
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }

  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

