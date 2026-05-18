import 'package:flutter/material.dart';

import 'src/screens/app_shell.dart';
import 'src/screens/kiosk_profil_page.dart';
import 'src/theme/app_theme.dart';

void main() {
  runApp(const GCommersApp());
}

class GCommersApp extends StatelessWidget {
  const GCommersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GCommers',
      theme: AppTheme.light(),
      home: const AppShell(),
      routes: <String, WidgetBuilder>{
        '/home': (context) => const _PlaceholderHomeRoute(),
        '/profile': (context) => const KiosProfilePage(),
        '/login': (context) => const PlaceholderLoginRoute(),
      },
    );
  }
}

class PlaceholderLoginRoute extends StatelessWidget {
  const PlaceholderLoginRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('MASUK'),
      ),
    );
  }
}

class _PlaceholderHomeRoute extends StatelessWidget {
  const _PlaceholderHomeRoute();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Selamat Datang'),
      ),
    );
  }
}

