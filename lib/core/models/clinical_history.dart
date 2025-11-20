import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'clinical_history.g.dart';

@HiveType(typeId: 1)
class ClinicalHistory extends Equatable {
  // Campos de traumas
  @HiveField(0)
  final bool traumaCraneo;
  @HiveField(1)
  final String traumaCraneoEspecifique;
  @HiveField(2)
  final bool traumaTorax;
  @HiveField(3)
  final String traumaToraxEspecifique;
  @HiveField(4)
  final bool traumaAbdomen;
  @HiveField(5)
  final String traumaAbdomenEspecifique;
  @HiveField(6)
  final bool traumaColumna;
  @HiveField(7)
  final String traumaColumnaEspecifique;
  @HiveField(8)
  final bool traumaExtremidades;
  @HiveField(9)
  final String traumaExtremidadesEspecifique;
  @HiveField(10)
  final bool traumaPelvis;
  @HiveField(11)
  final String traumaPelvisEspecifique;
  @HiveField(12)
  final bool traumaOtros;
  @HiveField(13)
  final String traumaOtrosEspecifique;

  // Campos adicionales de historia clínica
  @HiveField(14)
  final String agenteCausal;
  @HiveField(15)
  final String cinematica;
  @HiveField(16)
  final String medidaSeguridad;
  @HiveField(17)
  final String observaciones;

  const ClinicalHistory({
    this.traumaCraneo = false,
    this.traumaCraneoEspecifique = '',
    this.traumaTorax = false,
    this.traumaToraxEspecifique = '',
    this.traumaAbdomen = false,
    this.traumaAbdomenEspecifique = '',
    this.traumaColumna = false,
    this.traumaColumnaEspecifique = '',
    this.traumaExtremidades = false,
    this.traumaExtremidadesEspecifique = '',
    this.traumaPelvis = false,
    this.traumaPelvisEspecifique = '',
    this.traumaOtros = false,
    this.traumaOtrosEspecifique = '',
    this.agenteCausal = '',
    this.cinematica = '',
    this.medidaSeguridad = '',
    this.observaciones = '',
  });

  ClinicalHistory copyWith({
    bool? traumaCraneo,
    String? traumaCraneoEspecifique,
    bool? traumaTorax,
    String? traumaToraxEspecifique,
    bool? traumaAbdomen,
    String? traumaAbdomenEspecifique,
    bool? traumaColumna,
    String? traumaColumnaEspecifique,
    bool? traumaExtremidades,
    String? traumaExtremidadesEspecifique,
    bool? traumaPelvis,
    String? traumaPelvisEspecifique,
    bool? traumaOtros,
    String? traumaOtrosEspecifique,
    String? agenteCausal,
    String? cinematica,
    String? medidaSeguridad,
    String? observaciones,
  }) {
    return ClinicalHistory(
      traumaCraneo: traumaCraneo ?? this.traumaCraneo,
      traumaCraneoEspecifique:
          traumaCraneoEspecifique ?? this.traumaCraneoEspecifique,
      traumaTorax: traumaTorax ?? this.traumaTorax,
      traumaToraxEspecifique:
          traumaToraxEspecifique ?? this.traumaToraxEspecifique,
      traumaAbdomen: traumaAbdomen ?? this.traumaAbdomen,
      traumaAbdomenEspecifique:
          traumaAbdomenEspecifique ?? this.traumaAbdomenEspecifique,
      traumaColumna: traumaColumna ?? this.traumaColumna,
      traumaColumnaEspecifique:
          traumaColumnaEspecifique ?? this.traumaColumnaEspecifique,
      traumaExtremidades: traumaExtremidades ?? this.traumaExtremidades,
      traumaExtremidadesEspecifique:
          traumaExtremidadesEspecifique ?? this.traumaExtremidadesEspecifique,
      traumaPelvis: traumaPelvis ?? this.traumaPelvis,
      traumaPelvisEspecifique:
          traumaPelvisEspecifique ?? this.traumaPelvisEspecifique,
      traumaOtros: traumaOtros ?? this.traumaOtros,
      traumaOtrosEspecifique:
          traumaOtrosEspecifique ?? this.traumaOtrosEspecifique,
      agenteCausal: agenteCausal ?? this.agenteCausal,
      cinematica: cinematica ?? this.cinematica,
      medidaSeguridad: medidaSeguridad ?? this.medidaSeguridad,
      observaciones: observaciones ?? this.observaciones,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'traumaCraneo': traumaCraneo,
      'traumaCraneoEspecifique': traumaCraneoEspecifique,
      'traumaTorax': traumaTorax,
      'traumaToraxEspecifique': traumaToraxEspecifique,
      'traumaAbdomen': traumaAbdomen,
      'traumaAbdomenEspecifique': traumaAbdomenEspecifique,
      'traumaColumna': traumaColumna,
      'traumaColumnaEspecifique': traumaColumnaEspecifique,
      'traumaExtremidades': traumaExtremidades,
      'traumaExtremidadesEspecifique': traumaExtremidadesEspecifique,
      'traumaPelvis': traumaPelvis,
      'traumaPelvisEspecifique': traumaPelvisEspecifique,
      'traumaOtros': traumaOtros,
      'traumaOtrosEspecifique': traumaOtrosEspecifique,
      'agenteCausal': agenteCausal,
      'cinematica': cinematica,
      'medidaSeguridad': medidaSeguridad,
      'observaciones': observaciones,
    };
  }

  @override
  List<Object?> get props => [
    traumaCraneo,
    traumaCraneoEspecifique,
    traumaTorax,
    traumaToraxEspecifique,
    traumaAbdomen,
    traumaAbdomenEspecifique,
    traumaColumna,
    traumaColumnaEspecifique,
    traumaExtremidades,
    traumaExtremidadesEspecifique,
    traumaPelvis,
    traumaPelvisEspecifique,
    traumaOtros,
    traumaOtrosEspecifique,
    agenteCausal,
    cinematica,
    medidaSeguridad,
    observaciones,
  ];
}
