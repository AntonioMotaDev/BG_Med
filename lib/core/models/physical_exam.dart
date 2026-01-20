import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'physical_exam.g.dart';

@HiveType(typeId: 2)
class PhysicalExam extends Equatable {
  // Campos básicos de evaluación
  @HiveField(0)
  final String eva; // Escala EVA (0-10)
  @HiveField(1)
  final String llc; // LLC en segundos
  @HiveField(2)
  final String glucosa; // Glucosa mg/dl
  @HiveField(3)
  final String ta; // Tensión arterial mm/Hg

  // Campos SAMPLE
  @HiveField(4)
  final String sampleAlergias; // S: Signos y síntomas / A: Alergias
  @HiveField(5)
  final String sampleMedicamentos; // M: Medicamentos
  @HiveField(6)
  final String sampleEnfermedades; // P: Historia médica previa
  @HiveField(7)
  final String sampleHoraAlimento; // L: Última ingesta oral
  @HiveField(8)
  final String sampleEventosPrevios; // E: Eventos previos

  // Estructura de signos vitales dinámicos
  @HiveField(9)
  final List<String> timeColumns; // ['Hora 1', 'Hora 2', 'Hora 3', ...]
  @HiveField(10)
  final Map<String, Map<String, String>> vitalSignsData; // {'T/A': {'Hora 1': '120/80', 'Hora 2': '130/85'}, ...}

  // Timestamp para auditoría
  @HiveField(11)
  final String timestamp;

  // Campos obsoletos mantenidos para compatibilidad (serán removidos en futuras versiones)
  @HiveField(12)
  final String vitalSigns;
  @HiveField(13)
  final String head;
  @HiveField(14)
  final String neck;
  @HiveField(15)
  final String thorax;
  @HiveField(16)
  final String abdomen;
  @HiveField(17)
  final String extremities;

  const PhysicalExam({
    // Campos principales
    this.eva = '',
    this.llc = '',
    this.glucosa = '',
    this.ta = '',
    // Campos SAMPLE
    this.sampleAlergias = '',
    this.sampleMedicamentos = '',
    this.sampleEnfermedades = '',
    this.sampleHoraAlimento = '',
    this.sampleEventosPrevios = '',
    // Signos vitales dinámicos
    this.timeColumns = const [],
    this.vitalSignsData = const {},
    this.timestamp = '',
    // Campos obsoletos (compatibilidad)
    this.vitalSigns = '',
    this.head = '',
    this.neck = '',
    this.thorax = '',
    this.abdomen = '',
    this.extremities = '',
  });

