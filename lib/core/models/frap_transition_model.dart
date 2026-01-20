import 'package:bg_med/core/models/frap.dart';
import 'package:bg_med/core/models/frap_firestore.dart';
import 'package:bg_med/core/models/patient.dart';
import 'package:bg_med/core/models/clinical_history.dart';
import 'package:bg_med/core/models/physical_exam.dart';
import 'package:bg_med/core/models/insumo.dart';
import 'package:bg_med/core/models/personal_medico.dart';
import 'package:bg_med/core/models/escalas_obstetricas.dart';
import 'package:bg_med/core/services/frap_data_validator.dart';
import 'package:bg_med/core/services/frap_conversion_logger.dart';

/// Modelo híbrido de transición para migración gradual entre modelos
class FrapTransitionModel {
  final Frap? localModel;
  final FrapFirestore? cloudModel;
  final DateTime lastSync;
  final bool needsMigration;
  final MigrationStatus migrationStatus;
  final List<String> migrationErrors;
  final Map<String, dynamic> migrationMetadata;

  const FrapTransitionModel({
    this.localModel,
    this.cloudModel,
    required this.lastSync,
    this.needsMigration = false,
    this.migrationStatus = MigrationStatus.notStarted,
    this.migrationErrors = const [],
    this.migrationMetadata = const {},
  });

  /// Crear modelo híbrido desde modelo local
  factory FrapTransitionModel.fromLocal(Frap local) {
    return FrapTransitionModel(
      localModel: local,
      lastSync: local.updatedAt,
      needsMigration: false,
      migrationStatus: MigrationStatus.completed,
    );
  }

  /// Crear modelo híbrido desde modelo nube
  factory FrapTransitionModel.fromCloud(FrapFirestore cloud) {
    return FrapTransitionModel(
      cloudModel: cloud,
      lastSync: cloud.updatedAt,
      needsMigration: true,
      migrationStatus: MigrationStatus.pending,
    );
  }

  /// Crear modelo híbrido con ambos modelos
  factory FrapTransitionModel.hybrid({
    required Frap local,
    required FrapFirestore cloud,
    required DateTime lastSync,
  }) {
    final needsMigration = !_areModelsEquivalent(local, cloud);

    return FrapTransitionModel(
      localModel: local,
      cloudModel: cloud,
      lastSync: lastSync,
      needsMigration: needsMigration,
      migrationStatus:
          needsMigration ? MigrationStatus.pending : MigrationStatus.completed,
    );
  }

  /// Verificar si los modelos son equivalentes
  static bool _areModelsEquivalent(Frap local, FrapFirestore cloud) {
    // Comparar datos críticos del paciente
    final localName = local.patient.fullName.toLowerCase();
    final cloudName = cloud.patientName.toLowerCase();

    if (localName != cloudName) return false;

    if (local.patient.age != cloud.patientAge) return false;

    if (local.patient.sex != cloud.patientGender) return false;

    // Comparar fechas de creación (con tolerancia de 5 minutos)
    final timeDifference = local.createdAt.difference(cloud.createdAt).abs();
    if (timeDifference.inMinutes > 5) return false;

    return true;
  }

  /// Obtener el modelo estándar (local como prioridad)
  Frap? get standardModel => localModel;

  /// Obtener el modelo de respaldo (nube)
  FrapFirestore? get backupModel => cloudModel;

  /// Obtener el nombre del paciente
  String get patientName {
    if (localModel != null) {
      return localModel!.patient.fullName;
    } else if (cloudModel != null) {
      return cloudModel!.patientName;
    }
    return 'Sin nombre';
  }

  /// Obtener la edad del paciente
  int get patientAge {
    if (localModel != null) {
      return localModel!.patient.age;
    } else if (cloudModel != null) {
      return cloudModel!.patientAge;
    }
    return 0;
  }

  /// Obtener el género del paciente
  String get patientGender {
    if (localModel != null) {
      return localModel!.patient.sex;
    } else if (cloudModel != null) {
      return cloudModel!.patientGender;
    }
    return '';
  }

