import 'package:bg_med/core/theme/app_theme.dart';
import 'package:bg_med/features/auth/presentation/providers/auth_provider.dart';
import 'package:bg_med/features/dashboard/presentation/widgets/connectivity_indicator.dart';
import 'package:bg_med/features/dashboard/presentation/widgets/profile_menu.dart';
import 'package:bg_med/features/dashboard/presentation/widgets/statistics_section.dart';
import 'package:bg_med/features/dashboard/presentation/widgets/quick_actions_section.dart';
import 'package:bg_med/features/dashboard/presentation/widgets/recent_activity_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        centerTitle: true,
        elevation: 0,
        actions: const [
          ConnectivityIndicator(),
          SizedBox(width: 8),
          ProfileMenu(),
          SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.primaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bienvenido a BG Med App',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sistema de Registros de Atención Prehospitalaria',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, color: Colors.teal),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? user?.email ?? 'Usuario',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Statistics Section
            const StatisticsSection(),
            const SizedBox(height: 24),

            // Quick Actions Section
            const QuickActionsSection(),
            const SizedBox(height: 24),

            // Recent Activity Section
            const RecentActivitySection(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
