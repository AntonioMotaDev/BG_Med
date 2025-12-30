import 'package:bg_med/features/auth/presentation/providers/auth_provider.dart';
import 'package:bg_med/features/auth/presentation/screens/login_screen.dart';
import 'package:bg_med/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _buildScreen(authState),
    );
  }

  Widget _buildScreen(AuthState authState) {
    switch (authState.status) {
      case AuthStatus.initial:
      case AuthStatus.loading:
        return _buildLoadingScreen();

      case AuthStatus.authenticated:
        if (authState.user != null) {
          return const DashboardScreen();
        }
        return const LoginScreen();

      case AuthStatus.unauthenticated:
      case AuthStatus.error:
        return const LoginScreen();
    }
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Image.asset('assets/icons/icon.png', fit: BoxFit.contain),
            ),
            const SizedBox(height: 24),

            // Título
            const Text(
              'BG Med',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // Subtítulo
            Text(
              'Sistema de Registro Prehospitalario',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Indicador de carga
            CircularProgressIndicator(color: Colors.blue[600], strokeWidth: 3),
            const SizedBox(height: 16),

            // Texto de carga
            Text(
              'Iniciando...',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
