import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bg_med/core/services/frap_unified_service.dart';
import 'package:bg_med/features/frap/presentation/screens/pdf_preview_screen.dart';
import 'package:bg_med/features/frap/presentation/screens/frap_screen.dart';
import 'package:bg_med/core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:bg_med/features/frap/presentation/widgets/injury_location_display_widget.dart';
import 'dart:typed_data';
import 'package:bg_med/features/frap/presentation/providers/frap_unified_provider.dart';

// Clase de configuración para secciones
class SectionConfig {
  final String key;
  final String title;
  final IconData icon;
  final Color color;
  final Map<String, String> fieldMappings;
  final Map<String, dynamic> fallbacks;
  final Map<String, Map<String, dynamic>> specialFields;
  final Map<String, String> booleanFields;
  final Map<String, Map<String, dynamic>> conditionalFields;
  final List<String> vitalSigns;

  const SectionConfig({
    required this.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.fieldMappings,
    this.fallbacks = const {},
    this.specialFields = const {},
    this.booleanFields = const {},
    this.conditionalFields = const {},
    this.vitalSigns = const [],
  });
}

class FrapRecordDetailsScreen extends ConsumerStatefulWidget {
  final UnifiedFrapRecord record;

  const FrapRecordDetailsScreen({super.key, required this.record});

  @override
  ConsumerState<FrapRecordDetailsScreen> createState() =>
      _FrapRecordDetailsScreenState();
}

