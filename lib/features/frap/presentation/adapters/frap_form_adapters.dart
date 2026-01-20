import 'package:bg_med/core/models/frap.dart';
import 'package:bg_med/core/models/frap_firestore.dart';
import 'package:bg_med/core/models/frap_transition_model.dart';
import 'package:bg_med/core/models/insumo.dart';
import 'package:bg_med/core/models/personal_medico.dart';
import 'package:bg_med/core/models/escalas_obstetricas.dart';
import 'package:bg_med/core/models/patient.dart';
import 'package:bg_med/core/models/clinical_history.dart';
import 'package:bg_med/core/models/physical_exam.dart';
import 'package:bg_med/core/services/frap_data_validator.dart';

/// Adaptadores de formularios para manejo de datos híbridos
class FrapFormAdapters {
  /// Adaptador para datos de insumos
  static Map<String, dynamic> adaptInsumos(
    dynamic data, {
    bool isFromCloud = false,
  }) {
    if (data == null) {
      return {
        'insumosList': <Map<String, dynamic>>[],
        'insumos': '',
        'totalInsumos': 0,
        'totalCantidad': 0,
      };
    }

    if (isFromCloud) {
      // Datos vienen de la nube (Map<String, dynamic>)
      if (data is Map<String, dynamic>) {
        // Verificar si ya están en formato de lista
        if (data['insumosList'] != null && data['insumosList'] is List) {
          return _normalizeInsumosData(data);
        }

        // Buscar insumos en diferentes ubicaciones
        final insumosData = data['insumos'] ?? [];
        if (insumosData is List) {
          final validation = FrapDataValidator.validateInsumosData(insumosData);
          if (validation.isValid && validation.cleanedData != null) {
            final cleanedInsumos = validation.cleanedData!['insumos'] as List;
            return {
              'insumosList': cleanedInsumos,
              'insumos': cleanedInsumos
                  .map((i) => '${i['cantidad']} - ${i['articulo']}')
                  .join('\n'),
              'totalInsumos': cleanedInsumos.length,
              'totalCantidad': cleanedInsumos.fold(
                0,
                (sum, i) => sum + (i['cantidad'] as int),
              ),
            };
          }
        }
      }
    } else {
      // Datos vienen del modelo local (List<Insumo>)
      if (data is List<Insumo>) {
        return {
          'insumosList': data.map((i) => i.toJson()).toList(),
          'insumos': data
              .map((i) => '${i.cantidad} - ${i.articulo}')
              .join('\n'),
          'totalInsumos': data.length,
          'totalCantidad': data.fold(0, (sum, i) => sum + i.cantidad),
        };
      }
    }

    return {
      'insumosList': <Map<String, dynamic>>[],
      'insumos': '',
      'totalInsumos': 0,
      'totalCantidad': 0,
    };
  }

  /// Adaptador para datos de personal médico
  static Map<String, dynamic> adaptPersonalMedico(
    dynamic data, {
    bool isFromCloud = false,
  }) {
    if (data == null) {
      return {
        'personalMedicoList': <Map<String, dynamic>>[],
        'personalMedico': '',
        'totalPersonal': 0,
      };
    }

    if (isFromCloud) {
      // Datos vienen de la nube (Map<String, dynamic>)
      if (data is Map<String, dynamic>) {
        // Verificar si ya están en formato de lista
        if (data['personalMedicoList'] != null &&
            data['personalMedicoList'] is List) {
          return _normalizePersonalMedicoData(data);
        }

        // Buscar personal médico en diferentes ubicaciones
        final personalData = data['personalMedico'] ?? [];
        if (personalData is List) {
          final validation = FrapDataValidator.validatePersonalMedicoData(
            personalData,
          );
          if (validation.isValid && validation.cleanedData != null) {
            final cleanedPersonal =
                validation.cleanedData!['personalMedico'] as List;
            return {
              'personalMedicoList': cleanedPersonal,
              'personalMedico': cleanedPersonal
                  .map(
                    (p) =>
                        '${p['nombre']} - ${p['especialidad']} - ${p['cedula']}',
                  )
                  .join('\n'),
              'totalPersonal': cleanedPersonal.length,
            };
          }
        }
      }
    } else {
      // Datos vienen del modelo local (List<PersonalMedico>)
      if (data is List<PersonalMedico>) {
        return {
          'personalMedicoList': data.map((p) => p.toJson()).toList(),
          'personalMedico': data
              .map((p) => '${p.nombre} - ${p.especialidad} - ${p.cedula}')
              .join('\n'),
          'totalPersonal': data.length,
        };
      }
    }

    return {
      'personalMedicoList': <Map<String, dynamic>>[],
      'personalMedico': '',
      'totalPersonal': 0,
    };
  }

