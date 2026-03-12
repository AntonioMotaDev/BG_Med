import 'package:bg_med/core/models/frap.dart';
import 'package:bg_med/core/models/patient.dart';

class DuplicateGroup {
  final String groupId;
  final List<Frap> records;
  final DuplicateType type;
  final double confidence;

  DuplicateGroup({
    required this.groupId,
    required this.records,
    required this.type,
    required this.confidence,
  });
}

enum DuplicateType {
  exact, // Registros idénticos
  similar, // Registros muy similares
  potential, // Posibles duplicados
}

class DuplicateDetectionService {
  // Detectar duplicados por múltiples criterios
  Future<List<DuplicateGroup>> detectDuplicates(List<Frap> records) async {
    final Map<String, List<Frap>> groups = {};

    for (final record in records) {
      final contentHash = _generateContentHash(record);
      final patientHash = _generatePatientHash(record.patient);
      final timeHash = _generateTimeHash(record.createdAt);

      // Agrupar por hash de contenido
      if (!groups.containsKey(contentHash)) {
        groups[contentHash] = [];
      }
      groups[contentHash]!.add(record);

      // Agrupar por hash de paciente + tiempo cercano
      final patientTimeKey = '$patientHash-$timeHash';
      if (!groups.containsKey(patientTimeKey)) {
        groups[patientTimeKey] = [];
      }
      groups[patientTimeKey]!.add(record);
    }

    // Convertir grupos a DuplicateGroup
    final List<DuplicateGroup> duplicateGroups = [];

    for (final entry in groups.entries) {
      if (entry.value.length > 1) {
        final type = _determineDuplicateType(entry.value);
        final confidence = _calculateConfidence(entry.value);

        duplicateGroups.add(
          DuplicateGroup(
            groupId: entry.key,
            records: entry.value,
            type: type,
            confidence: confidence,
          ),
        );
      }
    }

    return duplicateGroups;
  }

  // Comparar registros por contenido semántico
  bool areRecordsEquivalent(Frap local, Frap cloud) {
    // Comparar datos críticos del paciente
    if (!_arePatientsEquivalent(local.patient, cloud.patient)) {
      return false;
    }

    // Comparar fechas de creación (con tolerancia de 5 minutos)
    final timeDifference = local.createdAt.difference(cloud.createdAt).abs();
    if (timeDifference.inMinutes > 5) {
      return false;
    }

    // Comparar contenido de secciones principales
    if (!_areSectionsEquivalent(local, cloud)) {
      return false;
    }

    return true;
  }

  // Generar hash único basado en contenido
  String _generateContentHash(Frap record) {
    final content = [
      record.patient.name,
      record.patient.age.toString(),
      record.patient.sex,
      record.createdAt.toIso8601String(),
      record.clinicalHistory.traumaCraneo.toString(),
      record.clinicalHistory.traumaTorax.toString(),
      record.clinicalHistory.agenteCausal,
      (record.physicalExam['vitalSigns']?.toString() ?? ''),
    ].join('|');

    return _hashString(content);
  }

  String _generatePatientHash(Patient patient) {
    final patientData = [
      patient.name.toLowerCase().trim(),
      patient.age.toString(),
      patient.sex,
    ].join('|');

    return _hashString(patientData);
  }

  String _generateTimeHash(DateTime dateTime) {
    // Redondear a intervalos de 5 minutos para tolerancia
    final rounded = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      (dateTime.minute ~/ 5) * 5,
    );

    return rounded.toIso8601String();
  }

  bool _arePatientsEquivalent(Patient p1, Patient p2) {
    return p1.name.toLowerCase().trim() == p2.name.toLowerCase().trim() &&
        p1.age == p2.age &&
        p1.sex == p2.sex;
  }

  bool _areSectionsEquivalent(Frap f1, Frap f2) {
    // Comparar secciones principales de trauma
    return f1.clinicalHistory.traumaCraneo == f2.clinicalHistory.traumaCraneo &&
        f1.clinicalHistory.traumaTorax == f2.clinicalHistory.traumaTorax &&
        f1.clinicalHistory.agenteCausal == f2.clinicalHistory.agenteCausal &&
        (f1.physicalExam['vitalSigns']?.toString() ?? '') ==
            (f2.physicalExam['vitalSigns']?.toString() ?? '');
  }

  DuplicateType _determineDuplicateType(List<Frap> records) {
    if (records.length == 2) {
      final r1 = records[0];
      final r2 = records[1];

      if (areRecordsEquivalent(r1, r2)) {
        return DuplicateType.exact;
      }
    }

    // Verificar similitud alta
    bool hasHighSimilarity = false;
    for (int i = 0; i < records.length; i++) {
      for (int j = i + 1; j < records.length; j++) {
        if (_calculateSimilarity(records[i], records[j]) > 0.8) {
          hasHighSimilarity = true;
          break;
        }
      }
    }

    return hasHighSimilarity ? DuplicateType.similar : DuplicateType.potential;
  }

  double _calculateConfidence(List<Frap> records) {
    if (records.length < 2) return 0.0;

    double totalSimilarity = 0.0;
    int comparisons = 0;

    for (int i = 0; i < records.length; i++) {
      for (int j = i + 1; j < records.length; j++) {
        totalSimilarity += _calculateSimilarity(records[i], records[j]);
        comparisons++;
      }
    }

    return comparisons > 0 ? totalSimilarity / comparisons : 0.0;
  }

  double _calculateSimilarity(Frap r1, Frap r2) {
    double similarity = 0.0;

    // Similitud de paciente (40% del peso)
    if (r1.patient.name.toLowerCase().trim() ==
        r2.patient.name.toLowerCase().trim()) {
      similarity += 0.4;
    }

    // Similitud de edad (20% del peso)
    if (r1.patient.age == r2.patient.age) {
      similarity += 0.2;
    }

    // Similitud de tiempo (30% del peso)
    final timeDiff = r1.createdAt.difference(r2.createdAt).abs();
    if (timeDiff.inMinutes <= 5) {
      similarity += 0.3;
    } else if (timeDiff.inMinutes <= 30) {
      similarity += 0.15;
    }

    // Similitud de contenido (10% del peso)
    if (r1.clinicalHistory.agenteCausal == r2.clinicalHistory.agenteCausal &&
        r1.clinicalHistory.agenteCausal.isNotEmpty) {
      similarity += 0.1;
    }

    return similarity;
  }

  String _hashString(String input) {
    // Hash simple para este ejemplo
    // En producción, usar un hash más robusto como SHA-256
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = ((hash << 5) - hash + input.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    return hash.toString();
  }
}
