import 'package:flutter/material.dart';

import 'src/screens/app_shell.dart';
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
    );
  }
}
