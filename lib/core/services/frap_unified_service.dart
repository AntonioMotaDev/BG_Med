import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:bg_med/core/services/frap_local_service.dart';
import 'package:bg_med/core/services/frap_firestore_service.dart';
import 'package:bg_med/core/services/folio_generator_service.dart';
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
import 'package:bg_med/core/services/frap_migration_service.dart';
import 'package:bg_med/features/frap/presentation/providers/frap_data_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Helper para construir dirección completa desde un paciente local
String _buildFullAddressFromPatient(Patient patient) {
  final List<String> parts = [];

  final street = (patient.street).toString().trim();
  final exterior = (patient.exteriorNumber).toString().trim();
  final interior = (patient.interiorNumber ?? '').toString().trim();
  final neighborhood = (patient.neighborhood).toString().trim();
  final city = (patient.city).toString().trim();

  if (street.isNotEmpty) {
    String streetLine = street;
    if (exterior.isNotEmpty) {
      streetLine = '$streetLine $exterior';
    }
    if (interior.isNotEmpty) {
      streetLine = '$streetLine Int. $interior';
    }
    parts.add(streetLine);
  }
  if (neighborhood.isNotEmpty) parts.add(neighborhood);
  if (city.isNotEmpty) parts.add(city);

  return parts.join(', ');
}

// Helper para construir dirección completa desde un mapa de patientInfo (nube)
String _buildFullAddressFromMap(Map<String, dynamic> patientInfo) {
  final List<String> parts = [];

  final street = patientInfo['street']?.toString().trim() ?? '';
  final exterior = patientInfo['exteriorNumber']?.toString().trim() ?? '';
  final interior = patientInfo['interiorNumber']?.toString().trim() ?? '';
  final neighborhood = patientInfo['neighborhood']?.toString().trim() ?? '';
  final city = patientInfo['city']?.toString().trim() ?? '';

  if (street.isNotEmpty) {
    String streetLine = street;
    if (exterior.isNotEmpty) streetLine = '$streetLine $exterior';
    if (interior.isNotEmpty) streetLine = '$streetLine Int. $interior';
    parts.add(streetLine);
  }
  if (neighborhood.isNotEmpty) parts.add(neighborhood);
  if (city.isNotEmpty) parts.add(city);

  return parts.join(', ');
}

class FrapUnifiedService {
  final FrapLocalService _localService;
  final FrapFirestoreService _cloudService;
  final Connectivity _connectivity;
  late final FrapMigrationService _migrationService;
  final FolioGeneratorService _folioGenerator;

  FrapUnifiedService({
    required FrapLocalService localService,
    required FrapFirestoreService cloudService,
    Connectivity? connectivity,
  }) : _localService = localService,
       _cloudService = cloudService,
       _connectivity = connectivity ?? Connectivity(),
       _folioGenerator = FolioGeneratorService() {
    _migrationService = FrapMigrationService(
      localService: localService,
      cloudService: cloudService,
    );
  }

  /// Obtener el servicio de migración
  FrapMigrationService get migrationService => _migrationService;

  // Verificar conectividad a internet
  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      return !connectivityResults.contains(ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }

  // Guardar registro unificado (local + nube si hay conexión)
  Future<UnifiedSaveResult> saveFrapRecord(FrapData frapData) async {
    final result = UnifiedSaveResult();

    try {
      FrapConversionLogger.logConversionStart('save_unified', 'new_record');

      // Generar folio automáticamente si no está presente
      final frapDataWithFolio = await _ensureFolioExists(frapData);

      // Siempre guardar localmente primero
      final localRecordId = await _localService.createFrapRecord(
        frapData: frapDataWithFolio,
      );

      if (localRecordId != null) {
        result.localRecordId = localRecordId;
        result.savedLocally = true;

        // Intentar guardar en la nube si hay conexión
        final hasInternet = await hasInternetConnection();
        if (hasInternet) {
          try {
            final cloudRecordId = await _cloudService.createFrapRecord(
              frapData: frapDataWithFolio,
            );
            if (cloudRecordId != null) {
              result.cloudRecordId = cloudRecordId;
              result.savedToCloud = true;

              // Marcar como sincronizado en local (si el método existe)
              try {
                await _localService.markAsSynced(localRecordId);
              } catch (e) {
                // Si el método no existe, registrar la advertencia
                FrapConversionLogger.logConversionError(
                  'mark_as_synced',
                  localRecordId,
                  'Method not available: $e',
                  null,
                );
              }
            }
          } catch (e) {
            result.cloudError = e.toString();
            // El registro se mantiene local y se sincronizará después
          }
        } else {
          result.message =
              'Guardado localmente. Se sincronizará cuando haya conexión.';
        }

        result.success = true;
        result.message =
            result.message.isNotEmpty
                ? result.message
                : 'Registro guardado exitosamente';

        FrapConversionLogger.logConversionSuccess(
          'save_unified',
          localRecordId,
          {
            'savedLocally': result.savedLocally,
            'savedToCloud': result.savedToCloud,
            'hasInternet': hasInternet,
          },
        );
      } else {
        throw Exception('No se pudo guardar localmente');
      }
    } catch (e) {
      result.success = false;
      result.message = 'Error al guardar: $e';
      result.errors.add(e.toString());

      FrapConversionLogger.logConversionError(
        'save_unified',
        'new_record',
        e.toString(),
        null,
      );
    }

    return result;
  }

