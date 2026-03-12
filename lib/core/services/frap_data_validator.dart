/// Resultado de validación de datos
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final Map<String, dynamic>? cleanedData;

  const ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
    this.cleanedData,
  });

  @override
  String toString() {
    return 'ValidationResult(isValid: $isValid, errors: $errors, warnings: $warnings)';
  }
}

class FrapDataValidator {
  /// Validar datos del paciente
  static ValidationResult validatePatientData(
    Map<String, dynamic> patientData,
  ) {
    final errors = <String>[];
    final warnings = <String>[];
    final cleanedData = <String, dynamic>{};

    // Validar campos requeridos
    if (patientData['firstName'] == null ||
        patientData['firstName'].toString().trim().isEmpty) {
      errors.add('Nombre del paciente es requerido');
    } else {
      cleanedData['firstName'] = patientData['firstName'].toString().trim();
    }

    if (patientData['age'] == null) {
      errors.add('Edad del paciente es requerida');
    } else {
      final age = int.tryParse(patientData['age'].toString());
      if (age == null || age < 0 || age > 150) {
        errors.add('Edad debe ser un número válido entre 0 y 150');
      } else {
        cleanedData['age'] = age;
      }
    }

    if (patientData['sex'] == null ||
        patientData['sex'].toString().trim().isEmpty) {
      errors.add('Sexo del paciente es requerido');
    } else {
      cleanedData['sex'] = patientData['sex'].toString().trim();
    }

    // Validar campos opcionales
    if (patientData['paternalLastName'] != null) {
      cleanedData['paternalLastName'] =
          patientData['paternalLastName'].toString().trim();
    }

    if (patientData['maternalLastName'] != null) {
      cleanedData['maternalLastName'] =
          patientData['maternalLastName'].toString().trim();
    }

    if (patientData['phone'] != null) {
      final phone = patientData['phone'].toString().trim();
      if (phone.isNotEmpty && !_isValidPhone(phone)) {
        warnings.add('Formato de teléfono puede ser inválido');
      }
      cleanedData['phone'] = phone;
    }

    if (patientData['address'] != null) {
      cleanedData['address'] = patientData['address'].toString().trim();
    }

    // Validar campos de dirección
    if (patientData['street'] != null) {
      cleanedData['street'] = patientData['street'].toString().trim();
    }

    if (patientData['exteriorNumber'] != null) {
      cleanedData['exteriorNumber'] =
          patientData['exteriorNumber'].toString().trim();
    }

    if (patientData['interiorNumber'] != null) {
      cleanedData['interiorNumber'] =
          patientData['interiorNumber'].toString().trim();
    }

    if (patientData['neighborhood'] != null) {
      cleanedData['neighborhood'] =
          patientData['neighborhood'].toString().trim();
    }

    if (patientData['city'] != null) {
      cleanedData['city'] = patientData['city'].toString().trim();
    }

    if (patientData['insurance'] != null) {
      cleanedData['insurance'] = patientData['insurance'].toString().trim();
    }

    if (patientData['responsiblePerson'] != null) {
      cleanedData['responsiblePerson'] =
          patientData['responsiblePerson'].toString().trim();
    }

    if (patientData['gender'] != null) {
      cleanedData['gender'] = patientData['gender'].toString().trim();
    }

    if (patientData['addressDetails'] != null) {
      cleanedData['addressDetails'] =
          patientData['addressDetails'].toString().trim();
    }

    if (patientData['tipoEntrega'] != null) {
      cleanedData['tipoEntrega'] = patientData['tipoEntrega'].toString().trim();
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      cleanedData: cleanedData,
    );
  }

  /// Validar datos de historia clínica
  static ValidationResult validateClinicalHistoryData(
    Map<String, dynamic> clinicalData,
  ) {
    final errors = <String>[];
    final warnings = <String>[];
    final cleanedData = <String, dynamic>{};

    // Todos los campos son opcionales en historia clínica
    if (clinicalData['allergies'] != null) {
      cleanedData['allergies'] = clinicalData['allergies'].toString().trim();
    }

    if (clinicalData['medications'] != null) {
      cleanedData['medications'] =
          clinicalData['medications'].toString().trim();
    }

    if (clinicalData['previousIllnesses'] != null) {
      cleanedData['previousIllnesses'] =
          clinicalData['previousIllnesses'].toString().trim();
    }

    return ValidationResult(
      isValid: true,
      errors: errors,
      warnings: warnings,
      cleanedData: cleanedData,
    );
  }

  /// Validar datos de examen físico
  static ValidationResult validatePhysicalExamData(
    Map<String, dynamic> examData,
  ) {
    final errors = <String>[];
    final warnings = <String>[];
    final cleanedData = <String, dynamic>{};

    // Validar signos vitales
    if (examData['vitalSigns'] != null) {
      cleanedData['vitalSigns'] = examData['vitalSigns'].toString().trim();
    }

    // Validar valores numéricos si están presentes
    if (examData['heartRate'] != null) {
      final hr = int.tryParse(examData['heartRate'].toString());
      if (hr != null && (hr < 0 || hr > 300)) {
        warnings.add('Frecuencia cardíaca fuera de rango normal');
      }
    }

    if (examData['respiratoryRate'] != null) {
      final rr = int.tryParse(examData['respiratoryRate'].toString());
      if (rr != null && (rr < 0 || rr > 100)) {
        warnings.add('Frecuencia respiratoria fuera de rango normal');
      }
    }

    if (examData['temperature'] != null) {
      final temp = double.tryParse(examData['temperature'].toString());
      if (temp != null && (temp < 20 || temp > 45)) {
        warnings.add('Temperatura fuera de rango normal');
      }
    }

    return ValidationResult(
      isValid: true,
      errors: errors,
      warnings: warnings,
      cleanedData: cleanedData,
    );
  }

