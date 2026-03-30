import 'dart:async';
import 'package:bg_med/core/services/frap_local_service.dart';
import 'package:bg_med/core/services/frap_firestore_service.dart';
import 'package:bg_med/core/models/frap_firestore.dart';
import 'package:bg_med/features/frap/presentation/providers/frap_data_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FrapSyncService {
  final FrapLocalService _localService;
  final FrapFirestoreService _cloudService;
  final Connectivity _connectivity;

  FrapSyncService({
    required FrapLocalService localService,
    required FrapFirestoreService cloudService,
    Connectivity? connectivity,
  }) : _localService = localService,
       _cloudService = cloudService,
       _connectivity = connectivity ?? Connectivity();

  // Verificar conectividad a internet
  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      return !connectivityResults.contains(ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }

  // Sincronizar registros locales con la nube
  Future<SyncResult> syncLocalToCloud() async {
    final result = SyncResult();

    try {
      // Verificar conectividad
      if (!await hasInternetConnection()) {
        throw Exception('No hay conexión a internet');
      }

      // Obtener registros locales no sincronizados
      final localRecords = await _localService.getUnsyncedRecords();

      if (localRecords.isEmpty) {
        result.message = 'No hay registros locales para sincronizar';
        return result;
      }

      // Sincronizar cada registro local con la nube
      for (final localRecord in localRecords) {
        try {
          // Convertir Frap local a FrapData
          final frapData = _localService.convertFrapToFrapData(localRecord);

          // Crear registro en la nube
          final cloudRecordId = await _cloudService.createFrapRecord(
            frapData: frapData,
          );

          if (cloudRecordId != null) {
            // Marcar el registro local como sincronizado para evitar duplicados en próximos sync
            try {
              await _localService.markAsSynced(
                localRecord.id,
                'firestore',
                cloudRecordId,
              );
            } catch (markError) {
              // No es bloqueante; el registro ya existe en cloud
            }
            result.successCount++;
            result.syncedRecords.add(localRecord.id);
          } else {
            result.failedCount++;
            result.failedRecords.add(localRecord.id);
          }
        } catch (e) {
          result.failedCount++;
          result.failedRecords.add(localRecord.id);
          result.errors.add(
            'Error sincronizando ${localRecord.patient.name}: $e',
          );
        }
      }

      result.success = result.failedCount == 0;
      result.message =
          'Sincronización completada. ${result.successCount} exitosos, ${result.failedCount} fallidos';

      // Persistir la fecha del último sync exitoso
      if (result.success || result.successCount > 0) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(
          'frap_last_sync_time_ms',
          DateTime.now().millisecondsSinceEpoch,
        );
      }
    } catch (e) {
      result.success = false;
      result.message = 'Error durante la sincronización: $e';
      result.errors.add(e.toString());
    }

    return result;
  }

  // Sincronizar registros de la nube al almacenamiento local
  Future<SyncResult> syncCloudToLocal() async {
    final result = SyncResult();

    try {
      // Verificar conectividad
      if (!await hasInternetConnection()) {
        throw Exception('No hay conexión a internet');
      }

      // Obtener registros de la nube
      final cloudRecords = await _cloudService.getAllFrapRecords();

      if (cloudRecords.isEmpty) {
        result.message = 'No hay registros en la nube para sincronizar';
        return result;
      }

      // Obtener registros locales existentes
      final localRecords = await _localService.getAllFrapRecords();
      final localRecordIds = localRecords.map((record) => record.id).toSet();

      // Sincronizar registros de la nube que no existen localmente
      for (final cloudRecord in cloudRecords) {
        try {
          // Verificar si el registro ya existe localmente
          if (!localRecordIds.contains(cloudRecord.id)) {
            // Convertir FrapFirestore a FrapData y luego a Frap local
            final frapData = _convertFrapFirestoreToFrapData(cloudRecord);

            // Crear registro local
            final localRecordId = await _localService.createFrapRecord(
              frapData: frapData,
            );

            if (localRecordId != null) {
              result.successCount++;
              result.syncedRecords.add(cloudRecord.id ?? '');
            } else {
              result.failedCount++;
              result.failedRecords.add(cloudRecord.id ?? '');
            }
          }
        } catch (e) {
          result.failedCount++;
          result.failedRecords.add(cloudRecord.id ?? '');
          result.errors.add(
            'Error sincronizando ${cloudRecord.patientName}: $e',
          );
        }
      }

      result.success = result.failedCount == 0;
      result.message =
          'Sincronización completada. ${result.successCount} nuevos registros descargados, ${result.failedCount} fallidos';
    } catch (e) {
      result.success = false;
      result.message = 'Error durante la sincronización: $e';
      result.errors.add(e.toString());
    }

    return result;
  }

  // Sincronización bidireccional completa
  Future<SyncResult> fullSync() async {
    final result = SyncResult();

    try {
      // Verificar conectividad
      if (!await hasInternetConnection()) {
        throw Exception('No hay conexión a internet');
      }

      // Sincronizar local a nube
      final localToCloudResult = await syncLocalToCloud();
      result.successCount += localToCloudResult.successCount;
      result.failedCount += localToCloudResult.failedCount;
      result.errors.addAll(localToCloudResult.errors);
      result.syncedRecords.addAll(localToCloudResult.syncedRecords);
      result.failedRecords.addAll(localToCloudResult.failedRecords);

      // Sincronizar nube a local
      final cloudToLocalResult = await syncCloudToLocal();
      result.successCount += cloudToLocalResult.successCount;
      result.failedCount += cloudToLocalResult.failedCount;
      result.errors.addAll(cloudToLocalResult.errors);
      result.syncedRecords.addAll(cloudToLocalResult.syncedRecords);
      result.failedRecords.addAll(cloudToLocalResult.failedRecords);

      result.success = result.failedCount == 0;
      result.message =
          'Sincronización completa finalizada. ${result.successCount} registros sincronizados, ${result.failedCount} fallidos';
    } catch (e) {
      result.success = false;
      result.message = 'Error durante la sincronización completa: $e';
      result.errors.add(e.toString());
    }

    return result;
  }

  // Respaldar registros locales en la nube
  Future<SyncResult> backupLocalRecords() async {
    final result = SyncResult();

    try {
      // Verificar conectividad
      if (!await hasInternetConnection()) {
        throw Exception('No hay conexión a internet');
      }

      // Crear backup de registros locales
      final backupData = await _localService.backupFrapRecords();

      if (backupData.isEmpty) {
        result.message = 'No hay registros locales para respaldar';
        return result;
      }

      // Restaurar backup en la nube
      await _cloudService.restoreFrapRecords(backupData: backupData);

      result.success = true;
      result.successCount = backupData.length;
      result.message =
          'Backup completado. ${backupData.length} registros respaldados en la nube';
    } catch (e) {
      result.success = false;
      result.message = 'Error durante el backup: $e';
      result.errors.add(e.toString());
    }

    return result;
  }

  // Restaurar registros de la nube al almacenamiento local
  Future<SyncResult> restoreFromCloud() async {
    final result = SyncResult();

    try {
      // Verificar conectividad
      if (!await hasInternetConnection()) {
        throw Exception('No hay conexión a internet');
      }

      // Crear backup de registros en la nube
      final backupData = await _cloudService.backupFrapRecords();

      if (backupData.isEmpty) {
        result.message = 'No hay registros en la nube para restaurar';
        return result;
      }

      // Convertir datos de la nube al formato local
      final localBackupData =
          backupData.map((cloudData) {
            final frapFirestore = FrapFirestore.fromMap(
              cloudData,
              cloudData['id'],
            );
            final frapData = _convertFrapFirestoreToFrapData(frapFirestore);
            return _convertFrapDataToLocalBackupFormat(frapData);
          }).toList();

      // Restaurar en almacenamiento local
      await _localService.restoreFrapRecords(backupData: localBackupData);

      result.success = true;
      result.successCount = localBackupData.length;
      result.message =
          'Restauración completada. ${localBackupData.length} registros restaurados localmente';
    } catch (e) {
      result.success = false;
      result.message = 'Error durante la restauración: $e';
      result.errors.add(e.toString());
    }

    return result;
  }

  // Obtener estadísticas de sincronización
  Future<SyncStats> getSyncStats() async {
    try {
      final localStats = await _localService.getFrapStatistics();
      final hasInternet = await hasInternetConnection();

      Map<String, dynamic> cloudStats = {};
      if (hasInternet) {
        try {
          cloudStats = await _cloudService.getFrapStatistics();
        } catch (e) {
          // Si hay error con la nube, usar estadísticas vacías
          cloudStats = {
            'total': 0,
            'today': 0,
            'thisWeek': 0,
            'thisMonth': 0,
            'thisYear': 0,
          };
        }
      }

      // Contar sólo los registros que no se han sincronizado usando el flag real del modelo
      final unsyncedRecords = await _localService.getUnsyncedRecords();

      // Leer la fecha real del último sync desde SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final lastSyncMs = prefs.getInt('frap_last_sync_time_ms');
      final lastSyncTime =
          lastSyncMs != null
              ? DateTime.fromMillisecondsSinceEpoch(lastSyncMs)
              : null;

      return SyncStats(
        localRecords: localStats['total'] ?? 0,
        cloudRecords: cloudStats['total'] ?? 0,
        unsyncedRecords: unsyncedRecords.length,
        lastSyncTime: lastSyncTime,
        hasInternetConnection: hasInternet,
      );
    } catch (e) {
      return SyncStats(
        localRecords: 0,
        cloudRecords: 0,
        unsyncedRecords: 0,
        lastSyncTime: null,
        hasInternetConnection: false,
        error: e.toString(),
      );
    }
  }

  // Convertir FrapFirestore a FrapData
  FrapData _convertFrapFirestoreToFrapData(FrapFirestore frapFirestore) {
    return FrapData(
      serviceInfo: frapFirestore.serviceInfo,
      registryInfo: frapFirestore.registryInfo,
      patientInfo: frapFirestore.patientInfo,
      management: frapFirestore.management,
      medications: frapFirestore.medications,
      gynecoObstetric: frapFirestore.gynecoObstetric,
      attentionNegative: frapFirestore.attentionNegative,
      pathologicalHistory: frapFirestore.pathologicalHistory,
      clinicalHistory: frapFirestore.clinicalHistory,
      physicalExam: frapFirestore.physicalExam,
      priorityJustification: frapFirestore.priorityJustification,
      injuryLocation: frapFirestore.injuryLocation,
      receivingUnit: frapFirestore.receivingUnit,
      patientReception: frapFirestore.patientReception,
    );
  }

  // Convertir FrapData a formato de backup local
  // Utiliza los nombres de campo reales del esquema FrapData/patientInfo para no perder datos
  Map<String, dynamic> _convertFrapDataToLocalBackupFormat(FrapData frapData) {
    final pi = frapData.patientInfo;
    // Reconstruir nombre completo como fallback si 'name' no existe
    final fullName =
        pi['name']?.toString().isNotEmpty == true
            ? pi['name'].toString()
            : [
              pi['firstName'] ?? '',
              pi['paternalLastName'] ?? '',
              pi['maternalLastName'] ?? '',
            ].where((s) => s.toString().isNotEmpty).join(' ');

    return {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'patient': {
        'name': fullName,
        'firstName': pi['firstName'] ?? '',
        'paternalLastName': pi['paternalLastName'] ?? '',
        'maternalLastName': pi['maternalLastName'] ?? '',
        'age': pi['age'] ?? 0,
        'sex': pi['sex'] ?? '',
        'address': pi['address'] ?? '',
        'phone': pi['phone'] ?? '',
        'street': pi['street'] ?? '',
        'exteriorNumber': pi['exteriorNumber'] ?? '',
        'interiorNumber': pi['interiorNumber'] ?? '',
        'neighborhood': pi['neighborhood'] ?? '',
        'city': pi['city'] ?? '',
        'gender': pi['gender'] ?? '',
        'insurance': pi['insurance'] ?? '',
        'responsiblePerson': pi['responsiblePerson'] ?? '',
      },
      'clinicalHistory': {
        'allergies':
            frapData.clinicalHistory['allergies'] ??
            frapData.pathologicalHistory['allergies'] ??
            '',
        'medications':
            frapData.medications['medicamentos'] ??
            frapData.clinicalHistory['medications'] ??
            '',
        'previousIllnesses':
            frapData.pathologicalHistory['enfermedadesPrevias'] ??
            frapData.pathologicalHistory['previous_illnesses'] ??
            frapData.clinicalHistory['previousIllnesses'] ??
            '',
      },
      'physicalExam': frapData.physicalExam,
      'serviceInfo': frapData.serviceInfo,
      'registryInfo': frapData.registryInfo,
      'management': frapData.management,
      'medications': frapData.medications,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}

// Clase para el resultado de sincronización
class SyncResult {
  bool success;
  String message;
  int successCount;
  int failedCount;
  List<String> syncedRecords;
  List<String> failedRecords;
  List<String> errors;

  SyncResult({
    this.success = false,
    this.message = '',
    this.successCount = 0,
    this.failedCount = 0,
    List<String>? syncedRecords,
    List<String>? failedRecords,
    List<String>? errors,
  }) : syncedRecords = syncedRecords ?? [],
       failedRecords = failedRecords ?? [],
       errors = errors ?? [];
}

// Clase para estadísticas de sincronización
class SyncStats {
  final int localRecords;
  final int cloudRecords;
  final int unsyncedRecords;
  final DateTime? lastSyncTime;
  final bool hasInternetConnection;
  final String? error;

  SyncStats({
    required this.localRecords,
    required this.cloudRecords,
    required this.unsyncedRecords,
    this.lastSyncTime,
    required this.hasInternetConnection,
    this.error,
  });
}
