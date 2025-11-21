import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class FrapFirestore extends Equatable {
  final String? id;
  final String userId; // ID del usuario que creó el registro
  final DateTime createdAt;
  final DateTime updatedAt;

  // Información del Servicio
  final Map<String, dynamic> serviceInfo;

  // Información del Registro
  final Map<String, dynamic> registryInfo;

  // Información del Paciente
  final Map<String, dynamic> patientInfo;

  // Manejo
  final Map<String, dynamic> management;

  // Medicamentos
  final Map<String, dynamic> medications;

  // Gineco-Obstétrico
  final Map<String, dynamic> gynecoObstetric;

  // Negativa de Atención
  final Map<String, dynamic> attentionNegative;

  // Antecedentes Patológicos
  final Map<String, dynamic> pathologicalHistory;

  // Historia Clínica
  final Map<String, dynamic> clinicalHistory;

  // Examen Físico
  final Map<String, dynamic> physicalExam;

  // Justificación de Prioridad
  final Map<String, dynamic> priorityJustification;

  // Localización de Lesiones
  final Map<String, dynamic> injuryLocation;

  // Unidad Receptora
  final Map<String, dynamic> receivingUnit;

  // Recepción del Paciente
  final Map<String, dynamic> patientReception;

  // Insumos
  final List<Map<String, dynamic>> insumos;

  const FrapFirestore({
    this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.serviceInfo = const {},
    this.registryInfo = const {},
    this.patientInfo = const {},
    this.management = const {},
    this.medications = const {},
    this.gynecoObstetric = const {},
    this.attentionNegative = const {},
    this.pathologicalHistory = const {},
    this.clinicalHistory = const {},
    this.physicalExam = const {},
    this.priorityJustification = const {},
    this.injuryLocation = const {},
    this.receivingUnit = const {},
    this.patientReception = const {},
    this.insumos = const [],
  });

  // Factory constructor desde Firestore
  factory FrapFirestore.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Debug: Ver qué contiene attentionNegative en los datos raw de Firebase
    print('🔥 [FIREBASE RAW] attentionNegative for doc ${doc.id}:');
    print(data['attentionNegative']);

    // Helper function para convertir timestamps de manera segura
    DateTime parseTimestamp(dynamic timestamp) {
      if (timestamp == null) {
        return DateTime.now();
      }
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      }
      if (timestamp is String) {
        return DateTime.parse(timestamp);
      }
      return DateTime.now();
    }

    // Helper function para convertir Maps de manera segura
    Map<String, dynamic> parseMap(dynamic mapData) {
      if (mapData == null) return {};
      if (mapData is Map<String, dynamic>) return mapData;
      return {};
    }

    List<Map<String, dynamic>> parseList(dynamic listData) {
      if (listData == null) return [];
      if (listData is List<dynamic>) {
        return listData.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    }

    return FrapFirestore(
      id: doc.id,
      userId: data['userId'] ?? '',
      createdAt: parseTimestamp(data['createdAt']),
      updatedAt: parseTimestamp(data['updatedAt']),
      serviceInfo: parseMap(data['serviceInfo']),
      registryInfo: parseMap(data['registryInfo']),
      patientInfo: parseMap(data['patientInfo']),
      management: parseMap(data['management']),
      medications: parseMap(data['medications']),
      gynecoObstetric: parseMap(data['gynecoObstetric']),
      attentionNegative: parseMap(data['attentionNegative']),
      pathologicalHistory: parseMap(data['pathologicalHistory']),
      clinicalHistory: parseMap(data['clinicalHistory']),
      physicalExam: parseMap(data['physicalExam']),
      priorityJustification: parseMap(data['priorityJustification']),
      injuryLocation: parseMap(data['injuryLocation']),
      receivingUnit: parseMap(data['receivingUnit']),
      patientReception: parseMap(data['patientReception']),
      insumos: parseList(data['insumos']),
    );
  }

  // Factory constructor desde Map
  factory FrapFirestore.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseTimestamp(dynamic timestamp) {
      if (timestamp == null) {
        return DateTime.now();
      }
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      }
      if (timestamp is String) {
        try {
          return DateTime.parse(timestamp);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    Map<String, dynamic> parseMap(dynamic mapData) {
      if (mapData == null) return {};
      if (mapData is Map<String, dynamic>) return mapData;
      return {};
    }

    List<Map<String, dynamic>> parseList(dynamic listData) {
      if (listData == null) return [];
      if (listData is List<dynamic>) {
        return listData.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    }

    return FrapFirestore(
      id: id,
      userId: data['userId'] ?? '',
      createdAt: parseTimestamp(data['createdAt']),
      updatedAt: parseTimestamp(data['updatedAt']),
      serviceInfo: parseMap(data['serviceInfo']),
      registryInfo: parseMap(data['registryInfo']),
      patientInfo: parseMap(data['patientInfo']),
      management: parseMap(data['management']),
      medications: parseMap(data['medications']),
      gynecoObstetric: parseMap(data['gynecoObstetric']),
      attentionNegative: parseMap(data['attentionNegative']),
      pathologicalHistory: parseMap(data['pathologicalHistory']),
      clinicalHistory: parseMap(data['clinicalHistory']),
      physicalExam: parseMap(data['physicalExam']),
      priorityJustification: parseMap(data['priorityJustification']),
      injuryLocation: parseMap(data['injuryLocation']),
      receivingUnit: parseMap(data['receivingUnit']),
      patientReception: parseMap(data['patientReception']),
      insumos: parseList(data['insumos']),
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'serviceInfo': serviceInfo,
      'registryInfo': registryInfo,
      'patientInfo': patientInfo,
      'management': management,
      'medications': medications,
      'gynecoObstetric': gynecoObstetric,
      'attentionNegative': attentionNegative,
      'pathologicalHistory': pathologicalHistory,
      'clinicalHistory': clinicalHistory,
      'physicalExam': physicalExam,
      'priorityJustification': priorityJustification,
      'injuryLocation': injuryLocation,
      'receivingUnit': receivingUnit,
      'patientReception': patientReception,
      'insumos': insumos,
    };
  }

  // Convertir a Map sin timestamps (para casos especiales)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'serviceInfo': serviceInfo,
      'registryInfo': registryInfo,
      'patientInfo': patientInfo,
      'management': management,
      'medications': medications,
      'gynecoObstetric': gynecoObstetric,
      'attentionNegative': attentionNegative,
      'pathologicalHistory': pathologicalHistory,
      'clinicalHistory': clinicalHistory,
      'physicalExam': physicalExam,
      'priorityJustification': priorityJustification,
      'injuryLocation': injuryLocation,
      'receivingUnit': receivingUnit,
      'patientReception': patientReception,
      'insumos': insumos,
    };
  }

  // Método para crear una copia con campos actualizados
  FrapFirestore copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? serviceInfo,
    Map<String, dynamic>? registryInfo,
    Map<String, dynamic>? patientInfo,
    Map<String, dynamic>? management,
    Map<String, dynamic>? medications,
    Map<String, dynamic>? gynecoObstetric,
    Map<String, dynamic>? attentionNegative,
    Map<String, dynamic>? pathologicalHistory,
    Map<String, dynamic>? clinicalHistory,
    Map<String, dynamic>? physicalExam,
    Map<String, dynamic>? priorityJustification,
    Map<String, dynamic>? injuryLocation,
    Map<String, dynamic>? receivingUnit,
    Map<String, dynamic>? patientReception,
    List<Map<String, dynamic>>? insumos,
  }) {
    return FrapFirestore(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serviceInfo: serviceInfo ?? this.serviceInfo,
      registryInfo: registryInfo ?? this.registryInfo,
      patientInfo: patientInfo ?? this.patientInfo,
      management: management ?? this.management,
      medications: medications ?? this.medications,
      gynecoObstetric: gynecoObstetric ?? this.gynecoObstetric,
      attentionNegative: attentionNegative ?? this.attentionNegative,
      pathologicalHistory: pathologicalHistory ?? this.pathologicalHistory,
      clinicalHistory: clinicalHistory ?? this.clinicalHistory,
      physicalExam: physicalExam ?? this.physicalExam,
      priorityJustification:
          priorityJustification ?? this.priorityJustification,
      injuryLocation: injuryLocation ?? this.injuryLocation,
      receivingUnit: receivingUnit ?? this.receivingUnit,
      patientReception: patientReception ?? this.patientReception,
      insumos: insumos ?? this.insumos,
    );
  }

  // Factory constructor para crear un nuevo registro
  factory FrapFirestore.create({
    required String userId,
    Map<String, dynamic>? serviceInfo,
    Map<String, dynamic>? registryInfo,
    Map<String, dynamic>? patientInfo,
    Map<String, dynamic>? management,
    Map<String, dynamic>? medications,
    Map<String, dynamic>? gynecoObstetric,
    Map<String, dynamic>? attentionNegative,
    Map<String, dynamic>? pathologicalHistory,
    Map<String, dynamic>? clinicalHistory,
    Map<String, dynamic>? physicalExam,
    Map<String, dynamic>? priorityJustification,
    Map<String, dynamic>? injuryLocation,
    Map<String, dynamic>? receivingUnit,
    Map<String, dynamic>? patientReception,
    List<Map<String, dynamic>>? insumos,
  }) {
    final now = DateTime.now();
    return FrapFirestore(
      userId: userId,
      createdAt: now,
      updatedAt: now,
      serviceInfo: serviceInfo ?? {},
      registryInfo: registryInfo ?? {},
      patientInfo: patientInfo ?? {},
      management: management ?? {},
      medications: medications ?? {},
      gynecoObstetric: gynecoObstetric ?? {},
      attentionNegative: attentionNegative ?? {},
      pathologicalHistory: pathologicalHistory ?? {},
      clinicalHistory: clinicalHistory ?? {},
      physicalExam: physicalExam ?? {},
      priorityJustification: priorityJustification ?? {},
      injuryLocation: injuryLocation ?? {},
      receivingUnit: receivingUnit ?? {},
      patientReception: patientReception ?? {},
      insumos: insumos ?? [],
    );
  }

  // Obtener nombre del paciente desde patientInfo
  String get patientName {
    final firstName = patientInfo['firstName'] ?? '';
    final paternalLastName = patientInfo['paternalLastName'] ?? '';
    final maternalLastName = patientInfo['maternalLastName'] ?? '';

    if (firstName.isEmpty &&
        paternalLastName.isEmpty &&
        maternalLastName.isEmpty) {
      return 'Sin nombre';
    }

    return '$firstName $paternalLastName $maternalLastName'.trim();
  }

  // Obtener edad del paciente
  int get patientAge {
    return patientInfo['age'] ?? 0;
  }

  // Obtener el sexo del paciente
  String get patientSex {
    return patientInfo['sex'] ?? '';
  }

  // Obtener genero del paciente
  String get patientGender {
    return patientInfo['gender'] ?? '';
  }

  // Obtener detalles de dirección del paciente (entre calles / referencias)
  String get patientAddressDetails {
    return patientInfo['addressDetails'] ?? '';
  }

  // Obtener tipo de entrega del paciente
  String get patientTipoEntrega {
    return patientInfo['tipoEntrega'] ?? '';
  }

  // Verificar si el registro está completo
  bool get isComplete {
    return serviceInfo.isNotEmpty &&
        registryInfo.isNotEmpty &&
        patientInfo.isNotEmpty &&
        management.isNotEmpty;
  }

  // Obtener porcentaje de completitud
  double get completionPercentage {
    int totalSections = 10;
    int completedSections = 0;

    if (serviceInfo.isNotEmpty) completedSections++;
    if (registryInfo.isNotEmpty) completedSections++;
    if (patientInfo.isNotEmpty) completedSections++;
    if (management.isNotEmpty) completedSections++;
    if (medications.isNotEmpty) completedSections++;
    if (physicalExam.isNotEmpty) completedSections++;
    if (priorityJustification.isNotEmpty) completedSections++;
    if (injuryLocation.isNotEmpty) completedSections++;
    if (receivingUnit.isNotEmpty) completedSections++;
    if (patientReception.isNotEmpty) completedSections++;

    return (completedSections / totalSections) * 100;
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    createdAt,
    updatedAt,
    serviceInfo,
    registryInfo,
    patientInfo,
    management,
    medications,
    gynecoObstetric,
    attentionNegative,
    pathologicalHistory,
    clinicalHistory,
    physicalExam,
    priorityJustification,
    injuryLocation,
    receivingUnit,
    patientReception,
    insumos,
  ];

  @override
  String toString() {
    return 'FrapFirestore(id: $id, patient: $patientName, age: $patientAge, sex: $patientSex, gender: $patientGender, addressDetails: $patientAddressDetails, tipoEntrega: $patientTipoEntrega, completion: ${completionPercentage.toStringAsFixed(1)}%)';
  }
}
