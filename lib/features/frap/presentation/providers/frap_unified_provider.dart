import 'package:bg_med/core/services/frap_unified_service.dart';
import 'package:bg_med/core/services/frap_local_service.dart';
import 'package:bg_med/core/services/frap_firestore_service.dart';
import 'package:bg_med/features/frap/presentation/providers/frap_local_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:bg_med/features/frap/presentation/providers/frap_data_provider.dart';
import 'package:bg_med/core/services/folio_generator_service.dart';
import 'dart:convert';
import 'dart:developer' as developer;

// Estados de sincronización
enum SyncStatus { idle, syncing, success, error }

// Estado unificado
class UnifiedFrapState {
  final List<UnifiedFrapRecord> records;
  final bool isLoading;
  final String? error;
  final SyncStatus syncStatus;
  final DateTime? lastSync;
  final int totalRecords;
  final int localRecords;
  final int cloudRecords;
  final int syncedRecords;
  final int duplicateCount;
  final int localDuplicatesCount;

  const UnifiedFrapState({
    this.records = const [],
    this.isLoading = false,
    this.error,
    this.syncStatus = SyncStatus.idle,
    this.lastSync,
    this.totalRecords = 0,
    this.localRecords = 0,
    this.cloudRecords = 0,
    this.syncedRecords = 0,
    this.duplicateCount = 0,
    this.localDuplicatesCount = 0,
  });

  UnifiedFrapState copyWith({
    List<UnifiedFrapRecord>? records,
    bool? isLoading,
    String? error,
    SyncStatus? syncStatus,
    DateTime? lastSync,
    int? totalRecords,
    int? localRecords,
    int? cloudRecords,
    int? syncedRecords,
    int? duplicateCount,
    int? localDuplicatesCount,
  }) {
    return UnifiedFrapState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSync: lastSync ?? this.lastSync,
      totalRecords: totalRecords ?? this.totalRecords,
      localRecords: localRecords ?? this.localRecords,
      cloudRecords: cloudRecords ?? this.cloudRecords,
      syncedRecords: syncedRecords ?? this.syncedRecords,
      duplicateCount: duplicateCount ?? this.duplicateCount,
      localDuplicatesCount: localDuplicatesCount ?? this.localDuplicatesCount,
    );
  }
}

// Notificador unificado
class UnifiedFrapNotifier extends StateNotifier<UnifiedFrapState> {
  final FrapUnifiedService _unifiedService;
  final FrapLocalNotifier _localNotifier;
  bool _isUpdating = false;

  UnifiedFrapNotifier(this._unifiedService, this._localNotifier)
    : super(const UnifiedFrapState()) {
    // Remover la inicialización automática para evitar problemas de timing
    // _initialize();
  }

  // Método para inicialización manual
  Future<void> initialize() async {
    await loadAllRecords();
  }

  // void verComoJSON(List<UnifiedFrapRecord> registros) {
  //   for (int i = 0; i < registros.length; i++) {
  //     var info = registros[i].getDetailedInfo();
  //     var jsonString = JsonEncoder.withIndent('  ').convert(info);
  //     print("\n📄 Registro $i (JSON):");
  //     print(jsonString);
  //   }
  // }

  // Cargar todos los registros
  Future<void> loadAllRecords() async {
    if (_isUpdating) return;
    _isUpdating = true;

    state = state.copyWith(isLoading: true, error: null);

    try {
      developer.log('Cargando registros unificados...');
      final records = await _unifiedService.getAllRecords();
      final stats = _calculateStats(records);

      state = state.copyWith(
        records: records,
        isLoading: false,
        totalRecords: stats['total'],
        localRecords: stats['local'],
        cloudRecords: stats['cloud'],
        syncedRecords: stats['synced'],
        duplicateCount: stats['duplicates'],
        localDuplicatesCount: stats['localDuplicates'],
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error cargando registros: $e',
      );
    } finally {
      _isUpdating = false;
    }
  }

