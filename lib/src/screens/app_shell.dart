import 'package:flutter/material.dart';

import '../services/session_manager.dart';
import 'home_screen.dart';
import 'splash_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    // Ensure session storage is initialized before reading it,
    // to avoid transient null sessions during hot reload.
    sessionManager.init();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    // Ensure SharedPreferences is ready in case this runs right after hot reload.
    await sessionManager.init();


    final session = await sessionManager.getSession();
    if (!mounted) return;

    if (session == null) {
      Navigator.of(context).pushReplacementNamed('/role-selection');
      return;
    }

    final role = session.role.toLowerCase();

    if (role == 'kiosk') {
      Navigator.of(context).pushReplacementNamed(
        '/home',
        arguments: session,
      );
      return;
    }

    if (role == 'transportir') {
      Navigator.of(context).pushReplacementNamed(
        '/transportir-home',
        arguments: session,
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => HomeScreen(session: session)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

