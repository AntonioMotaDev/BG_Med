/// Excepción lanzada cuando la validación de datos falla
class ValidationException implements Exception {
  final List<String> errors;

  ValidationException(this.errors);

  @override
  String toString() {
    return 'ValidationException: ${errors.join(", ")}';
  }
}

/// Excepción lanzada cuando la conversión de datos falla
class ConversionException implements Exception {
  final String message;

  ConversionException(this.message);

  @override
  String toString() {
    return 'ConversionException: $message';
  }
}

/// Excepción lanzada cuando un registro no se encuentra
class RecordNotFoundException implements Exception {
  final String message;

  RecordNotFoundException(this.message);

  @override
  String toString() {
    return 'RecordNotFoundException: $message';
  }
}

/// Excepción lanzada cuando la generación de folio falla
class FolioGenerationException implements Exception {
  final String message;

  FolioGenerationException(this.message);

  @override
  String toString() {
    return 'FolioGenerationException: $message';
  }
}
