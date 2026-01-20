/// Mapeo y conversión de datos entre diferentes formatos de FRAP
class FrapConversionMapping {
  /// Mapeo de campos del paciente
  static Map<String, String> patientFieldMapping = {
    // Campos básicos
    'name': 'name',
    'age': 'age',
    'sex': 'sex',
    'address': 'address',

    // Campos expandidos
    'firstName': 'firstName',
    'paternalLastName': 'paternalLastName',
    'maternalLastName': 'maternalLastName',
    'phone': 'phone',
    'street': 'street',
    'exteriorNumber': 'exteriorNumber',
    'interiorNumber': 'interiorNumber',
    'neighborhood': 'neighborhood',
    'city': 'city',
    'insurance': 'insurance',
    'responsiblePerson': 'responsiblePerson',
    'gender': 'gender',
    'addressDetails': 'addressDetails',
    'tipoEntrega': 'tipoEntrega',
  };

  /// Mapeo de campos de historia clínica
  static Map<String, String> clinicalHistoryFieldMapping = {
    // Campos básicos
    'allergies': 'allergies',
    'medications': 'medications',
    'previousIllnesses': 'previousIllnesses',

    // Campos expandidos
    'currentSymptoms': 'currentSymptoms',
    'pain': 'pain',
    'painScale': 'painScale',
    'dosage': 'dosage',
    'frequency': 'frequency',
    'route': 'route',
    'time': 'time',
    'previousSurgeries': 'previousSurgeries',
    'hospitalizations': 'hospitalizations',
    'transfusions': 'transfusions',
    'horaUltimoAlimento': 'horaUltimoAlimento',
    'eventosPrevios': 'eventosPrevios',
  };

  /// Mapeo de campos de examen físico
  static Map<String, String> physicalExamFieldMapping = {
    // Campos básicos de evaluación
    'eva': 'eva',
    'llc': 'llc',
    'glucosa': 'glucosa',
    'ta': 'ta',

    // Campos SAMPLE
    'sampleAlergias': 'sampleAlergias',
    'sampleMedicamentos': 'sampleMedicamentos',
    'sampleEnfermedades': 'sampleEnfermedades',
    'sampleHoraAlimento': 'sampleHoraAlimento',
    'sampleEventosPrevios': 'sampleEventosPrevios',

    // Estructura de signos vitales dinámicos
    'timeColumns': 'timeColumns',
    'vitalSignsData': 'vitalSignsData',
    'timestamp': 'timestamp',
  };

  /// Mapeo de campos de insumos
  static Map<String, String> insumoFieldMapping = {
    'cantidad': 'cantidad',
    'articulo': 'articulo',
  };

  /// Mapeo de campos de personal médico
  static Map<String, String> personalMedicoFieldMapping = {
    'nombre': 'nombre',
    'especialidad': 'especialidad',
    'cedula': 'cedula',
  };

  /// Mapeo de campos de escalas obstétricas
  static Map<String, String> escalasObstetricasFieldMapping = {
    'silvermanAnderson': 'silvermanAnderson',
    'apgar': 'apgar',
    'frecuenciaCardiacaFetal': 'frecuenciaCardiacaFetal',
    'contracciones': 'contracciones',
  };

  /// Secciones que existen en ambos modelos
  static List<String> commonSections = [
    'serviceInfo',
    'registryInfo',
    'management',
    'medications',
    'gynecoObstetric',
    'attentionNegative',
    'pathologicalHistory',
    'priorityJustification',
    'injuryLocation',
    'receivingUnit',
    'patientReception',
  ];

  /// Campos que solo existen en el modelo local
  static List<String> localOnlyFields = [
    'isSynced', // Campo de control interno, no se sincroniza
  ];

  /// Campos que solo existen en el modelo nube
  static List<String> cloudOnlyFields = ['userId'];

  /// Campos que existen en ambos pero con estructura diferente
  static Map<String, String> crossModelFieldMapping = {
    'consentimientoSignature': 'serviceInfo.consentimientoSignature',
    'insumos': 'management.insumos',
    'personalMedico': 'management.personalMedico',
    'escalasObstetricas': 'gynecoObstetric.escalasObstetricas',
  };

  /// Validar si un campo existe en el modelo local
  static bool isLocalField(String fieldName) {
    return patientFieldMapping.containsKey(fieldName) ||
        clinicalHistoryFieldMapping.containsKey(fieldName) ||
        physicalExamFieldMapping.containsKey(fieldName) ||
        insumoFieldMapping.containsKey(fieldName) ||
        personalMedicoFieldMapping.containsKey(fieldName) ||
        escalasObstetricasFieldMapping.containsKey(fieldName) ||
        crossModelFieldMapping.containsKey(fieldName) ||
        localOnlyFields.contains(fieldName);
  }

  /// Validar si un campo existe en el modelo nube
  static bool isCloudField(String fieldName) {
    return patientFieldMapping.containsKey(fieldName) ||
        clinicalHistoryFieldMapping.containsKey(fieldName) ||
        physicalExamFieldMapping.containsKey(fieldName) ||
        crossModelFieldMapping.containsKey(fieldName) ||
        cloudOnlyFields.contains(fieldName);
  }

  /// Obtener el campo correspondiente en el modelo opuesto
  static String? getCorrespondingField(String fieldName, bool toLocal) {
    if (toLocal) {
      // Buscar en mapeos de nube a local
      return patientFieldMapping[fieldName] ??
          clinicalHistoryFieldMapping[fieldName] ??
          physicalExamFieldMapping[fieldName] ??
          insumoFieldMapping[fieldName] ??
          personalMedicoFieldMapping[fieldName] ??
          escalasObstetricasFieldMapping[fieldName] ??
          crossModelFieldMapping[fieldName];
    } else {
      // Buscar en mapeos de local a nube
      final reverseMapping = <String, String>{};
      patientFieldMapping.forEach((key, value) => reverseMapping[value] = key);
      clinicalHistoryFieldMapping.forEach(
        (key, value) => reverseMapping[value] = key,
      );
      physicalExamFieldMapping.forEach(
        (key, value) => reverseMapping[value] = key,
      );
      insumoFieldMapping.forEach((key, value) => reverseMapping[value] = key);
      personalMedicoFieldMapping.forEach(
        (key, value) => reverseMapping[value] = key,
      );
      escalasObstetricasFieldMapping.forEach(
        (key, value) => reverseMapping[value] = key,
      );
      crossModelFieldMapping.forEach(
        (key, value) => reverseMapping[value] = key,
      );

      return reverseMapping[fieldName];
    }
  }

  /// Generar reporte de diferencias entre modelos
  static Map<String, dynamic> generateDifferenceReport() {
    final report = <String, dynamic>{
      'localOnlyFields': localOnlyFields,
      'cloudOnlyFields': cloudOnlyFields,
      'commonSections': commonSections,
      'crossModelFields': crossModelFieldMapping.keys.toList(),
      'totalLocalFields':
          patientFieldMapping.length +
          clinicalHistoryFieldMapping.length +
          physicalExamFieldMapping.length +
          insumoFieldMapping.length +
          personalMedicoFieldMapping.length +
          escalasObstetricasFieldMapping.length +
          crossModelFieldMapping.length +
          localOnlyFields.length,
      'totalCloudFields':
          patientFieldMapping.length +
          clinicalHistoryFieldMapping.length +
          physicalExamFieldMapping.length +
          crossModelFieldMapping.length +
          cloudOnlyFields.length,
    };

    return report;
  }
}