class _FrapRecordDetailsScreenState
    extends ConsumerState<FrapRecordDetailsScreen> {
  late Map<String, dynamic> _detailedInfo;
  bool _isLoading = true;
  bool _isCheckingEditPermission = true;
  bool _canEditRecord = false;
  String? _editBlockedReason;

  // Configuración centralizada de secciones
  late final List<SectionConfig> _sectionConfigs;

  @override
  void initState() {
    super.initState();
    _initializeSectionConfigs();
    _loadDetailedInfo();
    _refreshEditPermission();
  }

  Future<void> _refreshEditPermission() async {
    setState(() {
      _isCheckingEditPermission = true;
    });

    final notifier = ref.read(unifiedFrapProvider.notifier);
    final permission = await notifier.canEditRecord(widget.record);
    if (!mounted) return;

    setState(() {
      _canEditRecord = permission.canEdit;
      _editBlockedReason = permission.message;
      _isCheckingEditPermission = false;
    });
  }

  void _initializeSectionConfigs() {
    _sectionConfigs = [
      // Información del servicio
      const SectionConfig(
        key: 'serviceInfo',
        title: 'Información del Servicio',
        icon: Icons.local_hospital,
        color: Colors.blue,
        fieldMappings: {
          'horaLlamada': 'Hora de llamada',
          'horaArribo': 'Hora de arribo',
          'tiempoEsperaArribo': 'Tiempo de espera arribo',
          'horaLlegada': 'Hora de llegada',
          'horaTermino': 'Hora de terminación',
          'tiempoEsperaLlegada': 'Tiempo de espera llegada',
          'ubicacion': 'Ubicación',
          'tipoServicio': 'Tipo de servicio',
          'tipoServicioEspecifique': 'Especifique',
          'lugarOcurrencia': 'Lugar de ocurrencia',
          'lugarOcurrenciaEspecifique': 'Especifique lugar',
          'tipoUrgencia': 'Tipo de urgencia',
          'urgenciaEspecifique': 'Especifique urgencia',
        },
        specialFields: {
          'consentimientoSignature': {
            'label': 'Firma de consentimiento',
            'isSignature': true,
            'signatureTitle': 'Firma de Consentimiento',
          },
        },
      ),
      // Información del registro
      const SectionConfig(
        key: 'registryInfo',
        title: 'Información del Registro',
        icon: Icons.assignment,
        color: Colors.indigo,
        fieldMappings: {
          'convenio': 'Convenio',
          'folio': 'Folio',
          'episodio': 'Episodio',
          'fecha': 'Fecha de registro',
          'solicitadoPor': 'Solicitado por',
        },
      ),
      // Información del paciente
      SectionConfig(
        key: 'patientInfo',
        title: 'Información del Paciente',
        icon: Icons.person,
        color: Colors.blue,
        fallbacks: {'tipoEntrega': 'No especificado'},
        specialFields: {
          'fullName': {
            'label': 'Nombre completo',
            'isFullWidth': true,
            'customBuilder': (data) => widget.record.patientName,
          },
          'fullAddress': {
            'label': 'Dirección',
            'isFullWidth': true,
            'customBuilder': (data) => _buildFullAddress(data),
          },
          'age': {
            'label': 'Edad',
            'customBuilder':
                (data) => _formatAge(
                  _getSafeStringValue(data, 'age'),
                  widget.record.patientAge,
                ),
          },
          'sex': {
            'label': 'Sexo',
            'customBuilder':
                (data) =>
                    _getSafeStringValue(data, 'sex') ??
                    widget.record.patientGender,
          },
          'gender': {
            'label': 'Género',
            'customBuilder': (data) => _getSafeStringValue(data, 'gender'),
          },
          'phone': {
            'label': 'Teléfono',
            'customBuilder':
                (data) => _formatPhone(_getSafeStringValue(data, 'phone')),
          },
          'emergencyContact': {
            'label': 'Contacto de emergencia',
            'customBuilder':
                (data) => _getSafeStringValue(data, 'emergencyContact'),
          },
          'currentCondition': {
            'label': 'Padecimiento actual',
            'isFullWidth': true,
            'customBuilder':
                (data) => _getSafeStringValue(data, 'currentCondition'),
          },
        },
        fieldMappings: {
          'responsiblePerson': 'Persona responsable',
          'addressDetails': 'Detalles de dirección',
          'insurance': 'Seguro médico',
          'tipoEntrega': 'Tipo de entrega',
          'tipoEntregaOtro': 'Otro tipo de entrega',
        },
      ),
      // Manejo
      SectionConfig(
        key: 'management',
        title: 'Manejo',
        icon: Icons.healing,
        color: Colors.purple,
        fieldMappings: {'observaciones': 'Observaciones'},
        booleanFields: {
          'viaAerea': 'Vía aérea',
          'canalizacion': 'Canalización',
          'empaquetamiento': 'Empaquetamiento',
          'inmovilizacion': 'Inmovilización',
          'monitor': 'Monitor',
          'rcpBasica': 'RCP básica',
          'mastPna': 'MAST/PNA',
          'collarinCervical': 'Collarín cervical',
          'desfibrilacion': 'Desfibrilación',
          'apoyoVent': 'Apoyo ventilatorio',
        },
        conditionalFields: {
          'oxigeno': {
            'label': 'Oxígeno',
            'condition': (data) => data['oxigeno'] == true,
            'dependentField': 'ltMin',
            'dependentLabel': 'Oxigeno Lt/min',
          },
          'viaAerea': {
            'label': 'Especifique vía aérea',
            'condition': (data) => data['viaAerea'] == true,
            'dependentField': 'viaAereaEspecifique',
            'dependentLabel': 'Especifique',
          },
          'canalizacion': {
            'label': 'Especifique canalización',
            'condition': (data) => data['canalizacion'] == true,
            'dependentField': 'canalizacionEspecifique',
            'dependentLabel': 'Especifique',
          },
          'empaquetamiento': {
            'label': 'Especifique empaquetamiento',
            'condition': (data) => data['empaquetamiento'] == true,
            'dependentField': 'empaquetamientoEspecifique',
            'dependentLabel': 'Especifique',
          },
          'inmovilizacion': {
            'label': 'Especifique inmovilización',
            'condition': (data) => data['inmovilizacion'] == true,
            'dependentField': 'inmovilizacionEspecifique',
            'dependentLabel': 'Especifique',
          },
          'monitor': {
            'label': 'Especifique monitor',
            'condition': (data) => data['monitor'] == true,
            'dependentField': 'monitorEspecifique',
            'dependentLabel': 'Especifique',
          },
          'rcpBasica': {
            'label': 'Especifique RCP básica',
            'condition': (data) => data['rcpBasica'] == true,
            'dependentField': 'rcpBasicaEspecifique',
            'dependentLabel': 'Especifique',
          },
          'mastPna': {
            'label': 'Especifique MAST/PNA',
            'condition': (data) => data['mastPna'] == true,
            'dependentField': 'mastPnaEspecifique',
            'dependentLabel': 'Especifique',
          },
          'collarinCervical': {
            'label': 'Especifique collarín cervical',
            'condition': (data) => data['collarinCervical'] == true,
            'dependentField': 'collarinCervicalEspecifique',
            'dependentLabel': 'Especifique',
          },
          'desfibrilacion': {
            'label': 'Especifique desfibrilación',
            'condition': (data) => data['desfibrilacion'] == true,
            'dependentField': 'desfibrilacionEspecifique',
            'dependentLabel': 'Especifique',
          },
          'apoyoVent': {
            'label': 'Especifique apoyo ventilatorio',
            'condition': (data) => data['apoyoVent'] == true,
            'dependentField': 'apoyoVentEspecifique',
            'dependentLabel': 'Especifique',
          },
          'oxigenoEspecifique': {
            'label': 'Especifique oxígeno',
            'condition': (data) => data['oxigeno'] == true,
            'dependentField': 'oxigenoEspecifique',
            'dependentLabel': 'Especifique',
          },
        },
      ),
      // Medicamentos
      SectionConfig(
        key: 'medications',
        title: 'Medicamentos',
        icon: Icons.medication,
        color: Colors.orange,
        fieldMappings: {'observaciones': 'Observaciones'},
        specialFields: {
          'medicationsList': {
            'label': 'Medicamentos administrados',
            'isFullWidth': true,
            'customBuilder': (data) => _buildMedicationsList(data),
          },
        },
      ),
      // Urgencias Gineco-Obstétricas
      SectionConfig(
        key: 'gynecoObstetric',
        title: 'Urgencias Gineco-Obstétricas',
        icon: Icons.pregnant_woman,
        color: Colors.pink,
        fieldMappings: {
          'fum': 'Última menstruación',
          'semanasGestacion': 'Semanas de gestación',
          'frecuenciaCardiacaFetal': 'Frecuencia cardíaca fetal',
          'contracciones': 'Contracciones',
          'observaciones': 'Observaciones',
        },
        booleanFields: {
          'isParto': 'Es parto',
          'isAborto': 'Es aborto',
          'isHxVaginal': 'Hx vaginal',
          'ruidosFetalesPerceptibles': 'Ruidos fetales perceptibles',
        },
        specialFields: {
          'silvermanAnderson': {
            'label': 'Escala Silverman-Anderson',
            'isFullWidth': true,
            'customBuilder':
                (data) => _buildSilvermanAndersonDisplay(
                  data['silvermanAnderson'] ?? {},
                ),
          },
          'apgar': {
            'label': 'Escala APGAR',
            'isFullWidth': true,
            'customBuilder': (data) => _buildApgarDisplay(data['apgar'] ?? {}),
          },
        },
      ),
      // Negativa de atención
      SectionConfig(
        key: 'attentionNegative',
        title: 'Negativa de atención',
        icon: Icons.cancel,
        color: Colors.red,
        fieldMappings: {
          'motivoNegativa': 'Motivo de negativa',
          'observaciones': 'Observaciones',
          'declarationText': 'Declaración del paciente',
        },
        specialFields: {
          'patientSignature': {
            'label': 'Firma paciente',
            'isSignature': true,
            'signatureTitle': 'Firma del Paciente',
          },
          'witnessSignature': {
            'label': 'Firma Testigo',
            'isSignature': true,
            'signatureTitle': 'Firma del Testigo',
          },
        },
      ),
      // Antecedentes Patológicos
      SectionConfig(
        key: 'pathologicalHistory',
        title: 'Antecedentes Patológicos',
        icon: Icons.history,
        color: Colors.brown,
        fieldMappings: {'observaciones': 'Observaciones'},
        booleanFields: {
          'diabetes': 'Diabetes',
          'hipertension': 'Hipertensión',
          'cardiopatias': 'Cardiopatías',
          'enfermedadesRenales': 'Enfermedades renales',
          'enfermedadesHepaticas': 'Enfermedades hepáticas',
          'enfermedadesRespiratorias': 'Enfermedades respiratorias',
          'enfermedadesNeurologicas': 'Enfermedades neurológicas',
          'cancer': 'Cáncer',
          'vih': 'VIH',
          'otras': 'Otras',
        },
        conditionalFields: {
          'diabetes': {
            'label': 'Especifique diabetes',
            'condition': (data) => data['diabetes'] == true,
            'dependentField': 'diabetesEspecifique',
            'dependentLabel': 'Especifique',
          },
          'hipertension': {
            'label': 'Especifique hipertensión',
            'condition': (data) => data['hipertension'] == true,
            'dependentField': 'hipertensionEspecifique',
            'dependentLabel': 'Especifique',
          },
          'cardiopatias': {
            'label': 'Especifique cardiopatías',
            'condition': (data) => data['cardiopatias'] == true,
            'dependentField': 'cardiopatiasEspecifique',
            'dependentLabel': 'Especifique',
          },
          'enfermedadesRenales': {
            'label': 'Especifique enfermedades renales',
            'condition': (data) => data['enfermedadesRenales'] == true,
            'dependentField': 'enfermedadesRenalesEspecifique',
            'dependentLabel': 'Especifique',
          },
          'enfermedadesHepaticas': {
            'label': 'Especifique enfermedades hepáticas',
            'condition': (data) => data['enfermedadesHepaticas'] == true,
            'dependentField': 'enfermedadesHepaticasEspecifique',
            'dependentLabel': 'Especifique',
          },
          'enfermedadesRespiratorias': {
            'label': 'Especifique enfermedades respiratorias',
            'condition': (data) => data['enfermedadesRespiratorias'] == true,
            'dependentField': 'enfermedadesRespiratoriasEspecifique',
            'dependentLabel': 'Especifique',
          },
          'enfermedadesNeurologicas': {
            'label': 'Especifique enfermedades neurológicas',
            'condition': (data) => data['enfermedadesNeurologicas'] == true,
            'dependentField': 'enfermedadesNeurologicasEspecifique',
            'dependentLabel': 'Especifique',
          },
          'cancer': {
            'label': 'Especifique cáncer',
            'condition': (data) => data['cancer'] == true,
            'dependentField': 'cancerEspecifique',
            'dependentLabel': 'Especifique',
          },
          'vih': {
            'label': 'Especifique VIH',
            'condition': (data) => data['vih'] == true,
            'dependentField': 'vihEspecifique',
            'dependentLabel': 'Especifique',
          },
          'otras': {
            'label': 'Especifique otras',
            'condition': (data) => data['otras'] == true,
            'dependentField': 'otrasEspecifique',
            'dependentLabel': 'Especifique',
          },
        },
      ),
      // Antecedentes Clínicos
      SectionConfig(
        key: 'clinicalHistory',
        title: 'Antecedentes Clínicos',
        icon: Icons.medical_services,
        color: Colors.teal,
        fieldMappings: {
          'agenteCausal': 'Agente causal',
          'cinematica': 'Cinemática',
          'medidaSeguridad': 'Medida de Seguridad',
          'observaciones': 'Observaciones',
        },
        booleanFields: {
          'traumaCraneo': 'Trauma cráneo',
          'traumaTorax': 'Trauma tórax',
          'traumaAbdomen': 'Trauma abdomen',
          'traumaColumna': 'Trauma columna',
          'traumaExtremidades': 'Trauma extremidades',
          'traumaPelvis': 'Trauma pelvis',
          'traumaOtros': 'Trauma otros',
        },
        conditionalFields: {
          'traumaCraneo': {
            'label': 'Especifique trauma cráneo',
            'condition': (data) => data['traumaCraneo'] == true,
            'dependentField': 'traumaCraneoEspecifique',
            'dependentLabel': 'Especifique',
          },
          'traumaTorax': {
            'label': 'Especifique trauma tórax',
            'condition': (data) => data['traumaTorax'] == true,
            'dependentField': 'traumaToraxEspecifique',
            'dependentLabel': 'Especifique',
          },
          'traumaAbdomen': {
            'label': 'Especifique trauma abdomen',
            'condition': (data) => data['traumaAbdomen'] == true,
            'dependentField': 'traumaAbdomenEspecifique',
            'dependentLabel': 'Especifique',
          },
          'traumaColumna': {
            'label': 'Especifique trauma columna',
            'condition': (data) => data['traumaColumna'] == true,
            'dependentField': 'traumaColumnaEspecifique',
            'dependentLabel': 'Especifique',
          },
          'traumaExtremidades': {
            'label': 'Especifique trauma extremidades',
            'condition': (data) => data['traumaExtremidades'] == true,
            'dependentField': 'traumaExtremidadesEspecifique',
            'dependentLabel': 'Especifique',
          },
          'traumaPelvis': {
            'label': 'Especifique trauma pelvis',
            'condition': (data) => data['traumaPelvis'] == true,
            'dependentField': 'traumaPelvisEspecifique',
            'dependentLabel': 'Especifique',
          },
          'traumaOtros': {
            'label': 'Especifique trauma otros',
            'condition': (data) => data['traumaOtros'] == true,
            'dependentField': 'traumaOtrosEspecifique',
            'dependentLabel': 'Especifique',
          },
        },
      ),
      // Exploración Física
      SectionConfig(
        key: 'physicalExam',
        title: 'Exploración Física',
        icon: Icons.health_and_safety,
        color: Colors.cyan,
        fieldMappings: {
          'eva': 'EVA',
          'llc': 'LLC',
          'glucosa': 'Glucosa',
          'ta': 'T/A',
        },
        specialFields: {
          'vitalSigns': {
            'label': 'Signos Vitales',
            'isFullWidth': true,
            'customBuilder': (data) => _buildVitalSignsDisplay(data),
          },
          'sampleSection': {
            'label': 'Evaluación SAMPLE',
            'isFullWidth': true,
            'customBuilder': (data) => _buildSampleSection(data),
          },
        },
      ),
      // Justificación de Prioridad
      SectionConfig(
        key: 'priorityJustification',
        title: 'Justificación de Prioridad',
        icon: Icons.priority_high,
        color: Colors.deepOrange,
        fieldMappings: {
          'priority': 'Prioridad',
          'pupils': 'Pupilas',
          'skinColor': 'Color de piel',
          'skin': 'Piel',
          'temperature': 'Temperatura',
        },
        conditionalFields: {
          'influence': {
            'label': 'Influenciado por',
            'condition': (data) => data['influence'] == 'Otro',
            'dependentField': 'especifique',
            'dependentLabel': 'Influenciado por',
          },
        },
      ),
      // Unidad Médica que Recibe
      const SectionConfig(
        key: 'receivingUnit',
        title: 'Unidad Medica que Recibe',
        icon: Icons.local_hospital,
        color: Colors.indigo,
        fieldMappings: {
          'lugarOrigen': 'Lugar de origen',
          'lugarDestino': 'Lugar de destino',
          'lugarConsulta': 'Lugar de consulta',
          'ambulanciaNumero': 'Número de ambulancia',
          'ambulanciaPlacas': 'Placas de ambulancia',
          'personal': 'Personal',
          'doctor': 'Doctor',
          'otroLugar': 'Otro lugar',
          'observaciones': 'Observaciones',
        },
      ),
      // Recepción del Paciente
      const SectionConfig(
        key: 'patientReception',
        title: 'Recepción del Paciente',
        icon: Icons.how_to_reg,
        color: Colors.green,
        fieldMappings: {
          'receivingDoctor': 'Medico que recibe',
          'doctorName': 'Nombre del doctor',
          'doctorCedula': 'Cédula del doctor',
        },
        specialFields: {
          'doctorSignature': {
            'label': 'Firma del medico',
            'isSignature': true,
            'signatureTitle': 'Firma del Médico',
          },
        },
      ),
      // Consentimiento de Servicio
      const SectionConfig(
        key: 'consentimientoServicio',
        title: 'Consentimiento de Servicio',
        icon: Icons.assignment_turned_in,
        color: Colors.green,
        fieldMappings: {},
        specialFields: {
          'consentimientoSignature': {
            'label': 'Firma de consentimiento',
            'isSignature': true,
            'signatureTitle': 'Firma de Consentimiento',
          },
        },
      ),
      // Insumos Utilizados
      SectionConfig(
        key: 'insumos',
        title: 'Insumos Utilizados',
        icon: Icons.inventory,
        color: Colors.amber,
        fieldMappings: {},
        specialFields: {
          'insumos': {
            'label': 'Lista de insumos',
            'isFullWidth': true,
            'customBuilder': (data) => _buildInsumosList(data),
          },
        },
      ),
    ];
  }

  void _loadDetailedInfo() {
    setState(() {
      _isLoading = true;
    });

    _detailedInfo = widget.record.getDetailedInfo();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _refreshCurrentRecordFromProvider() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(unifiedFrapProvider.notifier).loadAllRecords();
      if (!mounted) return;

      final refreshedRecord = _findLatestRecordForEditing();
      if (refreshedRecord != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => FrapRecordDetailsScreen(record: refreshedRecord),
          ),
        );
        return;
      }

      _loadDetailedInfo();
      await _refreshEditPermission();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se encontró una versión más reciente del registro',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _loadDetailedInfo();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar registro: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Método auxiliar para decodificar firmas base64 correctamente
  Uint8List _getImageBytesFromBase64(String base64Data) {
    try {
      // Validar que el string no esté vacío
      if (base64Data.trim().isEmpty) {
        return Uint8List(0);
      }

      // Remover el prefijo 'data:image/png;base64,' si existe
      final base64String = base64Data.split(',').last;

      // Validar que el string base64 sea válido
      if (base64String.isEmpty) {
        return Uint8List(0);
      }

      return base64Decode(base64String);
    } catch (e) {
      return Uint8List(0);
    }
  }

  // Agrega este método auxiliar en _FrapRecordDetailsScreenState
  List<DrawnInjuryDisplay> _getAdjustedInjuries(
    List<DrawnInjuryDisplay> originalInjuries,
    Map<String, dynamic> injuryLocationMap,
    Size targetSize,
  ) {
    if (originalInjuries.isEmpty) return originalInjuries;

    // Obtener información del tamaño original si está disponible
    final originalImageSize = injuryLocationMap['originalImageSize'];
    final originalImageRect = injuryLocationMap['originalImageRect'];

    Size? originalSize;
    Rect? originalRect;

    if (originalImageSize != null && originalImageSize is Map) {
      originalSize = Size(
        (originalImageSize['width'] ?? 400).toDouble(),
        (originalImageSize['height'] ?? 600).toDouble(),
      );
    }

    if (originalImageRect != null && originalImageRect is Map) {
      originalRect = Rect.fromLTWH(
        (originalImageRect['left'] ?? 0).toDouble(),
        (originalImageRect['top'] ?? 0).toDouble(),
        (originalImageRect['width'] ?? 400).toDouble(),
        (originalImageRect['height'] ?? 600).toDouble(),
      );
    }

    // Si no tenemos información del tamaño original, usar las lesiones tal cual
    if (originalSize == null || originalRect == null) {
      return originalInjuries;
    }

    // Calcular factores de escala
    final scaleX = targetSize.width / originalRect.width;
    final scaleY = targetSize.height / originalRect.height;

    // Ajustar cada lesión
    return originalInjuries.map((injury) {
      final adjustedPoints =
          injury.points.map((point) {
            // Convertir del espacio original al espacio actual
            final adjustedX = (point.dx - originalRect!.left) * scaleX;
            final adjustedY = (point.dy - originalRect.top) * scaleY;

            return Offset(adjustedX, adjustedY);
          }).toList();

      return DrawnInjuryDisplay(
        points: adjustedPoints,
        injuryType: injury.injuryType,
      );
    }).toList();
  }

  // Método para mostrar firma en tamaño grande
  void _showSignatureFullScreen(
    String title,
    String base64Data, {
    String? doctorName,
  }) {
    try {
      final decodedBytes = _getImageBytesFromBase64(base64Data);
      if (decodedBytes.isNotEmpty) {
        showDialog(
          context: context,
          builder:
              (context) => Dialog(
                backgroundColor: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue[600], size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Contenido de la firma
                      Flexible(
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: InteractiveViewer(
                              child: Image.memory(
                                decodedBytes,
                                fit: BoxFit.contain,
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                        const Center(
                                          child: Text(
                                            'Error al cargar la firma',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Footer con información
                      if (doctorName != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Médico: $doctorName',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al mostrar la firma: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Registro de Atencion Prehospitalaria',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar registro',
            onPressed: _refreshCurrentRecordFromProvider,
          ),
          IconButton(
            icon:
                _isCheckingEditPermission
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Icon(
                      Icons.edit,
                      color: _canEditRecord ? null : Colors.grey,
                    ),
            tooltip:
                _canEditRecord
                    ? 'Editar registro'
                    : (_editBlockedReason ?? 'Edición no disponible'),
            onPressed:
                (!_isCheckingEditPermission && _canEditRecord)
                    ? () => _editRecord()
                    : null,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'pdf':
                  _generatePDF();
                  break;
                case 'delete':
                  _deleteRecord();
                  break;
                case 'share':
                  _shareRecord();
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'pdf',
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Generar PDF'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share, size: 20),
                        SizedBox(width: 8),
                        Text('Compartir'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header con información básica
                      _buildHeaderCard(),

                      const SizedBox(height: 16),

                      // Información del servicio
                      _buildSectionFromConfig(_sectionConfigs[0]),

                      // Información del registro
                      _buildSectionFromConfig(_sectionConfigs[1]),

                      // Información del paciente
                      _buildSectionFromConfig(_sectionConfigs[2]),

                      // Manejo
                      _buildSectionFromConfig(_sectionConfigs[3]),

                      // Medicamentos
                      _buildSectionFromConfig(_sectionConfigs[4]),

                      // Gineco-obstétrica (solo para pacientes femeninos)
                      if (_detailedInfo['patientInfo']['sex'].toLowerCase() ==
                          'femenino')
                        _buildGynecoObstetricSection(),

                      // Atención negativa (solo si hay datos registrados)
                      if (_hasAttentionNegativeData())
                        _buildSectionFromConfig(_sectionConfigs[6]),

                      // Historia patológica
                      _buildSectionFromConfig(_sectionConfigs[7]),

                      // Historia clínica
                      _buildSectionFromConfig(_sectionConfigs[8]),

                      // Examen físico
                      _buildSectionFromConfig(_sectionConfigs[9]),

                      // Justificación de prioridad
                      _buildSectionFromConfig(_sectionConfigs[10]),

                      // Localización de lesiones
                      _buildInjuryLocationSection(),

                      // Unidad receptora
                      _buildSectionFromConfig(_sectionConfigs[11]),

                      _buildPersonalMedicoSection(),

                      // Recepción del paciente
                      _buildSectionFromConfig(_sectionConfigs[12]),

                      // Nuevas secciones agregadas
                      _buildInsumosSection(),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors:
                widget.record.patientGender.toLowerCase() == 'femenino'
                    ? [AppTheme.primaryGreen, AppTheme.primaryGreen]
                    : [AppTheme.primaryBlue, AppTheme.primaryBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Icon(Icons.person, size: 32, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.record.patientName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.record.patientAge} años • ${widget.record.patientGender}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.record.isLocal ? 'LOCAL' : 'NUBE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Información adicional
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Fecha de creación',
                    DateFormat(
                      'dd/MM/yyyy HH:mm',
                    ).format(widget.record.createdAt),
                    Icons.calendar_today,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(
                    'Completitud',
                    '${widget.record.completionPercentage.toStringAsFixed(1)}%',
                    Icons.assessment,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _buildSyncStatusIndicator(),

            const SizedBox(height: 12),

            // Barra de progreso
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progreso de completitud',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: widget.record.completionPercentage / 100,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.record.completionPercentage >= 80
                        ? Colors.green[300]!
                        : widget.record.completionPercentage >= 50
                        ? Colors.orange[300]!
                        : Colors.red[300]!,
                  ),
                  minHeight: 8,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusIndicator() {
    final hasCloudCopy = widget.record.cloudRecord != null;
    final isSynced = widget.record.isSynced;

    late String label;
    late Color chipColor;
    late IconData icon;

    if (hasCloudCopy && isSynced) {
      label = 'Actualizado en nube';
      chipColor = Colors.green;
      icon = Icons.cloud_done;
    } else if (hasCloudCopy && !isSynced) {
      label = 'Pendiente de sincronizacion';
      chipColor = Colors.orange;
      icon = Icons.sync_problem;
    } else {
      label = 'Solo local';
      chipColor = Colors.blueGrey;
      icon = Icons.storage;
    }

    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.95)),
        const SizedBox(width: 8),
        const Text(
          'Estado:',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: chipColor.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.8)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionFromConfig(SectionConfig config) {
    final details = _buildDetailsFromConfig(config);

    if (details.isEmpty) return const SizedBox.shrink();

    return _buildSectionCard(
      title: config.title,
      icon: config.icon,
      color: config.color,
      child: _buildThreeColumnDetails(details),
    );
  }

  // Método auxiliar para construir widgets de firma de manera segura
  Widget _buildSignatureWidget(dynamic signatureData, String signatureTitle) {
    try {
      if (signatureData != null && signatureData.toString().isNotEmpty) {
        final decodedBytes = _getImageBytesFromBase64(signatureData.toString());
        if (decodedBytes.isNotEmpty) {
          return GestureDetector(
            onTap:
                () => _showSignatureFullScreen(
                  signatureTitle,
                  signatureData.toString(),
                ),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.memory(
                decodedBytes,
                height: 60,
                fit: BoxFit.contain,
                errorBuilder:
                    (context, error, stackTrace) =>
                        const Text('Firma no disponible'),
              ),
            ),
          );
        }
      }
      return const Text('No registrada');
    } catch (e) {
      return const Text('Firma corrupta');
    }
  }

  Widget _buildThreeColumnDetails(List<Map<String, dynamic>> details) {
    // Filtrar detalles que tienen valor
    final detailsWithData =
        details
            .where(
              (detail) =>
                  detail['value'] != null &&
                  (detail['value'] is Widget ||
                      (detail['value'] is String &&
                          detail['value'].toString().trim().isNotEmpty)),
            )
            .toList();

    // Si no hay datos, mostrar mensaje
    if (detailsWithData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No hay información disponible',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete la información para ver los datos aquí',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Separar campos especiales (firmas y ancho completo) de campos normales
    final normalFields =
        detailsWithData
            .where((d) => d['isSignature'] != true && d['isFullWidth'] != true)
            .toList();
    final specialFields =
        detailsWithData
            .where((d) => d['isSignature'] == true || d['isFullWidth'] == true)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campos especiales (firmas y ancho completo) en ancho completo
        if (specialFields.isNotEmpty) ...[
          ...specialFields.map((detail) {
            if (detail['isFullWidth'] == true) {
              return _buildFullWidthDetail(detail['label'], detail['value']);
            }
            return _buildServiceDetailCard(
              detail['label'],
              detail['value'],
              isSignature: detail['isSignature'] == true,
            );
          }),
        ],
        // Campos normales en 3 columnas
        if (normalFields.isNotEmpty) ...[
          _buildThreeColumnGrid(normalFields),
          if (specialFields.isNotEmpty) const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildThreeColumnGrid(List<Map<String, dynamic>> details) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: details.length,
      itemBuilder: (context, index) {
        final detail = details[index];
        return _buildServiceDetailCard(detail['label'], detail['value']);
      },
    );
  }

  Widget _buildServiceDetailCard(
    String label,
    dynamic value, {
    bool isSignature = false,
  }) {
    final hasValue =
        value != null &&
        (value is Widget ||
            (value is String && value.toString().trim().isNotEmpty));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Row(
          children: [
            Icon(
              _getIconForField(label),
              size: 16,
              color: hasValue ? Colors.blue[600] : Colors.grey[500],
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: hasValue ? Colors.blue[700] : Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Value
        value is Widget
            ? value
            : Text(
              hasValue ? value.toString() : 'No especificado',
              style: TextStyle(
                fontSize: 12,
                fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal,
                color: hasValue ? Colors.black87 : Colors.grey[500],
              ),
              maxLines: isSignature ? 1 : 3,
              overflow: TextOverflow.ellipsis,
            ),
      ],
    );
  }

  IconData _getIconForField(String label) {
    if (label.contains('Hora')) return Icons.access_time;
    if (label.contains('Tiempo')) return Icons.timer;
    if (label.contains('Ubicacion')) return Icons.location_on;
    if (label.contains('Tipo')) return Icons.category;
    if (label.contains('Lugar')) return Icons.place;
    if (label.contains('Urgencia')) return Icons.emergency;
    if (label.contains('Firma')) return Icons.edit;
    if (label.contains('Especifique')) return Icons.edit_note;
    return Icons.info_outline;
  }

  // Método para construir dirección completa
  String _buildFullAddress(Map<dynamic, dynamic> patientInfoMap) {
    final addressParts = <String>[];

    final street = _getSafeStringValue(patientInfoMap, 'street');
    final extNumber = _getSafeStringValue(patientInfoMap, 'exteriorNumber');
    final intNumber = _getSafeStringValue(patientInfoMap, 'interiorNumber');
    final neighborhood = _getSafeStringValue(patientInfoMap, 'neighborhood');
    final city = _getSafeStringValue(patientInfoMap, 'city');
    final addressDetails = _getSafeStringValue(
      patientInfoMap,
      'addressDetails',
    );

    if (street != null) addressParts.add(street);
    if (extNumber != null) addressParts.add('No. $extNumber');
    if (intNumber != null) addressParts.add('Int. $intNumber');
    if (neighborhood != null) addressParts.add('Col. $neighborhood');
    if (city != null) addressParts.add(city);
    if (addressDetails != null && addressDetails.trim().isNotEmpty) {
      addressParts.add(addressDetails);
    }

    return addressParts.isNotEmpty
        ? addressParts.join(', ')
        : _getSafeStringValue(patientInfoMap, 'address') ??
            widget.record.patientAddress;
  }

  // Método para formatear edad
  String _formatAge(String? age, int fallbackAge) {
    if (age == null || age.trim().isEmpty) {
      return '$fallbackAge años';
    }

    try {
      final ageNum = int.parse(age);
      if (ageNum < 0 || ageNum > 150) {
        return '$fallbackAge años';
      }
      return '$ageNum años';
    } catch (e) {
      return '$fallbackAge años';
    }
  }

  // Método para formatear teléfono
  String? _formatPhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return null;
    }

    // Remover caracteres no numéricos
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanPhone.length == 10) {
      // Formato: (XXX) XXX-XXXX
      return '(${cleanPhone.substring(0, 3)}) ${cleanPhone.substring(3, 6)}-${cleanPhone.substring(6)}';
    } else if (cleanPhone.length == 7) {
      // Formato: XXX-XXXX
      return '${cleanPhone.substring(0, 3)}-${cleanPhone.substring(3)}';
    }

    return phone; // Devolver original si no coincide con formatos conocidos
  }

  Widget _buildGynecoObstetricSection() {
    final gynecoObstetric = _detailedInfo['gynecoObstetric'];

    Map<String, dynamic> gynecoObstetricMap = {};
    if (gynecoObstetric is Map) {
      gynecoObstetricMap = Map<String, dynamic>.from(gynecoObstetric);
    }
    if (gynecoObstetricMap.isEmpty) return const SizedBox.shrink();

    final details = [
      {'label': 'Última menstruación', 'value': gynecoObstetricMap['fum']},
      {
        'label': 'Semanas de gestación',
        'value': gynecoObstetricMap['semanasGestacion'],
      },
      {'label': 'Gesta', 'value': gynecoObstetricMap['gesta']},
      {'label': 'Abortos', 'value': gynecoObstetricMap['abortos']},
      {'label': 'Partos', 'value': gynecoObstetricMap['partos']},
      {'label': 'Cesáreas', 'value': gynecoObstetricMap['cesareas']},
      {
        'label': 'Métodos anticonceptivos',
        'value': gynecoObstetricMap['metodosAnticonceptivos'],
      },
      {
        'label': 'Ruidos cardiacos fetales',
        'value': gynecoObstetricMap['ruidosCardiacosFetales'],
      },
      {
        'label': 'Expulsión de placenta',
        'value': gynecoObstetricMap['expulsionPlacenta'],
      },
      {'label': 'Hora', 'value': gynecoObstetricMap['hora']},
      {'label': 'Observaciones', 'value': gynecoObstetricMap['observaciones']},
      {
        'label': 'Frecuencia cardíaca fetal',
        'value': gynecoObstetricMap['frecuenciaCardiacaFetal'],
      },
      {'label': 'Contracciones', 'value': gynecoObstetricMap['contracciones']},
    ];

    return _buildSectionCard(
      title: 'Urgencias Gineco-Obstétricas',
      icon: Icons.pregnant_woman,
      color: Colors.pink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Datos básicos gineco-obstétricos
          _buildTwoColumnDetails(details),

          // Escalas obstétricas (si existen)
          const SizedBox(height: 16),
          _buildEscalasObstetricasContent(gynecoObstetricMap),
        ],
      ),
    );
  }

  // Método para construir solo el contenido de escalas (sin la card)
  Widget _buildEscalasObstetricasContent(Map<String, dynamic> gynecoData) {
    // Las escalas están DENTRO de gynecoObstetric, no en un campo separado
    if (gynecoData.isEmpty) {
      return const SizedBox.shrink();
    }

    List<Widget> escalasWidgets = [];

    // Escala de Silverman-Anderson
    if (gynecoData['silvermanAnderson'] != null) {
      final silverman = gynecoData['silvermanAnderson'];
      if (silverman is Map && silverman.isNotEmpty) {
        escalasWidgets.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Escala Silverman-Anderson',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.pink[700],
                ),
              ),
              const SizedBox(height: 8),
              _buildSilvermanAndersonDisplay(silverman),
            ],
          ),
        );
      }
    }

    // Escala APGAR
    if (gynecoData['apgar'] != null) {
      final apgar = gynecoData['apgar'];
      if (apgar is Map && apgar.isNotEmpty) {
        if (escalasWidgets.isNotEmpty) {
          escalasWidgets.add(const SizedBox(height: 16));
        }
        escalasWidgets.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Escala APGAR',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.pink[700],
                ),
              ),
              const SizedBox(height: 8),
              _buildApgarDisplay(apgar),
            ],
          ),
        );
      }
    }

    if (escalasWidgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: Colors.pink.withValues(alpha: 0.3), thickness: 1),
        const SizedBox(height: 12),
        Text(
          'Escalas Obstétricas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.pink[800],
          ),
        ),
        const SizedBox(height: 12),
        ...escalasWidgets,
      ],
    );
  }

  Widget _buildInsumosSection() {
    // Obtener insumos desde _detailedInfo
    final insumosData = _detailedInfo['insumos'];
    List<dynamic> insumosList = [];

    if (insumosData != null) {
      if (insumosData is List) {
        insumosList =
            insumosData
                .where((item) => item != null && item is Map<String, dynamic>)
                .toList();
      } else if (insumosData is Map) {
        // Si es un mapa, convertirlo a lista
        insumosList = [insumosData];
      }
    }

    if (insumosList.isEmpty) return const SizedBox.shrink();

    return _buildSectionCard(
      title: 'Insumos Utilizados',
      icon: Icons.inventory_2,
      color: Colors.deepPurple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (insumosList.isNotEmpty) ...[
            for (int i = 0; i < insumosList.length; i++)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.deepPurple.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getSafeStringValue(insumosList[i], 'articulo') ??
                                'Sin especificar',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cantidad: ${_getSafeStringValue(insumosList[i], 'cantidad') ?? '0.0'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ] else ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No se registraron insumos',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonalMedicoSection() {
    // Obtener personal médico desde _detailedInfo
    final personalData = _detailedInfo['personalMedico'];
    List<dynamic> personalList = [];

    if (personalData != null) {
      if (personalData is List) {
        personalList =
            personalData
                .where((item) => item != null && item is Map<String, dynamic>)
                .toList();
      } else if (personalData is Map) {
        // Si es un mapa, convertirlo a lista
        personalList = [personalData];
      }
    }

    if (personalList.isEmpty) return const SizedBox.shrink();

    return _buildSectionCard(
      title: 'Personal Médico',
      icon: Icons.medical_services,
      color: Colors.blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (personalList.isNotEmpty) ...[
            for (int i = 0; i < personalList.length; i++)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getSafeStringValue(personalList[i], 'nombre') ??
                                'Sin especificar',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (_getSafeStringValue(
                                personalList[i],
                                'especialidad',
                              )?.isNotEmpty ==
                              true)
                            Text(
                              'Especialidad: ${_getSafeStringValue(personalList[i], 'especialidad')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          if (_getSafeStringValue(
                                personalList[i],
                                'cedula',
                              )?.isNotEmpty ==
                              true)
                            Text(
                              'Cédula: ${_getSafeStringValue(personalList[i], 'cedula')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ] else ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No se registró personal médico',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Método auxiliar para obtener valores de string de manera segura
  String? _getSafeStringValue(dynamic data, String key) {
    if (data is Map<String, dynamic> && data.containsKey(key)) {
      final value = data[key];
      if (value != null) {
        return value.toString().trim();
      }
    }
    // Also check Map<dynamic, dynamic>
    if (data is Map && data.containsKey(key)) {
      final value = data[key];
      if (value != null) {
        return value.toString().trim();
      }
    }
    return null;
  }

  Widget _buildSilvermanAndersonDisplay(Map<dynamic, dynamic> silverman) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.pink.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.pink.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Puntajes por criterio:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...silverman.entries.where((entry) => entry.value != null).map((
            entry,
          ) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      _getSilvermanCriteriaName(entry.key),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${entry.value}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildApgarDisplay(Map<dynamic, dynamic> apgar) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.pink.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.pink.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Puntajes por criterio:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...apgar.entries.where((entry) => entry.value != null).map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      _getApgarCriteriaName(entry.key),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${entry.value}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _getSilvermanCriteriaName(dynamic key) {
    switch (key) {
      case 'respirationMoved':
        return 'Movimientos respiratorios';
      case 'retraction':
        return 'Retracción';
      case 'nasal':
        return 'Aleteo nasal';
      case 'moan':
        return 'Quejido';
      case 'circulation':
        return 'Circulación';
      default:
        return key.toString();
    }
  }

  String _getApgarCriteriaName(dynamic key) {
    switch (key) {
      case 'heartRate':
        return 'Frecuencia cardíaca';
      case 'respiratoryEffort':
        return 'Esfuerzo respiratorio';
      case 'muscleTone':
        return 'Tono muscular';
      case 'reflexes':
        return 'Reflejos';
      case 'skinColor':
        return 'Color de la piel';
      default:
        return key.toString();
    }
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header de la sección
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenido de la sección
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildTwoColumnDetails(List<Map<String, dynamic>> details) {
    // No filtrar campos vacíos para mostrar todos los campos
    final detailsWithData = details;

    // Si no hay datos, mostrar mensaje
    if (detailsWithData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No hay información disponible para esta sección',
            style: TextStyle(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children:
          detailsWithData
              .map(
                (detail) => _buildDetailRow(detail['label'], detail['value']),
              )
              .toList(),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    if (value == null || (value is String && value.trim().isEmpty)) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                '$label:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No especificado',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child:
                value is Widget
                    ? value
                    : Text(
                      value.toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Future<void> _editRecord() async {
    final notifier = ref.read(unifiedFrapProvider.notifier);
    UnifiedFrapRecord recordForEditing = widget.record;

    // Verificar permisos de edición
    final permission = await notifier.canEditRecord(widget.record);
    if (!mounted) return;

    if (!permission.canEdit) {
      // Mostrar error si no se puede editar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(permission.message!),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (permission.needsDownload) {
      // Mostrar advertencia si necesita descarga
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Descargar registro'),
              content: Text(permission.message!),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Continuar'),
                ),
              ],
            ),
      );
      if (!mounted) return;
      if (confirmed != true) return;

      // Descargar el registro (sincronizar desde la nube)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Descargando registro...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );

      try {
        // Sincronizar registros (esto descargará el registro de la nube)
        final syncResult = await notifier.syncRecordsWithResult();
        if (!mounted) return;

        if (!syncResult.success) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                syncResult.message.isNotEmpty
                    ? syncResult.message
                    : 'No se pudo descargar el registro para edición',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
          return;
        }

        final refreshedRecord = _findLatestRecordForEditing();
        if (refreshedRecord == null) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No se encontró la copia local del registro después de sincronizar',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }

        recordForEditing = refreshedRecord;

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro descargado correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al descargar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
    }

    // Resolver versión más reciente incluso cuando no hubo descarga explícita.
    recordForEditing = _findLatestRecordForEditing() ?? recordForEditing;

    // Navegar a pantalla de edición
    if (!mounted) return;
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => FrapScreen(editingRecord: recordForEditing),
      ),
    );

    if (!mounted || updated != true) return;
    await _refreshCurrentRecordFromProvider();
  }

  UnifiedFrapRecord? _findLatestRecordForEditing() {
    final records = ref.read(unifiedFrapProvider).records;

    if (records.isEmpty) {
      return null;
    }

    final targetLocalId = widget.record.localRecord?.id;
    final targetCloudId = widget.record.cloudRecord?.id;
    final targetFolio = widget.record.folio.trim().toUpperCase();

    UnifiedFrapRecord? match;

    if (targetLocalId != null) {
      for (final record in records) {
        if (record.localRecord?.id == targetLocalId) {
          match = record;
          break;
        }
      }
    }

    if (match == null && targetCloudId != null && targetCloudId.isNotEmpty) {
      for (final record in records) {
        if (record.cloudRecord?.id == targetCloudId) {
          match = record;
          break;
        }
      }
    }

    if (match == null && targetFolio.isNotEmpty) {
      for (final record in records) {
        if (record.folio.trim().toUpperCase() == targetFolio) {
          match = record;
          break;
        }
      }
    }

    return match;
  }

  void _generatePDF() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPreviewScreen(record: widget.record),
      ),
    );
  }

  Future<void> _deleteRecord() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: Text(
              '¿Está seguro de eliminar el registro de ${widget.record.patientName}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
    if (!mounted) return;

    if (confirmed == true) {
      final notifier = ref.read(unifiedFrapProvider.notifier);

      try {
        final result = await notifier.deleteRecord(widget.record);
        if (!mounted) return;

        // Determinar el color y mensaje según el resultado
        Color snackBarColor;
        String message;

        if (result.success) {
          snackBarColor = Colors.green;
          message = result.message;
        } else if (result.deletedFromLocal && result.cloudError != null) {
          snackBarColor = Colors.orange;
          message = result.message;
        } else {
          snackBarColor = Colors.red;
          message = result.message;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: snackBarColor,
            duration: const Duration(seconds: 4),
          ),
        );

        if (result.success || result.deletedFromLocal) {
          Navigator.of(
            context,
          ).pop(); // Regresar a la lista si se eliminó localmente
        }
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar el registro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareRecord() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de compartir próximamente disponible'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // Construir leyenda visual de tipos de lesiones
  List<Widget> _buildInjuryLegend(List<DrawnInjuryDisplay> injuries) {
    // Obtener tipos únicos
    Set<int> uniqueTypes = injuries.map((injury) => injury.injuryType).toSet();

    return uniqueTypes.map((typeIndex) {
      final typeName = _getInjuryTypeName(typeIndex);
      final color = _getInjuryTypeColor(typeIndex);
      final number = typeIndex + 1; // Los números van de 1-10

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              typeName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  // Obtener color del tipo de lesión
  Color _getInjuryTypeColor(int typeIndex) {
    const colors = [
      Colors.red, // Hemorragia
      Color(0xFF8D6E63), // Herida (brown)
      Colors.purple, // Contusión
      Colors.orange, // Fractura
      Colors.yellow, // Luxación/Esguince
      Colors.pink, // Objeto extraño
      Colors.deepOrange, // Quemadura
      Colors.green, // Picadura/Mordedura
      Colors.indigo, // Edema/Hematoma
      Colors.grey, // Otro
    ];

    if (typeIndex >= 0 && typeIndex < colors.length) {
      return colors[typeIndex];
    }
    return Colors.grey;
  }

  // Métodos automatizados para procesar configuraciones
  Map<String, dynamic> _extractSectionData(String sectionKey) {
    if (_detailedInfo.containsKey(sectionKey)) {
      final data = _detailedInfo[sectionKey];
      if (data is Map<String, dynamic>) {
        return data;
      } else if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
    }
    return {};
  }

  List<Map<String, dynamic>> _buildDetailsFromConfig(SectionConfig config) {
    final sectionData = _extractSectionData(config.key);
    final details = <Map<String, dynamic>>[];

    final otroFieldsMapping = {
      'tipoServicio': 'tipoServicioEspecifique',
      'lugarOcurrencia': 'lugarOcurrenciaEspecifique',
      'tipoUrgencia': 'urgenciaEspecifique',
      'tipoEntrega': 'tipoEntregaOtro',
    };

    final fieldsToSkip = <String>{};

    config.fieldMappings.forEach((fieldKey, label) {
      if (config.specialFields.containsKey(fieldKey)) {
        return;
      }

      if (fieldsToSkip.contains(fieldKey)) {
        return;
      }

      final value = _getSafeStringValue(sectionData, fieldKey);
      final fallbackValue = config.fallbacks[fieldKey];
      var finalValue = value ?? (fallbackValue?.toString());
      var finalLabel = label;

      // Manejar campos con opción "Otro" que requieren especificación
      if (finalValue != null && otroFieldsMapping.containsKey(fieldKey)) {
        final cleanValue = finalValue.trim().toLowerCase();

        if (cleanValue == 'otro') {
          final especifiqueField = otroFieldsMapping[fieldKey]!;
          final especifiqueValue = _getSafeStringValue(
            sectionData,
            especifiqueField,
          );

          if (especifiqueValue != null && especifiqueValue.trim().isNotEmpty) {
            finalValue = especifiqueValue;
            fieldsToSkip.add(especifiqueField);
          }
        }
      }

      if (fieldKey == 'entreCalles' ||
          (finalValue != null && finalValue.trim().isNotEmpty)) {
        details.add({
          'label': finalLabel,
          'value': finalValue ?? 'No especificado',
        });
      }
    });

    final processedBooleanFields = <String>{};

    config.booleanFields.forEach((fieldKey, label) {
      if (sectionData[fieldKey] == true) {
        String displayValue = 'Sí';

        if (config.conditionalFields.containsKey(fieldKey)) {
          final conditionalConfig = config.conditionalFields[fieldKey]!;
          final dependentField = conditionalConfig['dependentField'] as String;
          final especifiqueValue = _getSafeStringValue(
            sectionData,
            dependentField,
          );

          if (especifiqueValue != null && especifiqueValue.trim().isNotEmpty) {
            displayValue = especifiqueValue;
            processedBooleanFields.add(dependentField);
          }
        }

        details.add({'label': label, 'value': displayValue});
      }
    });

    config.conditionalFields.forEach((fieldKey, fieldConfig) {
      final condition =
          fieldConfig['condition'] as Function(Map<String, dynamic>);
      if (condition(sectionData)) {
        final dependentField = fieldConfig['dependentField'] as String;

        if (processedBooleanFields.contains(dependentField)) {
          return;
        }

        final dependentLabel = fieldConfig['dependentLabel'] as String;
        final value = _getSafeStringValue(sectionData, dependentField);
        if (value != null && value.toString().trim().isNotEmpty) {
          details.add({'label': dependentLabel, 'value': value});
        }
      }
    });

    // Procesar campos especiales
    config.specialFields.forEach((fieldKey, fieldConfig) {
      final label = fieldConfig['label'] as String;
      final isSignature = fieldConfig['isSignature'] as bool? ?? false;
      final signatureTitle = fieldConfig['signatureTitle'] as String?;
      final isFullWidth = fieldConfig['isFullWidth'] as bool? ?? false;
      final customBuilder =
          fieldConfig['customBuilder'] as Function(Map<String, dynamic>)?;

      if (isSignature) {
        final signatureData = sectionData[fieldKey];
        final signatureWidget = _buildSignatureWidget(
          signatureData,
          signatureTitle ?? label,
        );
        details.add({
          'label': label,
          'value': signatureWidget,
          'isSignature': true,
          'isFullWidth': isFullWidth,
        });
      } else if (customBuilder != null) {
        final customValue = customBuilder(sectionData);
        details.add({
          'label': label,
          'value': customValue,
          'isFullWidth': isFullWidth,
        });
      } else {
        final value = _getSafeStringValue(sectionData, fieldKey);
        if (value != null && value.toString().trim().isNotEmpty) {
          details.add({
            'label': label,
            'value': value,
            'isFullWidth': isFullWidth,
          });
        }
      }
    });

    return details;
  }

  /*Widget _buildInjuryLocationSection() {
    final injuryLocation = _detailedInfo['injuryLocation'];
    Map<String, dynamic> injuryLocationMap = {};
    if (injuryLocation is Map) {
      injuryLocationMap = Map<String, dynamic>.from(injuryLocation);
    }
    if (injuryLocationMap.isEmpty) return const SizedBox.shrink();

    List<Map<String, dynamic>> details = [];
    List<DrawnInjuryDisplay> drawnInjuries = [];

    // Procesar lesiones dibujadas si existen
    if (injuryLocationMap['drawnInjuries'] != null) {
      final List<dynamic> injuriesData = injuryLocationMap['drawnInjuries'];

      if (injuriesData.isNotEmpty) {
        // Convertir datos a objetos DrawnInjuryDisplay
        drawnInjuries =
            injuriesData.map((injury) {
              final List<dynamic> pointsData = injury['points'];
              final points =
                  pointsData
                      .map((point) => Offset(point['dx'], point['dy']))
                      .toList();
              final injuryType = injury['injuryType'] as int;

              return DrawnInjuryDisplay(points: points, injuryType: injuryType);
            }).toList();

        // Agrupar lesiones por tipo para mostrar resumen
        Map<int, int> injuriesByType = {};
        for (var injury in drawnInjuries) {
          injuriesByType[injury.injuryType] =
              (injuriesByType[injury.injuryType] ?? 0) + 1;
        }

        // Crear detalles para cada tipo de lesión
        injuriesByType.forEach((typeIndex, count) {
          final typeName = _getInjuryTypeName(typeIndex);
          details.add({
            'label': typeName,
            'value':
                '$count ${count == 1 ? 'lesión marcada' : 'lesiones marcadas'}',
          });
        });

        // Mostrar total de lesiones
        details.add({
          'label': 'Total de lesiones',
          'value':
              '${drawnInjuries.length} ${drawnInjuries.length == 1 ? 'lesión' : 'lesiones'} dibujadas',
        });
      }
    }

    // Mostrar notas adicionales
    if (injuryLocationMap['notes'] != null &&
        injuryLocationMap['notes'].toString().trim().isNotEmpty) {
      details.add({
        'label': 'Notas adicionales',
        'value': injuryLocationMap['notes'],
        'isFullWidth': true,
      });
    }

    return _buildSectionCard(
      title: 'Localización de Lesiones',
      icon: Icons.my_location,
      color: Colors.red,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Layout horizontal: Lista de lesiones + Mapa visual
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Panel izquierdo - Lista de lesiones
              Container(
                width: 250,
                margin: const EdgeInsets.only(right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lesiones registradas:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Lista de lesiones
                    if (drawnInjuries.isNotEmpty) ...[
                      ...drawnInjuries.asMap().entries.map((entry) {
                        final injury = entry.value;
                        final typeName = _getInjuryTypeName(injury.injuryType);
                        final color = _getInjuryTypeColor(injury.injuryType);
                        final number = injury.injuryType + 1;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: color.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Número de la lesión
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '$number',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Información de la lesión
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      typeName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: color.withValues(alpha: 0.8),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${injury.points.length} ${injury.points.length == 1 ? 'punto' : 'puntos'} marcados',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 16),

                      // Resumen
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Total: ${drawnInjuries.length} ${drawnInjuries.length == 1 ? 'lesión' : 'lesiones'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'No se han registrado lesiones',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Panel derecho - Mapa visual del cuerpo humano
              Expanded(
                child: Container(
                  height: 400,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: InjuryLocationDisplayWidget(
                      drawnInjuries: drawnInjuries,
                      originalImageSize:
                          injuryLocationMap['originalImageSize'] != null
                              ? Size(
                                injuryLocationMap['originalImageSize']['width']
                                        ?.toDouble() ??
                                    400.0,
                                injuryLocationMap['originalImageSize']['height']
                                        ?.toDouble() ??
                                    600.0,
                              )
                              : const Size(400, 600), // Tamaño por defecto
                      originalImageRect:
                          injuryLocationMap['originalImageRect'] != null
                              ? Rect.fromLTWH(
                                injuryLocationMap['originalImageRect']['left']
                                        ?.toDouble() ??
                                    0.0,
                                injuryLocationMap['originalImageRect']['top']
                                        ?.toDouble() ??
                                    0.0,
                                injuryLocationMap['originalImageRect']['width']
                                        ?.toDouble() ??
                                    400.0,
                                injuryLocationMap['originalImageRect']['height']
                                        ?.toDouble() ??
                                    600.0,
                              )
                              : const Rect.fromLTWH(
                                0,
                                0,
                                400,
                                600,
                              ), // Rect por defecto
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Leyenda de tipos de lesiones (ahora más compacta)
          if (drawnInjuries.isNotEmpty) ...[
            const Text(
              'Leyenda de tipos:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: _buildInjuryLegend(drawnInjuries),
            ),
            const SizedBox(height: 16),
          ],

          // Detalles en texto
          ...details.map((detail) {
            if (detail['isFullWidth'] == true) {
              return _buildFullWidthDetail(detail['label'], detail['value']);
            }
            return _buildDetailRow(detail['label'], detail['value']);
          }),
        ],
      ),
    );
  }
  */

  Widget _buildInjuryLocationSection() {
    final injuryLocation = _detailedInfo['injuryLocation'];
    Map<String, dynamic> injuryLocationMap = {};
    if (injuryLocation is Map) {
      injuryLocationMap = Map<String, dynamic>.from(injuryLocation);
    }
    if (injuryLocationMap.isEmpty) return const SizedBox.shrink();

    List<Map<String, dynamic>> details = [];
    List<DrawnInjuryDisplay> drawnInjuries = [];

    // Procesar lesiones dibujadas si existen
    if (injuryLocationMap['drawnInjuries'] != null) {
      final List<dynamic> injuriesData = injuryLocationMap['drawnInjuries'];

      if (injuriesData.isNotEmpty) {
        // Convertir datos a objetos DrawnInjuryDisplay
        drawnInjuries =
            injuriesData.map((injury) {
              final List<dynamic> pointsData = injury['points'];
              final points =
                  pointsData
                      .map((point) => Offset(point['dx'], point['dy']))
                      .toList();
              final injuryType = injury['injuryType'] as int;

              return DrawnInjuryDisplay(points: points, injuryType: injuryType);
            }).toList();

        // Agrupar lesiones por tipo para mostrar resumen
        Map<int, int> injuriesByType = {};
        for (var injury in drawnInjuries) {
          injuriesByType[injury.injuryType] =
              (injuriesByType[injury.injuryType] ?? 0) + 1;
        }

        // Crear detalles para cada tipo de lesión
        injuriesByType.forEach((typeIndex, count) {
          final typeName = _getInjuryTypeName(typeIndex);
          details.add({
            'label': typeName,
            'value':
                '$count ${count == 1 ? 'lesión marcada' : 'lesiones marcadas'}',
          });
        });

        // Mostrar total de lesiones
        details.add({
          'label': 'Total de lesiones',
          'value':
              '${drawnInjuries.length} ${drawnInjuries.length == 1 ? 'lesión' : 'lesiones'} dibujadas',
        });
      }
    }

    // Mostrar notas adicionales
    if (injuryLocationMap['notes'] != null &&
        injuryLocationMap['notes'].toString().trim().isNotEmpty) {
      details.add({
        'label': 'Notas adicionales',
        'value': injuryLocationMap['notes'],
        'isFullWidth': true,
      });
    }

    return _buildSectionCard(
      title: 'Localización de Lesiones',
      icon: Icons.my_location,
      color: Colors.red,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Definir el tamaño objetivo para el área de visualización
          final targetSize = Size(constraints.maxWidth * 0.8, 400);

          // Ajustar las lesiones al tamaño objetivo
          final adjustedInjuries = _getAdjustedInjuries(
            drawnInjuries,
            injuryLocationMap,
            targetSize,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Layout horizontal: Lista de lesiones + Mapa visual
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Panel izquierdo - Lista de lesiones
                  Container(
                    width: 250,
                    margin: const EdgeInsets.only(right: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lesiones registradas:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Lista de lesiones
                        if (drawnInjuries.isNotEmpty) ...[
                          ...drawnInjuries.asMap().entries.map((entry) {
                            // final index = entry.key;
                            final injury = entry.value;
                            final typeName = _getInjuryTypeName(
                              injury.injuryType,
                            );
                            final color = _getInjuryTypeColor(
                              injury.injuryType,
                            );
                            final number = injury.injuryType + 1;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: color.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Número de la lesión
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$number',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Información de la lesión
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          typeName,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: color.withOpacity(0.8),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${injury.points.length} ${injury.points.length == 1 ? 'punto' : 'puntos'} marcados',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),

                          const SizedBox(height: 16),

                          // Resumen
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Total: ${drawnInjuries.length} ${drawnInjuries.length == 1 ? 'lesión' : 'lesiones'}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'No se han registrado lesiones',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Panel derecho - Mapa visual del cuerpo humano
                  Expanded(
                    child: Container(
                      height: 400,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: InjuryLocationDisplayWidget(
                          drawnInjuries:
                              adjustedInjuries, // Usar lesiones ajustadas
                          originalImageSize:
                              targetSize, // Pasar el tamaño objetivo como "original"
                          originalImageRect: Rect.fromLTWH(
                            0,
                            0,
                            targetSize.width,
                            targetSize.height,
                          ), // Rect completo
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Leyenda de tipos de lesiones
              if (drawnInjuries.isNotEmpty) ...[
                const Text(
                  'Leyenda de tipos:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: _buildInjuryLegend(drawnInjuries),
                ),
                const SizedBox(height: 16),
              ],

              // Detalles en texto
              ...details.map((detail) {
                if (detail['isFullWidth'] == true) {
                  return _buildFullWidthDetail(
                    detail['label'],
                    detail['value'],
                  );
                }
                return _buildDetailRow(detail['label'], detail['value']);
              }),
            ],
          );
        },
      ),
    );
  }

  // Método auxiliar para obtener el nombre del tipo de lesión
  String _getInjuryTypeName(int typeIndex) {
    const injuryTypes = [
      'Hemorragia', // 0
      'Herida', // 1
      'Contusión', // 2
      'Fractura', // 3
      'Luxación/Esguince', // 4
      'Objeto extraño', // 5
      'Quemadura', // 6
      'Picadura/Mordedura', // 7
      'Edema/Hematoma', // 8
      'Otro', // 9
    ];

    if (typeIndex >= 0 && typeIndex < injuryTypes.length) {
      return injuryTypes[typeIndex];
    }
    return 'Tipo desconocido';
  }

  // Método auxiliar para mostrar detalles de ancho completo (como notas)
  Widget _buildFullWidthDetail(String label, dynamic value) {
    if (value == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          if (value is Widget)
            value
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                value.toString(),
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMedicationsList(Map<String, dynamic> data) {
    final medicationsListRaw = data['medicationsList'] as List<dynamic>? ?? [];

    if (medicationsListRaw.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
            const SizedBox(width: 8),
            Text(
              'No se administraron medicamentos',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.medication, color: Colors.orange[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Total de medicamentos: ${medicationsListRaw.length}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[900],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        ...medicationsListRaw.asMap().entries.map((entry) {
          final index = entry.key;
          final medication = entry.value;

          if (medication is! Map) return const SizedBox.shrink();

          final medicationMap = Map<String, dynamic>.from(medication);
          final medicamento =
              medicationMap['medicamento']?.toString() ?? 'Sin especificar';
          final dosis = medicationMap['dosis']?.toString() ?? '';
          final viaAdministracion =
              medicationMap['viaAdministracion']?.toString() ?? '';
          final hora = medicationMap['hora']?.toString() ?? '';
          final medicoIndico = medicationMap['medicoIndico']?.toString() ?? '';
          final medicoOtro = medicationMap['medicoOtro']?.toString() ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 1),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: index.isEven ? Colors.white : Colors.orange[50],
              border: Border(
                left: BorderSide(color: Colors.orange[200]!, width: 1),
                right: BorderSide(color: Colors.orange[200]!, width: 1),
                bottom:
                    index == medicationsListRaw.length - 1
                        ? BorderSide(color: Colors.orange[200]!, width: 1)
                        : BorderSide.none,
              ),
              borderRadius:
                  index == medicationsListRaw.length - 1
                      ? const BorderRadius.vertical(bottom: Radius.circular(8))
                      : BorderRadius.zero,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.orange[700],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medicamento,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (dosis.isNotEmpty) ...[
                            _buildMedicationDetailRow(
                              Icons.medical_services,
                              'Dosis',
                              dosis,
                            ),
                            const SizedBox(height: 4),
                          ],
                          if (viaAdministracion.isNotEmpty) ...[
                            _buildMedicationDetailRow(
                              Icons.healing,
                              'Vía de administración',
                              viaAdministracion,
                            ),
                            const SizedBox(height: 4),
                          ],
                          if (hora.isNotEmpty) ...[
                            _buildMedicationDetailRow(
                              Icons.access_time,
                              'Hora',
                              hora,
                            ),
                            const SizedBox(height: 4),
                          ],
                          if (medicoIndico.isNotEmpty) ...[
                            _buildMedicationDetailRow(
                              Icons.person,
                              'Médico que indicó',
                              medicoIndico,
                            ),
                            const SizedBox(height: 4),
                          ],
                          if (medicoOtro.isNotEmpty) ...[
                            _buildMedicationDetailRow(
                              Icons.note,
                              'Otro médico',
                              medicoOtro,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMedicationDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.orange[700]),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  // Widget _buildPersonalMedicoList(Map<String, dynamic> data) {
  //   final personalListRaw = data['personalMedicoList'] as List<dynamic>? ?? [];

  //   // Aplanar la lista si viene anidada (cada elemento puede ser una lista)
  //   final personalList = <Map<String, dynamic>>[];
  //   final seenPersonal = <String>{}; // Para evitar duplicados

  //   for (var item in personalListRaw) {
  //     if (item is List) {
  //       // Si el item es una lista, agregar cada elemento
  //       for (var subItem in item) {
  //         if (subItem is Map) {
  //           final nombre = subItem['nombre']?.toString() ?? '';
  //           final cedula = subItem['cedula']?.toString() ?? '';
  //           final key = '$nombre-$cedula'; // Clave única

  //           if (!seenPersonal.contains(key) && nombre.isNotEmpty) {
  //             seenPersonal.add(key);
  //             personalList.add(Map<String, dynamic>.from(subItem));
  //           }
  //         }
  //       }
  //     } else if (item is Map) {
  //       // Si el item es un mapa directamente
  //       final nombre = item['nombre']?.toString() ?? '';
  //       final cedula = item['cedula']?.toString() ?? '';
  //       final key = '$nombre-$cedula';

  //       if (!seenPersonal.contains(key) && nombre.isNotEmpty) {
  //         seenPersonal.add(key);
  //         personalList.add(Map<String, dynamic>.from(item));
  //       }
  //     }
  //   }

  //   if (personalList.isEmpty) {
  //     return Container(
  //       padding: const EdgeInsets.all(16),
  //       decoration: BoxDecoration(
  //         color: Colors.grey.withValues(alpha: 0.1),
  //         borderRadius: BorderRadius.circular(8),
  //         border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
  //       ),
  //       child: Row(
  //         children: [
  //           Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
  //           const SizedBox(width: 12),
  //           Expanded(
  //             child: Text(
  //               'No se ha registrado personal médico',
  //               style: TextStyle(
  //                 color: Colors.grey[600],
  //                 fontStyle: FontStyle.italic,
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     );
  //   }

  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         'Personal médico (${personalList.length}):',
  //         style: TextStyle(
  //           fontWeight: FontWeight.bold,
  //           fontSize: 16,
  //           color: Colors.purple[700],
  //         ),
  //       ),
  //       const SizedBox(height: 8),
  //       ...personalList.map((personal) {
  //         final nombre = personal['nombre']?.toString() ?? '';
  //         final especialidad = personal['especialidad']?.toString() ?? '';
  //         final cedula = personal['cedula']?.toString() ?? '';

  //         return Container(
  //           padding: const EdgeInsets.all(12),
  //           margin: const EdgeInsets.only(bottom: 8),
  //           decoration: BoxDecoration(
  //             color: Colors.purple.withValues(alpha: 0.1),
  //             borderRadius: BorderRadius.circular(8),
  //             border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
  //           ),
  //           child: Row(
  //             children: [
  //               Icon(Icons.person, color: Colors.purple, size: 20),
  //               const SizedBox(width: 12),
  //               Expanded(
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Text(
  //                       nombre,
  //                       style: const TextStyle(
  //                         fontWeight: FontWeight.bold,
  //                         fontSize: 12,
  //                         color: Colors.purple,
  //                       ),
  //                     ),
  //                     const SizedBox(height: 4),
  //                     Text(
  //                       '$especialidad (Cédula: $cedula)',
  //                       style: const TextStyle(
  //                         fontSize: 11,
  //                         color: Colors.black87,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ],
  //           ),
  //         );
  //       }),
  //     ],
  //   );
  // }

  // Método para verificar si hay datos de atención negativa
  bool _hasAttentionNegativeData() {
    final attentionNegativeData = _detailedInfo['attentionNegative'];
    if (attentionNegativeData == null) return false;

    // Verificar si hay algún campo con datos
    if (attentionNegativeData is Map) {
      final data = Map<String, dynamic>.from(attentionNegativeData);

      // Verificar campos de texto
      if (data['motivoNegativa']?.toString().trim().isNotEmpty == true) {
        return true;
      }
      if (data['observaciones']?.toString().trim().isNotEmpty == true) {
        return true;
      }
      if (data['declarationText']?.toString().trim().isNotEmpty == true) {
        return true;
      }

      // Verificar firmas
      if (data['patientSignature'] != null) {
        return true;
      }
      if (data['witnessSignature'] != null) {
        return true;
      }
    }

    return false;
  }

  Widget _buildVitalSignsDisplay(Map<dynamic, dynamic> data) {
    // Obtener datos dinámicos de signos vitales
    final vitalSignsData =
        data['vitalSignsData'] as Map<String, dynamic>? ?? {};

    // Corregir el cast de timeColumns
    final timeColumnsRaw = data['timeColumns'];
    final List<String> timeColumns =
        timeColumnsRaw is List
            ? timeColumnsRaw.map((e) => e.toString()).toList()
            : <String>[];

    // Lista de signos vitales estándar
    final List<String> vitalSigns = [
      'T/A',
      'FC',
      'FR',
      'Temp.',
      'Sat. O2',
      'LLC',
      'Glu',
      'Glasgow',
    ];

    // Verificar si hay datos de signos vitales dinámicos
    bool hasVitalSignsData = false;
    final List<Widget> vitalSignsWidgets = [];

    for (final vitalSign in vitalSigns) {
      final vitalData = vitalSignsData[vitalSign];
      if (vitalData != null &&
          vitalData is Map<String, dynamic> &&
          vitalData.isNotEmpty) {
        hasVitalSignsData = true;

        // Extraer las columnas de tiempo disponibles
        final values = <String>[];

        // Usar columnas de tiempo dinámicas o buscar columnas estándar
        final availableTimeColumns =
            timeColumns.isNotEmpty
                ? timeColumns
                : ['Hora 1', 'Hora 2', 'Hora 3'];

        for (final timeKey in availableTimeColumns) {
          final value = vitalData[timeKey]?.toString() ?? '';
          values.add(value);
        }

        if (values.any((v) => v.isNotEmpty)) {
          vitalSignsWidgets.add(
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.cyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vitalSign,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.cyan,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ...availableTimeColumns.asMap().entries.map((entry) {
                        final index = entry.key;
                        final timeColumn = entry.value;
                        final value = values[index];

                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.cyan.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  timeColumn,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  value.isNotEmpty ? value : '-',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.cyan,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
      }
    }

    // Si no hay datos dinámicos, mostrar valores simples
    if (!hasVitalSignsData) {
      final simpleVitalSigns = <Widget>[];

      for (final vitalSign in vitalSigns) {
        final value = data[vitalSign]?.toString();
        if (value != null && value.isNotEmpty) {
          simpleVitalSigns.add(
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: Colors.cyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    vitalSign,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.cyan,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }

      if (simpleVitalSigns.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Signos Vitales',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.cyan[700],
              ),
            ),
            const SizedBox(height: 8),
            ...simpleVitalSigns,
          ],
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Signos Vitales',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.cyan[700],
          ),
        ),
        const SizedBox(height: 8),
        ...vitalSignsWidgets,
      ],
    );
  }

  // Método para construir sección SAMPLE
  Widget _buildSampleSection(Map<String, dynamic> data) {
    final sampleFields = [
      {'key': 'sampleAlergias', 'label': 'Alergias', 'icon': Icons.warning},
      {
        'key': 'sampleMedicamentos',
        'label': 'Medicamentos',
        'icon': Icons.medication,
      },
      {
        'key': 'sampleEnfermedades',
        'label': 'Historia médica previa',
        'icon': Icons.history,
      },
      {
        'key': 'sampleHoraAlimento',
        'label': 'Última ingesta oral',
        'icon': Icons.restaurant,
      },
      {
        'key': 'sampleEventosPrevios',
        'label': 'Eventos previos',
        'icon': Icons.event,
      },
    ];

    final sampleWidgets = <Widget>[];
    bool hasSampleData = false;

    for (final field in sampleFields) {
      final value = data[field['key']]?.toString();
      if (value != null && value.isNotEmpty) {
        hasSampleData = true;
        sampleWidgets.add(
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(field['icon'] as IconData, color: Colors.orange, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        field['label'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black87,
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
    }

    if (!hasSampleData) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
            const SizedBox(width: 12),
            Text(
              'No hay datos de evaluación SAMPLE',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Evaluación SAMPLE',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.orange[700],
          ),
        ),
        const SizedBox(height: 8),
        ...sampleWidgets,
      ],
    );
  }

  // Método para construir lista de insumos
  Widget _buildInsumosList(Map<String, dynamic> data) {
    final insumosList = data['insumos'] as List<dynamic>? ?? [];

    if (insumosList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
            const SizedBox(width: 12),
            Text(
              'No hay insumos registrados',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Insumos Utilizados',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.amber[700],
          ),
        ),
        const SizedBox(height: 8),
        ...insumosList.map((insumo) {
          final cantidad = insumo['cantidad']?.toString() ?? '';
          final articulo = insumo['articulo']?.toString() ?? '';

          return Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.inventory, color: Colors.amber, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        articulo,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cantidad: $cantidad',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
