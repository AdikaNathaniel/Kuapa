import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../shared/widgets/kuapa_button.dart';
import '../../../../shared/widgets/kuapa_text_field.dart';
import '../../data/models/auth_models.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _biometricAvailable = false;
  bool _hasStoredCredentials = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final available = await BiometricService.instance.isAvailable();
    final hasCreds = await BiometricService.instance.hasStoredCredentials();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _hasStoredCredentials = hasCreds;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    await ref.read(authUserProvider.notifier).login(phone: phone, password: password);

    if (!mounted) return;
    final user = ref.read(authUserProvider).valueOrNull;
    if (user != null) {
      if (_biometricAvailable) {
        await BiometricService.instance.saveCredentials(phone, password);
        if (mounted) setState(() => _hasStoredCredentials = true);
      }
      _navigateToDashboard(user.role.name);
    }
  }

  Future<void> _biometricLogin() async {
    final authenticated = await BiometricService.instance.authenticate();
    if (!authenticated) return;

    final creds = await BiometricService.instance.getCredentials();
    if (creds == null) return;

    await ref.read(authUserProvider.notifier).login(phone: creds.phone, password: creds.password);

    if (!mounted) return;
    final user = ref.read(authUserProvider).valueOrNull;
    if (user != null) _navigateToDashboard(user.role.name);
  }

  void _navigateToDashboard(String role) {
    switch (role) {
      case 'FARMER':
        context.go('/farmer/dashboard');
      case 'BUYER':
        context.go('/buyer/dashboard');
      case 'TRANSPORTER':
        context.go('/transporter/dashboard');
    }
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/kuapa_logo.jpg',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Kuapa',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppTheme.primary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Farm to Table, Direct',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade500,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState    = ref.watch(authUserProvider);
    final isLoading    = authState.isLoading;
    final errorMsg     = authState.hasError ? parseApiError(authState.error) : null;
    final showBiometric = _biometricAvailable && _hasStoredCredentials;

    // Show a snackbar whenever the auth state transitions to an error
    ref.listen<AsyncValue<AuthUser?>>(authUserProvider, (prev, next) {
      if (next.hasError && !(prev?.hasError ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    parseApiError(next.error),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                Center(child: _buildLogo()),
                const SizedBox(height: 40),
                const Center(
                  child: Text(
                    'Welcome back',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 32),

                KuapaTextField(
                  label: 'Phone Number',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone,
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

                if (errorMsg != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(errorMsg, style: const TextStyle(color: Colors.red, fontSize: 13))),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                KuapaButton(label: 'Sign In', onPressed: _login, isLoading: isLoading),

                if (showBiometric) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: GestureDetector(
                      onTap: isLoading ? null : _biometricLogin,
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primary.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(Icons.fingerprint, size: 36, color: AppTheme.primary),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Sign in with Fingerprint',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    GestureDetector(
                      onTap: () => context.push('/register'),
                      child: const Text('Register', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
