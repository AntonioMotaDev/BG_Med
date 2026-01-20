import 'package:bg_med/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class MedicationsFormDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  final Map<String, dynamic>? initialData;

  const MedicationsFormDialog({
    super.key,
    required this.onSave,
    this.initialData,
  });

  @override
  State<MedicationsFormDialog> createState() => _MedicationsFormDialogState();
}

class _MedicationsFormDialogState extends State<MedicationsFormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Lista de medicamentos
  List<MedicationRow> _medications = [];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.initialData != null) {
      final data = widget.initialData!;

      // Si hay medicamentos guardados en formato de tabla
      if (data['medicationsList'] != null && data['medicationsList'] is List) {
        final List<dynamic> medicationsList = data['medicationsList'];
        _medications =
            medicationsList.map((med) {
              return MedicationRow(
                medicamento: med['medicamento'] ?? '',
                dosis: med['dosis'] ?? '',
                viaAdministracion: med['viaAdministracion'] ?? '',
                hora: med['hora'] ?? '',
                medicoIndico: med['medicoIndico'] ?? '',
              );
            }).toList();
      } else if (data['medications'] != null &&
          data['medications'].toString().isNotEmpty) {
        // Migrar de formato texto libre a tabla
        final String medicationsText = data['medications'];
        _medications = _parseTextToMedications(medicationsText);
      }
    }

    // Si no hay medicamentos, agregar una fila vacía
    if (_medications.isEmpty) {
      _addMedicationRow();
    }
  }

  List<MedicationRow> _parseTextToMedications(String text) {
    final List<MedicationRow> medications = [];
    final lines = text.split('\n');

    for (final line in lines) {
      if (line.trim().isNotEmpty) {
        // Intentar parsear líneas con formato común
        final parts = line.split(' - ');
        if (parts.length >= 3) {
          medications.add(
            MedicationRow(
              medicamento: parts[0].trim(),
              dosis: parts.length > 1 ? parts[1].trim() : '',
              viaAdministracion: parts.length > 2 ? parts[2].trim() : '',
              hora: parts.length > 3 ? parts[3].trim() : '',
              medicoIndico: parts.length > 4 ? parts[4].trim() : '',
            ),
          );
        } else {
          // Si no se puede parsear, agregar como medicamento general
          medications.add(
            MedicationRow(
              medicamento: line.trim(),
              dosis: '',
              viaAdministracion: '',
              hora: '',
              medicoIndico: '',
            ),
          );
        }
      }
    }

    return medications;
  }

  void _addMedicationRow() {
    setState(() {
      _medications.add(const MedicationRow());
    });
  }

  void _removeMedicationRow(int index) {
    setState(() {
      _medications.removeAt(index);
      // Asegurar que siempre haya al menos una fila
      if (_medications.isEmpty) {
        _addMedicationRow();
      }
    });
  }

  void _updateMedicationRow(int index, MedicationRow medication) {
    setState(() {
      _medications[index] = medication;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.medication, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'MEDICAMENTOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Form content
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título y descripción
                      const Text(
                        'Registro de Medicamentos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Registre todos los medicamentos administrados al paciente durante la atención prehospitalaria.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tabla de medicamentos
                      _buildMedicationsTable(),

                      const SizedBox(height: 16),

                      // Botón para agregar medicamento
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _addMedicationRow,
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar Medicamento'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Guía de formato
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue[200]!,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Información importante:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '• Todos los campos son obligatorios para cada medicamento\n'
                              '• Use el selector de hora (reloj) para elegir la hora de administración\n'
                              '• Escriba el nombre completo del médico que indicó el medicamento\n'
                              '• Puede agregar o eliminar medicamentos según sea necesario\n'
                              '• Debe completar al menos un medicamento con todos sus datos',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue[800],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveForm,
                    icon:
                        _isLoading
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Icon(Icons.save),
                    label: Text(
                      _isLoading ? 'Guardando...' : 'Guardar Sección',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationsTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de la tabla
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withAlpha(25),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            border: Border.all(color: AppTheme.primaryBlue.withAlpha(77)),
          ),
          child: const Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Medicamento',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Dosis',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Vía',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Hora',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Médico',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 40), // Espacio para botón eliminar
            ],
          ),
        ),

        // Filas de medicamentos
        ...List.generate(_medications.length, (index) {
          return _buildMedicationRow(index);
        }),
      ],
    );
  }

  Widget _buildMedicationRow(int index) {
    final medication = _medications[index];
    final isLastRow = index == _medications.length - 1;

    return Container(
      margin: EdgeInsets.only(bottom: isLastRow ? 0 : 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Medicamento
            Expanded(
              flex: 2,
              child: TextFormField(
                initialValue: medication.medicamento,
                decoration: const InputDecoration(
                  hintText: 'Ej: Paracetamol',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                style: const TextStyle(fontSize: 12),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Requerido';
                  }
                  return null;
                },
                onChanged: (value) {
                  _updateMedicationRow(
                    index,
                    medication.copyWith(medicamento: value),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),

            // Dosis
            Expanded(
              child: TextFormField(
                initialValue: medication.dosis,
                decoration: const InputDecoration(
                  hintText: '500mg',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                style: const TextStyle(fontSize: 12),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Requerido';
                  }
                  return null;
                },
                onChanged: (value) {
                  _updateMedicationRow(
                    index,
                    medication.copyWith(dosis: value),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),

            // Vía de administración
            Expanded(
              child: TextFormField(
                initialValue: medication.viaAdministracion,
                decoration: const InputDecoration(
                  hintText: 'Oral',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                style: const TextStyle(fontSize: 12),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Requerido';
                  }
                  return null;
                },
                onChanged: (value) {
                  _updateMedicationRow(
                    index,
                    medication.copyWith(viaAdministracion: value),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),

            // Hora mejorada
            Expanded(flex: 2, child: _buildTimeField(index, medication)),
            const SizedBox(width: 8),

            // Médico que indicó
            Expanded(
              flex: 2,
              child: TextFormField(
                initialValue: medication.medicoIndico,
                decoration: const InputDecoration(
                  hintText: 'Ej: Dr. García',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                style: const TextStyle(fontSize: 12),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Requerido';
                  }
                  return null;
                },
                onChanged: (value) {
                  _updateMedicationRow(
                    index,
                    medication.copyWith(medicoIndico: value),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),

            // Botón eliminar
            if (_medications.length > 1)
              IconButton(
                onPressed: () => _removeMedicationRow(index),
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              )
            else
              const SizedBox(width: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeField(int index, MedicationRow medication) {
    return InkWell(
      onTap: () => _selectTime(context, index, medication),
      child: InputDecorator(
        decoration: InputDecoration(
          hintText: 'HH:MM',
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          suffixIcon: const Icon(Icons.access_time, size: 16),
          errorText: medication.hora.isEmpty ? 'Requerido' : null,
          errorStyle: const TextStyle(fontSize: 10),
        ),
        child: Text(
          medication.hora.isEmpty ? '' : medication.hora,
          style: TextStyle(
            fontSize: 12,
            color: medication.hora.isEmpty ? Colors.grey : Colors.black87,
          ),
        ),
      ),
    );
  }

  Future<void> _selectTime(
    BuildContext context,
    int index,
    MedicationRow medication,
  ) async {
    // Parsear hora actual si existe
    TimeOfDay initialTime = TimeOfDay.now();
    if (medication.hora.isNotEmpty) {
      final parts = medication.hora.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          initialTime = TimeOfDay(hour: hour, minute: minute);
        }
      }
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedTime = _formatTimeOfDay(picked);
      _updateMedicationRow(index, medication.copyWith(hora: formattedTime));
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Método para normalizar formato de hora
  String _normalizeTimeFormat(String time) {
    if (time.isEmpty) return '';

    try {
      final parts = time.split(':');
      if (parts.length != 2) return time;

      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);

      if (hour == null || minute == null) return time;
      if (hour < 0 || hour > 23) return time;
      if (minute < 0 || minute > 59) return time;

      // Normalizar a formato HH:MM
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return time;
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor complete todos los campos obligatorios'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validar que todos los medicamentos tengan hora
    List<String> medicationsWithoutTime = [];
    for (int i = 0; i < _medications.length; i++) {
      final med = _medications[i];
      if (med.medicamento.isNotEmpty && med.hora.isEmpty) {
        medicationsWithoutTime.add('Medicamento ${i + 1}');
      }
    }

    if (medicationsWithoutTime.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Complete la hora para: ${medicationsWithoutTime.join(", ")}',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validar que al menos un medicamento tenga datos completos
    bool hasValidMedication = false;
    for (final medication in _medications) {
      if (medication.medicamento.isNotEmpty &&
          medication.dosis.isNotEmpty &&
          medication.viaAdministracion.isNotEmpty &&
          medication.hora.isNotEmpty &&
          medication.medicoIndico.isNotEmpty) {
        hasValidMedication = true;
        break;
      }
    }

    if (!hasValidMedication) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debe completar al menos un medicamento con todos sus datos',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Filtrar y validar medicamentos con datos completos
      final validMedications =
          _medications.where((med) {
            return med.medicamento.isNotEmpty &&
                med.dosis.isNotEmpty &&
                med.viaAdministracion.isNotEmpty &&
                med.hora.isNotEmpty &&
                med.medicoIndico.isNotEmpty;
          }).toList();

      // Normalizar y validar formato de hora
      final normalizedMedications =
          validMedications.map((med) {
            final normalizedTime = _normalizeTimeFormat(med.hora);
            if (normalizedTime.isEmpty || normalizedTime == med.hora) {
              return med;
            }
            return med.copyWith(hora: normalizedTime);
          }).toList();

      final formData = {
        'medicationsList':
            normalizedMedications.map((med) {
              return {
                'medicamento': med.medicamento.trim(),
                'dosis': med.dosis.trim(),
                'viaAdministracion': med.viaAdministracion.trim(),
                'hora': med.hora,
                'medicoIndico': med.medicoIndico.trim(),
                'medicoOtro':
                    '', // Campo obsoleto, se mantiene para compatibilidad
              };
            }).toList(),
        'medications': normalizedMedications
            .map((med) {
              return '${med.medicamento.trim()} - ${med.dosis.trim()} - ${med.viaAdministracion.trim()} - ${med.hora} - ${med.medicoIndico.trim()}';
            })
            .join('\n'),
        'totalMedications': normalizedMedications.length,
        'timestamp': DateTime.now().toIso8601String(),
      };

      widget.onSave(formData);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  '${normalizedMedications.length} medicamento(s) guardado(s) correctamente',
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error al guardar: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

// Clase para representar una fila de medicamento
class MedicationRow {
  final String medicamento;
  final String dosis;
  final String viaAdministracion;
  final String hora;
  final String medicoIndico;

  const MedicationRow({
    this.medicamento = '',
    this.dosis = '',
    this.viaAdministracion = '',
    this.hora = '',
    this.medicoIndico = '',
  });

  MedicationRow copyWith({
    String? medicamento,
    String? dosis,
    String? viaAdministracion,
    String? hora,
    String? medicoIndico,
  }) {
    return MedicationRow(
      medicamento: medicamento ?? this.medicamento,
      dosis: dosis ?? this.dosis,
      viaAdministracion: viaAdministracion ?? this.viaAdministracion,
      hora: hora ?? this.hora,
      medicoIndico: medicoIndico ?? this.medicoIndico,
    );
  }
}