  /// Obtener el porcentaje de completitud
  double get completionPercentage {
    if (localModel != null) {
      return localModel!.completionPercentage;
    } else if (cloudModel != null) {
      return cloudModel!.completionPercentage;
    }
    return 0.0;
  }

  /// Obtener la fecha de creación
  DateTime get createdAt {
    if (localModel != null) {
      return localModel!.createdAt;
    } else if (cloudModel != null) {
      return cloudModel!.createdAt;
    }
    return DateTime.now();
  }

  /// Obtener la fecha de actualización
  DateTime get updatedAt {
    if (localModel != null) {
      return localModel!.updatedAt;
    } else if (cloudModel != null) {
      return cloudModel!.updatedAt;
    }
    return DateTime.now();
  }

  /// Obtener el ID del registro
  String get id {
    if (localModel != null) {
      return localModel!.id;
    } else if (cloudModel != null) {
      return cloudModel!.id ?? '';
    }
    return '';
  }

  /// Verificar si el registro está sincronizado
  bool get isSynced {
    if (localModel != null) {
      return localModel!.isSynced;
    }
    return true; // Los registros de nube se consideran sincronizados
  }

  /// Migrar a modelo local estándar
  Frap migrateToLocalStandard() {
    if (localModel != null) {
      return localModel!;
    }

    if (cloudModel != null) {
      try {
        FrapConversionLogger.logConversionStart(
          'cloud_to_local',
          cloudModel!.id ?? 'unknown',
        );

        // Validar y convertir datos del paciente
        final patientValidation = FrapDataValidator.validatePatientData(
          cloudModel!.patientInfo,
        );
        final patientData = patientValidation.cleanedData ?? {};

        // Validar y convertir historia clínica
        final clinicalValidation =
            FrapDataValidator.validateClinicalHistoryData(
              cloudModel!.clinicalHistory,
            );
        final clinicalData = clinicalValidation.cleanedData ?? {};

        // Validar y convertir examen físico
        final examValidation = FrapDataValidator.validatePhysicalExamData(
          cloudModel!.physicalExam,
        );
        final examData = examValidation.cleanedData ?? {};

        // Crear modelo local
        final localFrap = Frap(
          id:
              cloudModel!.id ??
              'migrated_${DateTime.now().millisecondsSinceEpoch}',
          patient: _createPatientFromCloud(patientData),
          clinicalHistory: _createClinicalHistoryFromCloud(clinicalData),
          physicalExam: _createPhysicalExamFromCloud(examData),
          createdAt: cloudModel!.createdAt,
          updatedAt: cloudModel!.updatedAt,
          serviceInfo: _convertSectionData(cloudModel!.serviceInfo),
          registryInfo: _convertSectionData(cloudModel!.registryInfo),
          management: _convertSectionData(cloudModel!.management),
          medications: _convertSectionData(cloudModel!.medications),
          gynecoObstetric: _convertSectionData(cloudModel!.gynecoObstetric),
          attentionNegative: _convertSectionData(cloudModel!.attentionNegative),
          pathologicalHistory: _convertSectionData(
            cloudModel!.pathologicalHistory,
          ),
          priorityJustification: _convertSectionData(
            cloudModel!.priorityJustification,
          ),
          injuryLocation: _convertSectionData(cloudModel!.injuryLocation),
          receivingUnit: _convertSectionData(cloudModel!.receivingUnit),
          patientReception: _convertSectionData(cloudModel!.patientReception),
          insumos: _convertInsumosFromCloud(cloudModel!),
          personalMedico: _convertPersonalMedicoFromCloud(cloudModel!),
          escalasObstetricas: _convertEscalasObstetricasFromCloud(cloudModel!),
          isSynced: true,
        );

        FrapConversionLogger.logConversionSuccess(
          'cloud_to_local',
          localFrap.id,
          {
            'patientFields': patientData.length,
            'clinicalFields': clinicalData.length,
            'examFields': examData.length,
          },
        );

        return localFrap;
      } catch (e, stackTrace) {
        FrapConversionLogger.logConversionError(
          'cloud_to_local',
          cloudModel!.id ?? 'unknown',
          e.toString(),
          stackTrace,
        );
        rethrow;
      }
    }

    throw Exception('No hay modelo disponible para migración');
  }

