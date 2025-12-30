import 'package:bg_med/core/services/frap_unified_service.dart';
import 'package:bg_med/core/services/frap_local_service.dart';
import 'package:bg_med/core/services/frap_firestore_service.dart';
import 'package:bg_med/features/frap/presentation/providers/frap_local_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bg_med/features/frap/presentation/providers/frap_data_provider.dart';
import 'package:bg_med/core/services/folio_generator_service.dart';
import 'dart:convert';

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

  void verComoJSON(List<UnifiedFrapRecord> registros) {
    for (int i = 0; i < registros.length; i++) {
      var info = registros[i].getDetailedInfo();
      var jsonString = JsonEncoder.withIndent('  ').convert(info);
      print("\n📄 Registro $i (JSON):");
      print(jsonString);
    }
  }

  // Cargar todos los registros
  Future<void> loadAllRecords() async {
    if (_isUpdating) return;
    _isUpdating = true;

    state = state.copyWith(isLoading: true, error: null);

    try {
      print('Cargando registros unificados...');
      final records = await _unifiedService.getAllRecords();
      verComoJSON(records);
      print('Registros: $records');

      final stats = _calculateStats(records);
      print('Estadísticas calculadas: $stats');

      state = state.copyWith(
        records: records,
        isLoading: false,
        totalRecords: stats['total'],
        localRecords: stats['local'],
        cloudRecords: stats['cloud'],
        syncedRecords: stats['synced'],
        error: null,
      );
    } catch (e) {
      print('Error cargando registros: $e');
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

    for (final record in records) {
      if (record.isLocal) {
        localCount++;
        if (record.isSynced) syncedCount++;
      } else {
        cloudCount++;
        syncedCount++;
      }
    }

    return {
      'total': records.length,
      'local': localCount,
      'cloud': cloudCount,
      'synced': syncedCount,
    };
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
      print('Iniciando syncAndCleanup...');
      state = state.copyWith(syncStatus: SyncStatus.syncing);

      // 1. Sincronizar registros
      print('Sincronizando registros pendientes...');
      final syncResult = await _unifiedService.syncPendingRecords();

      print('Resultado de sincronización: $syncResult');

      if (syncResult.success) {
        // 2. Recargar registros después de la sincronización
        print('Recargando registros después de sincronización...');
        await loadAllRecords();

        state = state.copyWith(
          syncStatus: SyncStatus.success,
          lastSync: DateTime.now(),
        );

        return {
          'success': true,
          'message': 'Sincronización completada exitosamente',
          'syncedRecords': syncResult.successCount,
          'cleanupResult': {
            'removedCount': 0, // Por ahora no implementamos limpieza automática
            'statistics': {'estimatedSpaceFreedMB': '0.00'},
          },
        };
      } else {
        print('Error en sincronización: ${syncResult.message}');
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
      print('Excepción en syncAndCleanup: $e');
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
  };
});

// Provider para el notificador de registros unificados (para compatibilidad)
final unifiedRecordsNotifierProvider =
    StateNotifierProvider<UnifiedFrapNotifier, UnifiedFrapState>((ref) {
      final unifiedService = ref.watch(frapUnifiedServiceProvider);
      final localNotifier = ref.watch(frapLocalProvider.notifier);

      return UnifiedFrapNotifier(unifiedService, localNotifier);
    });
