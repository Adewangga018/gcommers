import 'package:flutter/material.dart';

import 'src/screens/app_shell.dart';
import 'src/screens/kiosk_dashboard_page.dart';
import 'src/screens/kiosk_profil_page.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/payment_page.dart';
import 'src/screens/payment_success_page.dart';
import 'src/screens/history_page.dart';
import 'src/screens/order_page.dart';
import 'src/screens/order_history_detail_page.dart';
import 'src/screens/scan_qr_page.dart';
import 'src/screens/received_goods_page.dart';
import 'src/screens/notification_page.dart';
import 'src/screens/settings_pages.dart';
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
        '/home': (context) => const KiosDashboardPage(),
        '/history': (context) => const HistoryPage(),
        '/history-detail': (context) {
          final poNumber = ModalRoute.of(context)?.settings.arguments as String? ?? 'PO-2026-10-9842';
          return OrderHistoryDetailPage(poNumber: poNumber);
        },
        '/orders': (context) => const OrderPage(),
        '/scan-qr': (context) => const ScanQrPage(),
        '/received-goods': (context) => const ReceivedGoodsPage(),
        '/payment': (context) => const PaymentPage(),
        '/payment-success': (context) => const PaymentSuccessPage(),
        '/profile': (context) => const KiosProfilePage(),
        '/login': (context) => const LoginScreen(),
        '/notifications': (context) => const NotificationPage(),
        '/account-info': (context) => const AccountInfoPage(),
        '/security': (context) => const SecurityPage(),
        '/notification-settings': (context) => const NotificationSettingsPage(),
        '/help': (context) => const HelpPage(),
      },
    );
  }
}
