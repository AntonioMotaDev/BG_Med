import 'package:flutter_riverpod/flutter_riverpod.dart';

// Modelo para almacenar todos los datos del FRAP
class FrapData {
  final Map<String, dynamic> serviceInfo;
  final Map<String, dynamic> registryInfo;
  final Map<String, dynamic> patientInfo;
  final Map<String, dynamic> management;
  final Map<String, dynamic> medications;
  final Map<String, dynamic> gynecoObstetric;
  final Map<String, dynamic> attentionNegative;
  final Map<String, dynamic> pathologicalHistory;
  final Map<String, dynamic> clinicalHistory;
  final Map<String, dynamic> physicalExam;
  final Map<String, dynamic> priorityJustification;
  final Map<String, dynamic> injuryLocation;
  final Map<String, dynamic> receivingUnit;
  final Map<String, dynamic> patientReception;
  final List<Map<String, dynamic>> insumos;

  const FrapData({
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

  FrapData copyWith({
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
    return FrapData(
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

  Map<String, dynamic> getSectionData(String sectionId) {
    switch (sectionId) {
      case 'service_info':
        return serviceInfo;
      case 'registry_info':
        return registryInfo;
      case 'patient_info':
        return patientInfo;
      case 'management':
        return management;
      case 'medications':
        return medications;
      case 'gyneco_obstetric':
        return gynecoObstetric;
      case 'attention_negative':
        return attentionNegative;
      case 'pathological_history':
        return pathologicalHistory;
      case 'clinical_history':
        return clinicalHistory;
      case 'physical_exam':
        return physicalExam;
      case 'priority_justification':
        return priorityJustification;
      case 'injury_location':
        return injuryLocation;
      case 'receiving_unit':
        return receivingUnit;
      case 'patient_reception':
        return patientReception;
      case 'insumos':
        return {'insumos': insumos};
      default:
        return {};
    }
  }

  int getFilledFieldsCount(String sectionId) {
    final sectionData = getSectionData(sectionId);
    return sectionData.values
        .where((value) => value != null && value.toString().trim().isNotEmpty)
        .length;
  }
}

// Provider para manejar los datos del FRAP
final frapDataProvider = StateNotifierProvider<FrapDataNotifier, FrapData>((
  ref,
) {
  return FrapDataNotifier();
});

class FrapDataNotifier extends StateNotifier<FrapData> {
  FrapDataNotifier() : super(const FrapData());

  void updateSectionData(String sectionId, Map<String, dynamic> data) {
    switch (sectionId) {
      case 'service_info':
        state = state.copyWith(serviceInfo: {...state.serviceInfo, ...data});
        break;
      case 'registry_info':
        state = state.copyWith(registryInfo: {...state.registryInfo, ...data});
        break;
      case 'patient_info':
        state = state.copyWith(patientInfo: {...state.patientInfo, ...data});
        break;
      case 'management':
        state = state.copyWith(management: {...state.management, ...data});
        break;
      case 'medications':
        state = state.copyWith(medications: {...state.medications, ...data});
        break;
      case 'gyneco_obstetric':
        state = state.copyWith(
          gynecoObstetric: {...state.gynecoObstetric, ...data},
        );
        break;
      case 'attention_negative':
        state = state.copyWith(
          attentionNegative: {...state.attentionNegative, ...data},
        );
        break;
      case 'pathological_history':
        state = state.copyWith(
          pathologicalHistory: {...state.pathologicalHistory, ...data},
        );
        break;
      case 'clinical_history':
        state = state.copyWith(
          clinicalHistory: {...state.clinicalHistory, ...data},
        );
        break;
      case 'physical_exam':
        state = state.copyWith(physicalExam: {...state.physicalExam, ...data});
        break;
      case 'priority_justification':
        state = state.copyWith(
          priorityJustification: {...state.priorityJustification, ...data},
        );
        break;
      case 'injury_location':
        state = state.copyWith(
          injuryLocation: {...state.injuryLocation, ...data},
        );
        break;
      case 'receiving_unit':
        state = state.copyWith(
          receivingUnit: {...state.receivingUnit, ...data},
        );
        break;
      case 'patient_reception':
        state = state.copyWith(
          patientReception: {...state.patientReception, ...data},
        );
        break;
      case 'insumos':
        // Usar insumosList que es la lista de mapas, no 'insumos' que es String
        final insumosList = data['insumosList'] as List<dynamic>? ?? [];
        final typedInsumos =
            insumosList
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
        state = state.copyWith(insumos: typedInsumos);
        break;
    }
  }

  void clearAllData() {
    state = const FrapData();
  }

  void setAllData(FrapData data) {
    state = data;
  }
}