  /// Migrar a modelo nube estándar
  FrapFirestore migrateToCloudStandard() {
    if (cloudModel != null) {
      return cloudModel!;
    }

    if (localModel != null) {
      try {
        FrapConversionLogger.logConversionStart(
          'local_to_cloud',
          localModel!.id,
        );

        final cloudFrap = FrapFirestore(
          id: localModel!.id,
          userId: '', // Se debe obtener del contexto de autenticación
          createdAt: localModel!.createdAt,
          updatedAt: localModel!.updatedAt,
          serviceInfo: localModel!.serviceInfo,
          registryInfo: localModel!.registryInfo,
          patientInfo: _createPatientInfoFromLocal(localModel!),
          management: _createManagementFromLocal(localModel!),
          medications: localModel!.medications,
          gynecoObstetric: _createGynecoObstetricFromLocal(localModel!),
          attentionNegative: localModel!.attentionNegative,
          pathologicalHistory: localModel!.pathologicalHistory,
          clinicalHistory: _createClinicalHistoryFromLocal(localModel!),
          physicalExam: _createPhysicalExamFromLocal(localModel!),
          priorityJustification: localModel!.priorityJustification,
          injuryLocation: localModel!.injuryLocation,
          receivingUnit: localModel!.receivingUnit,
          patientReception: localModel!.patientReception,
        );

        FrapConversionLogger.logConversionSuccess(
          'local_to_cloud',
          cloudFrap.id ?? '',
          {
            'patientFields': cloudFrap.patientInfo.length,
            'clinicalFields': cloudFrap.clinicalHistory.length,
            'examFields': cloudFrap.physicalExam.length,
          },
        );

        return cloudFrap;
      } catch (e, stackTrace) {
        FrapConversionLogger.logConversionError(
          'local_to_cloud',
          localModel!.id,
          e.toString(),
          stackTrace,
        );
        rethrow;
      }
    }

    throw Exception('No hay modelo disponible para migración');
  }

  // Métodos auxiliares para conversión
  Patient _createPatientFromCloud(Map<String, dynamic> patientData) {
    return Patient(
      name:
          '${patientData['firstName'] ?? ''} ${patientData['paternalLastName'] ?? ''}',
      age: patientData['age'] ?? 0,
      sex: patientData['sex'] ?? '',
      address: patientData['address'] ?? '',
      firstName: patientData['firstName'] ?? '',
      paternalLastName: patientData['paternalLastName'] ?? '',
      maternalLastName: patientData['maternalLastName'] ?? '',
      phone: patientData['phone'] ?? '',
      street: patientData['street'] ?? '',
      exteriorNumber: patientData['exteriorNumber'] ?? '',
      interiorNumber: patientData['interiorNumber'],
      neighborhood: patientData['neighborhood'] ?? '',
      city: patientData['city'] ?? '',
      insurance: patientData['insurance'] ?? '',
      responsiblePerson: patientData['responsiblePerson'],
      gender: patientData['gender'] ?? '',
      addressDetails: patientData['addressDetails'] ?? '',
      tipoEntrega: patientData['tipoEntrega'] ?? '',
    );
  }

