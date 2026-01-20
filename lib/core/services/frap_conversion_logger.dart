import 'dart:developer' as developer;
import 'package:bg_med/core/models/frap.dart';
import 'package:bg_med/core/models/frap_firestore.dart';
import 'package:bg_med/core/services/frap_data_validator.dart';

/// Servicio de logging para conversiones FRAP
class FrapConversionLogger {
  static const String _tag = 'FrapConversion';

  /// Log de inicio de conversión
  static void logConversionStart(String direction, String recordId) {
    developer.log(
      'Iniciando conversión $direction para registro: $recordId',
      name: _tag,
      level: 1000, // Info level
    );
  }

  /// Log de conversión exitosa
  static void logConversionSuccess(
    String direction,
    String recordId,
    Map<String, dynamic> stats,
  ) {
    developer.log(
      'Conversión $direction exitosa para registro: $recordId\n'
      'Estadísticas: $stats',
      name: _tag,
      level: 1000,
    );
  }

  /// Log de error en conversión
  static void logConversionError(
    String direction,
    String recordId,
    String error,
    StackTrace? stackTrace,
  ) {
    developer.log(
      'Error en conversión $direction para registro: $recordId\n'
      'Error: $error',
      name: _tag,
      level: 900, // Warning level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log de validación de datos
  static void logValidationResult(String section, ValidationResult result) {
    if (result.errors.isNotEmpty) {
      developer.log(
        'Errores de validación en $section:\n'
        '${result.errors.join('\n')}',
        name: _tag,
        level: 900,
      );
    }

    if (result.warnings.isNotEmpty) {
      developer.log(
        'Advertencias de validación en $section:\n'
        '${result.warnings.join('\n')}',
        name: _tag,
        level: 800, // Info level
      );
    }
  }

  /// Log de campos faltantes
  static void logMissingFields(String direction, List<String> missingFields) {
    if (missingFields.isNotEmpty) {
      developer.log(
        'Campos faltantes en conversión $direction:\n'
        '${missingFields.join(', ')}',
        name: _tag,
        level: 800,
      );
    }
  }

  /// Log de campos convertidos
  static void logConvertedFields(
    String direction,
    Map<String, dynamic> convertedFields,
  ) {
    developer.log(
      'Campos convertidos en $direction:\n'
      '${convertedFields.keys.join(', ')}',
      name: _tag,
      level: 700, // Debug level
    );
  }

  /// Log de estadísticas de conversión
  static void logConversionStats(String direction, Map<String, dynamic> stats) {
    developer.log(
      'Estadísticas de conversión $direction:\n'
      '${stats.entries.map((e) => '${e.key}: ${e.value}').join('\n')}',
      name: _tag,
      level: 1000,
    );
  }

  /// Log de sincronización
  static void logSyncOperation(
    String operation,
    int successCount,
    int failedCount,
    List<String> errors,
  ) {
    developer.log(
      'Operación de sincronización: $operation\n'
      'Exitosos: $successCount\n'
      'Fallidos: $failedCount\n'
      'Errores: ${errors.join(', ')}',
      name: _tag,
      level: 1000,
    );
  }

  /// Log de comparación de registros
  static void logRecordComparison(Frap local, FrapFirestore cloud) {
    final comparison = _compareRecords(local, cloud);

    developer.log(
      'Comparación de registros:\n'
      '${comparison.entries.map((e) => '${e.key}: ${e.value}').join('\n')}',
      name: _tag,
      level: 700,
    );
  }

  /// Comparar registros local y nube
  static Map<String, String> _compareRecords(Frap local, FrapFirestore cloud) {
    final comparison = <String, String>{};

    // Comparar datos del paciente
    comparison['patientName'] =
        'Local: ${local.patient.fullName} | Cloud: ${cloud.patientName}';
    comparison['patientAge'] =
        'Local: ${local.patient.age} | Cloud: ${cloud.patientAge}';
    comparison['patientGender'] =
        'Local: ${local.patient.sex} | Cloud: ${cloud.patientGender}';

    // Comparar fechas
    comparison['createdAt'] =
        'Local: ${local.createdAt} | Cloud: ${cloud.createdAt}';
    comparison['updatedAt'] =
        'Local: ${local.updatedAt} | Cloud: ${cloud.updatedAt}';

    // Comparar secciones
    comparison['serviceInfo'] =
        'Local: ${local.serviceInfo.length} campos | Cloud: ${cloud.serviceInfo.length} campos';
    comparison['management'] =
        'Local: ${local.management.length} campos | Cloud: ${cloud.management.length} campos';
    comparison['medications'] =
        'Local: ${local.medications.length} campos | Cloud: ${cloud.medications.length} campos';

    return comparison;
  }

  /// Log de métricas de performance
  static void logPerformanceMetrics(
    String operation,
    Duration duration,
    Map<String, dynamic> metrics,
  ) {
    developer.log(
      'Métricas de performance para $operation:\n'
      'Duración: ${duration.inMilliseconds}ms\n'
      '${metrics.entries.map((e) => '${e.key}: ${e.value}').join('\n')}',
      name: _tag,
      level: 1000,
    );
  }

  /// Log de resumen de conversión
  static void logConversionSummary(
    String direction,
    int totalRecords,
    int successCount,
    int failedCount,
    List<String> errors,
  ) {
    final successRate =
        totalRecords > 0 ? (successCount / totalRecords) * 100 : 0.0;

    developer.log(
      'Resumen de conversión $direction:\n'
      'Total de registros: $totalRecords\n'
      'Exitosos: $successCount\n'
      'Fallidos: $failedCount\n'
      'Tasa de éxito: ${successRate.toStringAsFixed(2)}%\n'
      'Errores: ${errors.join(', ')}',
      name: _tag,
      level: 1000,
    );
  }

  /// Log de campos específicos del modelo local
  static void logLocalSpecificFields(Frap local) {
    final signature = local.serviceInfo['consentimientoSignature'] as String?;
    final localFields = <String, dynamic>{
      'consentimientoSignature (serviceInfo)':
          signature != null && signature.isNotEmpty ? 'Presente' : 'Vacío',
      'insumos': '${local.insumos.length} elementos',
      'personalMedico': '${local.personalMedico.length} elementos',
      'escalasObstetricas':
          local.escalasObstetricas != null ? 'Presente' : 'Nulo',
      'isSynced': local.isSynced,
    };

    developer.log(
      'Campos específicos del modelo local:\n'
      '${localFields.entries.map((e) => '${e.key}: ${e.value}').join('\n')}',
      name: _tag,
      level: 700,
    );
  }

  /// Log de campos específicos del modelo nube
  static void logCloudSpecificFields(FrapFirestore cloud) {
    final cloudFields = <String, dynamic>{
      'userId': cloud.userId.isNotEmpty ? 'Presente' : 'Vacío',
      'patientInfo': '${cloud.patientInfo.length} campos',
      'clinicalHistory': '${cloud.clinicalHistory.length} campos',
      'physicalExam': '${cloud.physicalExam.length} campos',
    };

    developer.log(
      'Campos específicos del modelo nube:\n'
      '${cloudFields.entries.map((e) => '${e.key}: ${e.value}').join('\n')}',
      name: _tag,
      level: 700,
    );
  }

  /// Log de detección de conflictos
  static void logConflictDetection(
    String recordId,
    String conflictType,
    Map<String, dynamic> details,
  ) {
    developer.log(
      'Conflicto detectado en registro: $recordId\n'
      'Tipo: $conflictType\n'
      'Detalles: $details',
      name: _tag,
      level: 900,
    );
  }

  /// Log de resolución de conflictos
  static void logConflictResolution(
    String recordId,
    String resolution,
    Map<String, dynamic> details,
  ) {
    developer.log(
      'Conflicto resuelto en registro: $recordId\n'
      'Resolución: $resolution\n'
      'Detalles: $details',
      name: _tag,
      level: 1000,
    );
  }

  /// Log de limpieza de datos
  static void logDataCleaning(
    String section,
    int originalCount,
    int cleanedCount,
    List<String> removedFields,
  ) {
    developer.log(
      'Limpieza de datos en $section:\n'
      'Campos originales: $originalCount\n'
      'Campos después de limpieza: $cleanedCount\n'
      'Campos removidos: ${removedFields.join(', ')}',
      name: _tag,
      level: 800,
    );
  }

  /// Log de validación de integridad
  static void logIntegrityCheck(
    String recordId,
    bool isIntegrityValid,
    List<String> integrityIssues,
  ) {
    if (!isIntegrityValid) {
      developer.log(
        'Problemas de integridad en registro: $recordId\n'
        'Problemas: ${integrityIssues.join(', ')}',
        name: _tag,
        level: 900,
      );
    } else {
      developer.log(
        'Integridad validada para registro: $recordId',
        name: _tag,
        level: 700,
      );
    }
  }
}
