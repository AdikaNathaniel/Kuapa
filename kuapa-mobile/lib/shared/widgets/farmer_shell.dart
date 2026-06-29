import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

// ─── Farmer shell (4 tabs + centred FAB) ──────────────────────────────────────

class FarmerShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const FarmerShell({super.key, required this.navigationShell});

  static const _tabs = [
    _TabItem(icon: Icons.home_outlined,           activeIcon: Icons.home,           label: 'Home'),
    _TabItem(icon: Icons.inventory_2_outlined,    activeIcon: Icons.inventory_2,    label: 'Listings'),
    _TabItem(icon: Icons.receipt_long_outlined,   activeIcon: Icons.receipt_long,   label: 'Orders'),
    _TabItem(icon: Icons.local_shipping_outlined, activeIcon: Icons.local_shipping, label: 'Transport'),
  ];

  void _onTap(int index) =>
      navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/farmer/add-product'),
        backgroundColor: AppTheme.primary,
        tooltip: 'Add Product',
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        child: Row(
          children: [
            for (int i = 0; i < 2; i++)
              _NavItem(tab: _tabs[i], selected: navigationShell.currentIndex == i, onTap: () => _onTap(i)),
            const SizedBox(width: 72), // gap for FAB notch
            for (int i = 2; i < 4; i++)
              _NavItem(tab: _tabs[i], selected: navigationShell.currentIndex == i, onTap: () => _onTap(i)),
          ],
        ),
      ),
    );
  }
}

// ─── Buyer shell (5 tabs) ─────────────────────────────────────────────────────

class BuyerShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const BuyerShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textSecondary,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined),         activeIcon: Icon(Icons.home),          label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined),   activeIcon: Icon(Icons.storefront),    label: 'Market'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), activeIcon: Icon(Icons.shopping_bag),  label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline),   activeIcon: Icon(Icons.chat_bubble),   label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping_outlined), activeIcon: Icon(Icons.local_shipping), label: 'Deliveries'),
        ],
      ),
    );
  }
}

// ─── Transporter shell (3 tabs) ───────────────────────────────────────────────

class TransporterShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const TransporterShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textSecondary,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined),       activeIcon: Icon(Icons.home),        label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined),  activeIcon: Icon(Icons.assignment),  label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined),         activeIcon: Icon(Icons.map),         label: 'Map'),
        ],
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _TabItem({required this.icon, required this.activeIcon, required this.label});
}

class _NavItem extends StatelessWidget {
  final _TabItem tab;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({required this.tab, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? tab.activeIcon : tab.icon,
                color: selected ? AppTheme.primary : AppTheme.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                tab.label,
                style: TextStyle(
                  fontSize: 11,
                  color: selected ? AppTheme.primary : AppTheme.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );
}