  /// Adaptador para escalas obstétricas
  static Map<String, dynamic> adaptEscalasObstetricas(
    dynamic data, {
    bool isFromCloud = false,
  }) {
    if (data == null) {
      return {
        'silvermanAnderson': <String, int>{},
        'apgar': <String, int>{},
        'frecuenciaCardiacaFetal': 0,
        'contracciones': '',
        'hasEscalas': false,
      };
    }

    if (isFromCloud) {
      // Datos vienen de la nube (Map<String, dynamic>)
      if (data is Map<String, dynamic>) {
        final escalasData = data['escalasObstetricas'] ?? data['escalas'] ?? {};
        if (escalasData is Map<String, dynamic>) {
          final validation = FrapDataValidator.validateEscalasObstetricasData(
            escalasData,
          );
          if (validation.isValid && validation.cleanedData != null) {
            final cleanedData = validation.cleanedData!;
            return {
              'silvermanAnderson': Map<String, int>.from(
                cleanedData['silvermanAnderson'] ?? {},
              ),
              'apgar': Map<String, int>.from(cleanedData['apgar'] ?? {}),
              'frecuenciaCardiacaFetal':
                  cleanedData['frecuenciaCardiacaFetal'] ?? 0,
              'contracciones': cleanedData['contracciones'] ?? '',
              'hasEscalas': true,
            };
          }
        }
      }
    } else {
      // Datos vienen del modelo local (EscalasObstetricas?)
      if (data is EscalasObstetricas) {
        return {
          'silvermanAnderson': data.silvermanAnderson,
          'apgar': data.apgar,
          'frecuenciaCardiacaFetal': data.frecuenciaCardiacaFetal,
          'contracciones': data.contracciones,
          'hasEscalas': true,
        };
      }
    }

    return {
      'silvermanAnderson': <String, int>{},
      'apgar': <String, int>{},
      'frecuenciaCardiacaFetal': 0,
      'contracciones': '',
      'hasEscalas': false,
    };
  }

