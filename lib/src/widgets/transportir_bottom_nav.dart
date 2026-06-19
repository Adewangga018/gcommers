import 'package:flutter/material.dart';

import '../models/auth_models.dart';
import '../theme/app_theme.dart';

class TransportirBottomNav extends StatelessWidget {
  const TransportirBottomNav({
    required this.currentIndex,
    this.session,
    super.key,
  });

  final int currentIndex;
  final AuthSession? session;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppTheme.paper,
      selectedItemColor: AppTheme.ink,
      unselectedItemColor: AppTheme.muted,
      selectedLabelStyle: AppTheme.body(size: 12, weight: FontWeight.w700),
      unselectedLabelStyle: AppTheme.body(size: 12),
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment_outlined),
          activeIcon: Icon(Icons.assignment),
          label: 'Pesanan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_shipping_outlined),
          activeIcon: Icon(Icons.local_shipping),
          label: 'Pengiriman',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
      onTap: (index) {
        if (index == currentIndex) return;
        final route = switch (index) {
          0 => '/transportir-home',
          1 => '/transportir-orders',
          2 => '/transportir-shipments',
          3 => '/transportir-profile',
          _ => null,
        };
        if (route == null) return;
        Navigator.of(context).pushReplacementNamed(route, arguments: session);
      },
    );
  }
}
