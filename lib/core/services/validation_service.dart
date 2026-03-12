import 'package:bg_med/core/models/frap.dart';
import 'package:bg_med/core/models/patient.dart';

class ValidationResult {
  final bool isValid;
  final List<ValidationError> errors;
  final List<ValidationWarning> warnings;

  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
}

class ValidationError {
  final String field;
  final String message;
  final ValidationSeverity severity;

  ValidationError({
    required this.field,
    required this.message,
    this.severity = ValidationSeverity.error,
  });
}

class ValidationWarning {
  final String field;
  final String message;

  ValidationWarning({required this.field, required this.message});
}

enum ValidationSeverity { error, critical, warning }

class ValidationService {
  // Validar campos de paciente
  ValidationResult validatePatient(Patient patient) {
    final List<ValidationError> errors = [];
    final List<ValidationWarning> warnings = [];

    // Validar nombre
    if (patient.name.trim().isEmpty) {
      errors.add(
        ValidationError(
          field: 'name',
          message: 'El nombre del paciente es obligatorio',
          severity: ValidationSeverity.critical,
        ),
      );
    } else if (patient.name.trim().length < 2) {
      errors.add(
        ValidationError(
          field: 'name',
          message: 'El nombre debe tener al menos 2 caracteres',
        ),
      );
    }

    // Validar edad
    if (patient.age <= 0) {
      errors.add(
        ValidationError(
          field: 'age',
          message: 'La edad debe ser mayor a 0',
          severity: ValidationSeverity.critical,
        ),
      );
    } else if (patient.age > 150) {
      warnings.add(
        ValidationWarning(
          field: 'age',
          message: 'La edad parece ser muy alta. Verifique que sea correcta.',
        ),
      );
    }

    // Validar género
    if (patient.sex.trim().isEmpty) {
      errors.add(
        ValidationError(field: 'sex', message: 'El género es obligatorio'),
      );
    }

    // Validar dirección
    if (patient.address.trim().isEmpty) {
      warnings.add(
        ValidationWarning(
          field: 'address',
          message: 'Se recomienda incluir la dirección del paciente',
        ),
      );
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  // Validar campos de emergencia
  ValidationResult validateEmergency(Frap frap) {
    final List<ValidationError> errors = [];
    final List<ValidationWarning> warnings = [];

    // Validar paciente
    final patientValidation = validatePatient(frap.patient);
    errors.addAll(patientValidation.errors);
    warnings.addAll(patientValidation.warnings);

    // Validar fecha de creación
    if (frap.createdAt.isAfter(DateTime.now())) {
      errors.add(
        ValidationError(
          field: 'createdAt',
          message: 'La fecha de creación no puede ser futura',
          severity: ValidationSeverity.critical,
        ),
      );
    }

    // Validar que no sea muy antigua (más de 1 año)
    final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
    if (frap.createdAt.isBefore(oneYearAgo)) {
      warnings.add(
        ValidationWarning(
          field: 'createdAt',
          message: 'El registro es muy antiguo. Verifique la fecha.',
        ),
      );
    }

    // Validar secciones principales
    // Verificar si se registró información de trauma
    final hasTraumaInfo =
        frap.clinicalHistory.traumaCraneo ||
        frap.clinicalHistory.traumaTorax ||
        frap.clinicalHistory.traumaAbdomen ||
        frap.clinicalHistory.traumaColumna ||
        frap.clinicalHistory.traumaExtremidades ||
        frap.clinicalHistory.traumaPelvis ||
        frap.clinicalHistory.traumaOtros;

    if (!hasTraumaInfo && frap.clinicalHistory.observaciones.isEmpty) {
      warnings.add(
        ValidationWarning(
          field: 'clinicalHistory',
          message:
              'Se recomienda registrar información de trauma o agregar observaciones',
        ),
      );
    }

    if (frap.physicalExam.isEmpty ||
        (frap.physicalExam['vitalSigns']?.toString() ?? '').trim().isEmpty) {
      warnings.add(
        ValidationWarning(
          field: 'vitalSigns',
          message: 'Se recomienda incluir los signos vitales',
        ),
      );
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  // Validar campos médicos específicos
  ValidationResult validateMedicalData(Map<String, dynamic> data) {
    final List<ValidationError> errors = [];
    final List<ValidationWarning> warnings = [];

    // Validar presión arterial
    if (data.containsKey('bloodPressure')) {
      final bp = data['bloodPressure'] as String?;
      if (bp != null && bp.isNotEmpty) {
        if (!_isValidBloodPressure(bp)) {
          errors.add(
            ValidationError(
              field: 'bloodPressure',
              message:
                  'Formato de presión arterial inválido. Use formato: 120/80',
            ),
          );
        }
      }
    }

    // Validar frecuencia cardíaca
    if (data.containsKey('heartRate')) {
      final hr = data['heartRate'];
      if (hr != null) {
        final hrInt = int.tryParse(hr.toString());
        if (hrInt == null || hrInt < 30 || hrInt > 300) {
          errors.add(
            ValidationError(
              field: 'heartRate',
              message: 'La frecuencia cardíaca debe estar entre 30 y 300 lpm',
            ),
          );
        }
      }
    }

    // Validar temperatura
    if (data.containsKey('temperature')) {
      final temp = data['temperature'];
      if (temp != null) {
        final tempDouble = double.tryParse(temp.toString());
        if (tempDouble == null || tempDouble < 30 || tempDouble > 45) {
          errors.add(
            ValidationError(
              field: 'temperature',
              message: 'La temperatura debe estar entre 30°C y 45°C',
            ),
          );
        }
      }
    }

    // Validar glucosa
    if (data.containsKey('glucose')) {
      final glucose = data['glucose'];
      if (glucose != null) {
        final glucoseInt = int.tryParse(glucose.toString());
        if (glucoseInt == null || glucoseInt < 20 || glucoseInt > 1000) {
          errors.add(
            ValidationError(
              field: 'glucose',
              message: 'La glucosa debe estar entre 20 y 1000 mg/dl',
            ),
          );
        }
      }
    }

    // Validar escala de dolor (EVA)
    if (data.containsKey('painScale')) {
      final painScale = data['painScale'];
      if (painScale != null) {
        final painInt = int.tryParse(painScale.toString());
        if (painInt == null || painInt < 0 || painInt > 10) {
          errors.add(
            ValidationError(
              field: 'painScale',
              message: 'La escala de dolor debe estar entre 0 y 10',
            ),
          );
        }
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  // Validar teléfono
  ValidationResult validatePhone(String phone) {
    final List<ValidationError> errors = [];
    final List<ValidationWarning> warnings = [];

    if (phone.trim().isEmpty) {
      return ValidationResult(
        isValid: true,
        errors: errors,
        warnings: warnings,
      );
    }

    // Remover espacios y caracteres especiales
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanPhone.length < 10) {
      errors.add(
        ValidationError(
          field: 'phone',
          message: 'El teléfono debe tener al menos 10 dígitos',
        ),
      );
    } else if (cleanPhone.length > 15) {
      warnings.add(
        ValidationWarning(
          field: 'phone',
          message: 'El número de teléfono parece ser muy largo',
        ),
      );
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  // Validar email
  ValidationResult validateEmail(String email) {
    final List<ValidationError> errors = [];
    final List<ValidationWarning> warnings = [];

    if (email.trim().isEmpty) {
      return ValidationResult(
        isValid: true,
        errors: errors,
        warnings: warnings,
      );
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      errors.add(
        ValidationError(field: 'email', message: 'Formato de email inválido'),
      );
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  // Validar edad específica
  ValidationResult validateAge(int age) {
    final List<ValidationError> errors = [];
    final List<ValidationWarning> warnings = [];

    if (age <= 0) {
      errors.add(
        ValidationError(
          field: 'age',
          message: 'La edad debe ser mayor a 0',
          severity: ValidationSeverity.critical,
        ),
      );
    } else if (age < 1) {
      warnings.add(
        ValidationWarning(
          field: 'age',
          message: 'Verifique si la edad en meses está correcta',
        ),
      );
    } else if (age > 150) {
      warnings.add(
        ValidationWarning(
          field: 'age',
          message: 'La edad parece ser muy alta. Verifique que sea correcta.',
        ),
      );
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  // Validar que un campo no esté vacío
  ValidationResult validateRequired(String value, String fieldName) {
    final List<ValidationError> errors = [];
    final List<ValidationWarning> warnings = [];

    if (value.trim().isEmpty) {
      errors.add(
        ValidationError(
          field: fieldName,
          message: 'Este campo es obligatorio',
          severity: ValidationSeverity.critical,
        ),
      );
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  // Validar longitud mínima
  ValidationResult validateMinLength(
    String value,
    String fieldName,
    int minLength,
  ) {
    final List<ValidationError> errors = [];
    final List<ValidationWarning> warnings = [];

    if (value.trim().length < minLength) {
      errors.add(
        ValidationError(
          field: fieldName,
          message: 'Debe tener al menos $minLength caracteres',
        ),
      );
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  // Validar presión arterial
  bool _isValidBloodPressure(String bp) {
    final regex = RegExp(r'^\d{2,3}/\d{2,3}$');
    if (!regex.hasMatch(bp)) return false;

    final parts = bp.split('/');
    final systolic = int.tryParse(parts[0]);
    final diastolic = int.tryParse(parts[1]);

    if (systolic == null || diastolic == null) return false;

    return systolic >= 60 &&
        systolic <= 300 &&
        diastolic >= 40 &&
        diastolic <= 200 &&
        systolic > diastolic;
  }

  // Combinar múltiples validaciones
  ValidationResult combineValidations(List<ValidationResult> validations) {
    final List<ValidationError> allErrors = [];
    final List<ValidationWarning> allWarnings = [];

    for (final validation in validations) {
      allErrors.addAll(validation.errors);
      allWarnings.addAll(validation.warnings);
    }

    return ValidationResult(
      isValid: allErrors.isEmpty,
      errors: allErrors,
      warnings: allWarnings,
    );
  }
}