  /// Adaptador para consentimiento de servicio
  static Map<String, dynamic> adaptConsentimientoServicio(
    dynamic data, {
    bool isFromCloud = false,
  }) {
    if (data == null) {
      return {
        'consentimientoSignature': '',
        'hasConsentimiento': false,
        'timestamp': '',
      };
    }

    if (isFromCloud) {
      // En la nube, el consentimiento puede estar en serviceInfo
      if (data is Map<String, dynamic>) {
        final consentimiento =
            data['consentimientoSignature'] ?? data['consentimiento'] ?? '';
        return {
          'consentimientoSignature': consentimiento,
          'hasConsentimiento': consentimiento.toString().isNotEmpty,
          'timestamp': data['timestamp'] ?? '',
        };
      }
    } else {
      // Datos vienen del modelo local (String)
      if (data is String) {
        return {
          'consentimientoSignature': data,
          'hasConsentimiento': data.isNotEmpty,
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
    }

    return {
      'consentimientoSignature': '',
      'hasConsentimiento': false,
      'timestamp': '',
    };
  }

  /// Adaptador para datos de historia clínica
  static Map<String, dynamic> adaptClinicalHistory(
    dynamic data, {
    bool isFromCloud = false,
  }) {
    final defaultData = {
      'allergies': '',
      'medications': '',
      'previousIllnesses': '',
      'currentSymptoms': '',
      'pain': '',
      'painScale': '',
      'dosage': '',
      'frequency': '',
      'route': '',
      'time': '',
      'previousSurgeries': '',
      'hospitalizations': '',
      'transfusions': '',
      'horaUltimoAlimento': '',
      'eventosPrevios': '',
    };

    if (data == null) return defaultData;

    if (isFromCloud) {
      // Datos vienen de la nube (Map<String, dynamic>)
      if (data is Map<String, dynamic>) {
        final validation = FrapDataValidator.validateClinicalHistoryData(data);
        if (validation.isValid && validation.cleanedData != null) {
          return {...defaultData, ...validation.cleanedData!};
        }
      }
    } else {
      // Datos vienen del modelo local (ClinicalHistory)
      if (data is ClinicalHistory) {
        return {
          'traumaCraneo': data.traumaCraneo,
          'traumaCraneoEspecifique': data.traumaCraneoEspecifique,
          'traumaTorax': data.traumaTorax,
          'traumaToraxEspecifique': data.traumaToraxEspecifique,
          'traumaAbdomen': data.traumaAbdomen,
          'traumaAbdomenEspecifique': data.traumaAbdomenEspecifique,
          'traumaColumna': data.traumaColumna,
          'traumaColumnaEspecifique': data.traumaColumnaEspecifique,
          'traumaExtremidades': data.traumaExtremidades,
          'traumaExtremidadesEspecifique': data.traumaExtremidadesEspecifique,
          'traumaPelvis': data.traumaPelvis,
          'traumaPelvisEspecifique': data.traumaPelvisEspecifique,
          'traumaOtros': data.traumaOtros,
          'traumaOtrosEspecifique': data.traumaOtrosEspecifique,
          'agenteCausal': data.agenteCausal,
          'cinematica': data.cinematica,
          'medidaSeguridad': data.medidaSeguridad,
          'observaciones': data.observaciones,
        };
      }
    }

    return defaultData;
  }

  /// Adaptador para datos de exploración física
  static Map<String, dynamic> adaptPhysicalExam(
    dynamic data, {
    bool isFromCloud = false,
  }) {
    final defaultData = {
      'eva': '',
      'llc': '',
      'glucosa': '',
      'ta': '',
      'sampleAlergias': '',
      'sampleMedicamentos': '',
      'sampleEnfermedades': '',
      'sampleHoraAlimento': '',
      'sampleEventosPrevios': '',
      'timeColumns': <String>[],
      'vitalSignsData': <String, Map<String, String>>{},
      'timestamp': '',
    };

    if (data == null) return defaultData;

    if (isFromCloud) {
      // Datos vienen de la nube (Map<String, dynamic>)
      if (data is Map<String, dynamic>) {
        final validation = FrapDataValidator.validatePhysicalExamData(data);
        if (validation.isValid && validation.cleanedData != null) {
          return {...defaultData, ...validation.cleanedData!};
        }
      }
    } else {
      // Datos vienen del modelo local (PhysicalExam)
      if (data is PhysicalExam) {
        return {
          'eva': data.eva,
          'llc': data.llc,
          'glucosa': data.glucosa,
          'ta': data.ta,
          'sampleAlergias': data.sampleAlergias,
          'sampleMedicamentos': data.sampleMedicamentos,
          'sampleEnfermedades': data.sampleEnfermedades,
          'sampleHoraAlimento': data.sampleHoraAlimento,
          'sampleEventosPrevios': data.sampleEventosPrevios,
          'timeColumns': data.timeColumns,
          'vitalSignsData': data.vitalSignsData,
          'timestamp': data.timestamp,
        };
      }
    }

    return defaultData;
  }

  /// Adaptador para datos de paciente completos
  static Map<String, dynamic> adaptPatientData(
    dynamic data, {
    bool isFromCloud = false,
  }) {
    final defaultData = {
      'firstName': '',
      'paternalLastName': '',
      'maternalLastName': '',
      'age': 0,
      'sex': '',
      'address': '',
      'phone': '',
      'street': '',
      'exteriorNumber': '',
      'interiorNumber': '',
      'neighborhood': '',
      'city': '',
      'insurance': '',
      'responsiblePerson': '',
      'gender': '',
      'addressDetails': '',
      'tipoEntrega': '',
    };

    if (data == null) return defaultData;

    if (isFromCloud) {
      // Datos vienen de la nube (Map<String, dynamic>)
      if (data is Map<String, dynamic>) {
        final validation = FrapDataValidator.validatePatientData(data);
        if (validation.isValid && validation.cleanedData != null) {
          return {...defaultData, ...validation.cleanedData!};
        }
      }
    } else {
      // Datos vienen del modelo local (Patient)
      if (data is Patient) {
        return {
          'firstName': data.firstName,
          'paternalLastName': data.paternalLastName,
          'maternalLastName': data.maternalLastName,
          'age': data.age,
          'sex': data.sex,
          'address': data.address,
          'phone': data.phone,
          'street': data.street,
          'exteriorNumber': data.exteriorNumber,
          'interiorNumber': data.interiorNumber,
          'neighborhood': data.neighborhood,
          'city': data.city,
          'insurance': data.insurance,
          'responsiblePerson': data.responsiblePerson,
          'gender': data.gender,
          'addressDetails': data.addressDetails,
          'tipoEntrega': data.tipoEntrega,
        };
      }
    }

    return defaultData;
  }

  /// Adaptador universal para cualquier registro FRAP
  static Map<String, dynamic> adaptFrapRecord(dynamic record) {
    final adaptedData = <String, dynamic>{};

    if (record is Frap) {
      // Registro local
      adaptedData.addAll({
        'id': record.id,
        'createdAt': record.createdAt,
        'updatedAt': record.updatedAt,
        'isSynced': record.isSynced,
        'isLocal': true,
        'isCloud': false,
      });

      // Datos del paciente
      adaptedData['patientInfo'] = adaptPatientData(
        record.patient,
        isFromCloud: false,
      );

      // Campos específicos del modelo local
      adaptedData['insumos'] = adaptInsumos(record.insumos, isFromCloud: false);
      adaptedData['personalMedico'] = adaptPersonalMedico(
        record.personalMedico,
        isFromCloud: false,
      );
      adaptedData['escalasObstetricas'] = adaptEscalasObstetricas(
        record.escalasObstetricas,
        isFromCloud: false,
      );
      adaptedData['consentimientoServicio'] = adaptConsentimientoServicio(
        record.serviceInfo['consentimientoSignature'],
        isFromCloud: false,
      );
      adaptedData['clinicalHistory'] = adaptClinicalHistory(
        record.clinicalHistory,
        isFromCloud: false,
      );
      adaptedData['physicalExam'] = adaptPhysicalExam(
        record.physicalExam,
        isFromCloud: false,
      );

      // Secciones comunes
      adaptedData.addAll({
        'serviceInfo': record.serviceInfo,
        'registryInfo': record.registryInfo,
        'management': record.management,
        'medications': record.medications,
        'gynecoObstetric': record.gynecoObstetric,
        'attentionNegative': record.attentionNegative,
        'pathologicalHistory': record.pathologicalHistory,
        'priorityJustification': record.priorityJustification,
        'injuryLocation': record.injuryLocation,
        'receivingUnit': record.receivingUnit,
        'patientReception': record.patientReception,
      });
    } else if (record is FrapFirestore) {
      // Registro de la nube
      adaptedData.addAll({
        'id': record.id,
        'userId': record.userId,
        'createdAt': record.createdAt,
        'updatedAt': record.updatedAt,
        'isSynced': true,
        'isLocal': false,
        'isCloud': true,
      });

      // Datos del paciente
      adaptedData['patientInfo'] = adaptPatientData(
        record.patientInfo,
        isFromCloud: true,
      );

      // Campos específicos del modelo local (extraer de secciones de nube)
      adaptedData['insumos'] = adaptInsumos(
        record.management,
        isFromCloud: true,
      );
      adaptedData['personalMedico'] = adaptPersonalMedico(
        record.management,
        isFromCloud: true,
      );
      adaptedData['escalasObstetricas'] = adaptEscalasObstetricas(
        record.gynecoObstetric,
        isFromCloud: true,
      );
      adaptedData['consentimientoServicio'] = adaptConsentimientoServicio(
        record.serviceInfo,
        isFromCloud: true,
      );
      adaptedData['clinicalHistory'] = adaptClinicalHistory(
        record.serviceInfo,
        isFromCloud: true,
      );
      adaptedData['physicalExam'] = adaptPhysicalExam(
        record.serviceInfo,
        isFromCloud: true,
      );

      // Secciones comunes
      adaptedData.addAll({
        'serviceInfo': record.serviceInfo,
        'registryInfo': record.registryInfo,
        'management': record.management,
        'medications': record.medications,
        'gynecoObstetric': record.gynecoObstetric,
        'attentionNegative': record.attentionNegative,
        'pathologicalHistory': record.pathologicalHistory,
        'priorityJustification': record.priorityJustification,
        'injuryLocation': record.injuryLocation,
        'receivingUnit': record.receivingUnit,
        'patientReception': record.patientReception,
      });
    } else if (record is FrapTransitionModel) {
      // Modelo de transición - usar el modelo estándar (local)
      if (record.localModel != null) {
        return adaptFrapRecord(record.localModel!);
      } else if (record.cloudModel != null) {
        return adaptFrapRecord(record.cloudModel!);
      }
    }

    return adaptedData;
  }

  /// Normalizar datos de insumos
  static Map<String, dynamic> _normalizeInsumosData(Map<String, dynamic> data) {
    final insumosList = data['insumosList'] as List? ?? [];
    return {
      'insumosList': insumosList,
      'insumos': data['insumos'] ?? '',
      'totalInsumos': data['totalInsumos'] ?? insumosList.length,
      'totalCantidad': data['totalCantidad'] ?? 0,
    };
  }

  /// Normalizar datos de personal médico
  static Map<String, dynamic> _normalizePersonalMedicoData(
    Map<String, dynamic> data,
  ) {
    final personalList = data['personalMedicoList'] as List? ?? [];
    return {
      'personalMedicoList': personalList,
      'personalMedico': data['personalMedico'] ?? '',
      'totalPersonal': data['totalPersonal'] ?? personalList.length,
    };
  }

  /// Detectar el tipo de origen de los datos
  static DataOrigin detectDataOrigin(dynamic data) {
    if (data is Frap) return DataOrigin.local;
    if (data is FrapFirestore) return DataOrigin.cloud;
    if (data is FrapTransitionModel) return DataOrigin.hybrid;
    if (data is Map<String, dynamic>) {
      if (data.containsKey('userId')) return DataOrigin.cloud;
      if (data.containsKey('isSynced')) return DataOrigin.local;
      return DataOrigin.unknown;
    }
    return DataOrigin.unknown;
  }

  /// Obtener campos faltantes en conversión
  static List<String> getMissingFields(
    Map<String, dynamic> source,
    DataOrigin targetOrigin,
  ) {
    final missingFields = <String>[];

    if (targetOrigin == DataOrigin.local) {
      // Verificar campos específicos del modelo local
      if (!source.containsKey('insumos') ||
          (source['insumos'] is List && (source['insumos'] as List).isEmpty)) {
        missingFields.add('insumos');
      }
      if (!source.containsKey('personalMedico') ||
          (source['personalMedico'] is List &&
              (source['personalMedico'] as List).isEmpty)) {
        missingFields.add('personalMedico');
      }
      if (!source.containsKey('escalasObstetricas') ||
          source['escalasObstetricas'] == null) {
        missingFields.add('escalasObstetricas');
      }
      if (!source.containsKey('isSynced')) {
        missingFields.add('isSynced');
      }
    } else if (targetOrigin == DataOrigin.cloud) {
      // Verificar campos específicos del modelo nube
      if (!source.containsKey('userId') ||
          source['userId'] == null ||
          source['userId'].toString().isEmpty) {
        missingFields.add('userId');
      }
    }

    return missingFields;
  }

  /// Convertir datos de signos vitales dinámicos a formato de tabla
  static Map<String, dynamic> adaptVitalSignsData(
    Map<String, Map<String, String>> vitalSignsData,
    List<String> timeColumns,
  ) {
    final adaptedData = <String, dynamic>{
      'timeColumns': timeColumns,
      'vitalSigns': <String, dynamic>{},
    };

    for (final vitalSign in vitalSignsData.keys) {
      final values = vitalSignsData[vitalSign] ?? {};
      adaptedData['vitalSigns'][vitalSign] = values;
    }

    return adaptedData;
  }

  /// Validar y limpiar datos de medicamentos
  static Map<String, dynamic> validateAndCleanMedications(dynamic data) {
    if (data == null) return {'medications': '', 'medicationsList': []};

    if (data is String) {
      return {
        'medications': data,
        'medicationsList': _parseMedicationsFromText(data),
      };
    }

    if (data is List) {
      final medicationsList =
          data.map((med) {
            if (med is Map<String, dynamic>) {
              return {
                'medicamento': med['medicamento'] ?? '',
                'dosis': med['dosis'] ?? '',
                'viaAdministracion': med['viaAdministracion'] ?? '',
                'hora': med['hora'] ?? '',
                'medicoIndico': med['medicoIndico'] ?? '',
              };
            }
            return {'medicamento': med.toString()};
          }).toList();

      return {
        'medications': medicationsList
            .map(
              (m) =>
                  '${m['medicamento']} - ${m['dosis']} - ${m['viaAdministracion']} - ${m['hora']} - ${m['medicoIndico']}',
            )
            .join('\n'),
        'medicationsList': medicationsList,
      };
    }

    return {'medications': '', 'medicationsList': []};
  }

  /// Parsear medicamentos desde texto
  static List<Map<String, dynamic>> _parseMedicationsFromText(String text) {
    final medications = <Map<String, dynamic>>[];
    final lines = text.split('\n');

    for (final line in lines) {
      if (line.trim().isNotEmpty) {
        final parts = line.split(' - ');
        medications.add({
          'medicamento': parts.isNotEmpty ? parts[0].trim() : '',
          'dosis': parts.length > 1 ? parts[1].trim() : '',
          'viaAdministracion': parts.length > 2 ? parts[2].trim() : '',
          'hora': parts.length > 3 ? parts[3].trim() : '',
          'medicoIndico': parts.length > 4 ? parts[4].trim() : '',
        });
      }
    }

    return medications;
  }

  /// Obtener campos específicos del modelo Frap
  static Map<String, dynamic> getFrapSpecificFields(Frap record) {
    return {
      'consentimientoServicio':
          record.serviceInfo['consentimientoSignature'] ?? '',
      'insumos': adaptInsumos(record.insumos, isFromCloud: false),
      'personalMedico': adaptPersonalMedico(
        record.personalMedico,
        isFromCloud: false,
      ),
      'escalasObstetricas': adaptEscalasObstetricas(
        record.escalasObstetricas,
        isFromCloud: false,
      ),
      'clinicalHistory': adaptClinicalHistory(
        record.clinicalHistory,
        isFromCloud: false,
      ),
      'physicalExam': adaptPhysicalExam(
        record.physicalExam,
        isFromCloud: false,
      ),
    };
  }

  /// Obtener campos específicos del modelo FrapFirestore
  static Map<String, dynamic> getFrapFirestoreSpecificFields(
    FrapFirestore record,
  ) {
    return {
      'consentimientoServicio': adaptConsentimientoServicio(
        record.serviceInfo,
        isFromCloud: true,
      ),
      'insumos': adaptInsumos(record.management, isFromCloud: true),
      'personalMedico': adaptPersonalMedico(
        record.management,
        isFromCloud: true,
      ),
      'escalasObstetricas': adaptEscalasObstetricas(
        record.gynecoObstetric,
        isFromCloud: true,
      ),
      'clinicalHistory': adaptClinicalHistory(
        record.serviceInfo,
        isFromCloud: true,
      ),
      'physicalExam': adaptPhysicalExam(record.serviceInfo, isFromCloud: true),
    };
  }
}

/// Enum para identificar el origen de los datos
enum DataOrigin { local, cloud, hybrid, unknown }