  ClinicalHistory _createClinicalHistoryFromCloud(
    Map<String, dynamic> clinicalData,
  ) {
    return ClinicalHistory(
      traumaCraneo: clinicalData['traumaCraneo'] ?? false,
      traumaCraneoEspecifique: clinicalData['traumaCraneoEspecifique'] ?? '',
      traumaTorax: clinicalData['traumaTorax'] ?? false,
      traumaToraxEspecifique: clinicalData['traumaToraxEspecifique'] ?? '',
      traumaAbdomen: clinicalData['traumaAbdomen'] ?? false,
      traumaAbdomenEspecifique: clinicalData['traumaAbdomenEspecifique'] ?? '',
      traumaColumna: clinicalData['traumaColumna'] ?? false,
      traumaColumnaEspecifique: clinicalData['traumaColumnaEspecifique'] ?? '',
      traumaExtremidades: clinicalData['traumaExtremidades'] ?? false,
      traumaExtremidadesEspecifique:
          clinicalData['traumaExtremidadesEspecifique'] ?? '',
      traumaPelvis: clinicalData['traumaPelvis'] ?? false,
      traumaPelvisEspecifique: clinicalData['traumaPelvisEspecifique'] ?? '',
      traumaOtros: clinicalData['traumaOtros'] ?? false,
      traumaOtrosEspecifique: clinicalData['traumaOtrosEspecifique'] ?? '',
      agenteCausal: clinicalData['agenteCausal'] ?? '',
      cinematica: clinicalData['cinematica'] ?? '',
      medidaSeguridad: clinicalData['medidaSeguridad'] ?? '',
      observaciones: clinicalData['observaciones'] ?? '',
    );
  }

  PhysicalExam _createPhysicalExamFromCloud(Map<String, dynamic> examData) {
    return PhysicalExam.fromFormData(examData);
  }

  Map<String, dynamic> _convertSectionData(Map<String, dynamic> cloudSection) {
    if (cloudSection.isEmpty) return {};

    final validation = FrapDataValidator.validateSectionData(cloudSection);
    return validation.cleanedData ?? {};
  }

  List<Insumo> _convertInsumosFromCloud(FrapFirestore cloud) {
    final insumosData =
        cloud.serviceInfo['insumos'] ?? cloud.management['insumos'] ?? [];

    if (insumosData is List) {
      final validation = FrapDataValidator.validateInsumosData(insumosData);
      if (validation.isValid && validation.cleanedData != null) {
        final cleanedInsumos = validation.cleanedData!['insumos'] as List;
        return cleanedInsumos.map((insumoData) {
          return Insumo(
            cantidad: insumoData['cantidad'] ?? 0,
            articulo: insumoData['articulo'] ?? '',
          );
        }).toList();
      }
    }

    return [];
  }

  List<PersonalMedico> _convertPersonalMedicoFromCloud(FrapFirestore cloud) {
    final personalData =
        cloud.serviceInfo['personalMedico'] ??
        cloud.management['personalMedico'] ??
        [];

    if (personalData is List) {
      final validation = FrapDataValidator.validatePersonalMedicoData(
        personalData,
      );
      if (validation.isValid && validation.cleanedData != null) {
        final cleanedPersonal =
            validation.cleanedData!['personalMedico'] as List;
        return cleanedPersonal.map((personalData) {
          return PersonalMedico(
            nombre: personalData['nombre'] ?? '',
            especialidad: personalData['especialidad'] ?? '',
            cedula: personalData['cedula'] ?? '',
          );
        }).toList();
      }
    }

    return [];
  }

  EscalasObstetricas? _convertEscalasObstetricasFromCloud(FrapFirestore cloud) {
    final escalasData =
        cloud.gynecoObstetric['escalasObstetricas'] ??
        cloud.gynecoObstetric['escalas'] ??
        {};

    if (escalasData is Map<String, dynamic>) {
      final validation = FrapDataValidator.validateEscalasObstetricasData(
        escalasData,
      );
      if (validation.isValid && validation.cleanedData != null) {
        final cleanedData = validation.cleanedData!;
        return EscalasObstetricas(
          silvermanAnderson: Map<String, int>.from(
            cleanedData['silvermanAnderson'] ?? {},
          ),
          apgar: Map<String, int>.from(cleanedData['apgar'] ?? {}),
          frecuenciaCardiacaFetal: cleanedData['frecuenciaCardiacaFetal'] ?? 0,
          contracciones: cleanedData['contracciones'] ?? '',
        );
      }
    }

    return null;
  }

