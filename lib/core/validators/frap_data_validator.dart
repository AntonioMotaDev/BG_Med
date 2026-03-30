import 'package:bg_med/features/frap/presentation/providers/frap_data_provider.dart';

/// Resultado de validación con errores y advertencias
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  ValidationResult.success()
    : isValid = true,
      errors = const [],
      warnings = const [];

  ValidationResult.failure(this.errors, {List<String>? warnings})
    : isValid = false,
      warnings = warnings ?? const [];
}

/// Validador completo para FrapData
/// Valida campos requeridos, condicionales, formatos y tipos de datos
class FrapDataValidator {
  // Singleton pattern
  FrapDataValidator._();
  static final FrapDataValidator instance = FrapDataValidator._();

  /// Validación completa de FrapData
  ValidationResult validateComplete(FrapData data) {
    final errors = <String>[];
    final warnings = <String>[];

    // 1. Validar campos generales obligatorios
    final patientResult = _validatePatientInfo(data.patientInfo);
    errors.addAll(patientResult.errors);
    warnings.addAll(patientResult.warnings);

    final serviceResult = _validateServiceInfo(data.serviceInfo);
    errors.addAll(serviceResult.errors);
    warnings.addAll(serviceResult.warnings);

    final registryResult = _validateRegistryInfo(data.registryInfo);
    errors.addAll(registryResult.errors);
    warnings.addAll(registryResult.warnings);

    final physicalExamResult = _validatePhysicalExam(data.physicalExam);
    errors.addAll(physicalExamResult.errors);
    warnings.addAll(physicalExamResult.warnings);

    final managementResult = _validateManagement(data.management);
    errors.addAll(managementResult.errors);
    warnings.addAll(managementResult.warnings);

    // 2. Validar campos condicionales según tipo de urgencia
    final conditionalResult = validateConditionalFields(data);
    errors.addAll(conditionalResult.errors);
    warnings.addAll(conditionalResult.warnings);

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validación por sección individual
  ValidationResult validateSection(
    String sectionName,
    Map<String, dynamic> data,
  ) {
    switch (sectionName) {
      case 'patient_info':
        return _validatePatientInfo(data);
      case 'service_info':
        return _validateServiceInfo(data);
      case 'registry_info':
        return _validateRegistryInfo(data);
      case 'physical_exam':
        return _validatePhysicalExam(data);
      case 'management':
        return _validateManagement(data);
      case 'medications':
        return _validateMedications(data);
      case 'gyneco_obstetric':
        return _validateGynecoObstetric(data);
      case 'pathological_history':
        return _validatePathologicalHistory(data);
      case 'clinical_history':
        return _validateClinicalHistory(data);
      case 'priority_justification':
        return _validatePriorityJustification(data);
      case 'injury_location':
        return _validateInjuryLocation(data);
      case 'receiving_unit':
        return _validateReceivingUnit(data);
      case 'patient_reception':
        return _validatePatientReception(data);
      case 'attention_negative':
        return _validateAttentionNegative(data);
      case 'insumos':
        return _validateInsumos(data);
      default:
        return ValidationResult.success();
    }
  }

  /// Validación de campos condicionales según tipo de urgencia y sexo
  ValidationResult validateConditionalFields(FrapData data) {
    final errors = <String>[];
    final warnings = <String>[];

    final tipoUrgencia = data.serviceInfo['tipoUrgencia'] as String?;
    final patientSex = data.patientInfo['sex'] as String?;

    // Validaciones según tipo de urgencia
    if (tipoUrgencia == 'Clínico') {
      // Para urgencias clínicas, se requieren antecedentes patológicos
      final pathologicalResult = _validatePathologicalHistory(
        data.pathologicalHistory,
      );
      if (!pathologicalResult.isValid) {
        errors.addAll(
          pathologicalResult.errors.map(
            (e) => 'Antecedentes Patológicos (requerido para Clínico): $e',
          ),
        );
      }

      // Justificación de prioridad
      final priorityResult = _validatePriorityJustification(
        data.priorityJustification,
      );
      if (!priorityResult.isValid) {
        errors.addAll(
          priorityResult.errors.map(
            (e) => 'Justificación de Prioridad (requerido para Clínico): $e',
          ),
        );
      }
    } else if (tipoUrgencia == 'Trauma') {
      // Para urgencias de trauma, se requieren antecedentes clínicos
      final clinicalResult = _validateClinicalHistory(data.clinicalHistory);
      if (!clinicalResult.isValid) {
        errors.addAll(
          clinicalResult.errors.map(
            (e) => 'Antecedentes Clínicos (requerido para Trauma): $e',
          ),
        );
      }

      // Localización de lesiones
      final injuryResult = _validateInjuryLocation(data.injuryLocation);
      if (!injuryResult.isValid) {
        errors.addAll(
          injuryResult.errors.map(
            (e) => 'Localización de Lesiones (requerido para Trauma): $e',
          ),
        );
      }
    }

    // Validación de gineco-obstétrico solo para pacientes femeninos
    if (patientSex == 'Femenino') {
      final gynecoResult = _validateGynecoObstetric(data.gynecoObstetric);
      if (!gynecoResult.isValid) {
        warnings.addAll(
          gynecoResult.errors.map(
            (e) =>
                'Gineco-Obstétrico (recomendado para pacientes femeninos): $e',
          ),
        );
      }
    }

    // Validar medicamentos si hay administración en management
    final hasViaAdministracion =
        data.management['viaAdministracion'] != null &&
        (data.management['viaAdministracion'] as String).isNotEmpty;
    if (hasViaAdministracion) {
      final medicationsResult = _validateMedications(data.medications);
      if (!medicationsResult.isValid) {
        warnings.addAll(
          medicationsResult.errors.map(
            (e) =>
                'Medicamentos (recomendado si hay vía de administración): $e',
          ),
        );
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  // ============ Validaciones por Sección ============

  ValidationResult _validatePatientInfo(Map<String, dynamic> data) {
    final errors = <String>[];
    final warnings = <String>[];

    // Validar si fue un paciente seleccionado
    if (data['patientId'] == null) {
      // Campos obligatorios (usar nombres correctos de FrapData.patientInfo)
      if (_isEmptyOrNull(data['firstName'])) {
        errors.add('El nombre del paciente es obligatorio');
      }

      if (_isEmptyOrNull(data['paternalLastName'])) {
        errors.add('El apellido paterno del paciente es obligatorio');
      }

      if (_isEmptyOrNull(data['maternalLastName'])) {
        errors.add('El apellido materno del paciente es obligatorio');
      }

      if (_isEmptyOrNull(data['age'])) {
        errors.add('La edad del paciente es obligatoria');
      } else {
        final age = data['age'];
        if (age is int && (age < 0 || age > 150)) {
          errors.add('La edad debe estar entre 0 y 150 años');
        }
      }

      if (_isEmptyOrNull(data['sex'])) {
        errors.add('El sexo del paciente es obligatorio');
      }

      // Validación de cédula (si está presente)
      final cedula = data['cedula'] as String?;
      if (cedula != null && cedula.isNotEmpty && !isValidCedula(cedula)) {
        warnings.add('El formato de la cédula parece incorrecto');
      }

      // Validación de teléfono (si está presente)
      final phone = data['phone'] as String?;
      if (phone != null && phone.isNotEmpty && !isValidPhone(phone)) {
        warnings.add('El formato del teléfono parece incorrecto');
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  ValidationResult _validateServiceInfo(Map<String, dynamic> data) {
    final errors = <String>[];

    // Campos críticos de serviceInfo según el flujo del formulario
    if (_isEmptyOrNull(data['tipoServicio'])) {
      errors.add('El tipo de servicio es obligatorio');
    }

    if (_isEmptyOrNull(data['tipoUrgencia'])) {
      errors.add('El tipo de urgencia es obligatorio');
    }

    if (_isEmptyOrNull(data['ubicacion'])) {
      errors.add('La ubicación es obligatoria');
    }

    if (_isEmptyOrNull(data['lugarOcurrencia'])) {
      errors.add('El lugar de ocurrencia es obligatorio');
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  ValidationResult _validateRegistryInfo(Map<String, dynamic> data) {
    final errors = <String>[];

    // Campos de registryInfo (correctos según registry_info_form_dialog.dart)
    if (_isEmptyOrNull(data['folio'])) {
      errors.add('El folio del registro es obligatorio');
    }

    // Campos opcionales pero presentes en el diálogo:
    // - convenio, episodio, solicitadoPor, fecha
    // if (_isEmptyOrNull(data['convenio'])) {
    //   errors.add('El convenio es obligatorio');
    // }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  ValidationResult _validatePhysicalExam(Map<String, dynamic> data) {
    // PhysicalExam no requiere validaciones
    return ValidationResult.success();
  }

  ValidationResult _validateManagement(Map<String, dynamic> data) {
    // Management es opcional pero debe estar presente el Map
    // Las validaciones específicas dependen de los campos que se llenen
    return ValidationResult.success();
  }

  ValidationResult _validateMedications(Map<String, dynamic> data) {
    // Medications es opcional
    return ValidationResult.success();
  }

  ValidationResult _validateGynecoObstetric(Map<String, dynamic> data) {
    // Solo se valida si el paciente es femenino (validación condicional)
    return ValidationResult.success();
  }

  ValidationResult _validatePathologicalHistory(Map<String, dynamic> data) {
    final errors = <String>[];

    // Requerido solo para urgencias clínicas
    if (data.isEmpty) {
      errors.add('Debe completar los antecedentes patológicos');
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  ValidationResult _validateClinicalHistory(Map<String, dynamic> data) {
    final errors = <String>[];

    // Requerido solo para urgencias de trauma
    if (data.isEmpty) {
      errors.add('Debe completar los antecedentes clínicos');
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  ValidationResult _validatePriorityJustification(Map<String, dynamic> data) {
    final errors = <String>[];

    // Requerido para urgencias clínicas
    if (data.isEmpty) {
      errors.add('Debe completar la justificación de prioridad');
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  ValidationResult _validateInjuryLocation(Map<String, dynamic> data) {
    final errors = <String>[];

    // Requerido para urgencias de trauma
    if (data.isEmpty) {
      errors.add('Debe completar la localización de lesiones');
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  ValidationResult _validateReceivingUnit(Map<String, dynamic> data) {
    // Opcional
    return ValidationResult.success();
  }

  ValidationResult _validatePatientReception(Map<String, dynamic> data) {
    // Opcional
    return ValidationResult.success();
  }

  ValidationResult _validateAttentionNegative(Map<String, dynamic> data) {
    // Opcional
    return ValidationResult.success();
  }

  ValidationResult _validateInsumos(dynamic data) {
    // Los insumos son opcionales
    return ValidationResult.success();
  }

  // ============ Validaciones de Formato ============

  /// Valida formato de teléfono (10 dígitos)
  bool isValidPhone(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    return cleanPhone.length == 10;
  }

  /// Valida formato de email
  bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Valida formato de cédula (13 o 18 dígitos)
  bool isValidCedula(String cedula) {
    final cleanCedula = cedula.replaceAll(RegExp(r'[^\d]'), '');
    return cleanCedula.length == 13 || cleanCedula.length == 18;
  }

  /// Valida formato de presión arterial (ej: 120/80)
  // bool _isValidBloodPressure(String bp) {
  //   final bpRegex = RegExp(r'^\d{2,3}/\d{2,3}$');
  //   return bpRegex.hasMatch(bp);
  // }

  // ============ Utilidades ============

  bool _isEmptyOrNull(dynamic value) {
    if (value == null) return true;
    if (value is String) return value.trim().isEmpty;
    if (value is List) return value.isEmpty;
    if (value is Map) return value.isEmpty;
    return false;
  }
}
