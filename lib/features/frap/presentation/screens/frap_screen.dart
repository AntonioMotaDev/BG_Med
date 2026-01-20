import 'package:bg_med/core/theme/app_theme.dart';
import 'package:bg_med/features/frap/presentation/providers/frap_data_provider.dart';
import 'package:bg_med/features/frap/presentation/providers/frap_unified_provider.dart';
import 'package:bg_med/core/services/frap_unified_service.dart';
import 'package:bg_med/features/frap/presentation/dialogs/patient_info_form_dialog.dart';
import 'package:bg_med/features/frap/presentation/dialogs/service_info_form_dialog.dart';
import 'package:bg_med/features/frap/presentation/dialogs/registry_info_form_dialog.dart';
import 'package:bg_med/features/frap/presentation/dialogs/management_form_dialog.dart';
import 'package:bg_med/features/frap/presentation/dialogs/gyneco_obstetric_form_dialog.dart';
import 'package:bg_med/features/frap/presentation/dialogs/pathological_history_form_dialog.dart';
import 'package:bg_med/features/frap/presentation/dialogs/clinical_history_form_dialog.dart';
import 'package:bg_med/features/frap/presentation/dialogs/medications_form_dialog.dart';
import 'package:bg_med/features/frap/presentation/dialogs/priority_justification_form_dialog.dart';
import 'package:bg_med/features/frap/presentation/dialogs/receiving_unit_form_dialog.dart';
import 'package:bg_med/features/frap/presentation/dialogs/physical_exam_form_dialog.dart';
import 'package:bg_med/features/frap/presentation/dialogs/attention_negative_form_dialog.dart';
import 'package:bg_med/features/frap/presentation/dialogs/patient_reception_form_dialog.dart';
import 'package:bg_med/features/frap/presentation/dialogs/injury_location_form_dialog.dart';
import 'package:bg_med/features/frap/presentation/dialogs/insumos_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FrapScreen extends ConsumerStatefulWidget {
  final UnifiedFrapRecord? editingRecord;

  const FrapScreen({super.key, this.editingRecord});

  @override
  ConsumerState<FrapScreen> createState() => _FrapScreenState();
}

