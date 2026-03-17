import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bg_med/core/services/frap_local_service.dart';
import 'package:bg_med/core/services/frap_firestore_service.dart';
import 'package:bg_med/core/services/folio_generator_service.dart';
import 'package:bg_med/core/models/frap.dart';
import 'package:bg_med/core/models/frap_firestore.dart';
import 'package:bg_med/core/models/patient.dart';
import 'package:bg_med/core/models/clinical_history.dart';
import 'package:bg_med/core/models/insumo.dart';
import 'package:bg_med/core/models/personal_medico.dart';
import 'package:bg_med/core/models/escalas_obstetricas.dart';
import 'package:bg_med/core/services/frap_data_validator.dart';
import 'package:bg_med/core/services/frap_conversion_logger.dart';
import 'package:bg_med/core/services/frap_migration_service.dart';
import 'package:bg_med/core/exceptions/frap_exceptions.dart';
import 'package:bg_med/features/frap/presentation/providers/frap_data_provider.dart';
import 'package:collection/collection.dart';
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

      // 1. SIEMPRE guardar localmente primero
      try {
        final localRecordId = await _localService.createFrapRecord(
          frapData: frapDataWithFolio,
        );

        if (localRecordId == null) {
          throw Exception('El guardado local retornó ID nulo');
        }

        result.localRecordId = localRecordId;
        result.savedLocally = true;
        debugPrint('✅ Registro guardado localmente: $localRecordId');

        // 2. Intentar guardar en la nube si hay conexión
        final hasInternet = await hasInternetConnection();
        if (hasInternet) {
          try {
            final cloudRecordId = await _cloudService.createFrapRecord(
              frapData: frapDataWithFolio,
            );

            if (cloudRecordId != null) {
              result.cloudRecordId = cloudRecordId;
              result.savedToCloud = true;
              debugPrint('✅ Registro guardado en cloud: $cloudRecordId');

              // 3. CRÍTICO: Marcar como sincronizado (operación atómica)
              try {
                await _localService.markAsSynced(
                  localRecordId,
                  'firestore',
                  cloudRecordId,
                );

                // ✅ ÉXITO COMPLETO: Local + Cloud + Sincronizado
                result.success = true;
                result.message = 'Registro guardado exitosamente en la nube';

                FrapConversionLogger.logConversionSuccess(
                  'save_unified',
                  localRecordId,
                  {
                    'savedLocally': true,
                    'savedToCloud': true,
                    'markedAsSynced': true,
                    'cloudId': cloudRecordId,
                  },
                );
              } catch (syncError) {
                // ⚠️ markAsSynced falló, pero los datos están guardados en local y nube
                debugPrint(
                  '⚠️ markAsSynced falló para $localRecordId: $syncError',
                );

                // El registro fue guardado correctamente; el estado de sync se recupera automáticamente
                result.success = true;
                result.message =
                    'Registro guardado en la nube. Se sincronizará automáticamente.';
                result.syncError = syncError.toString();

                // Marcar como no sincronizado para reintento automático en próxima sync
                await _rollbackSyncStatus(localRecordId);

                FrapConversionLogger.logConversionError(
                  'mark_as_synced',
                  localRecordId,
                  'Sync marking failed: $syncError',
                  null,
                );
              }
            } else {
              // Cloud retornó ID nulo
              result.success = false;
              result.message = 'Guardado localmente. Cloud retornó ID nulo.';
              result.cloudError = 'Cloud service returned null ID';
            }
          } catch (cloudError) {
            // ❌ Guardado en cloud falló
            debugPrint('⚠️ Guardado en cloud falló: $cloudError');
            result.cloudError = cloudError.toString();
            result.success = true; // Local exitoso
            result.message =
                'Guardado localmente. Se sincronizará cuando haya conexión.';

            FrapConversionLogger.logConversionError(
              'cloud_save',
              localRecordId,
              'Cloud save failed: $cloudError',
              null,
            );
          }
        } else {
          // Sin conexión a internet
          result.success = true;
          result.message =
              'Guardado localmente. Se sincronizará cuando haya conexión.';
          debugPrint('ℹ️ Sin conexión. Registro guardado solo localmente.');
        }
      } catch (localError) {
        // ❌ Guardado local falló
        debugPrint('❌ Error guardando localmente: $localError');
        result.success = false;
        result.message = 'Error al guardar localmente: $localError';
        result.errors.add(localError.toString());

        FrapConversionLogger.logConversionError(
          'local_save',
          'new_record',
          localError.toString(),
          null,
        );
      }
    } catch (e) {
      // ❌ Error general/inesperado
      debugPrint('❌ Error inesperado en saveFrapRecord: $e');
      result.success = false;
      result.message = 'Error inesperado: $e';
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

  // T2.3: Estrategia de rollback para estado de sincronización
  Future<void> _rollbackSyncStatus(String localId) async {
    try {
      debugPrint(
        '🔄 Iniciando rollback de estado de sincronización para $localId',
      );

      // Marcar como NO sincronizado para permitir reintento
      await _localService.markAsNotSynced(localId);

      debugPrint(
        '✅ Rollback completado. Registro $localId marcado para re-sincronización',
      );
    } catch (rollbackError) {
      // Error en rollback - registrar pero no propagar
      debugPrint('❌ Rollback falló para $localId: $rollbackError');

      FrapConversionLogger.logConversionError(
        'rollback_sync_status',
        localId,
        'Rollback failed: $rollbackError',
        null,
      );
      // No re-lanzar - ya hay un error principal
    }
  }

  // T3.1: Asegurar que el folio existe con reintentos y validación
  Future<FrapData> _ensureFolioExists(
    FrapData frapData, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 100),
  }) async {
    // Verificar si ya existe un folio válido en registryInfo
    final currentRegistryInfo = Map<String, dynamic>.from(
      frapData.registryInfo,
    );
    final currentFolio = currentRegistryInfo['folio'];

    // Si ya tiene un folio válido, retornar sin cambios
    if (currentFolio != null && currentFolio.toString().trim().isNotEmpty) {
      debugPrint('✅ Folio existente: $currentFolio');
      return frapData;
    }

    // Necesita generar folio - intentar con reintentos
    Duration delay = initialDelay;
    String? generatedFolio;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        debugPrint('🔄 Intento ${attempt + 1}/$maxRetries de generar folio');

        // Obtener nombre del paciente para generar folio con iniciales
        final patientName = _getPatientNameFromData(frapData);
        generatedFolio = await _folioGenerator.generateUniquePatientFolio(
          patientName,
        );

        // Validar que el folio generado no esté vacío
        if (generatedFolio.trim().isEmpty) {
          throw FolioGenerationException(
            'La generación de folio retornó un valor vacío',
          );
        }

        // ✅ Éxito - asignar folio y retornar
        currentRegistryInfo['folio'] = generatedFolio;
        debugPrint('✅ Folio generado exitosamente: $generatedFolio');

        FrapConversionLogger.logConversionSuccess('folio_generation', 'auto', {
          'folio': generatedFolio,
          'attempt': attempt + 1,
        });

        return frapData.copyWith(registryInfo: currentRegistryInfo);
      } catch (e) {
        debugPrint('⚠️ Intento ${attempt + 1} falló: $e');

        if (attempt == maxRetries - 1) {
          // ❌ Último intento falló - usar folio de fallback
          debugPrint(
            '❌ Todos los intentos fallaron. Usando folio de fallback.',
          );

          final fallbackFolio =
              'SN-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch}';
          currentRegistryInfo['folio'] = fallbackFolio;

          FrapConversionLogger.logConversionError(
            'folio_generation',
            'auto',
            'Failed after $maxRetries attempts: $e',
            null,
          );

          FrapConversionLogger.logConversionSuccess(
            'folio_generation',
            'fallback',
            {'folio': fallbackFolio, 'reason': 'Max retries exceeded'},
          );

          return frapData.copyWith(registryInfo: currentRegistryInfo);
        }

        // Esperar antes de reintentar (exponential backoff)
        debugPrint('⏳ Reintentando en ${delay.inMilliseconds}ms...');
        await Future.delayed(delay);
        delay *= 2; // Doblar el tiempo de espera
      }
    }

    // Este punto no debería alcanzarse, pero por seguridad
    throw FolioGenerationException(
      'No se pudo generar folio después de $maxRetries intentos',
    );
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
        final existingLocal = localRecords.firstWhereOrNull(
          (r) => _areRecordsEquivalent(r, cloudRecord),
        );

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

          // Asegurar que el registro local quede vinculado con su par en nube
          final localIndex = unifiedRecords.indexWhere(
            (r) => r.localRecord?.id == existingLocal.id,
          );
          if (localIndex != -1) {
            final localCurrent = unifiedRecords[localIndex].localRecord;
            if (localCurrent != null) {
              unifiedRecords[localIndex] = UnifiedFrapRecord(
                localRecord: localCurrent,
                cloudRecord: cloudRecord,
                createdAt: localCurrent.createdAt,
                patientName: localCurrent.patient.fullName,
                patientAge: localCurrent.patient.age,
                patientSex: localCurrent.patient.sex,
                patientGender: localCurrent.patient.gender,
                patientAddress: _buildFullAddressFromPatient(
                  localCurrent.patient,
                ),
                patientPhone: localCurrent.patient.phone,
                patientInsurance: localCurrent.patient.insurance,
                patientResponsiblePerson:
                    localCurrent.patient.responsiblePerson ?? '',
                completionPercentage: localCurrent.completionPercentage,
                isSynced: localCurrent.isSynced,
                folio: localCurrent.registryInfo['folio']?.toString() ?? '',
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
    // 1) Si ambos tienen folio, usar folio como match fuerte
    final localFolio = _normalizeFolio(local.registryInfo['folio']);
    final cloudFolio = _normalizeFolio(cloud.registryInfo['folio']);
    if (localFolio.isNotEmpty && cloudFolio.isNotEmpty) {
      return localFolio == cloudFolio;
    }

    // 2) Fallback estricto: nombre normalizado + señal fuerte + ventana temporal
    final localPatientName = _normalizeText(local.patient.fullName);
    final cloudPatientName = _normalizeText(cloud.patientName);
    if (localPatientName.isEmpty || cloudPatientName.isEmpty) {
      return false;
    }
    if (localPatientName != cloudPatientName) {
      return false;
    }

    final localAge = local.patient.age;
    final cloudAge = cloud.patientAge;
    final sameAge = localAge > 0 && cloudAge > 0 && localAge == cloudAge;

    final localSex = _normalizeText(local.patient.sex);
    final cloudSex = _normalizeText(cloud.patientSex);
    final sameSex =
        localSex.isNotEmpty && cloudSex.isNotEmpty && localSex == cloudSex;

    final samePhone =
        _normalizePhone(local.patient.phone) ==
        _normalizePhone(cloud.patientInfo['phone']?.toString());
    final hasSamePhone =
        _normalizePhone(local.patient.phone).isNotEmpty && samePhone;

    final hasStrongSignal = hasSamePhone || (sameAge && sameSex);
    if (!hasStrongSignal) {
      return false;
    }

    return local.createdAt.difference(cloud.createdAt).abs().inMinutes <= 60;
  }

  String _normalizeFolio(dynamic folio) {
    return folio?.toString().trim().toUpperCase() ?? '';
  }

  String _normalizeText(String? value) {
    if (value == null) return '';
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _normalizePhone(String? value) {
    return (value ?? '').replaceAll(RegExp(r'\D'), '');
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

      // Convertir examen físico sin validación para conservar campos completos
      final examData = Map<String, dynamic>.from(cloud.physicalExam);

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
        physicalExam: examData,
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
        cloud.receivingUnit['personalMedico'] ??
        [];

    if (personalData is List) {
      final validation = FrapDataValidator.validatePersonalMedicoData(
        personalData,
      );
      if (validation.isValid && validation.cleanedData != null) {
        final cleanedPersonal =
            validation.cleanedData!['personalMedico'] as List;
        return cleanedPersonal.map((item) {
          return PersonalMedico(
            nombre: item['nombre'] ?? '',
            especialidad: item['especialidad'] ?? '',
            cedula: item['cedula'] ?? '',
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

  /// Eliminar un registro de forma local.
  /// Los registros en la nube son permanentes y solo pueden eliminarse individualmente.
  Future<UnifiedDeleteResult> deleteRecord(UnifiedFrapRecord record) async {
    final result = UnifiedDeleteResult();

    try {
      final localId = record.localRecord?.id;

      // Si no hay registro local, no hay nada que eliminar localmente
      if (localId == null) {
        result.success = false;
        result.wasOnlyLocal = false;
        result.message =
            'Este registro solo existe en la nube y no puede eliminarse desde aquí. '
            'Los registros en la nube solo se pueden eliminar de forma individual.';
        return result;
      }

      // Eliminar únicamente del almacenamiento local
      try {
        await _localService.deleteFrapRecord(localId);
        result.deletedFromLocal = true;
        result.wasOnlyLocal = record.cloudRecord == null;
        result.success = true;
        result.message =
            result.wasOnlyLocal
                ? 'Registro eliminado correctamente'
                : 'Registro eliminado localmente. El registro permanece en la nube.';
        debugPrint('✅ Registro local eliminado: $localId');
      } catch (e) {
        result.localError = 'Error al eliminar localmente: $e';
        result.success = false;
        result.message = 'Error al eliminar el registro: $e';
        debugPrint('❌ ${result.localError}');
      }
    } catch (e) {
      result.success = false;
      result.message = 'Error inesperado al eliminar: $e';
      debugPrint('Error en deleteRecord: $e');
    }

    return result;
  }

  /// Actualizar un registro de forma unificada (local y nube)
  Future<UnifiedUpdateResult> updateRecord(
    UnifiedFrapRecord originalRecord,
    FrapData updatedData,
  ) async {
    final result = UnifiedUpdateResult();

    try {
      final localId = originalRecord.localRecord?.id;
      String? cloudId = originalRecord.cloudRecord?.id;

      // Recuperar copia local cuando el registro original llega desactualizado.
      String? resolvedLocalId = localId;
      if (resolvedLocalId == null) {
        final folio = originalRecord.folio.trim();
        if (folio.isNotEmpty) {
          final localByFolio = await _localService.findRecordByFolio(folio);
          resolvedLocalId = localByFolio?.id;
        }
      }

      // Verificar que tenga al menos un ID
      if (resolvedLocalId == null && cloudId == null) {
        result.success = false;
        result.message = 'No se puede actualizar: registro sin identificadores';
        return result;
      }

      // Verificar conectividad
      final hasInternet = await hasInternetConnection();

      // Fallback: resolver cloudId por folio/equivalencia cuando no llega vinculado.
      if ((cloudId == null || cloudId.isEmpty) && hasInternet) {
        cloudId = await _resolveCloudIdForUpdate(originalRecord, updatedData);
      }

      // ID local efectivo: puede ser el existente o uno recién creado
      String? effectiveLocalId = resolvedLocalId;

      // 1. Actualizar en almacenamiento local si existe
      if (effectiveLocalId != null) {
        try {
          await _localService.updateFrapRecord(
            frapId: effectiveLocalId,
            frapData: updatedData,
          );
          result.updatedLocally = true;
          debugPrint('✅ Registro local actualizado: $effectiveLocalId');

          // T3.2: CRÍTICO - Resetear isSynced para marcar para re-sincronización
          if (cloudId != null) {
            try {
              await _localService.markAsNotSynced(effectiveLocalId);
              result.requiresSync = true;
              debugPrint('🔄 Registro marcado para re-sincronización');
            } catch (e) {
              debugPrint('⚠️ No se pudo marcar como no sincronizado: $e');
              // No es crítico - continuar
            }
          }
        } catch (e) {
          result.localError = 'Error al actualizar localmente: $e';
          debugPrint('❌ ${result.localError}');
        }
      } else if (hasInternet) {
        // Si no existe localmente pero vamos a actualizar en nube, crear copia local
        try {
          final newLocalId = await _localService.createFrapRecord(
            frapData: updatedData,
          );
          effectiveLocalId = newLocalId;
          result.updatedLocally = newLocalId != null;
          if (result.updatedLocally) {
            debugPrint('✅ Copia local creada con ID: $newLocalId');
          }
        } catch (e) {
          result.localError = 'Error al crear copia local: $e';
          debugPrint('❌ ${result.localError}');
        }
      }

      // 2. Actualizar en Firestore si existe y hay conexión
      if (cloudId != null && hasInternet) {
        try {
          await _cloudService.updateFrapRecord(
            frapId: cloudId,
            frapData: updatedData,
          );
          result.updatedInCloud = true;
          debugPrint('✅ Registro cloud actualizado: $cloudId');

          // Si cloud se actualizó exitosamente, marcar como sincronizado
          if (effectiveLocalId != null && result.updatedLocally) {
            try {
              await _localService.markAsSynced(
                effectiveLocalId,
                'firestore',
                cloudId,
              );
              result.requiresSync = false; // Ya está sincronizado
              debugPrint('✅ Registro marcado como sincronizado');
            } catch (syncError) {
              debugPrint('⚠️ Error marcando como sincronizado: $syncError');
              result.requiresSync = true; // Mantener necesidad de re-sync
            }
          }
        } catch (e) {
          result.cloudError = 'Error al actualizar en la nube: $e';
          debugPrint('❌ ${result.cloudError}');
          result.requiresSync = true; // Requiere sincronización posterior
        }
      } else if (cloudId != null && !hasInternet) {
        // Marcar para sincronización posterior
        result.requiresSync = true;
        result.cloudError =
            'Sin conexión. Los cambios se sincronizarán cuando haya internet';
        debugPrint(
          'ℹ️ Sin conexión - actualización pendiente de sincronización',
        );
      }

      // Determinar éxito general
      final wasOnlyLocal = cloudId == null;
      final wasOnlyCloud = effectiveLocalId == null && cloudId != null;

      if (wasOnlyLocal) {
        // Solo existía localmente
        result.success = result.updatedLocally;
        result.message =
            result.success
                ? 'Registro actualizado correctamente (solo local)'
                : 'Error al actualizar el registro local';
      } else if (wasOnlyCloud) {
        // Solo existía en la nube
        result.success = result.updatedInCloud || result.updatedLocally;
        if (result.success) {
          result.message =
              result.updatedInCloud
                  ? 'Registro actualizado correctamente'
                  : 'Registro descargado y actualizado localmente';
        } else {
          result.message = 'Error al actualizar el registro';
        }
      } else if (!hasInternet) {
        // Existe en ambos pero sin conexión
        result.success = result.updatedLocally;
        result.message =
            result.success
                ? 'Registro actualizado localmente. Se sincronizará cuando haya conexión'
                : 'Error al actualizar el registro';
      } else {
        // Existe en ambos con internet
        result.success = result.updatedLocally && result.updatedInCloud;
        if (result.success) {
          result.message =
              result.requiresSync
                  ? 'Registro actualizado. Pendiente de sincronización completa'
                  : 'Registro actualizado completamente';
        } else if (result.updatedLocally && !result.updatedInCloud) {
          result.message =
              'Registro actualizado localmente pero falló en la nube';
          result.requiresSync = true;
        } else if (!result.updatedLocally && result.updatedInCloud) {
          result.message =
              'Registro actualizado en la nube pero falló localmente';
        } else {
          result.message = 'Error al actualizar el registro';
        }
      }

      // Log final del resultado
      if (result.success) {
        debugPrint('✅ Actualización completa: ${result.message}');
      } else {
        debugPrint('❌ Actualización con errores: ${result.message}');
      }
    } catch (e) {
      result.success = false;
      result.message = 'Error inesperado al actualizar: $e';
      debugPrint('❌ Error en updateRecord: $e');
    }

    return result;
  }

  Future<String?> _resolveCloudIdForUpdate(
    UnifiedFrapRecord originalRecord,
    FrapData updatedData,
  ) async {
    try {
      final cloudRecords = await _cloudService.getAllFrapRecords();

      final updatedFolio = _normalizeFolio(
        updatedData.registryInfo['folio']?.toString(),
      );
      final originalFolio = _normalizeFolio(originalRecord.folio);

      if (updatedFolio.isNotEmpty || originalFolio.isNotEmpty) {
        final byFolio = cloudRecords.firstWhereOrNull((c) {
          final cloudFolio = _normalizeFolio(c.registryInfo['folio']);
          return cloudFolio.isNotEmpty &&
              (cloudFolio == updatedFolio || cloudFolio == originalFolio);
        });
        if (byFolio?.id != null && byFolio!.id!.isNotEmpty) {
          return byFolio.id;
        }
      }

      final normalizedName = _normalizeText(originalRecord.patientName);
      final bySignals = cloudRecords.firstWhereOrNull((c) {
        if (_normalizeText(c.patientName) != normalizedName) {
          return false;
        }

        final sameAge =
            originalRecord.patientAge > 0 &&
            c.patientAge > 0 &&
            originalRecord.patientAge == c.patientAge;
        final sameSex =
            _normalizeText(originalRecord.patientSex).isNotEmpty &&
            _normalizeText(c.patientSex).isNotEmpty &&
            _normalizeText(originalRecord.patientSex) ==
                _normalizeText(c.patientSex);
        final samePhone =
            _normalizePhone(originalRecord.patientPhone).isNotEmpty &&
            _normalizePhone(originalRecord.patientPhone) ==
                _normalizePhone(c.patientInfo['phone']?.toString());

        if (!(samePhone || (sameAge && sameSex))) {
          return false;
        }

        return c.createdAt
                .difference(originalRecord.createdAt)
                .abs()
                .inMinutes <=
            120;
      });

      if (bySignals?.id != null && bySignals!.id!.isNotEmpty) {
        return bySignals.id;
      }
    } catch (e) {
      debugPrint('⚠️ No se pudo resolver cloudId para actualización: $e');
    }

    return null;
  }

  /// Verificar permisos de edición para un registro
  Future<EditPermission> canEditRecord(UnifiedFrapRecord record) async {
    try {
      // Obtener el usuario actual
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return EditPermission.denied(
          'Debes iniciar sesión para editar registros',
        );
      }

      final currentUserId = currentUser.uid;

      // Obtener el userId del registro (solo disponible en cloudRecord)
      final recordOwnerId = record.cloudRecord?.userId;

      // 1. Verificar propiedad del registro (solo si existe en la nube)
      if (recordOwnerId != null && currentUserId != recordOwnerId) {
        return EditPermission.denied(
          'No puedes editar registros de otros usuarios',
        );
      }

      // 1.5. Bloquear edición cuando ya existe firma del médico receptor
      if (_hasReceivingDoctorSignature(record)) {
        return EditPermission.denied(
          'Este registro no se puede editar porque ya cuenta con la firma del médico receptor',
        );
      }

      // 2. Si solo está en nube y no hay internet
      if (record.localRecord == null && !await hasInternetConnection()) {
        return EditPermission.denied(
          'Sin conexión. No se puede editar este registro',
        );
      }

      // 3. Si solo está en nube con internet (necesita descarga)
      if (record.localRecord == null && await hasInternetConnection()) {
        return EditPermission.allowedWithWarning(
          'Este registro se descargará localmente para editarlo',
        );
      }

      // 4. Permitir edición normal (tiene copia local o puede descargar)
      return EditPermission.allowed();
    } catch (e) {
      debugPrint('Error al verificar permisos de edición: $e');
      return EditPermission.denied('Error al verificar permisos: $e');
    }
  }

  bool _hasReceivingDoctorSignature(UnifiedFrapRecord record) {
    final localReception = record.localRecord?.patientReception;
    if (_containsSignatureValue(localReception)) {
      return true;
    }

    final cloudReception = record.cloudRecord?.patientReception;
    if (_containsSignatureValue(cloudReception)) {
      return true;
    }

    final detailedReception = record.getDetailedInfo()['patientReception'];
    if (detailedReception is Map<String, dynamic> &&
        _containsSignatureValue(detailedReception)) {
      return true;
    }

    return false;
  }

  bool _containsSignatureValue(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) {
      return false;
    }

    const signatureKeys = [
      'doctorSignature',
      'receivingDoctorSignature',
      'doctor_signature',
      'firmaDoctor',
      'firmaMedico',
    ];

    for (final key in signatureKeys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return true;
      }
    }

    return false;
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
  final String folio;

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
    this.folio = '',
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
      folio: local.registryInfo['folio']?.toString() ?? '',
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
      folio: cloud.registryInfo['folio']?.toString() ?? '',
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
    debugPrint(
      '📋 getDetailedInfo - Fuente: ${localRecord != null
          ? "LOCAL"
          : cloudRecord != null
          ? "CLOUD"
          : "NINGUNA"}',
    );

    if (localRecord != null) {
      return _getDetailedInfoFromLocal(localRecord!);
    } else if (cloudRecord != null) {
      return _getDetailedInfoFromCloud(cloudRecord!);
    }
    return {};
  }

  Map<String, dynamic> _getDetailedInfoFromLocal(Frap local) {
    final localPhysicalExam = local.physicalExam;
    final shouldFallbackToCloud =
        cloudRecord != null && _shouldUseCloudPhysicalExam(localPhysicalExam);
    final physicalExamToUse =
        shouldFallbackToCloud ? cloudRecord!.physicalExam : localPhysicalExam;

    return {
      'serviceInfo': {
        ...local.serviceInfo,
        'tipoServicioEspecifique': local.tipoServicioEspecifique,
        'lugarOcurrenciaEspecifique': local.lugarOcurrenciaEspecifique,
        'tipoUrgencia': local.tipoUrgencia,
        'urgenciaEspecifique': local.urgenciaEspecifique,
        'ubicacion': local.ubicacion,
        'currentCondition': local.patient.currentCondition ?? '',
        'emergencyContact': local.patient.emergencyContact ?? '',
      },
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
        'currentCondition': local.patient.currentCondition ?? '',
        'emergencyContact': local.patient.emergencyContact ?? '',
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
      'physicalExam': physicalExamToUse,
      'priorityJustification': local.priorityJustification,
      'injuryLocation': local.injuryLocation,
      'receivingUnit': local.receivingUnit,
      'patientReception': local.patientReception,
      'insumos': local.insumos.map((i) => i.toJson()).toList(),
      'personalMedico': local.personalMedico.map((p) => p.toJson()).toList(),
      'escalasObstetricas': local.escalasObstetricas?.toJson(),
    };
  }

  bool _shouldUseCloudPhysicalExam(Map<String, dynamic> localPhysicalExam) {
    if (localPhysicalExam.isEmpty) {
      return true;
    }

    final simpleFields = [
      'eva',
      'llc',
      'glucosa',
      'ta',
      'sampleAlergias',
      'sampleMedicamentos',
      'sampleEnfermedades',
      'sampleHoraAlimento',
      'sampleEventosPrevios',
    ];

    final hasSimpleFields = simpleFields.any((key) {
      final value = localPhysicalExam[key];
      return value != null && value.toString().trim().isNotEmpty;
    });

    final vitalSignsData = localPhysicalExam['vitalSignsData'];
    final hasVitalSignsData =
        vitalSignsData is Map && vitalSignsData.isNotEmpty;

    return !(hasSimpleFields || hasVitalSignsData);
  }

  Map<String, dynamic> _getDetailedInfoFromCloud(FrapFirestore cloud) {
    return {
      'serviceInfo': {
        ...cloud.serviceInfo,
        'currentCondition':
            cloud.patientInfo['currentCondition'] ??
            cloud.serviceInfo['currentCondition'] ??
            '',
        'emergencyContact':
            cloud.patientInfo['emergencyContact'] ??
            cloud.serviceInfo['emergencyContact'] ??
            '',
      },
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
        'currentCondition':
            cloud.patientInfo['currentCondition']?.toString() ?? '',
        'emergencyContact':
            cloud.patientInfo['emergencyContact']?.toString() ?? '',
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
      'insumos': cloud.insumos,
      'personalMedico':
          cloud.management['personalMedico'] ??
          cloud.serviceInfo['personalMedico'] ??
          cloud.receivingUnit['personalMedico'] ??
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
  String? syncError; // Nuevo: error específico de sincronización
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

// Resultado de actualización unificada
class UnifiedUpdateResult {
  bool success = false;
  String message = '';
  bool updatedLocally = false;
  bool updatedInCloud = false;
  String? localError;
  String? cloudError;
  bool requiresSync = false;
}

// Permisos de edición
class EditPermission {
  final bool canEdit;
  final String? message;
  final bool needsDownload;

  EditPermission.allowed()
    : canEdit = true,
      message = null,
      needsDownload = false;

  EditPermission.allowedWithWarning(this.message)
    : canEdit = true,
      needsDownload = true;

  EditPermission.denied(this.message) : canEdit = false, needsDownload = false;
}