  // Factory constructor desde los datos del formulario
  factory PhysicalExam.fromFormData(Map<String, dynamic> formData) {
    final timeColumns = List<String>.from(formData['timeColumns'] ?? []);
    final vitalSignsData = <String, Map<String, String>>{};

    // Lista de signos vitales del diálogo
    const vitalSigns = [
      'EVA',
      'T/A',
      'FC',
      'FR',
      'Temp.',
      'Sat. O2',
      'LLC',
      'Glu',
      'Glasgow',
    ];

    // Extraer datos de signos vitales dinámicos
    for (final vitalSign in vitalSigns) {
      if (formData[vitalSign] != null && formData[vitalSign] is Map) {
        final vitalData = Map<String, String>.from(formData[vitalSign]);
        if (vitalData.isNotEmpty) {
          vitalSignsData[vitalSign] = vitalData;
        }
      }
    }

    return PhysicalExam(
      eva: formData['eva']?.toString() ?? '',
      llc: formData['llc']?.toString() ?? '',
      glucosa: formData['glucosa']?.toString() ?? '',
      ta: formData['ta']?.toString() ?? '',
      sampleAlergias: formData['sampleAlergias']?.toString() ?? '',
      sampleMedicamentos: formData['sampleMedicamentos']?.toString() ?? '',
      sampleEnfermedades: formData['sampleEnfermedades']?.toString() ?? '',
      sampleHoraAlimento: formData['sampleHoraAlimento']?.toString() ?? '',
      sampleEventosPrevios: formData['sampleEventosPrevios']?.toString() ?? '',
      timeColumns: timeColumns,
      vitalSignsData: vitalSignsData,
      timestamp:
          formData['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  // Método copyWith actualizado
  PhysicalExam copyWith({
    String? eva,
    String? llc,
    String? glucosa,
    String? ta,
    String? sampleAlergias,
    String? sampleMedicamentos,
    String? sampleEnfermedades,
    String? sampleHoraAlimento,
    String? sampleEventosPrevios,
    List<String>? timeColumns,
    Map<String, Map<String, String>>? vitalSignsData,
    String? timestamp,
    // Campos obsoletos
    String? vitalSigns,
    String? head,
    String? neck,
    String? thorax,
    String? abdomen,
    String? extremities,
  }) {
    return PhysicalExam(
      eva: eva ?? this.eva,
      llc: llc ?? this.llc,
      glucosa: glucosa ?? this.glucosa,
      ta: ta ?? this.ta,
      sampleAlergias: sampleAlergias ?? this.sampleAlergias,
      sampleMedicamentos: sampleMedicamentos ?? this.sampleMedicamentos,
      sampleEnfermedades: sampleEnfermedades ?? this.sampleEnfermedades,
      sampleHoraAlimento: sampleHoraAlimento ?? this.sampleHoraAlimento,
      sampleEventosPrevios: sampleEventosPrevios ?? this.sampleEventosPrevios,
      timeColumns: timeColumns ?? this.timeColumns,
      vitalSignsData: vitalSignsData ?? this.vitalSignsData,
      timestamp: timestamp ?? this.timestamp,
      // Campos obsoletos
      vitalSigns: vitalSigns ?? this.vitalSigns,
      head: head ?? this.head,
      neck: neck ?? this.neck,
      thorax: thorax ?? this.thorax,
      abdomen: abdomen ?? this.abdomen,
      extremities: extremities ?? this.extremities,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // Campos principales
      'eva': eva,
      'llc': llc,
      'glucosa': glucosa,
      'ta': ta,
      // Campos SAMPLE
      'sampleAlergias': sampleAlergias,
      'sampleMedicamentos': sampleMedicamentos,
      'sampleEnfermedades': sampleEnfermedades,
      'sampleHoraAlimento': sampleHoraAlimento,
      'sampleEventosPrevios': sampleEventosPrevios,
      // Signos vitales dinámicos
      'timeColumns': timeColumns,
      'vitalSignsData': vitalSignsData,
      'timestamp': timestamp,
      // También incluir los signos vitales individuales para compatibilidad con Firebase
      ...vitalSignsData,
    };
  }

  // Método para obtener los datos en el formato que espera Firebase
  Map<String, dynamic> toFirebaseFormat() {
    final Map<String, dynamic> firebaseData = {
      'eva': eva,
      'llc': llc,
      'glucosa': glucosa,
      'ta': ta,
      'sampleAlergias': sampleAlergias,
      'sampleMedicamentos': sampleMedicamentos,
      'sampleEnfermedades': sampleEnfermedades,
      'sampleHoraAlimento': sampleHoraAlimento,
      'sampleEventosPrevios': sampleEventosPrevios,
      'timeColumns': timeColumns,
    };

    // Agregar signos vitales como campos individuales
    for (final entry in vitalSignsData.entries) {
      firebaseData[entry.key] = entry.value;
    }

    return firebaseData;
  }

  // Método para verificar si hay datos válidos
  bool get hasData {
    return eva.isNotEmpty ||
        llc.isNotEmpty ||
        glucosa.isNotEmpty ||
        ta.isNotEmpty ||
        sampleAlergias.isNotEmpty ||
        sampleMedicamentos.isNotEmpty ||
        sampleEnfermedades.isNotEmpty ||
        sampleHoraAlimento.isNotEmpty ||
        sampleEventosPrevios.isNotEmpty ||
        vitalSignsData.isNotEmpty;
  }

  @override
  List<Object?> get props => [
    eva,
    llc,
    glucosa,
    ta,
    sampleAlergias,
    sampleMedicamentos,
    sampleEnfermedades,
    sampleHoraAlimento,
    sampleEventosPrevios,
    timeColumns,
    vitalSignsData,
    timestamp,
    // Campos obsoletos incluidos para mantener compatibilidad
    vitalSigns,
    head,
    neck,
    thorax,
    abdomen,
    extremities,
  ];
}
