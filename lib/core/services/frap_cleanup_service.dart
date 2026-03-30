import 'dart:convert';

import 'package:bg_med/core/services/frap_unified_service.dart';
import 'package:bg_med/core/services/frap_local_service.dart';
import 'package:bg_med/core/services/frap_firestore_service.dart';

class FrapCleanupService {
  final FrapLocalService _localService;
  final FrapFirestoreService _cloudService;

  FrapCleanupService({
    required FrapLocalService localService,
    required FrapFirestoreService cloudService,
  }) : _localService = localService,
       _cloudService = cloudService;

  // Limpiar registros duplicados con confirmación
  Future<Map<String, dynamic>> cleanupDuplicateRecordsWithConfirmation(
    List<UnifiedFrapRecord> records,
  ) async {
    try {
      final localBackupData = await _localService.backupFrapRecords();

      // Separar registros locales y de la nube
      final localRecords = records.where((r) => r.isLocal).toList();
      final cloudRecords = records.where((r) => !r.isLocal).toList();

      // Detectar duplicados
      final duplicates = _detectDuplicates(localRecords, cloudRecords);

      if (duplicates.isEmpty) {
        return {
          'success': true,
          'message': 'No se encontraron duplicados para limpiar',
          'removedCount': 0,
          'statistics': {
            'totalRecords': records.length,
            'localRecords': localRecords.length,
            'cloudRecords': cloudRecords.length,
            'duplicatesFound': 0,
          },
        };
      }

      // Procesar duplicados
      int removedCount = 0;
      final errors = <String>[];
      final removedLocalIds = <String>[];

      for (final duplicate in duplicates) {
        try {
          final localRecord = duplicate['local'] as UnifiedFrapRecord?;

          if (localRecord != null && localRecord.localRecord != null) {
            final localId = localRecord.localRecord!.id;
            if (localId.isEmpty) continue;

            // Eliminar registro local duplicado
            await _localService.deleteFrapRecord(localId);
            removedCount++;
            removedLocalIds.add(localId);
          }
        } catch (e) {
          errors.add('Error eliminando duplicado: $e');
        }
      }

      // Si hubo errores durante eliminación, intentar rollback completo local
      bool rollbackPerformed = false;
      if (errors.isNotEmpty && removedCount > 0) {
        try {
          await _localService.clearAllFrapRecords();
          await _localService.restoreFrapRecords(backupData: localBackupData);
          rollbackPerformed = true;
        } catch (rollbackError) {
          errors.add('Error durante rollback de limpieza: $rollbackError');
        }
      }

      return {
        'success': errors.isEmpty,
        'message':
            errors.isEmpty
                ? 'Limpieza completada. $removedCount registros eliminados'
                : 'Limpieza completada con errores: ${errors.join(', ')}',
        'removedCount': removedCount,
        'rollbackPerformed': rollbackPerformed,
        'removedLocalIds': removedLocalIds,
        'errors': errors,
        'statistics': {
          'totalRecords': records.length,
          'localRecords': localRecords.length,
          'cloudRecords': cloudRecords.length,
          'duplicatesFound': duplicates.length,
          'removedCount': removedCount,
        },
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error durante la limpieza: $e',
        'removedCount': 0,
        'errors': [e.toString()],
        'statistics': {},
      };
    }
  }

  // Detectar duplicados entre registros locales y de la nube
  List<Map<String, dynamic>> _detectDuplicates(
    List<UnifiedFrapRecord> localRecords,
    List<UnifiedFrapRecord> cloudRecords,
  ) {
    final duplicates = <Map<String, dynamic>>[];
    final seenLocalIds = <String>{};

    for (final localRecord in localRecords) {
      for (final cloudRecord in cloudRecords) {
        final localId = localRecord.localRecord?.id ?? '';
        if (localId.isEmpty || seenLocalIds.contains(localId)) continue;

        // Comparación robusta: folio, señales de paciente y ventana de tiempo
        final confidence = _calculateMatchConfidence(localRecord, cloudRecord);
        if (confidence >= 0.75) {
          seenLocalIds.add(localId);
          duplicates.add({
            'local': localRecord,
            'cloud': cloudRecord,
            'criteria': 'folio_or_patient_signals',
            'confidence': confidence,
          });
        }
      }
    }

    return duplicates;
  }

