import 'package:bg_med/core/theme/app_theme.dart';
import 'package:bg_med/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    // Mostrar errores y éxitos
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Limpiar error después de mostrarlo
        Future.delayed(const Duration(seconds: 3), () {
          ref.read(authNotifierProvider.notifier).clearError();
        });
      }

      // Mostrar éxito cuando se crea el usuario
      if (next.status == AuthStatus.authenticated &&
          previous?.status == AuthStatus.loading) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '¡Usuario creado exitosamente! Redirigiendo al dashboard...',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );

        // Redirigir al dashboard después de un breve delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/dashboard',
              (route) => false,
            );
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Header
              _buildHeader(),
              const SizedBox(height: 40),

              // Formulario de registro
              _buildRegisterForm(authState),
              const SizedBox(height: 24),

              // Botón de registro
              _buildRegisterButton(authState),
              const SizedBox(height: 32),

              // Enlace de login
              _buildLoginLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: Image.asset(
            'assets/icons/icon.png',
            width: 240,
            height: 240,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Crear Cuenta',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Completa los datos para crear tu cuenta',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildRegisterForm(AuthState authState) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Campo de nombre
          TextFormField(
            controller: _nameController,
            enabled: authState.status != AuthStatus.loading,
            decoration: InputDecoration(
              labelText: 'Nombre completo',
              hintText: 'Ingresa tu nombre completo',
              prefixIcon: const Icon(Icons.person_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu nombre';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Campo de email
          TextFormField(
            controller: _emailController,
            enabled: authState.status != AuthStatus.loading,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Correo electrónico',
              hintText: 'ejemplo@correo.com',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu correo electrónico';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Por favor ingresa un correo electrónico válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Campo de contraseña
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            enabled: authState.status != AuthStatus.loading,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              hintText: 'Mínimo 6 caracteres',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu contraseña';
              }
              if (value.length < 6) {
                return 'La contraseña debe tener al menos 6 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Campo de confirmar contraseña
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            enabled: authState.status != AuthStatus.loading,
            decoration: InputDecoration(
              labelText: 'Confirmar contraseña',
              hintText: 'Confirma tu contraseña',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor confirma tu contraseña';
              }
              if (value != _passwordController.text) {
                return 'Las contraseñas no coinciden';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton(AuthState authState) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed:
            authState.status == AuthStatus.loading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child:
            authState.status == AuthStatus.loading
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : const Text(
                  'Crear Cuenta',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('¿Ya tienes cuenta? ', style: TextStyle(color: Colors.grey[600])),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Inicia sesión',
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authNotifierProvider.notifier)
          .register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
            role: 'user', // Por defecto, los nuevos usuarios tienen rol 'user'
          );
    }
  }
}
