import 'package:bg_med/core/theme/app_theme.dart';
import 'package:bg_med/core/models/frap.dart';
import 'package:bg_med/core/models/appointment.dart';
import 'package:bg_med/core/services/appointment_service.dart';
import 'package:bg_med/features/dashboard/presentation/dialogs/appointment_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarTab extends ConsumerStatefulWidget {
  const CalendarTab({super.key});

  @override
  ConsumerState<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends ConsumerState<CalendarTab> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  final AppointmentService _appointmentService = AppointmentService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Agenda',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        foregroundColor: AppTheme.primaryBlue,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _selectedDate = DateTime.now();
                _focusedDate = DateTime.now();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar Widget
          Container(child: _buildTableCalendar()),

          // Selected Date Activities
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.event, color: Colors.blue[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Actividades del ${_formatSelectedDate()}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(child: _buildActivitiesList()),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "calendar_fab",
        onPressed: _showAddAppointmentDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Cita'),
      ),
    );
  }

  Widget _buildTableCalendar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TableCalendar<dynamic>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDate,
        selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
        eventLoader: (day) => _getAllEventsForDay(day),

        // Estilos del calendario
        calendarStyle: CalendarStyle(
          // Días normales
          defaultDecoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
          ),

          // Día seleccionado
          selectedDecoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            shape: BoxShape.circle,
          ),

          // Día actual
          todayDecoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),

          // Marcadores de eventos
          markerDecoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            shape: BoxShape.circle,
          ),

          // Texto de días
          defaultTextStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          selectedTextStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          todayTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBlue,
          ),

          // Marcadores
          markerSize: 8,
          markerMargin: const EdgeInsets.symmetric(horizontal: 0.3),
        ),

        // Header del calendario
        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextFormatter: (date, locale) {
            return _getMonthYear(date);
          },
          titleTextStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          leftChevronIcon: const Icon(Icons.chevron_left),
          rightChevronIcon: const Icon(Icons.chevron_right),
          headerPadding: const EdgeInsets.symmetric(vertical: 8),
        ),

        // Días de la semana
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.w500,
          ),
          weekendStyle: TextStyle(
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.w500,
          ),
        ),

        // Callbacks
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDate = selectedDay;
            _focusedDate = focusedDay;
          });
        },

        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDate = focusedDay;
          });
        },

        // Marcadores personalizados
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isNotEmpty) {
              return Positioned(
                bottom: 1,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryBlue,
                  ),
                  width: 8,
                  height: 8,
                  child: Center(
                    child: Text(
                      '${events.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 6,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildActivitiesList() {
    return FutureBuilder<List<dynamic>>(
      future: _getAllActivitiesForSelectedDate(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final activities = snapshot.data ?? [];

        if (activities.isEmpty) {
          return _buildEmptyDayState();
        }

        return ListView.builder(
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            if (activity is Frap) {
              return _buildFrapCard(activity);
            } else if (activity is Appointment) {
              return _buildAppointmentCard(activity);
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Future<List<dynamic>> _getAllActivitiesForSelectedDate() async {
    final List<dynamic> activities = [];

    try {
      // Agregar registros FRAP
      final frapBox = Hive.box<Frap>('fraps');
      final frapEvents =
          frapBox.values
              .where((frap) => _isSameDay(frap.createdAt, _selectedDate))
              .toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      activities.addAll(frapEvents);

      // Agregar citas
      final appointments = await _appointmentService.getAppointmentsByDate(
        _selectedDate,
      );
      activities.addAll(appointments);

      // Ordenar por hora
      activities.sort((a, b) {
        DateTime aTime = a is Frap ? a.createdAt : (a as Appointment).dateTime;
        DateTime bTime = b is Frap ? b.createdAt : (b as Appointment).dateTime;
        return aTime.compareTo(bTime);
      });
    } catch (e) {
      print('Error obteniendo actividades: $e');
    }

    return activities;
  }

  Widget _buildFrapCard(Frap frap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue[600],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(
          'FRAP - ${frap.patient.name}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${frap.createdAt.hour.toString().padLeft(2, '0')}:${frap.createdAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${frap.patient.age} años • ${frap.patient.sex}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'view':
                _showFrapDetails(frap);
                break;
              case 'edit':
                // TODO: Navigate to edit
                break;
            }
          },
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility),
                      SizedBox(width: 8),
                      Text('Ver detalles'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
              ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange[200]!),
      ),
      child: ListTile(
        leading: Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.orange[600],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(
          'CITA - ${appointment.title}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${appointment.dateTime.hour.toString().padLeft(2, '0')}:${appointment.dateTime.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(appointment.status),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _capitalize(appointment.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  appointment.patientName,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'view':
                _showAppointmentDetails(appointment);
                break;
              case 'edit':
                _showEditAppointmentDialog(appointment);
                break;
              case 'delete':
                _deleteAppointment(appointment);
                break;
            }
          },
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility),
                      SizedBox(width: 8),
                      Text('Ver detalles'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Eliminar', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'programada':
        return Colors.blue;
      case 'confirmada':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      case 'completada':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  void _showAppointmentDetails(Appointment appointment) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Cita - ${appointment.title}'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('Título', appointment.title),
                  _buildDetailRow('Descripción', appointment.description),
                  _buildDetailRow(
                    'Fecha y hora',
                    _formatDateTime(appointment.dateTime),
                  ),
                  _buildDetailRow('Paciente', appointment.patientName),
                  if (appointment.patientPhone.isNotEmpty)
                    _buildDetailRow('Teléfono', appointment.patientPhone),
                  if (appointment.patientAddress.isNotEmpty)
                    _buildDetailRow('Dirección', appointment.patientAddress),
                  _buildDetailRow(
                    'Tipo',
                    _capitalize(appointment.appointmentType),
                  ),
                  _buildDetailRow('Estado', _capitalize(appointment.status)),
                  if (appointment.notes.isNotEmpty)
                    _buildDetailRow('Notas', appointment.notes),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  void _showEditAppointmentDialog(Appointment appointment) {
    showDialog(
      context: context,
      builder:
          (context) => AppointmentFormDialog(
            appointment: appointment,
            onSave: (updatedAppointment) async {
              try {
                await _appointmentService.updateAppointment(
                  id: appointment.id,
                  title: updatedAppointment.title,
                  description: updatedAppointment.description,
                  dateTime: updatedAppointment.dateTime,
                  patientName: updatedAppointment.patientName,
                  patientPhone: updatedAppointment.patientPhone,
                  patientAddress: updatedAppointment.patientAddress,
                  appointmentType: updatedAppointment.appointmentType,
                  status: updatedAppointment.status,
                  notes: updatedAppointment.notes,
                );
                setState(() {
                  // Refrescar la vista
                });
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al actualizar la cita: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
    );
  }

  void _deleteAppointment(Appointment appointment) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: Text(
              '¿Estás seguro de que quieres eliminar la cita "${appointment.title}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _appointmentService.deleteAppointment(appointment.id);
                    setState(() {
                      // Refrescar la vista
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cita eliminada correctamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al eliminar la cita: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final date =
        '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    final time =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  // Método para obtener todos los eventos (FRAP + Citas) para un día específico
  List<dynamic> _getAllEventsForDay(DateTime day) {
    final List<dynamic> events = [];

    try {
      // Agregar registros FRAP
      final frapBox = Hive.box<Frap>('fraps');
      final frapEvents =
          frapBox.values
              .where((frap) => _isSameDay(frap.createdAt, day))
              .toList();
      events.addAll(frapEvents);

      // Agregar citas
      _appointmentService.getAppointmentsByDate(day).then((appointments) {
        events.addAll(appointments);
      });
    } catch (e) {
      print('Error obteniendo eventos: $e');
    }

    return events;
  }

  Widget _buildEmptyDayState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hay actividades programadas',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'para ${_formatSelectedDate()}',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddAppointmentDialog,
            icon: const Icon(Icons.add),
            label: const Text('Programar Cita'),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _getMonthYear(DateTime date) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatSelectedDate() {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return '${_selectedDate.day} de ${months[_selectedDate.month - 1]} de ${_selectedDate.year}';
  }

  void _showAddAppointmentDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AppointmentFormDialog(
            initialDate: _selectedDate,
            onSave: (appointment) async {
              try {
                await _appointmentService.createAppointment(
                  title: appointment.title,
                  description: appointment.description,
                  dateTime: appointment.dateTime,
                  patientName: appointment.patientName,
                  patientPhone: appointment.patientPhone,
                  patientAddress: appointment.patientAddress,
                  appointmentType: appointment.appointmentType,
                  notes: appointment.notes,
                );
                setState(() {
                  // Refrescar la vista
                });
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al crear la cita: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
    );
  }

  void _showFrapDetails(Frap frap) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('FRAP - ${frap.patient.name}'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('Paciente', frap.patient.name),
                  _buildDetailRow('Edad', '${frap.patient.age} años'),
                  _buildDetailRow('Sexo', frap.patient.sex),
                  _buildDetailRow('Dirección', frap.patient.address),
                  const SizedBox(height: 16),
                  Text(
                    'Historia Clínica',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (frap.clinicalHistory.traumaCraneo)
                    _buildDetailRow(
                      'Trauma Cráneo',
                      frap.clinicalHistory.traumaCraneoEspecifique.isEmpty
                          ? 'Sí'
                          : frap.clinicalHistory.traumaCraneoEspecifique,
                    ),
                  if (frap.clinicalHistory.traumaTorax)
                    _buildDetailRow(
                      'Trauma Tórax',
                      frap.clinicalHistory.traumaToraxEspecifique.isEmpty
                          ? 'Sí'
                          : frap.clinicalHistory.traumaToraxEspecifique,
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Fecha y hora del registro:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${frap.createdAt.day}/${frap.createdAt.month}/${frap.createdAt.year} ${frap.createdAt.hour.toString().padLeft(2, '0')}:${frap.createdAt.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
