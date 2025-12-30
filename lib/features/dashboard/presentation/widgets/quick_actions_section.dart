import 'package:bg_med/features/frap/presentation/screens/frap_screen.dart';
// import 'package:bg_med/features/dashboard/presentation/dialogs/patient_search_dialog.dart';
// import 'package:bg_med/features/dashboard/presentation/dialogs/records_management_dialog.dart';
import 'package:bg_med/features/patients/presentation/dialogs/patient_form_dialog.dart';
import 'package:bg_med/features/patients/presentation/providers/patients_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuickActionsSection extends ConsumerWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rápidas',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickAction(
                context,
                'Nuevo Registro',
                'Crear formulario FRAP',
                Icons.add_circle_outline,
                Colors.blue,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FrapScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickAction(
                context,
                'Nuevo Paciente',
                'Registrar paciente',
                Icons.person_add_outlined,
                Colors.green,
                () => _showAddPatientDialog(context, ref),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row(
        //   children: [
        //     Expanded(
        //       child: _buildQuickAction(
        //         context,
        //         'Buscar',
        //         'Buscar pacientes',
        //         Icons.search_outlined,
        //         Colors.purple,
        //         () => _showPatientSearchDialog(context),
        //       ),
        //     ),
        //     const SizedBox(width: 12),
        //     Expanded(
        //       child: _buildQuickAction(
        //         context,
        //         'Registros',
        //         'Administrar registros',
        //         Icons.list_alt_outlined,
        //         Colors.teal,
        //         () => _showRecordsManagementDialog(context),
        //       ),
        //     ),
        //   ],
        // ),
        const SizedBox(height: 12),
        // Row(
        //   children: [
        //     Expanded(
        //       child: _buildQuickAction(
        //         context,
        //         'Sincronizar',
        //         'Sincronizar datos',
        //         Icons.cloud_upload_outlined,
        //         Colors.indigo,
        //         () {},
        //       ),
        //     ),
        //     const SizedBox(width: 12),
        //     // Empty space to maintain grid layout
        //     const Expanded(child: SizedBox()),
        //   ],
        // ),
      ],
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // void _showPatientSearchDialog(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => const PatientSearchDialog(),
  //   );
  // }

  // void _showRecordsManagementDialog(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => const RecordsManagementDialog(),
  //   );
  // }

  void _showAddPatientDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => PatientFormDialog(
            title: 'Nuevo Paciente',
            onSave: (patient) async {
              final notifier = ref.read(patientsNotifierProvider.notifier);
              final result = await notifier.createPatient(patient);

              if (result != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Paciente registrado exitosamente'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
                Navigator.of(context).pop();
              } else if (context.mounted) {
                final errorMessage =
                    ref.read(patientsNotifierProvider).errorMessage;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      errorMessage ?? 'Error al registrar paciente',
                    ),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            },
          ),
    );
  }
}