  /// Validar datos de insumos
  static ValidationResult validateInsumosData(List<dynamic> insumosData) {
    final errors = <String>[];
    final warnings = <String>[];
    final cleanedInsumos = <Map<String, dynamic>>[];

    for (int i = 0; i < insumosData.length; i++) {
      final insumo = insumosData[i];
      if (insumo is Map<String, dynamic>) {
        final insumoErrors = <String>[];
        final insumoData = <String, dynamic>{};

        // Validar cantidad
        if (insumo['cantidad'] == null) {
          insumoErrors.add('Cantidad es requerida');
        } else {
          final cantidad = double.tryParse(insumo['cantidad'].toString());
          if (cantidad == null || cantidad < 0) {
            insumoErrors.add('Cantidad debe ser un número positivo');
          } else {
            insumoData['cantidad'] = cantidad;
          }
        }

        // Validar artículo
        if (insumo['articulo'] == null ||
            insumo['articulo'].toString().trim().isEmpty) {
          insumoErrors.add('Artículo es requerido');
        } else {
          insumoData['articulo'] = insumo['articulo'].toString().trim();
        }

        if (insumoErrors.isEmpty) {
          cleanedInsumos.add(insumoData);
        } else {
          errors.add('Insumo ${i + 1}: ${insumoErrors.join(', ')}');
        }
      } else {
        errors.add('Insumo ${i + 1}: Formato inválido');
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      cleanedData: {'insumos': cleanedInsumos},
    );
  }

  /// Validar datos de personal médico
  static ValidationResult validatePersonalMedicoData(
    List<dynamic> personalData,
  ) {
    final errors = <String>[];
    final warnings = <String>[];
    final cleanedPersonal = <Map<String, dynamic>>[];

    for (int i = 0; i < personalData.length; i++) {
      final personal = personalData[i];
      if (personal is Map<String, dynamic>) {
        final personalErrors = <String>[];
        final personalInfo = <String, dynamic>{};

        // Validar nombre
        if (personal['nombre'] == null ||
            personal['nombre'].toString().trim().isEmpty) {
          personalErrors.add('Nombre es requerido');
        } else {
          personalInfo['nombre'] = personal['nombre'].toString().trim();
        }

        // Validar especialidad
        if (personal['especialidad'] == null ||
            personal['especialidad'].toString().trim().isEmpty) {
          personalErrors.add('Especialidad es requerida');
        } else {
          personalInfo['especialidad'] =
              personal['especialidad'].toString().trim();
        }

        if (personalErrors.isEmpty) {
          cleanedPersonal.add(personalInfo);
        } else {
          errors.add('Personal médico ${i + 1}: ${personalErrors.join(', ')}');
        }
      } else {
        errors.add('Personal médico ${i + 1}: Formato inválido');
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      cleanedData: {'personalMedico': cleanedPersonal},
    );
  }

  /// Validar datos de escalas obstétricas
  static ValidationResult validateEscalasObstetricasData(
    Map<String, dynamic> escalasData,
  ) {
    final errors = <String>[];
    final warnings = <String>[];
    final cleanedData = <String, dynamic>{};

    // Validar Silverman-Anderson
    if (escalasData['silvermanAnderson'] != null) {
      if (escalasData['silvermanAnderson'] is Map<String, dynamic>) {
        cleanedData['silvermanAnderson'] = escalasData['silvermanAnderson'];
      } else {
        errors.add('Silverman-Anderson debe ser un objeto');
      }
    }

    // Validar Apgar
    if (escalasData['apgar'] != null) {
      if (escalasData['apgar'] is Map<String, dynamic>) {
        cleanedData['apgar'] = escalasData['apgar'];
      } else {
        errors.add('Apgar debe ser un objeto');
      }
    }

    // Validar frecuencia cardíaca fetal
    if (escalasData['frecuenciaCardiacaFetal'] != null) {
      final fcf = int.tryParse(
        escalasData['frecuenciaCardiacaFetal'].toString(),
      );
      if (fcf == null || fcf < 0 || fcf > 300) {
        errors.add('Frecuencia cardíaca fetal debe ser un número válido');
      } else {
        cleanedData['frecuenciaCardiacaFetal'] = fcf;
      }
    }

    // Validar contracciones
    if (escalasData['contracciones'] != null) {
      cleanedData['contracciones'] =
          escalasData['contracciones'].toString().trim();
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      cleanedData: cleanedData,
    );
  }

  /// Validar sección genérica
  static ValidationResult validateSectionData(
    Map<String, dynamic> sectionData,
  ) {
    final errors = <String>[];
    final warnings = <String>[];
    final cleanedData = <String, dynamic>{};

    sectionData.forEach((key, value) {
      if (value != null) {
        if (value is String) {
          final trimmed = value.trim();
          if (trimmed.isNotEmpty) {
            cleanedData[key] = trimmed;
          }
        } else if (value is num || value is bool) {
          cleanedData[key] = value;
        } else if (value is List) {
          if (value.isNotEmpty) {
            cleanedData[key] = value;
          }
        } else if (value is Map) {
          if (value.isNotEmpty) {
            cleanedData[key] = value;
          }
        }
      }
    });

    return ValidationResult(
      isValid: true,
      errors: errors,
      warnings: warnings,
      cleanedData: cleanedData,
    );
  }

  /// Validar formato de teléfono
  static bool _isValidPhone(String phone) {
    // Validación básica de teléfono
    final phoneRegex = RegExp(r'^[\d\s\-\+\(\)]+$');
    return phoneRegex.hasMatch(phone) && phone.length >= 7;
  }
}