class _FrapScreenState extends ConsumerState<FrapScreen> {
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Inicializar el servicio de sincronización automática
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Si estamos editando, cargar los datos del registro
      if (widget.editingRecord != null) {
        _loadRecordForEditing();
      }
    });
  }

  void _loadRecordForEditing() {
    final record = widget.editingRecord!;
    final detailedInfo = record.getDetailedInfo();

    // Crear FrapData desde el registro existente
    final frapData = FrapData(
      serviceInfo: Map<String, dynamic>.from(detailedInfo['serviceInfo'] ?? {}),
      registryInfo: Map<String, dynamic>.from(
        detailedInfo['registryInfo'] ?? {},
      ),
      patientInfo: Map<String, dynamic>.from(detailedInfo['patientInfo'] ?? {}),
      management: Map<String, dynamic>.from(detailedInfo['management'] ?? {}),
      medications: Map<String, dynamic>.from(detailedInfo['medications'] ?? {}),
      gynecoObstetric: Map<String, dynamic>.from(
        detailedInfo['gynecoObstetric'] ?? {},
      ),
      attentionNegative: Map<String, dynamic>.from(
        detailedInfo['attentionNegative'] ?? {},
      ),
      pathologicalHistory: Map<String, dynamic>.from(
        detailedInfo['pathologicalHistory'] ?? {},
      ),
      clinicalHistory: Map<String, dynamic>.from(
        detailedInfo['clinicalHistory'] ?? {},
      ),
      physicalExam: Map<String, dynamic>.from(
        detailedInfo['physicalExam'] ?? {},
      ),
      priorityJustification: Map<String, dynamic>.from(
        detailedInfo['priorityJustification'] ?? {},
      ),
      injuryLocation: Map<String, dynamic>.from(
        detailedInfo['injuryLocation'] ?? {},
      ),
      receivingUnit: Map<String, dynamic>.from(
        detailedInfo['receivingUnit'] ?? {},
      ),
      patientReception: Map<String, dynamic>.from(
        detailedInfo['patientReception'] ?? {},
      ),
      insumos:
          (detailedInfo['insumos'] as List?)
              ?.map((i) => Map<String, dynamic>.from(i as Map))
              .toList() ??
          [],
    );

    // Cargar los datos en el provider
    ref.read(frapDataProvider.notifier).setAllData(frapData);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Editando registro de ${record.patientName}'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final frapData = ref.watch(frapDataProvider);
    final isEditing = widget.editingRecord != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? 'Editar Registro FRAP'
              : 'Registro de Atención Prehospitalaria',
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          // Botón de sincronización manual
          IconButton(
            icon:
                _isSaving
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                    : const Icon(Icons.sync),
            onPressed:
                _isSaving
                    ? null
                    : () async {
                      setState(() {
                        _isSaving = true;
                      });

                      try {
                        final result =
                            await ref
                                .read(unifiedFrapProvider.notifier)
                                .syncRecordsWithResult();

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result.message),
                              backgroundColor:
                                  result.success ? Colors.green : Colors.orange,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error al sincronizar: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isSaving = false;
                          });
                        }
                      }
                    },
            tooltip: 'Sincronizar ahora',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información de estado de sincronización
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Los datos se guardarán tanto localmente como en la nube cuando haya conexión.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.8,
              children: [
                // Información del Paciente
                _buildSectionCard(
                  title: 'INFORMACIÓN DEL PACIENTE',
                  icon: Icons.person,
                  filledFields: frapData.getFilledFieldsCount('patient_info'),
                  totalFields: 14,
                  onTap: () => _openPatientInfoDialog(),
                ),

                // Información del Servicio
                _buildSectionCard(
                  title: 'INFORMACIÓN DEL SERVICIO',
                  icon: Icons.local_hospital,
                  filledFields: frapData.getFilledFieldsCount('service_info'),
                  totalFields: 8,
                  onTap: () => _openServiceInfoDialog(),
                ),

                // Información del Registro
                _buildSectionCard(
                  title: 'INFORMACIÓN DEL REGISTRO',
                  icon: Icons.assignment,
                  filledFields: frapData.getFilledFieldsCount('registry_info'),
                  totalFields: 5,
                  onTap: () => _openRegistryInfoDialog(),
                ),

                // Manejo
                _buildSectionCard(
                  title: 'MANEJO',
                  icon: Icons.medical_services,
                  filledFields: frapData.getFilledFieldsCount('management'),
                  totalFields: 12,
                  onTap: () => _openManagementDialog(),
                ),

                // Antecedentes Patológicos (solo para urgencias clínicas)
                if (_shouldShowSection('pathological_history'))
                  _buildSectionCard(
                    title: 'ANTECEDENTES PATOLÓGICOS',
                    icon: Icons.medical_services,
                    filledFields: frapData.getFilledFieldsCount(
                      'pathological_history',
                    ),
                    totalFields: 5,
                    onTap: () => _openPathologicalHistoryDialog(),
                    backgroundColor: _getSectionBackgroundColor(
                      'pathological_history',
                    ),
                    textColor: _getSectionTextColor('pathological_history'),
                    statusMessage: _getSectionStatusMessage(
                      'pathological_history',
                    ),
                  ),

                // Antecedentes Clínicos (solo para urgencias de trauma)
                if (_shouldShowSection('clinical_history'))
                  _buildSectionCard(
                    title: 'ANTECEDENTES CLÍNICOS',
                    icon: Icons.medical_services,
                    filledFields: frapData.getFilledFieldsCount(
                      'clinical_history',
                    ),
                    totalFields: 5,
                    onTap: () => _openClinicalHistoryDialog(),
                    backgroundColor: _getSectionBackgroundColor(
                      'clinical_history',
                    ),
                    textColor: _getSectionTextColor('clinical_history'),
                    statusMessage: _getSectionStatusMessage('clinical_history'),
                  ),

                // Medicamentos
                _buildSectionCard(
                  title: 'MEDICAMENTOS',
                  icon: Icons.medication,
                  filledFields: frapData.getFilledFieldsCount('medications'),
                  totalFields: 1,
                  onTap: () => _openMedicationsDialog(),
                ),

                // Gineco-Obstétrico
                _buildSectionCard(
                  title: 'GINECO-OBSTÉTRICAS',
                  icon: Icons.pregnant_woman,
                  filledFields: frapData.getFilledFieldsCount(
                    'gyneco_obstetric',
                  ),
                  totalFields: 10,
                  onTap: () => _openGynecoObstetricDialog(),
                ),

                // Examen Físico
                _buildSectionCard(
                  title: 'EXPLORACIÓN FÍSICA',
                  icon: Icons.health_and_safety,
                  filledFields: frapData.getFilledFieldsCount('physical_exam'),
                  totalFields: 12,
                  onTap: () => _openPhysicalExamDialog(),
                ),

                // Negativa de Atención
                _buildSectionCard(
                  title: 'NEGATIVA DE ATENCIÓN',
                  icon: Icons.cancel,
                  filledFields: frapData.getFilledFieldsCount(
                    'attention_negative',
                  ),
                  totalFields: 4,
                  onTap: () => _openAttentionNegativeDialog(),
                ),

                // Justificación de Prioridad
                _buildSectionCard(
                  title: 'JUSTIFICACIÓN DE PRIORIDAD',
                  icon: Icons.priority_high,
                  filledFields: frapData.getFilledFieldsCount(
                    'priority_justification',
                  ),
                  totalFields: 7,
                  onTap: () => _openPriorityJustificationDialog(),
                ),

                // Unidad Receptora
                _buildSectionCard(
                  title: 'UNIDAD MEDICA RECEPTORA',
                  icon: Icons.local_hospital,
                  filledFields: frapData.getFilledFieldsCount('receiving_unit'),
                  totalFields: 8,
                  onTap: () => _openReceivingUnitDialog(),
                ),

                // Localización de Lesiones
                _buildSectionCard(
                  title: 'LOCALIZACIÓN DE LESIONES',
                  icon: Icons.my_location,
                  filledFields: frapData.getFilledFieldsCount(
                    'injury_location',
                  ),
                  totalFields: 2,
                  onTap: () => _openInjuryLocationDialog(),
                ),

                // Recepción del Paciente
                _buildSectionCard(
                  title: 'RECEPCIÓN DEL PACIENTE',
                  icon: Icons.how_to_reg,
                  filledFields: frapData.getFilledFieldsCount(
                    'patient_reception',
                  ),
                  totalFields: 6,
                  onTap: () => _openPatientReceptionDialog(),
                ),

                // Insumos (Nuevo)
                _buildSectionCard(
                  title: 'INSUMOS',
                  icon: Icons.inventory,
                  filledFields: frapData.getFilledFieldsCount('insumos'),
                  totalFields: 2,
                  onTap: () => _openInsumosDialog(),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Indicador de estado de conexión
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.wifi, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Conectado - Se guardará en la nube',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Botón de guardado único
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveRecord,
                icon:
                    _isSaving
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Icon(Icons.cloud_upload),
                label: Text(
                  _isSaving
                      ? (isEditing ? 'Actualizando...' : 'Guardando...')
                      : (isEditing
                          ? 'Actualizar Registro'
                          : 'Guardar Registro'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _isSaving ? null : _showClearConfirmationDialog,
                icon: const Icon(Icons.delete_sweep_outlined),
                label: const Text('Limpiar Formulario'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required int filledFields,
    required int totalFields,
    required VoidCallback onTap,
    Color? backgroundColor,
    Color? textColor,
    String? statusMessage,
  }) {
    final isComplete = filledFields == totalFields;
    final isEmpty = filledFields == 0;
    final isDisabled =
        statusMessage != null && statusMessage.contains('No aplica');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isDisabled
                  ? Colors.grey[300]!
                  : isComplete
                  ? Colors.green[300]!
                  : Colors.grey[300]!,
          width: isComplete ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isDisabled
                            ? Colors.grey[200]!
                            : isComplete
                            ? Colors.green[100]!
                            : AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color:
                        isDisabled
                            ? Colors.grey[400]!
                            : isComplete
                            ? Colors.green[600]!
                            : AppTheme.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color:
                              textColor ??
                              (isDisabled ? Colors.grey[500] : Colors.black87),
                        ),
                      ),
                      if (isDisabled) ...[
                        const SizedBox(height: 4),
                        Text(
                          statusMessage,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  isDisabled
                      ? Icons.lock
                      : isComplete
                      ? Icons.check_circle
                      : isEmpty
                      ? Icons.radio_button_unchecked
                      : Icons.edit,
                  color:
                      isDisabled
                          ? Colors.grey[400]
                          : isComplete
                          ? Colors.green
                          : isEmpty
                          ? Colors.grey[400]
                          : AppTheme.primaryBlue,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openServiceInfoDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => ServiceInfoFormDialog(
            onSave: (data) {
              ref
                  .read(frapDataProvider.notifier)
                  .updateSectionData('service_info', data);
            },
            initialData: ref.read(frapDataProvider).serviceInfo,
          ),
    );
  }

  void _openRegistryInfoDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => RegistryInfoFormDialog(
            onSave: (data) {
              ref
                  .read(frapDataProvider.notifier)
                  .updateSectionData('registry_info', data);
            },
            initialData: ref.read(frapDataProvider).registryInfo,
          ),
    );
  }

  void _openPatientInfoDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => PatientInfoFormDialog(
            onSave: (data) {
              ref
                  .read(frapDataProvider.notifier)
                  .updateSectionData('patient_info', data);
            },
            initialData: ref.read(frapDataProvider).patientInfo,
          ),
    );
  }

  void _openManagementDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => ManagementFormDialog(
            onSave: (data) {
              ref
                  .read(frapDataProvider.notifier)
                  .updateSectionData('management', data);
            },
            initialData: ref.read(frapDataProvider).management,
          ),
    );
  }

  void _openMedicationsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => MedicationsFormDialog(
            onSave: (data) {
              ref
                  .read(frapDataProvider.notifier)
                  .updateSectionData('medications', data);
            },
            initialData: ref.read(frapDataProvider).medications,
          ),
    );
  }

  void _openGynecoObstetricDialog() {
    final frapData = ref.read(frapDataProvider);
    final patientSex = frapData.patientInfo['sex'] as String?;

    // Verificar si el paciente es de sexo femenino
    if (patientSex == null || patientSex.isEmpty) {
      _showInfoDialog(
        'Información requerida',
        'Primero debe completar la información del paciente para acceder a esta sección.',
      );
      return;
    }

    if (patientSex != 'Femenino') {
      _showInfoDialog(
        'Sección no disponible',
        'Esta sección solo está disponible para pacientes de sexo femenino.',
      );
      return;
    }

    // Si es femenino, mostrar el formulario
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => GynecoObstetricFormDialog(
            onSave: (data) {
              ref
                  .read(frapDataProvider.notifier)
                  .updateSectionData('gyneco_obstetric', data);
            },
            initialData: ref.read(frapDataProvider).gynecoObstetric,
          ),
    );
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendido'),
              ),
            ],
          ),
    );
  }

  void _openAttentionNegativeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AttentionNegativeFormDialog(
            onSave: (data) {
              ref
                  .read(frapDataProvider.notifier)
                  .updateSectionData('attention_negative', data);
            },
            initialData: ref.read(frapDataProvider).attentionNegative,
          ),
    );
  }

  void _openPathologicalHistoryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => PathologicalHistoryFormDialog(
            onSave: (data) {
              ref
                  .read(frapDataProvider.notifier)
                  .updateSectionData('pathological_history', data);
            },
            initialData: ref.read(frapDataProvider).pathologicalHistory,
          ),
    );
  }

  void _openClinicalHistoryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => ClinicalHistoryFormDialog(
            onSave: (data) {
              ref
                  .read(frapDataProvider.notifier)
                  .updateSectionData('clinical_history', data);
            },
            initialData: ref.read(frapDataProvider).clinicalHistory,
          ),
    );
  }

  void _openPhysicalExamDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => PhysicalExamFormDialog(
            onSave: (data) {
              ref
                  .read(frapDataProvider.notifier)
                  .updateSectionData('physical_exam', data);
            },
            initialData: ref.read(frapDataProvider).physicalExam,
          ),
    );
  }

  void _openPriorityJustificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => PriorityJustificationFormDialog(
            onSave: (data) {
              ref
                  .read(frapDataProvider.notifier)
                  .updateSectionData('priority_justification', data);
            },
            initialData: ref.read(frapDataProvider).priorityJustification,
          ),
    );
  }

  void _openInjuryLocationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => InjuryLocationFormDialog(
            onSave: (data) {
              ref
                  .read(frapDataProvider.notifier)
                  .updateSectionData('injury_location', data);
            },
            initialData: ref.read(frapDataProvider).injuryLocation,
          ),
    );
  }

  void _openReceivingUnitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => ReceivingUnitFormDialog(
            onSave: (data) {
              ref
                  .read(frapDataProvider.notifier)
                  .updateSectionData('receiving_unit', data);
            },
            initialData: ref.read(frapDataProvider).receivingUnit,
          ),
    );
  }

  void _openPatientReceptionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => PatientReceptionFormDialog(
            onSave: (data) {
              ref
                  .read(frapDataProvider.notifier)
                  .updateSectionData('patient_reception', data);
            },
            initialData: ref.read(frapDataProvider).patientReception,
          ),
    );
  }

  void _openInsumosDialog() {
    showDialog(
      context: context,
      builder:
          (context) => InsumosFormDialog(
            onSave: (data) {
              ref
                  .read(frapDataProvider.notifier)
                  .updateSectionData('insumos', data);
            },
            initialData:
                ref.read(frapDataProvider).insumos.isNotEmpty
                    ? {'insumosList': ref.read(frapDataProvider).insumos}
                    : null,
          ),
    );
  }

  // Función para determinar si una sección debe mostrarse según el tipo de urgencia
  bool _shouldShowSection(String sectionName) {
    final serviceInfo = ref.read(frapDataProvider).serviceInfo;
    final tipoUrgencia = serviceInfo['tipoUrgencia'] ?? '';

    // Si no hay tipo de urgencia seleccionado, mostrar todas las secciones
    if (tipoUrgencia.isEmpty) return true;

    switch (sectionName) {
      case 'pathological_history':
        // Antecedentes patológicos solo para urgencias clínicas
        return tipoUrgencia == 'Clínico';
      case 'clinical_history':
        // Antecedentes clínicos solo para urgencias de trauma
        return tipoUrgencia == 'Trauma';
      default:
        // Otras secciones se muestran siempre
        return true;
    }
  }

  // Función para obtener el color de fondo según el tipo de urgencia
  Color _getSectionBackgroundColor(String sectionName) {
    final serviceInfo = ref.read(frapDataProvider).serviceInfo;
    final tipoUrgencia = serviceInfo['tipoUrgencia'] ?? '';

    if (tipoUrgencia.isEmpty) return Colors.white;

    switch (sectionName) {
      case 'pathological_history':
        return tipoUrgencia == 'Clínico'
            ? Colors.green[50]!
            : Colors.grey[100]!;
      case 'clinical_history':
        return tipoUrgencia == 'Trauma' ? Colors.red[50]! : Colors.grey[100]!;
      default:
        return Colors.white;
    }
  }

  // Función para obtener el color del texto según el tipo de urgencia
  Color _getSectionTextColor(String sectionName) {
    final serviceInfo = ref.read(frapDataProvider).serviceInfo;
    final tipoUrgencia = serviceInfo['tipoUrgencia'] ?? '';

    if (tipoUrgencia.isEmpty) return Colors.black87;

    switch (sectionName) {
      case 'pathological_history':
        return tipoUrgencia == 'Clínico'
            ? Colors.green[700]!
            : Colors.grey[500]!;
      case 'clinical_history':
        return tipoUrgencia == 'Trauma' ? Colors.red[700]! : Colors.grey[500]!;
      default:
        return Colors.black87;
    }
  }

  // Función para obtener el mensaje de estado según el tipo de urgencia
  String _getSectionStatusMessage(String sectionName) {
    final serviceInfo = ref.read(frapDataProvider).serviceInfo;
    final tipoUrgencia = serviceInfo['tipoUrgencia'] ?? '';

    if (tipoUrgencia.isEmpty) return '';

    switch (sectionName) {
      case 'pathological_history':
        return tipoUrgencia == 'Clínico'
            ? 'Requerido para urgencias clínicas'
            : 'No aplica para urgencias de trauma';
      case 'clinical_history':
        return tipoUrgencia == 'Trauma'
            ? 'Requerido para urgencias de trauma'
            : 'No aplica para urgencias clínicas';
      default:
        return '';
    }
  }

  bool _validateForm() {
    final frapData = ref.read(frapDataProvider);

    // Validar que se hayan completado los campos mínimos requeridos
    if (frapData.patientInfo.isEmpty) {
      _showErrorDialog(
        'Error de validación',
        'Debe completar al menos la información del paciente para guardar el registro.',
      );
      return false;
    }

    return true;
  }

  Future<void> _saveRecord() async {
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final frapData = ref.read(frapDataProvider);
      final isEditing = widget.editingRecord != null;

      if (isEditing) {
        // Modo edición: actualizar registro existente
        final originalRecord = widget.editingRecord!;

        final result = await ref
            .read(unifiedFrapProvider.notifier)
            .updateRecord(originalRecord, frapData);

        if (!mounted) return;

        if (result.success || result.updatedLocally) {
          _showUpdateSuccessDialog(result);
          // Regresar a la pantalla anterior
          Navigator.of(context).pop();
        } else {
          _showErrorDialog(
            'Error al Actualizar',
            result.message.isNotEmpty
                ? result.message
                : 'No se pudo actualizar el registro',
          );
        }
      } else {
        // Modo creación: guardar nuevo registro
        final result = await ref
            .read(unifiedFrapProvider.notifier)
            .saveRecord(frapData);

        if (!mounted) return;

        if (result.success) {
          // Mostrar diálogo de éxito
          _showSuccessDialog(result);

          // Limpiar datos del formulario
          ref.read(frapDataProvider.notifier).clearAllData();
        } else {
          // Mostrar error
          _showErrorDialog(
            'Error al Guardar',
            result.message.isNotEmpty
                ? result.message
                : 'No se pudo guardar el registro',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error Inesperado', 'Ocurrió un error inesperado: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showUpdateSuccessDialog(UnifiedUpdateResult result) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: result.success ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                const Text('Registro Actualizado'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.message),
                if (result.requiresSync) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sync,
                          color: Colors.orange.shade700,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Se sincronizará con la nube cuando haya conexión.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Aceptar'),
              ),
            ],
          ),
    );
  }

  void _showSuccessDialog(UnifiedSaveResult result) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color:
                      result.savedToCloud
                          ? AppTheme.primaryBlue
                          : AppTheme.primaryGreen,
                ),
                const SizedBox(width: 8),
                const Text('Registro Guardado'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.message),
                const SizedBox(height: 16),
                if (result.savedLocally && !result.savedToCloud)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange.shade700,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Guardado localmente. Se sincronizará cuando haya conexión.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                const Text('¿Qué desea hacer a continuación?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Limpiar datos del formulario
                  ref.read(frapDataProvider.notifier).clearAllData();
                },
                child: const Text('Nuevo Registro'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navegar a la vista de registros
                  Navigator.pushNamed(context, '/frap-records');
                },
                child: const Text('Ver Registros'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Salir del formulario
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      result.savedToCloud
                          ? AppTheme.primaryBlue
                          : AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Salir'),
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendido'),
              ),
            ],
          ),
    );
  }

  void _showClearConfirmationDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar Limpieza'),
            content: const Text(
              '¿Estás seguro de que quieres limpiar todos los campos del formulario? Esta acción no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pop(); // Cerrar el diálogo de confirmación
                  ref.read(frapDataProvider.notifier).clearAllData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Formulario limpiado.'),
                      duration: Duration(seconds: 3),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Limpiar'),
              ),
            ],
          ),
    );
  }
}