  // Calcular estadísticas
  Map<String, int> _calculateStats(List<UnifiedFrapRecord> records) {
    int localCount = 0;
    int cloudCount = 0;
    int syncedCount = 0;
    int duplicateCount = 0;
    int localDuplicatesCount = 0;

    // Separar registros locales y de nube
    final localRecords = <UnifiedFrapRecord>[];
    final cloudRecords = <UnifiedFrapRecord>[];

    for (final record in records) {
      if (record.isLocal) {
        localCount++;
        localRecords.add(record);
        if (record.isSynced) syncedCount++;
      } else {
        cloudCount++;
        cloudRecords.add(record);
        syncedCount++;
      }
    }

    // Detectar duplicados (mismo nombre de paciente y fecha cercana)
    for (final localRecord in localRecords) {
      for (final cloudRecord in cloudRecords) {
        if (_areRecordsEquivalent(localRecord, cloudRecord)) {
          duplicateCount++;
          if (localRecord.isLocal) localDuplicatesCount++;
        }
      }
    }

    return {
      'total': records.length,
      'local': localCount,
      'cloud': cloudCount,
      'synced': syncedCount,
      'duplicates': duplicateCount,
      'localDuplicates': localDuplicatesCount,
    };
  }

  // Verificar si dos registros son equivalentes (duplicados)
  bool _areRecordsEquivalent(UnifiedFrapRecord local, UnifiedFrapRecord cloud) {
    final localFolio = local.folio.trim().toUpperCase();
    final cloudFolio = cloud.folio.trim().toUpperCase();

    // 1) Si ambos tienen folio, compararlo
    if (localFolio.isNotEmpty && cloudFolio.isNotEmpty) {
      return localFolio == cloudFolio;
    }

    // 2) Fallback estricto: nombre normalizado + señal fuerte + ventana temporal
    final localName = _normalizeText(local.patientName);
    final cloudName = _normalizeText(cloud.patientName);
    if (localName.isEmpty || cloudName.isEmpty || localName != cloudName) {
      return false;
    }

    final sameAge =
        local.patientAge > 0 &&
        cloud.patientAge > 0 &&
        local.patientAge == cloud.patientAge;

    final sameSex =
        local.patientSex.trim().isNotEmpty &&
        cloud.patientSex.trim().isNotEmpty &&
        _normalizeText(local.patientSex) == _normalizeText(cloud.patientSex);

    final samePhone = _arePhonesEquivalent(
      local.patientPhone,
      cloud.patientPhone,
    );

    final hasStrongSignal = samePhone || (sameAge && sameSex);
    if (!hasStrongSignal) {
      return false;
    }

    return local.createdAt.difference(cloud.createdAt).abs().inMinutes <= 60;
  }

  String _normalizeText(String? value) {
    if (value == null) return '';
    final collapsed = value.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    return collapsed;
  }

  bool _arePhonesEquivalent(String? a, String? b) {
    final phoneA = (a ?? '').replaceAll(RegExp(r'\D'), '');
    final phoneB = (b ?? '').replaceAll(RegExp(r'\D'), '');

    if (phoneA.isEmpty || phoneB.isEmpty) {
      return false;
    }

    return phoneA == phoneB;
  }

  // Guardar registro
  Future<UnifiedSaveResult> saveRecord(FrapData frapData) async {
    try {
      final result = await _unifiedService.saveFrapRecord(frapData);

      if (result.success) {
        await loadAllRecords(); // Recargar lista
      } else {
        state = state.copyWith(error: result.message);
      }

      return result;
    } catch (e) {
      state = state.copyWith(error: 'Error guardando registro: $e');
      return UnifiedSaveResult()
        ..success = false
        ..message = 'Error guardando registro: $e';
    }
  }