  double _calculateMatchConfidence(
    UnifiedFrapRecord local,
    UnifiedFrapRecord cloud,
  ) {
    final localFolio = local.folio.trim().toUpperCase();
    final cloudFolio = cloud.folio.trim().toUpperCase();

    // Coincidencia de folio es prácticamente determinística
    if (localFolio.isNotEmpty && cloudFolio.isNotEmpty && localFolio == cloudFolio) {
      return 1.0;
    }

    final localName = _normalizeText(local.patientName);
    final cloudName = _normalizeText(cloud.patientName);
    if (localName.isEmpty || cloudName.isEmpty || localName != cloudName) {
      return 0.0;
    }

    double confidence = 0.5; // nombre

    final sameAge =
        local.patientAge > 0 &&
        cloud.patientAge > 0 &&
        local.patientAge == cloud.patientAge;
    if (sameAge) confidence += 0.2;

    final sameSex =
        local.patientSex.trim().isNotEmpty &&
        cloud.patientSex.trim().isNotEmpty &&
        _normalizeText(local.patientSex) == _normalizeText(cloud.patientSex);
    if (sameSex) confidence += 0.1;

    final samePhone = _arePhonesEquivalent(local.patientPhone, cloud.patientPhone);
    if (samePhone) confidence += 0.2;

    final timeDiffMinutes = local.createdAt.difference(cloud.createdAt).abs().inMinutes;
    if (timeDiffMinutes <= 60) {
      confidence += 0.1;
    } else if (timeDiffMinutes > 240) {
      confidence -= 0.2;
    }

    return confidence.clamp(0.0, 1.0);
  }

  String _normalizeText(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _arePhonesEquivalent(String? a, String? b) {
    final phoneA = (a ?? '').replaceAll(RegExp(r'\D'), '');
    final phoneB = (b ?? '').replaceAll(RegExp(r'\D'), '');
    if (phoneA.isEmpty || phoneB.isEmpty) {
      return false;
    }
    return phoneA == phoneB;
  }

  // Obtener estadísticas de limpieza
  Future<Map<String, dynamic>> getCleanupStatistics(
    List<UnifiedFrapRecord> records,
  ) async {
    try {
      final localRecords = records.where((r) => r.isLocal).toList();
      final cloudRecords = records.where((r) => !r.isLocal).toList();

      final duplicates = _detectDuplicates(localRecords, cloudRecords);
      final estimatedSpaceFreedBytes = duplicates.fold<int>(0, (sum, item) {
        final local = item['local'] as UnifiedFrapRecord?;
        if (local?.localRecord == null) return sum;
        return sum + utf8.encode(jsonEncode(local!.localRecord!.toJson())).length;
      });

      return {
        'totalRecords': records.length,
        'localRecords': localRecords.length,
        'cloudRecords': cloudRecords.length,
        'duplicatesFound': duplicates.length,
        'estimatedSpaceFreedKB': (estimatedSpaceFreedBytes / 1024).toStringAsFixed(2),
        'estimatedSpaceFreedMB':
            (estimatedSpaceFreedBytes / (1024 * 1024)).toStringAsFixed(2),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'totalRecords': 0,
        'localRecords': 0,
        'cloudRecords': 0,
        'duplicatesFound': 0,
        'estimatedSpaceFreedKB': 0,
        'estimatedSpaceFreedMB': '0.00',
      };
    }
  }

  // Crear backup antes de limpiar
  Future<List<Map<String, dynamic>>> createBackupBeforeCleanup() async {
    try {
      final localRecords = await _localService.getAllFrapRecords();
      final cloudRecords = await _cloudService.getAllFrapRecords();

      final backup = <Map<String, dynamic>>[];

      // Backup de registros locales
      for (final record in localRecords) {
        backup.add({
          'type': 'local',
          'id': record.id,
          'patientName': record.patient.name,
          'createdAt': record.createdAt.toIso8601String(),
          'data': record.toJson(),
        });
      }

      // Backup de registros de la nube
      for (final record in cloudRecords) {
        backup.add({
          'type': 'cloud',
          'id': record.id ?? '',
          'patientName': record.patientName,
          'createdAt': record.createdAt.toIso8601String(),
          'data': {
            'patientInfo': record.patientInfo,
            'clinicalHistory': record.clinicalHistory,
            'physicalExam': record.physicalExam,
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
          },
        });
      }

      return backup;
    } catch (e) {
      throw Exception('Error al crear backup: $e');
    }
  }
}