  // Asegurar que el folio existe en los datos
  Future<FrapData> _ensureFolioExists(FrapData frapData) async {
    // Verificar si ya existe un folio en registryInfo
    final currentRegistryInfo = Map<String, dynamic>.from(
      frapData.registryInfo,
    );
    final currentFolio = currentRegistryInfo['folio'];

    // Si no hay folio o está vacío, generar uno nuevo
    if (currentFolio == null || currentFolio.toString().trim().isEmpty) {
      try {
        // Obtener nombre del paciente para generar folio con iniciales
        final patientName = _getPatientNameFromData(frapData);
        final newFolio = await _folioGenerator.generateUniquePatientFolio(
          patientName,
        );
        currentRegistryInfo['folio'] = newFolio;

        FrapConversionLogger.logConversionSuccess('folio_generation', 'auto', {
          'folio': newFolio,
        });

        return frapData.copyWith(registryInfo: currentRegistryInfo);
      } catch (e) {
        FrapConversionLogger.logConversionError(
          'folio_generation',
          'auto',
          e.toString(),
          null,
        );
        // Si falla la generación, usar un folio con timestamp
        final fallbackFolio =
            'SN-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch}';
        currentRegistryInfo['folio'] = fallbackFolio;

        FrapConversionLogger.logConversionSuccess(
          'folio_generation',
          'fallback',
          {'folio': fallbackFolio},
        );

        return frapData.copyWith(registryInfo: currentRegistryInfo);
      }
    }

    // Si ya existe un folio, devolver los datos sin cambios
    return frapData;
  }

  // Obtener nombre del paciente desde los datos
  String _getPatientNameFromData(FrapData frapData) {
    try {
      final patientInfo = frapData.patientInfo;

      // Intentar obtener nombre completo
      final firstName = patientInfo['firstName']?.toString() ?? '';
      final paternalLastName =
          patientInfo['paternalLastName']?.toString() ?? '';
      final maternalLastName =
          patientInfo['maternalLastName']?.toString() ?? '';

      // Construir nombre completo
      final fullName =
          [
            firstName,
            paternalLastName,
            maternalLastName,
          ].where((part) => part.isNotEmpty).join(' ').trim();

      if (fullName.isNotEmpty) {
        return fullName;
      }

      // Si no hay nombre estructurado, buscar en otros campos
      final name = patientInfo['name']?.toString() ?? '';
      if (name.isNotEmpty) {
        return name;
      }

      // Si no hay nombre, usar valor por defecto
      return 'Sin Nombre';
    } catch (e) {
      FrapConversionLogger.logConversionError(
        'patient_name_extraction',
        'unknown',
        e.toString(),
        null,
      );
      return 'Sin Nombre';
    }
  }