  // Eliminar registro (local y nube)
  Future<UnifiedDeleteResult> deleteRecord(UnifiedFrapRecord record) async {
    try {
      // Usar el servicio unificado para eliminar
      final result = await _unifiedService.deleteRecord(record);

      if (result.success || result.deletedFromLocal) {
        // Recargar la lista si se eliminó localmente
        await loadAllRecords();
      }

      // Actualizar estado con mensaje de error si hubo alguno
      if (!result.success) {
        state = state.copyWith(error: result.message);
      }

      return result;
    } catch (e) {
      final errorResult =
          UnifiedDeleteResult()
            ..success = false
            ..message = 'Error eliminando registro: $e';

      state = state.copyWith(error: errorResult.message);
      return errorResult;
    }
  }

  // Actualizar registro (local y nube)
  Future<UnifiedUpdateResult> updateRecord(
    UnifiedFrapRecord originalRecord,
    FrapData updatedData,
  ) async {
    try {
      // Usar el servicio unificado para actualizar
      final result = await _unifiedService.updateRecord(
        originalRecord,
        updatedData,
      );

      if (result.success || result.updatedLocally) {
        // Recargar la lista si se actualizó localmente
        await loadAllRecords();
      }

      // Actualizar estado con mensaje de error si hubo alguno
      if (!result.success) {
        state = state.copyWith(error: result.message);
      }

      return result;
    } catch (e) {
      final errorResult =
          UnifiedUpdateResult()
            ..success = false
            ..message = 'Error actualizando registro: $e';

      state = state.copyWith(error: errorResult.message);
      return errorResult;
    }
  }

  // Verificar permisos de edición
  Future<EditPermission> canEditRecord(UnifiedFrapRecord record) async {
    return await _unifiedService.canEditRecord(record);
  }

