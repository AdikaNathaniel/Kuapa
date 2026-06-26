import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authUserProvider, (_, next) {
      next.whenData((user) {
        if (user == null) {
          context.go('/login');
        } else {
          switch (user.role.name) {
            case 'FARMER':
              context.go('/farmer/dashboard');
            case 'BUYER':
              context.go('/buyer/dashboard');
            case 'TRANSPORTER':
              context.go('/transporter/dashboard');
            default:
              context.go('/login');
          }
        }
      });
    });

    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.agriculture, size: 64, color: AppTheme.primary),
            ),
            const SizedBox(height: 24),
            const Text(
              'Kuapa',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Text(
              'Farm to Table, Direct',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