  // Obtener todos los registros (local + nube)
  Future<List<UnifiedFrapRecord>> getAllRecords() async {
    final List<UnifiedFrapRecord> unifiedRecords = [];

    try {
      FrapConversionLogger.logConversionStart('get_all_records', 'batch');

      // Obtener registros locales
      final localRecords = await _localService.getAllFrapRecords();

      // Obtener registros de la nube si hay conexión
      List<FrapFirestore> cloudRecords = [];
      final hasInternet = await hasInternetConnection();

      if (hasInternet) {
        try {
          cloudRecords = await _cloudService.getAllFrapRecords();
        } catch (e) {
          FrapConversionLogger.logConversionError(
            'get_all_records',
            'cloud_fetch',
            e.toString(),
            null,
          );
        }
      }

      // Procesar registros locales
      for (final localRecord in localRecords) {
        unifiedRecords.add(UnifiedFrapRecord.fromLocal(localRecord));
      }

      // Procesar registros de la nube
      for (final cloudRecord in cloudRecords) {
        // Verificar si ya existe en local
        final existingLocal =
            localRecords
                .where((r) => _areRecordsEquivalent(r, cloudRecord))
                .firstOrNull;

        if (existingLocal == null) {
          // Es un registro solo de la nube
          unifiedRecords.add(UnifiedFrapRecord.fromCloud(cloudRecord));
        } else {
          // Actualizar el registro local con datos de la nube si es más reciente
          if (cloudRecord.updatedAt.isAfter(existingLocal.updatedAt)) {
            try {
              // Convertir el registro de la nube a formato local
              final updatedLocalFrap = _convertCloudToLocal(cloudRecord);
              // Mantener el ID local existente
              final frapData = _localService.convertFrapToFrapData(
                updatedLocalFrap,
              );
              await _localService.updateFrapRecord(
                frapId: existingLocal.id,
                frapData: frapData,
              );
              // Actualizar en la lista unificada
              final index = unifiedRecords.indexWhere(
                (r) => r.localRecord?.id == existingLocal.id,
              );
              if (index != -1) {
                // Recargar el registro actualizado
                final reloadedLocal = await _localService.getFrapRecord(
                  existingLocal.id,
                );
                if (reloadedLocal != null) {
                  unifiedRecords[index] = UnifiedFrapRecord.fromLocal(
                    reloadedLocal,
                  );
                }
              }
            } catch (e) {
              FrapConversionLogger.logConversionError(
                'get_all_records',
                'update_local',
                e.toString(),
                null,
              );
            }
          }
        }
      }

      // Ordenar por fecha de creación (más recientes primero)
      unifiedRecords.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      FrapConversionLogger.logConversionSuccess('get_all_records', 'batch', {
        'localRecords': localRecords.length,
        'cloudRecords': cloudRecords.length,
        'unifiedRecords': unifiedRecords.length,
      });
    } catch (e) {
      FrapConversionLogger.logConversionError(
        'get_all_records',
        'batch',
        e.toString(),
        null,
      );
    }

    return unifiedRecords;
  }

  // Verificar si dos registros son equivalentes
  bool _areRecordsEquivalent(Frap local, FrapFirestore cloud) {
    // Comparar por datos del paciente y fecha de creación
    final localPatientName = local.patient.fullName.toLowerCase();
    final cloudPatientName = cloud.patientName.toLowerCase();

    return localPatientName == cloudPatientName &&
        local.createdAt.difference(cloud.createdAt).abs().inMinutes < 5;
  }

