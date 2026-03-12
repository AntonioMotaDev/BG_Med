import 'package:bg_med/core/models/frap.dart';
import 'package:bg_med/core/models/patient_firestore.dart';
import 'package:bg_med/core/services/frap_unified_service.dart';
import 'package:bg_med/features/frap/presentation/providers/frap_unified_provider.dart';
import 'package:bg_med/features/frap/presentation/screens/frap_record_details_screen.dart';
import 'package:bg_med/features/patients/presentation/dialogs/patient_details_dialog.dart';
import 'package:bg_med/features/patients/presentation/providers/patients_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Clase para unificar actividades recientes
class RecentActivity {
  final String id;
  final String title;
  final String subtitle;
  final DateTime createdAt;
  final IconData icon;
  final Color color;
  final String type; // 'frap' o 'patient'
  final dynamic data; // Frap o PatientFirestore

  RecentActivity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.createdAt,
    required this.icon,
    required this.color,
    required this.type,
    required this.data,
  });
}

class RecentActivitySection extends ConsumerWidget {
  const RecentActivitySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsState = ref.watch(patientsNotifierProvider);
    final unifiedFrapState = ref.watch(unifiedFrapProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actividad Reciente',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder(
          valueListenable: Hive.box<Frap>('fraps').listenable(),
          builder: (context, Box<Frap> box, _) {
            try {
              final List<RecentActivity> activities = [];

              // Agregar registros FRAP
              for (final frap in box.values) {
                activities.add(
                  RecentActivity(
                    id: frap.id,
                    title: frap.patient.name,
                    subtitle: 'Registro FRAP creado',
                    createdAt: frap.createdAt,
                    icon: Icons.assignment,
                    color: Colors.blue[600]!,
                    type: 'frap',
                    data: frap,
                  ),
                );
              }

              // Agregar registros FRAP de nube que aun no existen localmente
              for (final record in unifiedFrapState.records) {
                if (record.isLocal || record.cloudRecord == null) {
                  continue;
                }

                activities.add(
                  RecentActivity(
                    id: record.id,
                    title: record.patientName,
                    subtitle: 'Registro FRAP creado',
                    createdAt: record.createdAt,
                    icon: Icons.assignment,
                    color: Colors.blue[600]!,
                    type: 'frap',
                    data: record,
                  ),
                );
              }

              // Agregar pacientes creados (solo si el estado es exitoso)
              if (patientsState.status == PatientsStatus.success) {
                for (final patient in patientsState.patients) {
                  activities.add(
                    RecentActivity(
                      id: patient.id ?? '',
                      title: patient.fullName,
                      subtitle: 'Paciente registrado',
                      createdAt: patient.createdAt,
                      icon: Icons.person_add,
                      color: Colors.green[600]!,
                      type: 'patient',
                      data: patient,
                    ),
                  );
                }
              }

              if (activities.isEmpty) {
                return _buildEmptyState();
              }

              // Ordenar por fecha de creación (más reciente primero)
              activities.sort((a, b) {
                final dateCompare = b.createdAt.compareTo(a.createdAt);
                if (dateCompare != 0) {
                  return dateCompare;
                }

                // Desempate estable para evitar cambios visuales entre rebuilds.
                return b.id.compareTo(a.id);
              });

              // Mostrar solo los últimos 5 registros
              final recentActivities = activities.take(5).toList();

              return Column(
                children:
                    recentActivities.map((activity) {
                      return _buildActivityTile(context, activity);
                    }).toList(),
              );
            } catch (e) {
              // Si hay error con la caja de Hive, mostrar estado vacío
              return _buildEmptyState();
            }
          },
        ),
      ],
    );
  }

  Widget _buildActivityTile(BuildContext context, RecentActivity activity) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: activity.color.withOpacity(0.1),
        child: Icon(activity.icon, color: activity.color, size: 20),
      ),
      title: Text(
        activity.title,
        style: const TextStyle(fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            activity.subtitle,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            _formatDate(activity.createdAt),
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
        ],
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: () => _handleActivityTap(context, activity),
    );
  }

  void _handleActivityTap(BuildContext context, RecentActivity activity) {
    switch (activity.type) {
      case 'frap':
        final data = activity.data;
        late final UnifiedFrapRecord record;
        if (data is Frap) {
          record = UnifiedFrapRecord.fromLocal(data);
        } else if (data is UnifiedFrapRecord) {
          record = data;
        } else {
          _showNavigationError(context, 'No se pudo abrir el detalle del FRAP');
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FrapRecordDetailsScreen(record: record),
          ),
        );
        break;
      case 'patient':
        final data = activity.data;
        if (data is! PatientFirestore) {
          _showNavigationError(
            context,
            'No se pudo abrir el detalle del paciente',
          );
          return;
        }

        showDialog(
          context: context,
          builder: (context) => PatientDetailsDialog(patient: data),
        );
        break;
      default:
        _showNavigationError(context, 'Tipo de actividad no soportado');
        break;
    }
  }

  void _showNavigationError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.timeline_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hay actividad reciente',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea un registro FRAP o registra un paciente para comenzar',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoy ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Ayer ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} días atrás';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