  // Sincronizar registros
  Future<void> syncRecords() async {
    state = state.copyWith(syncStatus: SyncStatus.syncing);

    try {
      final result = await _unifiedService.syncPendingRecords();

      if (result.success) {
        state = state.copyWith(
          syncStatus: SyncStatus.success,
          lastSync: DateTime.now(),
        );
        await loadAllRecords();
      } else {
        state = state.copyWith(
          syncStatus: SyncStatus.error,
          error: result.message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        syncStatus: SyncStatus.error,
        error: 'Error durante sincronización: $e',
      );
    }
  }

  // Sincronizar registros (versión que devuelve SyncResult)
  Future<SyncResult> syncRecordsWithResult() async {
    state = state.copyWith(syncStatus: SyncStatus.syncing);

    try {
      final result = await _unifiedService.syncPendingRecords();

      if (result.success) {
        state = state.copyWith(
          syncStatus: SyncStatus.success,
          lastSync: DateTime.now(),
        );
        await loadAllRecords();
      } else {
        state = state.copyWith(
          syncStatus: SyncStatus.error,
          error: result.message,
        );
      }

      return result;
    } catch (e) {
      state = state.copyWith(
        syncStatus: SyncStatus.error,
        error: 'Error durante sincronización: $e',
      );

      final errorResult = SyncResult();
      errorResult.success = false;
      errorResult.message = 'Error durante sincronización: $e';
      return errorResult;
    }
  }

  // Alias explícito para acciones manuales de sincronización desde UI
  Future<SyncResult> forceSyncNow() async {
    return await syncRecordsWithResult();
  }

  // Estadísticas de sincronización provenientes del servicio unificado
  Future<Map<String, dynamic>> getSyncStats() async {
    return await _unifiedService.getSyncStats();
  }

  // Buscar registros
  Future<void> searchRecords(String query) async {
    if (query.isEmpty) {
      await loadAllRecords();
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final allRecords = await _unifiedService.getAllRecords();
      final filteredRecords =
          allRecords
              .where(
                (record) => record.patientName.toLowerCase().contains(
                  query.toLowerCase(),
                ),
              )
              .toList();

      final stats = _calculateStats(filteredRecords);

      state = state.copyWith(
        records: filteredRecords,
        isLoading: false,
        totalRecords: stats['total'],
        localRecords: stats['local'],
        cloudRecords: stats['cloud'],
        syncedRecords: stats['synced'],
        duplicateCount: stats['duplicates'],
        localDuplicatesCount: stats['localDuplicates'],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error buscando registros: $e',
      );
    }
  }

  // Filtrar por rango de fechas
  Future<void> filterByDateRange(DateTime startDate, DateTime endDate) async {
    state = state.copyWith(isLoading: true);

    try {
      final allRecords = await _unifiedService.getAllRecords();
      final filteredRecords =
          allRecords
              .where(
                (record) =>
                    record.createdAt.isAfter(
                      startDate.subtract(const Duration(days: 1)),
                    ) &&
                    record.createdAt.isBefore(
                      endDate.add(const Duration(days: 1)),
                    ),
              )
              .toList();

      final stats = _calculateStats(filteredRecords);

      state = state.copyWith(
        records: filteredRecords,
        isLoading: false,
        totalRecords: stats['total'],
        localRecords: stats['local'],
        cloudRecords: stats['cloud'],
        syncedRecords: stats['synced'],
        duplicateCount: stats['duplicates'],
        localDuplicatesCount: stats['localDuplicates'],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error filtrando registros: $e',
      );
    }
  }

  // Limpiar errores
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Duplicar registro
  Future<String?> duplicateRecord(UnifiedFrapRecord record) async {
    try {
      String? newRecordId;

      if (record.localRecord != null) {
        newRecordId = await _localNotifier.duplicateLocalFrapRecord(record.id);
      }

      if (newRecordId != null) {
        await loadAllRecords();
        return newRecordId;
      } else {
        state = state.copyWith(error: 'Error duplicando registro');
        return null;
      }
    } catch (e) {
      state = state.copyWith(error: 'Error duplicando registro: $e');
      return null;
    }
  }

  // Sincronizar y limpiar duplicados
  Future<Map<String, dynamic>> syncAndCleanup() async {
    try {
      developer.log('Iniciando syncAndCleanup', name: 'UnifiedFrapProvider');
      state = state.copyWith(syncStatus: SyncStatus.syncing);

      // 1. Sincronizar registros
      final syncResult = await _unifiedService.syncPendingRecords();

      if (syncResult.success) {
        // 2. Recargar registros después de la sincronización
        await loadAllRecords();

        // 3. Limpiar duplicados locales de forma segura
        final cleanupResult = await _cleanupLocalDuplicates(state.records);

        // 4. Recargar nuevamente para reflejar eliminaciones
        await loadAllRecords();

        state = state.copyWith(
          syncStatus: SyncStatus.success,
          lastSync: DateTime.now(),
        );

        // Validar si hubo errores en la limpieza
        final cleanupErrors =
            cleanupResult['cleanupErrors'] as List<String>? ?? [];
        final hasCleanupErrors = cleanupErrors.isNotEmpty;

        return {
          'success': true,
          'message': 'Sincronización completada exitosamente',
          'syncedRecords': syncResult.successCount,
          'cleanupResult': cleanupResult,
          'hasCleanupWarnings': hasCleanupErrors,
          'cleanupWarnings': cleanupErrors,
        };
      } else {
        state = state.copyWith(
          syncStatus: SyncStatus.error,
          error: syncResult.message,
        );

        return {
          'success': false,
          'message': syncResult.message,
          'syncedRecords': 0,
        };
      }
    } catch (e) {
      developer.log(
        'Error en syncAndCleanup: $e',
        name: 'UnifiedFrapProvider',
        error: e,
      );
      state = state.copyWith(
        syncStatus: SyncStatus.error,
        error: 'Error durante sincronización: $e',
      );

      return {
        'success': false,
        'message': 'Error durante sincronización: $e',
        'syncedRecords': 0,
      };
    }
  }

  Future<Map<String, dynamic>> _cleanupLocalDuplicates(
    List<UnifiedFrapRecord> records,
  ) async {
    int removedCount = 0;
    int estimatedFreedBytes = 0;
    final List<String> cleanupErrors = [];

    try {
      final localRecords = records.where((r) => r.localRecord != null).toList();
      final cloudOnlyRecords =
          records.where((r) => r.localRecord == null).toList();

      final recordsById = <String, UnifiedFrapRecord>{
        for (final record in localRecords) record.localRecord!.id: record,
      };

      final idsToRemove = <String>{};

      // Regla 1: duplicados locales por folio. Priorizar NO SINCRONIZADO + RECIENTE.
      final localByFolio = <String, List<UnifiedFrapRecord>>{};
      for (final record in localRecords) {
        final folio = record.folio.trim().toUpperCase();
        if (folio.isEmpty) continue;
        localByFolio.putIfAbsent(folio, () => []).add(record);
      }

      for (final entry in localByFolio.entries) {
        final group = entry.value;
        if (group.length < 2) continue;

        // Prioridad: 1) No sincronizado más reciente  2) Sincronizado más reciente
        group.sort((a, b) {
          final aSynced = a.isSynced ? 1 : 0;
          final bSynced = b.isSynced ? 1 : 0;
          // Invertir: NO sincronizado (0) debe venir primero que sincronizado (1)
          if (aSynced != bSynced) {
            return aSynced.compareTo(bSynced);
          }

          final aUpdated = a.localRecord?.updatedAt ?? a.createdAt;
          final bUpdated = b.localRecord?.updatedAt ?? b.createdAt;
          return bUpdated.compareTo(aUpdated);
        });

        // Conservamos el primero (mejor candidato); el resto se elimina.
        for (int i = 1; i < group.length; i++) {
          idsToRemove.add(group[i].localRecord!.id);
        }
      }

      // Regla 2: si existe equivalente en nube, remover copia local ya sincronizada.
      for (final local in localRecords) {
        final localId = local.localRecord!.id;
        if (idsToRemove.contains(localId) || !local.isSynced) {
          continue;
        }

        // Verificar contra registros cloud-only Y también contra cloud que estén asociados
        bool hasEquivalentCloud = cloudOnlyRecords.any(
          (cloud) => _areRecordsEquivalent(local, cloud),
        );

        // Si no hay cloud-only, verificar si ya tiene asociado cloudRecord
        if (!hasEquivalentCloud && local.cloudRecord != null) {
          hasEquivalentCloud = true;
        }

        if (hasEquivalentCloud) {
          idsToRemove.add(localId);
        }
      }

      for (final localId in idsToRemove) {
        final record = recordsById[localId];
        if (record == null) continue;

        try {
          final estimatedBytes =
              utf8.encode(jsonEncode(record.getDetailedInfo())).length;
          final deleteResult = await _unifiedService.deleteRecord(record);

          if (deleteResult.deletedFromLocal) {
            removedCount++;
            estimatedFreedBytes += estimatedBytes;
          } else if (deleteResult.success == false) {
            cleanupErrors.add(
              'No se pudo eliminar: ${record.patientName} (${deleteResult.message})',
            );
          }
        } catch (e) {
          cleanupErrors.add('Error eliminando: ${record.patientName} - $e');
          developer.log(
            'Error eliminando duplicado local ($localId): $e',
            name: 'UnifiedFrapProvider',
            error: e,
          );
        }
      }

      return {
        'removedCount': removedCount,
        'statistics': {
          'estimatedSpaceFreedMB': (estimatedFreedBytes / (1024 * 1024))
              .toStringAsFixed(2),
        },
        'cleanupErrors': cleanupErrors,
        'totalAttempted': idsToRemove.length,
      };
    } catch (e) {
      developer.log(
        'Error en limpieza de duplicados: $e',
        name: 'UnifiedFrapProvider',
        error: e,
      );
      cleanupErrors.add('Error general en limpieza: $e');

      return {
        'removedCount': removedCount,
        'statistics': {
          'estimatedSpaceFreedMB': (estimatedFreedBytes / (1024 * 1024))
              .toStringAsFixed(2),
        },
        'cleanupErrors': cleanupErrors,
        'totalAttempted': 0,
      };
    }
  }

  @override
  void dispose() {
    _unifiedService.dispose();
    super.dispose();
  }
}

// Providers de servicios que se necesitan
final frapLocalServiceProvider = Provider<FrapLocalService>((ref) {
  return FrapLocalService();
});

// Provider del servicio de generación de folios
final folioGeneratorServiceProvider = Provider<FolioGeneratorService>((ref) {
  return FolioGeneratorService();
});

// Provider para generar folio inicial automático
final initialFolioProvider = FutureProvider<String>((ref) async {
  final folioGenerator = ref.watch(folioGeneratorServiceProvider);
  return await folioGenerator.generateUniqueFolio();
});

// Provider para generar folio con iniciales del paciente
final patientFolioProvider = FutureProvider.family<String, String>((
  ref,
  patientName,
) async {
  final folioGenerator = ref.watch(folioGeneratorServiceProvider);
  return await folioGenerator.generateUniquePatientFolio(patientName);
});

// Provider para generar folio automático (solo cuando se solicite)
final autoFolioProvider = FutureProvider.autoDispose<String>((ref) async {
  final folioGenerator = ref.watch(folioGeneratorServiceProvider);
  return await folioGenerator.generateUniqueFolio();
});

// Provider del servicio de Firestore
final frapFirestoreServiceProvider = Provider<FrapFirestoreService>((ref) {
  return FrapFirestoreService();
});

// Provider del servicio unificado
final frapUnifiedServiceProvider = Provider<FrapUnifiedService>((ref) {
  final localService = ref.watch(frapLocalServiceProvider);
  final cloudService = ref.watch(frapFirestoreServiceProvider);

  return FrapUnifiedService(
    localService: localService,
    cloudService: cloudService,
  );
});

// Provider principal
final unifiedFrapProvider =
    StateNotifierProvider<UnifiedFrapNotifier, UnifiedFrapState>((ref) {
      final unifiedService = ref.watch(frapUnifiedServiceProvider);
      final localNotifier = ref.watch(frapLocalProvider.notifier);

      return UnifiedFrapNotifier(unifiedService, localNotifier);
    });

// Provider para estadísticas (para compatibilidad)
final unifiedFrapStatisticsProvider = Provider<Map<String, dynamic>>((ref) {
  final state = ref.watch(unifiedFrapProvider);
  return {
    'total': state.totalRecords,
    'local': state.localRecords,
    'cloud': state.cloudRecords,
    'synced': state.syncedRecords,
    'duplicates': state.duplicateCount,
    'localDuplicates': state.localDuplicatesCount,
    'today':
        state.records.where((r) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          return r.createdAt.isAfter(today);
        }).length,
    'syncedCount': state.syncedRecords,
    'localOnlyCount': state.localRecords - state.syncedRecords,
    'duplicateCount': state.duplicateCount,
    'averageCompletion':
        state.records.isEmpty
            ? 0.0
            : state.records.fold<double>(
                  0,
                  (sum, r) => sum + r.completionPercentage,
                ) /
                state.records.length,
  };
});

// Estado de conectividad simple para reemplazar la capa de auto-sync legacy
final unifiedConnectivityProvider = StreamProvider<bool>((ref) {
  final connectivity = Connectivity();

  final stream = connectivity.onConnectivityChanged.map(
    (results) => !results.contains(ConnectivityResult.none),
  );

  return stream;
});

// Provider de estadísticas de sincronización unificado
final unifiedSyncStatsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final notifier = ref.watch(unifiedFrapProvider.notifier);
  return await notifier.getSyncStats();
});