  // Convertir registro de la nube a formato local con validación completa
  Frap _convertCloudToLocal(FrapFirestore cloud) {
    try {
      FrapConversionLogger.logConversionStart(
        'cloud_to_local',
        cloud.id ?? 'unknown',
      );

      // Validar y convertir datos del paciente
      final patientValidation = FrapDataValidator.validatePatientData(
        cloud.patientInfo,
      );
      final patientData = patientValidation.cleanedData ?? {};

      FrapConversionLogger.logValidationResult('patient', patientValidation);

      // Validar y convertir historia clínica
      final clinicalValidation = FrapDataValidator.validateClinicalHistoryData(
        cloud.clinicalHistory,
      );
      final clinicalData = clinicalValidation.cleanedData ?? {};

      FrapConversionLogger.logValidationResult(
        'clinical_history',
        clinicalValidation,
      );

      // Validar y convertir examen físico
      final examValidation = FrapDataValidator.validatePhysicalExamData(
        cloud.physicalExam,
      );
      final examData = examValidation.cleanedData ?? {};

      FrapConversionLogger.logValidationResult('physical_exam', examValidation);

      // Crear un registro local basado en los datos de la nube
      final localFrap = Frap(
        id: cloud.id ?? 'cloud_${DateTime.now().millisecondsSinceEpoch}',
        patient: Patient(
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
        ),
        clinicalHistory: ClinicalHistory(
          traumaCraneo: clinicalData['traumaCraneo'] ?? false,
          traumaCraneoEspecifique:
              clinicalData['traumaCraneoEspecifique'] ?? '',
          traumaTorax: clinicalData['traumaTorax'] ?? false,
          traumaToraxEspecifique: clinicalData['traumaToraxEspecifique'] ?? '',
          traumaAbdomen: clinicalData['traumaAbdomen'] ?? false,
          traumaAbdomenEspecifique:
              clinicalData['traumaAbdomenEspecifique'] ?? '',
          traumaColumna: clinicalData['traumaColumna'] ?? false,
          traumaColumnaEspecifique:
              clinicalData['traumaColumnaEspecifique'] ?? '',
          traumaExtremidades: clinicalData['traumaExtremidades'] ?? false,
          traumaExtremidadesEspecifique:
              clinicalData['traumaExtremidadesEspecifique'] ?? '',
          traumaPelvis: clinicalData['traumaPelvis'] ?? false,
          traumaPelvisEspecifique:
              clinicalData['traumaPelvisEspecifique'] ?? '',
          traumaOtros: clinicalData['traumaOtros'] ?? false,
          traumaOtrosEspecifique: clinicalData['traumaOtrosEspecifique'] ?? '',
          agenteCausal: clinicalData['agenteCausal'] ?? '',
          cinematica: clinicalData['cinematica'] ?? '',
          medidaSeguridad: clinicalData['medidaSeguridad'] ?? '',
          observaciones: clinicalData['observaciones'] ?? '',
        ),
        physicalExam: PhysicalExam.fromFormData(examData),
        createdAt: cloud.createdAt,
        updatedAt: cloud.updatedAt,
        serviceInfo: _convertSectionData(cloud.serviceInfo),
        registryInfo: _convertSectionData(cloud.registryInfo),
        management: _convertSectionData(cloud.management),
        medications: _convertSectionData(cloud.medications),
        gynecoObstetric: _convertSectionData(cloud.gynecoObstetric),
        attentionNegative: _convertSectionData(cloud.attentionNegative),
        pathologicalHistory: _convertSectionData(cloud.pathologicalHistory),
        priorityJustification: _convertSectionData(cloud.priorityJustification),
        injuryLocation: _convertSectionData(cloud.injuryLocation),
        receivingUnit: _convertSectionData(cloud.receivingUnit),
        patientReception: _convertSectionData(cloud.patientReception),
        consentimientoServicio: '', // Campo específico del modelo local
        insumos: _convertInsumosFromCloud(
          cloud,
        ), // Convertir insumos si existen
        personalMedico: _convertPersonalMedicoFromCloud(
          cloud,
        ), // Convertir personal médico si existe
        escalasObstetricas: _convertEscalasObstetricasFromCloud(
          cloud,
        ), // Convertir escalas si existen
        isSynced: true,
      );

      FrapConversionLogger.logConversionSuccess(
        'cloud_to_local',
        localFrap.id,
        {
          'patientFields': patientData.length,
          'clinicalFields': clinicalData.length,
          'examFields': examData.length,
          'insumos': localFrap.insumos.length,
          'personalMedico': localFrap.personalMedico.length,
        },
      );

      return localFrap;
    } catch (e, stackTrace) {
      FrapConversionLogger.logConversionError(
        'cloud_to_local',
        cloud.id ?? 'unknown',
        e.toString(),
        stackTrace,
      );
      rethrow;
    }
  }

  // Convertir datos de sección con validación
  Map<String, dynamic> _convertSectionData(Map<String, dynamic> cloudSection) {
    if (cloudSection.isEmpty) return {};

    final validation = FrapDataValidator.validateSectionData(cloudSection);
    return validation.cleanedData ?? {};
  }

  // Convertir insumos desde datos de la nube
  List<Insumo> _convertInsumosFromCloud(FrapFirestore cloud) {
    final insumosData = cloud.insumos;

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
    return [];
  }

