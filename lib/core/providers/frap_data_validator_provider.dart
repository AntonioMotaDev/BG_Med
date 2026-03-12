import 'package:bg_med/core/validators/frap_data_validator.dart';
// import 'package:bg_med/features/frap/presentation/providers/frap_data_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider para el validador de FrapData
final frapDataValidatorProvider = Provider<FrapDataValidator>((ref) {
  return FrapDataValidator.instance;
});
