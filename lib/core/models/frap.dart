import 'dart:convert';
import 'package:bg_med/core/models/clinical_history.dart';
import 'package:bg_med/core/models/patient.dart';
// import 'package:bg_med/core/models/physical_exam.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:bg_med/core/models/insumo.dart';
import 'package:bg_med/core/models/personal_medico.dart';
import 'package:bg_med/core/models/escalas_obstetricas.dart';

part 'frap.g.dart';

@HiveType(typeId: 3)
class Frap extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final Patient patient;
  @HiveField(2)
  final ClinicalHistory clinicalHistory;
  @HiveField(3)
  final String _physicalExamJson;
  @HiveField(4)
  final DateTime createdAt;

  // Getter para obtener physicalExam como Map
  Map<String, dynamic> get physicalExam {
    if (_physicalExamJson.isEmpty) return {};
    try {
      return jsonDecode(_physicalExamJson) as Map<String, dynamic>;
    } catch (e) {
      print('Error deserializando physicalExam: $e');
      return {};
    }
  }

  @HiveField(5)
  final DateTime updatedAt;
  @HiveField(6)
  final Map<String, dynamic> serviceInfo;
  @HiveField(7)
  final Map<String, dynamic> registryInfo;
  @HiveField(8)
  final Map<String, dynamic> management;
  @HiveField(9)
  final Map<String, dynamic> medications;
  @HiveField(10)
  final Map<String, dynamic> gynecoObstetric;
  @HiveField(11)
  final Map<String, dynamic> attentionNegative;
  @HiveField(12)
  final Map<String, dynamic> pathologicalHistory;
  @HiveField(13)
  final Map<String, dynamic> priorityJustification;
  @HiveField(14)
  final Map<String, dynamic> injuryLocation;
  @HiveField(15)
  final Map<String, dynamic> receivingUnit;
  @HiveField(16)
  final Map<String, dynamic> patientReception;
  @HiveField(18)
  final List<Insumo> insumos; // Lista de insumos
  @HiveField(19)
  final List<PersonalMedico> personalMedico; // Lista de personal médico
  @HiveField(20)
  final EscalasObstetricas? escalasObstetricas; // Escalas obstétricas

  @HiveField(21)
  final bool isSynced;

  // Nuevos campos para sincronización con diálogos y PDF
  @HiveField(23)
  final String? tipoUrgencia; // Clínico, Trauma, Otro
  @HiveField(24)
  final String? urgenciaEspecifique; // Especificación de urgencia
  @HiveField(25)
  final String? ubicacion; // Ubicación del servicio
  @HiveField(26)
  final String? tipoServicioEspecifique; // Especificación de tipo de servicio
  @HiveField(27)
  final String? lugarOcurrenciaEspecifique; // Especificación de lugar de ocurrencia

  Frap({
    // Campos existentes
    required this.id,
    required this.patient,
    required this.clinicalHistory,
    required Map<String, dynamic> physicalExam,
    required this.createdAt,
    // Nuevos campos con valores por defecto
    DateTime? updatedAt,
    this.serviceInfo = const {},
    this.registryInfo = const {},
    this.management = const {},
    this.medications = const {},
    this.gynecoObstetric = const {},
    this.attentionNegative = const {},
    this.pathologicalHistory = const {},
    this.priorityJustification = const {},
    this.injuryLocation = const {},
    this.receivingUnit = const {},
    this.patientReception = const {},
    this.insumos = const [],
    this.personalMedico = const [],
    this.escalasObstetricas,
    this.isSynced = false,
    this.tipoUrgencia,
    this.urgenciaEspecifique,
    this.ubicacion,
    this.tipoServicioEspecifique,
    this.lugarOcurrenciaEspecifique,
  }) : updatedAt = updatedAt ?? createdAt,
       _physicalExamJson = physicalExam.isEmpty ? '' : jsonEncode(physicalExam);

  // Método copyWith para crear copias con cambios
  Frap copyWith({
    String? id,
    Patient? patient,
    ClinicalHistory? clinicalHistory,
    Map<String, dynamic>? physicalExam,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? serviceInfo,
    Map<String, dynamic>? registryInfo,
    Map<String, dynamic>? management,
    Map<String, dynamic>? medications,
    Map<String, dynamic>? gynecoObstetric,
    Map<String, dynamic>? attentionNegative,
    Map<String, dynamic>? pathologicalHistory,
    Map<String, dynamic>? priorityJustification,
    Map<String, dynamic>? injuryLocation,
    Map<String, dynamic>? receivingUnit,
    Map<String, dynamic>? patientReception,
    List<Insumo>? insumos,
    List<PersonalMedico>? personalMedico,
    EscalasObstetricas? escalasObstetricas,
    bool? isSynced,
    String? tipoUrgencia,
    String? urgenciaEspecifique,
    String? ubicacion,
    String? tipoServicioEspecifique,
    String? lugarOcurrenciaEspecifique,
  }) {
    return Frap(
      id: id ?? this.id,
      patient: patient ?? this.patient,
      clinicalHistory: clinicalHistory ?? this.clinicalHistory,
      physicalExam: physicalExam ?? this.physicalExam,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serviceInfo: serviceInfo ?? this.serviceInfo,
      registryInfo: registryInfo ?? this.registryInfo,
      management: management ?? this.management,
      medications: medications ?? this.medications,
      gynecoObstetric: gynecoObstetric ?? this.gynecoObstetric,
      attentionNegative: attentionNegative ?? this.attentionNegative,
      pathologicalHistory: pathologicalHistory ?? this.pathologicalHistory,
      priorityJustification:
          priorityJustification ?? this.priorityJustification,
      injuryLocation: injuryLocation ?? this.injuryLocation,
      receivingUnit: receivingUnit ?? this.receivingUnit,
      patientReception: patientReception ?? this.patientReception,
      insumos: insumos ?? this.insumos,
      personalMedico: personalMedico ?? this.personalMedico,
      escalasObstetricas: escalasObstetricas ?? this.escalasObstetricas,
      isSynced: isSynced ?? this.isSynced,
      tipoUrgencia: tipoUrgencia ?? this.tipoUrgencia,
      urgenciaEspecifique: urgenciaEspecifique ?? this.urgenciaEspecifique,
      ubicacion: ubicacion ?? this.ubicacion,
      tipoServicioEspecifique:
          tipoServicioEspecifique ?? this.tipoServicioEspecifique,
      lugarOcurrenciaEspecifique:
          lugarOcurrenciaEspecifique ?? this.lugarOcurrenciaEspecifique,
    );
  }

  // Método para actualizar una sección específica
  Frap updateSection(String sectionName, Map<String, dynamic> sectionData) {
    switch (sectionName) {
      case 'serviceInfo':
        return copyWith(serviceInfo: sectionData);
      case 'registryInfo':
        return copyWith(registryInfo: sectionData);
      case 'management':
        return copyWith(management: sectionData);
      case 'medications':
        return copyWith(medications: sectionData);
      case 'gynecoObstetric':
        return copyWith(gynecoObstetric: sectionData);
      case 'attentionNegative':
        return copyWith(attentionNegative: sectionData);
      case 'pathologicalHistory':
        return copyWith(pathologicalHistory: sectionData);
      case 'priorityJustification':
        return copyWith(priorityJustification: sectionData);
      case 'injuryLocation':
        return copyWith(injuryLocation: sectionData);
      case 'receivingUnit':
        return copyWith(receivingUnit: sectionData);
      case 'patientReception':
        return copyWith(patientReception: sectionData);
      default:
        return this;
    }
  }

  // Método para obtener una sección específica
  Map<String, dynamic> getSection(String sectionName) {
    switch (sectionName) {
      case 'serviceInfo':
        return serviceInfo;
      case 'registryInfo':
        return registryInfo;
      case 'management':
        return management;
      case 'medications':
        return medications;
      case 'gynecoObstetric':
        return gynecoObstetric;
      case 'attentionNegative':
        return attentionNegative;
      case 'pathologicalHistory':
        return pathologicalHistory;
      case 'priorityJustification':
        return priorityJustification;
      case 'injuryLocation':
        return injuryLocation;
      case 'receivingUnit':
        return receivingUnit;
      case 'patientReception':
        return patientReception;
      default:
        return {};
    }
  }

  // Método para verificar si una sección tiene datos
  bool hasSectionData(String sectionName) {
    final section = getSection(sectionName);
    return section.isNotEmpty &&
        section.values.any(
          (value) => value != null && value.toString().trim().isNotEmpty,
        );
  }

  // Método para calcular completitud del registro
  double get completionPercentage {
    int totalSections = 10;
    int completedSections = 1;

    // Secciones básicas (siempre presentes)
    if (hasSectionData('serviceInfo')) completedSections++;
    if (hasSectionData('registryInfo')) completedSections++;
    if (patient.name.isNotEmpty) completedSections++;
    if (hasSectionData('management')) completedSections++;
    if (hasSectionData('medications')) completedSections++;
    if (physicalExam.isNotEmpty) completedSections++;
    if (hasSectionData('priorityJustification')) completedSections++;
    if (hasSectionData('receivingUnit')) completedSections++;
    if (hasSectionData('patientReception')) completedSections++;

    return (completedSections / totalSections) * 100;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient': patient.toJson(),
      'clinicalHistory': clinicalHistory.toJson(),
      'physicalExam': physicalExam,
      'serviceInfo': serviceInfo,
      'registryInfo': registryInfo,
      'management': management,
      'medications': medications,
      'gynecoObstetric': gynecoObstetric,
      'attentionNegative': attentionNegative,
      'pathologicalHistory': pathologicalHistory,
      'priorityJustification': priorityJustification,
      'injuryLocation': injuryLocation,
      'receivingUnit': receivingUnit,
      'patientReception': patientReception,
      'insumos': insumos.map((i) => i.toJson()).toList(),
      'personalMedico': personalMedico.map((p) => p.toJson()).toList(),
      'escalasObstetricas': escalasObstetricas?.toJson(),
      'tipoUrgencia': tipoUrgencia,
      'urgenciaEspecifique': urgenciaEspecifique,
      'ubicacion': ubicacion,
      'tipoServicioEspecifique': tipoServicioEspecifique,
      'lugarOcurrenciaEspecifique': lugarOcurrenciaEspecifique,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  @override
  List<Object?> get props => [
    id,
    patient,
    clinicalHistory,
    physicalExam,
    createdAt,
    updatedAt,
    serviceInfo,
    registryInfo,
    management,
    medications,
    gynecoObstetric,
    attentionNegative,
    pathologicalHistory,
    priorityJustification,
    injuryLocation,
    receivingUnit,
    patientReception,
    insumos,
    personalMedico,
    escalasObstetricas,
    isSynced,
    tipoUrgencia,
    urgenciaEspecifique,
    ubicacion,
    tipoServicioEspecifique,
    lugarOcurrenciaEspecifique,
  ];
}