  // Convertir personal médico desde datos de la nube
  List<PersonalMedico> _convertPersonalMedicoFromCloud(FrapFirestore cloud) {
    // Buscar personal médico en diferentes ubicaciones posibles
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

  // Convertir escalas obstétricas desde datos de la nube
  EscalasObstetricas? _convertEscalasObstetricasFromCloud(FrapFirestore cloud) {
    // Buscar escalas obstétricas en diferentes ubicaciones posibles
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

  // Sincronizar registros pendientes
  Future<SyncResult> syncPendingRecords() async {
    final result = SyncResult();

    try {
      if (!await hasInternetConnection()) {
        result.message = 'No hay conexión a internet';
        return result;
      }

      // Usar el servicio de migración para sincronización
      final migrationResult = await _migrationService.migrateBidirectional();

      result.success = migrationResult.success;
      result.message = migrationResult.message;
      result.successCount = migrationResult.migratedRecords;
      result.failedCount = migrationResult.failedRecords;
      result.errors = migrationResult.errors;
    } catch (e) {
      result.success = false;
      result.message = 'Error durante la sincronización: $e';
      result.errors.add(e.toString());
    }

    return result;
  }

  /// Obtener estadísticas de sincronización
  Future<Map<String, dynamic>> getSyncStats() async {
    return await _migrationService.getMigrationStats();
  }

  /// Eliminar un registro de forma unificada (local y nube)
  Future<UnifiedDeleteResult> deleteRecord(UnifiedFrapRecord record) async {
    final result = UnifiedDeleteResult();

    try {
      final localId = record.localRecord?.id;
      final cloudId = record.cloudRecord?.id;

      // Si no hay IDs, no hay nada que eliminar
      if (localId == null && cloudId == null) {
        result.success = false;
        result.message = 'No se puede eliminar: registro sin identificadores';
        return result;
      }

      // Verificar conectividad
      final hasInternet = await hasInternetConnection();

      // 1. Intentar eliminar del almacenamiento local
      if (localId != null) {
        try {
          await _localService.deleteFrapRecord(localId);
          result.deletedFromLocal = true;
        } catch (e) {
          result.localError = 'Error al eliminar localmente: $e';
          debugPrint(result.localError);
        }
      }

      // 2. Intentar eliminar de Firestore si hay conexión
      if (cloudId != null && hasInternet) {
        try {
          await _cloudService.deleteFrapRecord(cloudId);
          result.deletedFromCloud = true;
        } catch (e) {
          result.cloudError = 'Error al eliminar de la nube: $e';
          debugPrint(result.cloudError);
        }
      } else if (cloudId != null && !hasInternet) {
        // Si hay ID de nube pero no hay internet
        result.cloudError =
            'Sin conexión. El registro se eliminó localmente pero permanece en la nube';
      }

      // Marcar si solo existía localmente
      result.wasOnlyLocal = cloudId == null;
      final wasOnlyCloud = localId == null;

      // Determinar éxito general
      if (result.wasOnlyLocal) {
        // Solo existía localmente
        result.success = result.deletedFromLocal;
        result.message =
            result.success
                ? 'Registro eliminado correctamente (solo local)'
                : 'Error al eliminar el registro local';
      } else if (wasOnlyCloud) {
        // Solo existía en la nube
        result.success = result.deletedFromCloud;
        result.message =
            result.success
                ? 'Registro eliminado correctamente (solo en nube)'
                : 'Error al eliminar el registro de la nube';
      } else if (!hasInternet) {
        // Existe en nube pero sin conexión
        result.success = result.deletedFromLocal;
        result.message =
            result.success
                ? 'Registro eliminado localmente. Se eliminará de la nube cuando haya conexión'
                : 'Error al eliminar el registro';
      } else {
        // Debe eliminarse de ambos (existe en local y nube)
        result.success = result.deletedFromLocal && result.deletedFromCloud;
        if (result.success) {
          result.message = 'Registro eliminado completamente';
        } else if (result.deletedFromLocal && !result.deletedFromCloud) {
          result.message =
              'Registro eliminado localmente pero falló en la nube';
        } else if (!result.deletedFromLocal && result.deletedFromCloud) {
          result.message =
              'Registro eliminado de la nube pero falló localmente';
        } else {
          result.message = 'Error al eliminar el registro';
        }
      }
    } catch (e) {
      result.success = false;
      result.message = 'Error inesperado al eliminar: $e';
      debugPrint('Error en deleteRecord: $e');
    }

    return result;
  }

  /// Limpiar recursos
  void dispose() {
    _migrationService.dispose();
  }
}

// Clase para representar un registro unificado
class UnifiedFrapRecord {
  final Frap? localRecord;
  final FrapFirestore? cloudRecord;
  final DateTime createdAt;
  final String patientName;
  final int patientAge;
  final String patientSex;
  final String patientGender;
  final String patientAddress;
  final String patientPhone;
  final String patientInsurance;
  final String patientResponsiblePerson;
  final double completionPercentage;
  final bool isSynced;

  UnifiedFrapRecord({
    this.localRecord,
    this.cloudRecord,
    required this.createdAt,
    required this.patientName,
    required this.patientAge,
    required this.patientSex,
    required this.patientGender,
    required this.patientAddress,
    required this.patientPhone,
    required this.patientInsurance,
    required this.patientResponsiblePerson,
    required this.completionPercentage,
    required this.isSynced,
  });

  factory UnifiedFrapRecord.fromLocal(Frap local) {
    return UnifiedFrapRecord(
      localRecord: local,
      createdAt: local.createdAt,
      patientName: local.patient.fullName,
      patientAge: local.patient.age,
      patientSex: local.patient.sex,
      patientGender: local.patient.gender,
      patientAddress: _buildFullAddressFromPatient(local.patient),
      patientPhone: local.patient.phone,
      patientInsurance: local.patient.insurance,
      patientResponsiblePerson: local.patient.responsiblePerson ?? '',
      completionPercentage: local.completionPercentage,
      isSynced: local.isSynced,
    );
  }

  factory UnifiedFrapRecord.fromCloud(FrapFirestore cloud) {
    return UnifiedFrapRecord(
      cloudRecord: cloud,
      createdAt: cloud.createdAt,
      patientName: cloud.patientName,
      patientAge: cloud.patientAge,
      patientSex: cloud.patientSex,
      patientGender: cloud.patientGender,
      patientAddress: _buildFullAddressFromMap(cloud.patientInfo),
      patientPhone: cloud.patientInfo['phone']?.toString() ?? '',
      patientInsurance: cloud.patientInfo['insurance']?.toString() ?? '',
      patientResponsiblePerson:
          cloud.patientInfo['responsiblePerson']?.toString() ?? '',
      completionPercentage: cloud.completionPercentage,
      isSynced: true,
    );
  }

  // Propiedades adicionales
  bool get isLocal => localRecord != null;

  // Propiedad id para compatibilidad
  String get id {
    if (localRecord != null) {
      return localRecord!.id;
    } else if (cloudRecord != null) {
      return cloudRecord!.id ?? '';
    }
    return '';
  }

  // Método para obtener información detallada
  Map<String, dynamic> getDetailedInfo() {
    if (localRecord != null) {
      return _getDetailedInfoFromLocal(localRecord!);
    } else if (cloudRecord != null) {
      return _getDetailedInfoFromCloud(cloudRecord!);
    }
    return {};
  }

  Map<String, dynamic> _getDetailedInfoFromLocal(Frap local) {
    return {
      'serviceInfo': local.serviceInfo,
      'registryInfo': local.registryInfo,
      'patientInfo': {
        'name': local.patient.fullName,
        'age': local.patient.age,
        'sex': local.patient.sex,
        'address': local.patient.fullAddress,
        'phone': local.patient.phone,
        'insurance': local.patient.insurance,
        'responsiblePerson': local.patient.responsiblePerson,
        'gender': local.patient.gender,
        'firstName': local.patient.firstName,
        'paternalLastName': local.patient.paternalLastName,
        'maternalLastName': local.patient.maternalLastName,
        'street': local.patient.street,
        'exteriorNumber': local.patient.exteriorNumber,
        'interiorNumber': local.patient.interiorNumber,
        'neighborhood': local.patient.neighborhood,
        'city': local.patient.city,
        'addressDetails': local.patient.addressDetails,
        'tipoEntrega': local.patient.tipoEntrega,
      },
      'management': local.management,
      'medications': local.medications,
      'gynecoObstetric': local.gynecoObstetric,
      'attentionNegative': local.attentionNegative,
      'pathologicalHistory': local.pathologicalHistory,
      'clinicalHistory': {
        'traumaCraneo': local.clinicalHistory.traumaCraneo,
        'traumaCraneoEspecifique':
            local.clinicalHistory.traumaCraneoEspecifique,
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
        'traumaPelvisEspecifique':
            local.clinicalHistory.traumaPelvisEspecifique,
        'traumaOtros': local.clinicalHistory.traumaOtros,
        'traumaOtrosEspecifique': local.clinicalHistory.traumaOtrosEspecifique,
        'agenteCausal': local.clinicalHistory.agenteCausal,
        'cinematica': local.clinicalHistory.cinematica,
        'medidaSeguridad': local.clinicalHistory.medidaSeguridad,
        'observaciones': local.clinicalHistory.observaciones,
      },
      'physicalExam': {
        'eva': local.physicalExam.eva,
        'llc': local.physicalExam.llc,
        'glucosa': local.physicalExam.glucosa,
        'ta': local.physicalExam.ta,
        'sampleAlergias': local.physicalExam.sampleAlergias,
        'sampleMedicamentos': local.physicalExam.sampleMedicamentos,
        'sampleEnfermedades': local.physicalExam.sampleEnfermedades,
        'sampleHoraAlimento': local.physicalExam.sampleHoraAlimento,
        'sampleEventosPrevios': local.physicalExam.sampleEventosPrevios,
        'timeColumns': local.physicalExam.timeColumns,
        ...local.physicalExam.vitalSignsData,
      },
      'priorityJustification': local.priorityJustification,
      'injuryLocation': local.injuryLocation,
      'receivingUnit': local.receivingUnit,
      'patientReception': local.patientReception,
      'insumos': local.insumos.map((i) => i.toJson()).toList(),
      'personalMedico': local.personalMedico.map((p) => p.toJson()).toList(),
      'escalasObstetricas': local.escalasObstetricas?.toJson(),
    };
  }

  Map<String, dynamic> _getDetailedInfoFromCloud(FrapFirestore cloud) {
    return {
      'serviceInfo': cloud.serviceInfo,
      'registryInfo': cloud.registryInfo,
      'patientInfo': {
        'name':
            '${cloud.patientInfo['firstName'] ?? ''} ${cloud.patientInfo['paternalLastName'] ?? ''}',
        'age': cloud.patientInfo['age'],
        'sex': cloud.patientInfo['sex'],
        'address': _buildFullAddressFromMap(cloud.patientInfo),
        'phone': cloud.patientInfo['phone']?.toString() ?? '',
        'insurance': cloud.patientInfo['insurance']?.toString() ?? '',
        'responsiblePerson':
            cloud.patientInfo['responsiblePerson']?.toString() ?? '',
        'gender': cloud.patientInfo['gender'],
        'firstName': cloud.patientInfo['firstName'],
        'paternalLastName': cloud.patientInfo['paternalLastName'],
        'maternalLastName': cloud.patientInfo['maternalLastName'],
        'street': cloud.patientInfo['street'],
        'exteriorNumber': cloud.patientInfo['exteriorNumber'],
        'interiorNumber': cloud.patientInfo['interiorNumber'],
        'neighborhood': cloud.patientInfo['neighborhood'],
        'city': cloud.patientInfo['city'],
        'tipoEntrega': cloud.patientInfo['tipoEntrega'],
      },
      'management': cloud.management,
      'medications': cloud.medications,
      'gynecoObstetric': cloud.gynecoObstetric,
      'attentionNegative': cloud.attentionNegative,
      'pathologicalHistory': cloud.pathologicalHistory,
      'clinicalHistory': cloud.clinicalHistory,
      'physicalExam': cloud.physicalExam,
      'priorityJustification': cloud.priorityJustification,
      'injuryLocation': cloud.injuryLocation,
      'receivingUnit': cloud.receivingUnit,
      'patientReception': cloud.patientReception,
      'insumos':
          cloud.management['insumos'] ?? cloud.serviceInfo['insumos'] ?? [],
      'personalMedico':
          cloud.management['personalMedico'] ??
          cloud.serviceInfo['personalMedico'] ??
          [],
      'escalasObstetricas':
          cloud.gynecoObstetric['escalasObstetricas'] ??
          cloud.gynecoObstetric['escalas'],
    };
  }
}

// Resultado de guardado unificado
class UnifiedSaveResult {
  bool success = false;
  String message = '';
  List<String> errors = [];
  String? localRecordId;
  String? cloudRecordId;
  bool savedLocally = false;
  bool savedToCloud = false;
  String? cloudError;
}

// Resultado de sincronización
class SyncResult {
  bool success = false;
  String message = '';
  List<String> errors = [];
  int successCount = 0;
  int failedCount = 0;
}

// Resultado de eliminación unificada
class UnifiedDeleteResult {
  bool success = false;
  String message = '';
  bool deletedFromLocal = false;
  bool deletedFromCloud = false;
  String? localError;
  String? cloudError;
  bool wasOnlyLocal = false;
}
