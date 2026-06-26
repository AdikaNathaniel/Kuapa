import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/kuapa_button.dart';
import '../../../../shared/widgets/kuapa_text_field.dart';
import '../../data/models/auth_models.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  UserRole _selectedRole = UserRole.BUYER;
  bool _usePhone = false;

  static const _roleInfo = {
    UserRole.FARMER: ('Farmer', 'Sell your produce directly to buyers', Icons.grass),
    UserRole.BUYER: ('Buyer', 'Source fresh produce from local farmers', Icons.shopping_basket),
    UserRole.TRANSPORTER: ('Transporter', 'Provide delivery services', Icons.local_shipping),
  };

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authUserProvider.notifier).register(
          email: _usePhone ? null : _emailController.text.trim(),
          phone: _usePhone ? _emailController.text.trim() : null,
          password: _passwordController.text,
          role: _selectedRole,
        );

    if (!mounted) return;
    final user = ref.read(authUserProvider).valueOrNull;
    if (user != null) {
      switch (user.role.name) {
        case 'FARMER': context.go('/farmer/dashboard');
        case 'BUYER': context.go('/buyer/dashboard');
        case 'TRANSPORTER': context.go('/transporter/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authUserProvider);
    final isLoading = authState.isLoading;
    final error = authState.hasError ? authState.error.toString() : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('I am a...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ..._roleInfo.entries.map((entry) {
                final (label, desc, icon) = entry.value;
                final selected = _selectedRole == entry.key;
                return GestureDetector(
                  onTap: () => setState(() => _selectedRole = entry.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: selected ? AppTheme.primary : Colors.grey.shade300, width: selected ? 2 : 1),
                      borderRadius: BorderRadius.circular(12),
                      color: selected ? AppTheme.primary.withValues(alpha: 0.05) : Colors.white,
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: selected ? AppTheme.primary : AppTheme.textSecondary, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: selected ? AppTheme.primary : AppTheme.textPrimary)),
                              Text(desc, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                        if (selected) const Icon(Icons.check_circle, color: AppTheme.primary),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 20),
              Row(
                children: [
                  ChoiceChip(label: const Text('Email'), selected: !_usePhone, onSelected: (_) => setState(() => _usePhone = false)),
                  const SizedBox(width: 8),
                  ChoiceChip(label: const Text('Phone'), selected: _usePhone, onSelected: (_) => setState(() => _usePhone = true)),
                ],
              ),
              const SizedBox(height: 16),
              KuapaTextField(
                label: _usePhone ? 'Phone Number' : 'Email Address',
                controller: _emailController,
                keyboardType: _usePhone ? TextInputType.phone : TextInputType.emailAddress,
                prefixIcon: _usePhone ? Icons.phone : Icons.email_outlined,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              KuapaTextField(
                label: 'Password',
                controller: _passwordController,
                obscureText: true,
                prefixIcon: Icons.lock_outline,
                validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 16),
              KuapaTextField(
                label: 'Confirm Password',
                controller: _confirmController,
                obscureText: true,
                prefixIcon: Icons.lock_outline,
                validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null,
              ),

              if (error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(error, style: const TextStyle(color: Colors.red, fontSize: 13))),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              KuapaButton(label: 'Create Account', onPressed: _register, isLoading: isLoading),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? '),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Text('Sign In', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