  Map<String, dynamic> _createPatientInfoFromLocal(Frap local) {
    return {
      'firstName': local.patient.firstName,
      'paternalLastName': local.patient.paternalLastName,
      'maternalLastName': local.patient.maternalLastName,
      'age': local.patient.age,
      'sex': local.patient.sex,
      'address': local.patient.address,
      'phone': local.patient.phone,
      'street': local.patient.street,
      'exteriorNumber': local.patient.exteriorNumber,
      'interiorNumber': local.patient.interiorNumber,
      'neighborhood': local.patient.neighborhood,
      'city': local.patient.city,
      'insurance': local.patient.insurance,
      'responsiblePerson': local.patient.responsiblePerson,
      'gender': local.patient.gender,
      'addressDetails': local.patient.addressDetails,
      'tipoEntrega': local.patient.tipoEntrega,
    };
  }

  Map<String, dynamic> _createManagementFromLocal(Frap local) {
    return {
      ...local.management,
      'insumos': local.insumos.map((i) => i.toJson()).toList(),
      'personalMedico': local.personalMedico.map((p) => p.toJson()).toList(),
    };
  }

  Map<String, dynamic> _createGynecoObstetricFromLocal(Frap local) {
    return {
      ...local.gynecoObstetric,
      'escalasObstetricas': local.escalasObstetricas?.toJson(),
    };
  }

  Map<String, dynamic> _createClinicalHistoryFromLocal(Frap local) {
    return {
      'traumaCraneo': local.clinicalHistory.traumaCraneo,
      'traumaCraneoEspecifique': local.clinicalHistory.traumaCraneoEspecifique,
      'traumaTorax': local.clinicalHistory.traumaTorax,
      'traumaToraxEspecifique': local.clinicalHistory.traumaToraxEspecifique,
      'traumaAbdomen': local.clinicalHistory.traumaAbdomen,
      'traumaAbdomenEspecifique':
          local.clinicalHistory.traumaAbdomenEspecifique,
      'traumaColumna': local.clinicalHistory.traumaColumna,
      'traumaColumnaEspecifique':
          local.clinicalHistory.traumaColumnaEspecifique,
      'traumaExtremidades': local.clinicalHistory.traumaExtremidades,
      'traumaExtremidadesEspecifique':
          local.clinicalHistory.traumaExtremidadesEspecifique,
      'traumaPelvis': local.clinicalHistory.traumaPelvis,
      'traumaPelvisEspecifique': local.clinicalHistory.traumaPelvisEspecifique,
      'traumaOtros': local.clinicalHistory.traumaOtros,
      'traumaOtrosEspecifique': local.clinicalHistory.traumaOtrosEspecifique,
      'agenteCausal': local.clinicalHistory.agenteCausal,
      'cinematica': local.clinicalHistory.cinematica,
      'medidaSeguridad': local.clinicalHistory.medidaSeguridad,
      'observaciones': local.clinicalHistory.observaciones,
    };
  }

  Map<String, dynamic> _createPhysicalExamFromLocal(Frap local) {
    return local.physicalExam.toFirebaseFormat();
  }

  /// Crear copia con cambios
  FrapTransitionModel copyWith({
    Frap? localModel,
    FrapFirestore? cloudModel,
    DateTime? lastSync,
    bool? needsMigration,
    MigrationStatus? migrationStatus,
    List<String>? migrationErrors,
    Map<String, dynamic>? migrationMetadata,
  }) {
    return FrapTransitionModel(
      localModel: localModel ?? this.localModel,
      cloudModel: cloudModel ?? this.cloudModel,
      lastSync: lastSync ?? this.lastSync,
      needsMigration: needsMigration ?? this.needsMigration,
      migrationStatus: migrationStatus ?? this.migrationStatus,
      migrationErrors: migrationErrors ?? this.migrationErrors,
      migrationMetadata: migrationMetadata ?? this.migrationMetadata,
    );
  }
}

/// Estado de migración
enum MigrationStatus { notStarted, pending, inProgress, completed, failed }
