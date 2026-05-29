import 'package:flutter/material.dart';

import 'src/models/auth_models.dart';
import 'src/screens/app_shell.dart';
import 'src/screens/kiosk_dashboard_page.dart';
import 'src/screens/kiosk_profil_page.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/role_selection_screen.dart';
import 'src/screens/transportir_dashboard_screen.dart';
import 'src/screens/transportir_orders_flow.dart';
import 'src/screens/transportir_profile_page.dart';
import 'src/screens/transportir_shipping_flow.dart';
import 'src/screens/transportir_reports_flow.dart';
import 'src/screens/transportir_register_screen.dart';
import 'src/screens/transportir_login_screen.dart';
import 'src/screens/payment_page.dart';
import 'src/screens/payment_success_page.dart';
import 'src/screens/history_page.dart';
import 'src/screens/order_page.dart';
import 'src/screens/order_history_detail_page.dart';
import 'src/screens/scan_qr_page.dart';
import 'src/screens/received_goods_page.dart';
import 'src/screens/notification_page.dart';
import 'src/screens/settings_pages.dart';
import 'src/screens/edit_profile_page.dart';
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
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/kiosk-login': (context) => const LoginScreen(),
        '/transportir-login': (context) => const TransportirLoginScreen(),
        '/transportir-register': (context) => const TransportirRegisterScreen(),
        '/transportir-home': (context) {
          final session = ModalRoute.of(context)?.settings.arguments as AuthSession?;
          return TransportirDashboardScreen(session: session);
        },
        '/transportir-orders': (context) {
          final session = ModalRoute.of(context)?.settings.arguments as AuthSession?;
          return TransportirOrdersPage(session: session);
        },
        '/transportir-shipments': (context) {
          final session = ModalRoute.of(context)?.settings.arguments as AuthSession?;
          return TransportirShipmentsPage(session: session);
        },
        '/transportir-profile': (context) {
          final session = ModalRoute.of(context)?.settings.arguments as AuthSession?;
          return TransportirProfilePage(session: session);
        },
        '/transportir-reports': (context) {
          final session = ModalRoute.of(context)?.settings.arguments as AuthSession?;
          return TransportirReportsPage(session: session);
        },
        '/transportir-report-claim': (context) {
          final session = ModalRoute.of(context)?.settings.arguments as AuthSession?;
          return TransportirReportClaimPage(session: session);
        },
        '/transportir-report-success': (context) {
          final session = ModalRoute.of(context)?.settings.arguments as AuthSession?;
          return TransportirReportSuccessPage(session: session);
        },
        '/transportir-report-history': (context) {
          final session = ModalRoute.of(context)?.settings.arguments as AuthSession?;
          return TransportirReportHistoryPage(session: session);
        },
        '/transportir-report-detail': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as TransportirReportDetailArgs;
          return TransportirReportDetailPage(args: args);
        },
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
        '/edit-profile': (context) => const EditProfilePage(),
        '/account-info': (context) => const AccountInfoPage(),
        '/security': (context) => const SecurityPage(),
        '/notification-settings': (context) => const NotificationSettingsPage(),
        '/help': (context) => const HelpPage(),
      },
    );
  }
}
