import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:bg_med/core/models/frap.dart';
import 'package:bg_med/core/models/patient.dart';
import 'package:bg_med/core/models/clinical_history.dart';
import 'package:bg_med/core/models/physical_exam.dart';
import 'package:bg_med/core/models/insumo.dart';
import 'package:bg_med/core/models/personal_medico.dart';
import 'package:bg_med/features/frap/presentation/providers/frap_data_provider.dart';

class FrapLocalService {
  static const String _boxName = 'fraps';
  Box<Frap>? _frapBox;

  // Obtener la caja de Hive de forma segura
  Future<Box<Frap>> get _getFrapBox async {
    if (_frapBox != null && _frapBox!.isOpen) {
      return _frapBox!;
    }

    // Verificar si la caja está abierta
    if (Hive.isBoxOpen(_boxName)) {
      _frapBox = Hive.box<Frap>(_boxName);
      return _frapBox!;
    }

    // Si no está abierta, abrirla
    try {
      _frapBox = await Hive.openBox<Frap>(_boxName);
      return _frapBox!;
    } catch (e) {
      throw Exception('Error al abrir la caja de Hive: $e');
    }
  }

  // Generar ID único para registros FRAP
  String _generateId() {
    return const Uuid().v4();
  }

  // CREAR un nuevo registro FRAP local
  Future<String?> createFrapRecord({required FrapData frapData}) async {
    try {
      // Convertir FrapData a modelo Frap
      final frap = _convertFrapDataToFrap(frapData);

      // Guardar en Hive
      final box = await _getFrapBox;
      await box.add(frap);

      return frap.id;
    } catch (e) {
      throw Exception('Error al crear el registro FRAP local: $e');
    }
  }

  // ACTUALIZAR un registro FRAP local existente
  Future<void> updateFrapRecord({
    required String frapId,
    required FrapData frapData,
  }) async {
    try {
      // Buscar el registro existente
      final box = await _getFrapBox;
      final existingIndex = box.values.toList().indexWhere(
        (frap) => frap.id == frapId,
      );

      if (existingIndex == -1) {
        throw Exception('Registro no encontrado');
      }

      // Convertir FrapData a modelo Frap manteniendo el ID y fecha original
      final existingFrap = box.getAt(existingIndex)!;
      final updatedFrap = _convertFrapDataToFrap(
        frapData,
        existingId: existingFrap.id,
        existingCreatedAt: existingFrap.createdAt,
      );

      // Actualizar en Hive
      await box.putAt(existingIndex, updatedFrap);
    } catch (e) {
      throw Exception('Error al actualizar el registro FRAP local: $e');
    }
  }

  // ACTUALIZAR un registro FRAP local existente (sobrecarga con modelo Frap)
  Future<void> updateFrapRecordDirect(String frapId, Frap updatedFrap) async {
    try {
      final box = await _getFrapBox;
      final existingIndex = box.values.toList().indexWhere(
        (frap) => frap.id == frapId,
      );

      if (existingIndex == -1) {
        throw Exception('Registro no encontrado con ID: $frapId');
      }

      // Actualizar en Hive
      await box.putAt(existingIndex, updatedFrap);
    } catch (e) {
      throw Exception('Error al actualizar el registro FRAP local: $e');
    }
  }

  // OBTENER un registro FRAP por ID
  Future<Frap?> getFrapRecord(String frapId) async {
    try {
      final box = await _getFrapBox;
      final frap = box.values.firstWhere(
        (frap) => frap.id == frapId,
        orElse: () => throw Exception('Registro no encontrado'),
      );
      return frap;
    } catch (e) {
      return null;
    }
  }

  // BUSCAR un registro por folio
  Future<Frap?> findRecordByFolio(String folio) async {
    try {
      if (folio.trim().isEmpty) {
        return null;
      }
      final box = await _getFrapBox;
      final frap = box.values.firstWhere(
        (frap) => frap.registryInfo['folio']?.toString() == folio,
        orElse: () => throw Exception('Registro no encontrado con ese folio'),
      );
      return frap;
    } catch (e) {
      return null;
    }
  }

  // OBTENER todos los registros FRAP locales
  Future<List<Frap>> getAllFrapRecords() async {
    try {
      final box = await _getFrapBox;
      final records = box.values.toList();

      // Ordenar por fecha de creación descendente
      records.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return records;
    } catch (e) {
      print('Error al obtener los registros FRAP locales: $e');
      throw Exception('Error al obtener los registros FRAP locales: $e');
    }
  }

  // BUSCAR registros FRAP por nombre de paciente
  Future<List<Frap>> searchFrapRecordsByPatientName({
    required String patientName,
  }) async {
    try {
      final allRecords = await getAllFrapRecords();

      // Filtrar por nombre del paciente
      final filteredRecords =
          allRecords.where((record) {
            final fullName = record.patient.name.toLowerCase();
            final searchTerm = patientName.toLowerCase();
            return fullName.contains(searchTerm);
          }).toList();

      return filteredRecords;
    } catch (e) {
      throw Exception('Error al buscar registros FRAP locales: $e');
    }
  }

  // OBTENER registros FRAP por rango de fechas
  Future<List<Frap>> getFrapRecordsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final allRecords = await getAllFrapRecords();

      // Filtrar por rango de fechas
      final filteredRecords =
          allRecords.where((record) {
            return record.createdAt.isAfter(startDate) &&
                record.createdAt.isBefore(endDate.add(const Duration(days: 1)));
          }).toList();

      return filteredRecords;
    } catch (e) {
      throw Exception('Error al obtener registros FRAP por fecha: $e');
    }
  }

  // ELIMINAR un registro FRAP local
  Future<void> deleteFrapRecord(String frapId) async {
    try {
      final box = await _getFrapBox;
      final existingIndex = box.values.toList().indexWhere(
        (frap) => frap.id == frapId,
      );

      if (existingIndex == -1) {
        throw Exception('Registro no encontrado');
      }

      await box.deleteAt(existingIndex);
    } catch (e) {
      throw Exception('Error al eliminar el registro FRAP local: $e');
    }
  }

  // DUPLICAR un registro FRAP
  Future<String?> duplicateFrapRecord(String frapId) async {
    try {
      final originalRecord = await getFrapRecord(frapId);
      if (originalRecord == null) {
        throw Exception('Registro no encontrado');
      }

      // Crear una copia del registro
      final duplicatedRecord = originalRecord.copyWith(
        id: _generateId(),
        createdAt: DateTime.now(),
        isSynced: false,
      );

      final box = await _getFrapBox;
      await box.add(duplicatedRecord);
      return duplicatedRecord.id;
    } catch (e) {
      throw Exception('Error al duplicar el registro FRAP local: $e');
    }
  }

  // OBTENER estadísticas de registros FRAP
  Future<Map<String, dynamic>> getFrapStatistics() async {
    try {
      final allRecords = await getAllFrapRecords();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final thisWeek = today.subtract(Duration(days: today.weekday - 1));
      final thisMonth = DateTime(now.year, now.month, 1);
      final thisYear = DateTime(now.year, 1, 1);

      return {
        'total': allRecords.length,
        'today':
            allRecords.where((record) {
              final recordDate = DateTime(
                record.createdAt.year,
                record.createdAt.month,
                record.createdAt.day,
              );
              return recordDate.isAtSameMomentAs(today);
            }).length,
        'thisWeek':
            allRecords
                .where(
                  (record) =>
                      record.createdAt.isAfter(thisWeek) &&
                      record.createdAt.isBefore(
                        today.add(const Duration(days: 1)),
                      ),
                )
                .length,
        'thisMonth':
            allRecords
                .where(
                  (record) =>
                      record.createdAt.isAfter(thisMonth) &&
                      record.createdAt.isBefore(
                        thisMonth.add(const Duration(days: 32)),
                      ),
                )
                .length,
        'thisYear':
            allRecords
                .where(
                  (record) =>
                      record.createdAt.isAfter(thisYear) &&
                      record.createdAt.isBefore(
                        thisYear.add(const Duration(days: 366)),
                      ),
                )
                .length,
      };
    } catch (e) {
      throw Exception('Error al obtener las estadísticas FRAP locales: $e');
    }
  }

  // LIMPIAR todos los registros FRAP locales
  Future<void> clearAllFrapRecords() async {
    try {
      final box = await _getFrapBox;
      await box.clear();
    } catch (e) {
      throw Exception('Error al limpiar los registros FRAP locales: $e');
    }
  }

  // BACKUP de registros FRAP
  Future<List<Map<String, dynamic>>> backupFrapRecords() async {
    try {
      final records = await getAllFrapRecords();
      return records.map((record) => _frapToMap(record)).toList();
    } catch (e) {
      throw Exception('Error al crear backup de registros FRAP locales: $e');
    }
  }

  // RESTAURAR registros FRAP desde backup
  Future<void> restoreFrapRecords({
    required List<Map<String, dynamic>> backupData,
  }) async {
    try {
      // Restaurar registros desde el backup
      for (final recordData in backupData) {
        final frap = _frapFromMap(recordData);
        final box = await _getFrapBox;
        await box.add(frap);
      }
    } catch (e) {
      throw Exception('Error al restaurar registros FRAP locales: $e');
    }
  }

  // CONVERTIR FrapData a modelo Frap
  Frap _convertFrapDataToFrap(
    FrapData frapData, {
    String? existingId,
    DateTime? existingCreatedAt,
  }) {
    // Extraer información del paciente
    final patientInfo = frapData.patientInfo;

    // Construir el nombre completo del paciente
    final firstName = patientInfo['firstName'] ?? '';
    final paternalLastName = patientInfo['paternalLastName'] ?? '';
    final maternalLastName = patientInfo['maternalLastName'] ?? '';
    final fullName = '$firstName $paternalLastName $maternalLastName'.trim();

    // Construir la dirección completa
    final street = patientInfo['street'] ?? '';
    final exteriorNumber = patientInfo['exteriorNumber'] ?? '';
    final interiorNumber = patientInfo['interiorNumber'] ?? '';
    final neighborhood = patientInfo['neighborhood'] ?? '';
    final city = patientInfo['city'] ?? '';
    final addressDetails = patientInfo['addressDetails'] ?? '';

    String fullAddress =
        '$street $exteriorNumber $interiorNumber $neighborhood $city $addressDetails';

    final patient = Patient(
      name: fullName.isNotEmpty ? fullName : 'Sin nombre',
      age: patientInfo['age'] ?? 0,
      sex: patientInfo['sex'] ?? '',
      gender: (patientInfo['gender'] ?? '').toString(),
      address: fullAddress,
      firstName: firstName,
      paternalLastName: paternalLastName,
      maternalLastName: maternalLastName,
      phone: patientInfo['phone'] ?? '',
      street: street,
      exteriorNumber: exteriorNumber,
      interiorNumber: interiorNumber,
      neighborhood: neighborhood,
      city: city,
      insurance: patientInfo['insurance'] ?? '',
      responsiblePerson: patientInfo['responsiblePerson'],
      addressDetails: patientInfo['addressDetails'] ?? '',
      tipoEntrega: patientInfo['tipoEntrega'] ?? '',
      emergencyContact: patientInfo['emergencyContact'],
      currentCondition: patientInfo['currentCondition'],
      tipoEntregaOtro: patientInfo['tipoEntregaOtro'],
    );

    // Extraer historia clínica
    final clinicalHistoryData = frapData.clinicalHistory;
    final clinicalHistory = ClinicalHistory(
      traumaCraneo: clinicalHistoryData['traumaCraneo'] ?? false,
      traumaCraneoEspecifique:
          clinicalHistoryData['traumaCraneoEspecifique'] ?? '',
      traumaTorax: clinicalHistoryData['traumaTorax'] ?? false,
      traumaToraxEspecifique:
          clinicalHistoryData['traumaToraxEspecifique'] ?? '',
      traumaAbdomen: clinicalHistoryData['traumaAbdomen'] ?? false,
      traumaAbdomenEspecifique:
          clinicalHistoryData['traumaAbdomenEspecifique'] ?? '',
      traumaColumna: clinicalHistoryData['traumaColumna'] ?? false,
      traumaColumnaEspecifique:
          clinicalHistoryData['traumaColumnaEspecifique'] ?? '',
      traumaExtremidades: clinicalHistoryData['traumaExtremidades'] ?? false,
      traumaExtremidadesEspecifique:
          clinicalHistoryData['traumaExtremidadesEspecifique'] ?? '',
      traumaPelvis: clinicalHistoryData['traumaPelvis'] ?? false,
      traumaPelvisEspecifique:
          clinicalHistoryData['traumaPelvisEspecifique'] ?? '',
      traumaOtros: clinicalHistoryData['traumaOtros'] ?? false,
      traumaOtrosEspecifique:
          clinicalHistoryData['traumaOtrosEspecifique'] ?? '',
      agenteCausal: clinicalHistoryData['agenteCausal'] ?? '',
      cinematica: clinicalHistoryData['cinematica'] ?? '',
      medidaSeguridad: clinicalHistoryData['medidaSeguridad'] ?? '',
      observaciones: clinicalHistoryData['observaciones'] ?? '',
    );

    // Preparar serviceInfo duplicando currentCondition / emergencyContact si venían en patientInfo
    final Map<String, dynamic> mergedServiceInfo = {...frapData.serviceInfo};
    final currentCondition = (patientInfo['currentCondition'] ?? '').toString();
    final emergencyContact = (patientInfo['emergencyContact'] ?? '').toString();
    if (currentCondition.isNotEmpty) {
      mergedServiceInfo['currentCondition'] = currentCondition;
    }
    if (emergencyContact.isNotEmpty) {
      mergedServiceInfo['emergencyContact'] = emergencyContact;
    }

    final List<Insumo> insumos = <Insumo>[];
    if (frapData.insumos.isNotEmpty) {
      for (final item in frapData.insumos) {
        final cantidad =
            (item['cantidad'] is int)
                ? item['cantidad'] as int
                : int.tryParse(item['cantidad'].toString()) ?? 0;
        final articulo = (item['articulo'] ?? '').toString();
        if (cantidad > 0 && articulo.isNotEmpty) {
          insumos.add(Insumo(cantidad: cantidad, articulo: articulo));
        }
      }
    }

    final List<PersonalMedico> personalMedico = <PersonalMedico>[];
    // Se captura en receiving_unit_form_dialog como lista de mapas bajo 'personalMedico'
    if (frapData.receivingUnit.isNotEmpty) {
      final list = frapData.receivingUnit['personalMedico'] as List<dynamic>?;
      if (list != null) {
        for (final item in list) {
          if (item is Map) {
            final nombre = (item['nombre'] ?? '').toString();
            final especialidad = (item['especialidad'] ?? '').toString();
            final cedula = (item['cedula'] ?? '').toString();
            if (nombre.isNotEmpty) {
              personalMedico.add(
                PersonalMedico(
                  nombre: nombre,
                  especialidad: especialidad,
                  cedula: cedula,
                ),
              );
            }
          }
        }
      }
    }

    // Extraer examen físico
    final physicalExamData = frapData.physicalExam;

    // Usar el factory constructor del modelo actualizado
    final physicalExam = PhysicalExam.fromFormData(physicalExamData);

    final now = DateTime.now();
    final id = existingId ?? _generateId();
    final createdAt = existingCreatedAt ?? now;

    return Frap(
      id: id,
      patient: patient,
      clinicalHistory: clinicalHistory,
      physicalExam: physicalExam,
      createdAt: createdAt,
      updatedAt: now,
      serviceInfo: mergedServiceInfo,
      registryInfo: frapData.registryInfo,
      management: frapData.management,
      medications: frapData.medications,
      gynecoObstetric: frapData.gynecoObstetric,
      attentionNegative: frapData.attentionNegative,
      pathologicalHistory: frapData.pathologicalHistory,
      priorityJustification: frapData.priorityJustification,
      injuryLocation: frapData.injuryLocation,
      receivingUnit: frapData.receivingUnit,
      patientReception: frapData.patientReception,
      insumos: insumos,
      personalMedico: personalMedico,
      consentimientoSignature: frapData.serviceInfo['consentimientoSignature'],
      tipoUrgencia: frapData.serviceInfo['tipoUrgencia'],
      urgenciaEspecifique: frapData.serviceInfo['urgenciaEspecifique'],
      ubicacion: frapData.serviceInfo['ubicacion'],
      tipoServicioEspecifique: frapData.serviceInfo['tipoServicioEspecifique'],
      lugarOcurrenciaEspecifique:
          frapData.serviceInfo['lugarOcurrenciaEspecifique'],
    );
  }

  // CONVERTIR Frap a Map para backup
  Map<String, dynamic> _frapToMap(Frap frap) {
    return {
      'id': frap.id,
      'patient': {
        'name': frap.patient.name,
        'age': frap.patient.age,
        'sex': frap.patient.sex,
        'gender': frap.patient.gender,
        'address': frap.patient.address,
      },
      'clinicalHistory': {
        'traumaCraneo': frap.clinicalHistory.traumaCraneo,
        'traumaCraneoEspecifique': frap.clinicalHistory.traumaCraneoEspecifique,
        'traumaTorax': frap.clinicalHistory.traumaTorax,
        'traumaToraxEspecifique': frap.clinicalHistory.traumaToraxEspecifique,
        'traumaAbdomen': frap.clinicalHistory.traumaAbdomen,
        'traumaAbdomenEspecifique':
            frap.clinicalHistory.traumaAbdomenEspecifique,
        'traumaColumna': frap.clinicalHistory.traumaColumna,
        'traumaColumnaEspecifique':
            frap.clinicalHistory.traumaColumnaEspecifique,
        'traumaExtremidades': frap.clinicalHistory.traumaExtremidades,
        'traumaExtremidadesEspecifique':
            frap.clinicalHistory.traumaExtremidadesEspecifique,
        'traumaPelvis': frap.clinicalHistory.traumaPelvis,
        'traumaPelvisEspecifique': frap.clinicalHistory.traumaPelvisEspecifique,
        'traumaOtros': frap.clinicalHistory.traumaOtros,
        'traumaOtrosEspecifique': frap.clinicalHistory.traumaOtrosEspecifique,
        'agenteCausal': frap.clinicalHistory.agenteCausal,
        'cinematica': frap.clinicalHistory.cinematica,
        'medidaSeguridad': frap.clinicalHistory.medidaSeguridad,
        'observaciones': frap.clinicalHistory.observaciones,
      },
      'physicalExam': {
        'vitalSigns': frap.physicalExam.vitalSigns,
        'head': frap.physicalExam.head,
        'neck': frap.physicalExam.neck,
        'thorax': frap.physicalExam.thorax,
        'abdomen': frap.physicalExam.abdomen,
        'extremities': frap.physicalExam.extremities,
      },
      'insumos':
          frap.insumos
              .map(
                (insumo) => {
                  'cantidad': insumo.cantidad,
                  'articulo': insumo.articulo,
                },
              )
              .toList(),
      'createdAt': frap.createdAt.toIso8601String(),
    };
  }

  // CONVERTIR Map a Frap para restaurar
  Frap _frapFromMap(Map<String, dynamic> map) {
    final patientData = map['patient'] as Map<String, dynamic>;
    final clinicalHistoryData = map['clinicalHistory'] as Map<String, dynamic>;
    final physicalExamData = map['physicalExam'] as Map<String, dynamic>;
    final insumosData = map['insumos'] as List<dynamic>? ?? [];

    // Convertir insumos
    final List<Insumo> insumos =
        insumosData.map((item) {
          final insumoMap = item as Map<String, dynamic>;
          return Insumo(
            cantidad: insumoMap['cantidad'] as int,
            articulo: insumoMap['articulo'] as String,
          );
        }).toList();

    return Frap(
      id: map['id'] as String,
      patient: Patient(
        name: patientData['name'] as String,
        age: patientData['age'] as int,
        sex: patientData['sex'] as String,
        gender: patientData['gender'] as String,
        address: patientData['address'] as String,
      ),
      clinicalHistory: ClinicalHistory(
        traumaCraneo: clinicalHistoryData['traumaCraneo'] as bool? ?? false,
        traumaCraneoEspecifique:
            clinicalHistoryData['traumaCraneoEspecifique'] as String? ?? '',
        traumaTorax: clinicalHistoryData['traumaTorax'] as bool? ?? false,
        traumaToraxEspecifique:
            clinicalHistoryData['traumaToraxEspecifique'] as String? ?? '',
        traumaAbdomen: clinicalHistoryData['traumaAbdomen'] as bool? ?? false,
        traumaAbdomenEspecifique:
            clinicalHistoryData['traumaAbdomenEspecifique'] as String? ?? '',
        traumaColumna: clinicalHistoryData['traumaColumna'] as bool? ?? false,
        traumaColumnaEspecifique:
            clinicalHistoryData['traumaColumnaEspecifique'] as String? ?? '',
        traumaExtremidades:
            clinicalHistoryData['traumaExtremidades'] as bool? ?? false,
        traumaExtremidadesEspecifique:
            clinicalHistoryData['traumaExtremidadesEspecifique'] as String? ??
            '',
        traumaPelvis: clinicalHistoryData['traumaPelvis'] as bool? ?? false,
        traumaPelvisEspecifique:
            clinicalHistoryData['traumaPelvisEspecifique'] as String? ?? '',
        traumaOtros: clinicalHistoryData['traumaOtros'] as bool? ?? false,
        traumaOtrosEspecifique:
            clinicalHistoryData['traumaOtrosEspecifique'] as String? ?? '',
        agenteCausal: clinicalHistoryData['agenteCausal'] as String? ?? '',
        cinematica: clinicalHistoryData['cinematica'] as String? ?? '',
        medidaSeguridad:
            clinicalHistoryData['medidaSeguridad'] as String? ?? '',
        observaciones: clinicalHistoryData['observaciones'] as String? ?? '',
      ),
      physicalExam: PhysicalExam(
        vitalSigns: physicalExamData['vitalSigns'] as String,
        head: physicalExamData['head'] as String,
        neck: physicalExamData['neck'] as String,
        thorax: physicalExamData['thorax'] as String,
        abdomen: physicalExamData['abdomen'] as String,
        extremities: physicalExamData['extremities'] as String,
      ),
      insumos: insumos,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  // CONVERTIR Frap a FrapData para edición
  FrapData convertFrapToFrapData(Frap frap) {
    return FrapData(
      serviceInfo: {
        ...frap.serviceInfo,
        'consentimientoSignature': frap.consentimientoSignature,
        'tipoUrgencia': frap.tipoUrgencia,
        'urgenciaEspecifique': frap.urgenciaEspecifique,
        'ubicacion': frap.ubicacion,
        'tipoServicioEspecifique': frap.tipoServicioEspecifique,
        'lugarOcurrenciaEspecifique': frap.lugarOcurrenciaEspecifique,
      },
      registryInfo: frap.registryInfo,
      patientInfo: {
        'firstName': frap.patient.firstName,
        'paternalLastName': frap.patient.paternalLastName,
        'maternalLastName': frap.patient.maternalLastName,
        'age': frap.patient.age,
        'sex': frap.patient.sex,
        'gender': frap.patient.gender,
        'phone': frap.patient.phone,
        'street': frap.patient.street,
        'exteriorNumber': frap.patient.exteriorNumber,
        'interiorNumber': frap.patient.interiorNumber,
        'neighborhood': frap.patient.neighborhood,
        'city': frap.patient.city,
        'addressDetails': frap.patient.addressDetails,
        'insurance': frap.patient.insurance,
        'responsiblePerson': frap.patient.responsiblePerson,
        'currentCondition': frap.patient.currentCondition ?? '',
        'emergencyContact': frap.patient.emergencyContact ?? '',
        'address': frap.patient.fullAddress,
      },
      management: frap.management,
      medications: frap.medications,
      gynecoObstetric: frap.gynecoObstetric,
      attentionNegative: frap.attentionNegative,
      pathologicalHistory: frap.pathologicalHistory,
      clinicalHistory: {
        'traumaCraneo': frap.clinicalHistory.traumaCraneo,
        'traumaCraneoEspecifique': frap.clinicalHistory.traumaCraneoEspecifique,
        'traumaTorax': frap.clinicalHistory.traumaTorax,
        'traumaToraxEspecifique': frap.clinicalHistory.traumaToraxEspecifique,
        'traumaAbdomen': frap.clinicalHistory.traumaAbdomen,
        'traumaAbdomenEspecifique':
            frap.clinicalHistory.traumaAbdomenEspecifique,
        'traumaColumna': frap.clinicalHistory.traumaColumna,
        'traumaColumnaEspecifique':
            frap.clinicalHistory.traumaColumnaEspecifique,
        'traumaExtremidades': frap.clinicalHistory.traumaExtremidades,
        'traumaExtremidadesEspecifique':
            frap.clinicalHistory.traumaExtremidadesEspecifique,
        'traumaPelvis': frap.clinicalHistory.traumaPelvis,
        'traumaPelvisEspecifique': frap.clinicalHistory.traumaPelvisEspecifique,
        'traumaOtros': frap.clinicalHistory.traumaOtros,
        'traumaOtrosEspecifique': frap.clinicalHistory.traumaOtrosEspecifique,
        'agenteCausal': frap.clinicalHistory.agenteCausal,
        'cinematica': frap.clinicalHistory.cinematica,
        'medidaSeguridad': frap.clinicalHistory.medidaSeguridad,
        'observaciones': frap.clinicalHistory.observaciones,
      },
      physicalExam: frap.physicalExam.toFirebaseFormat(),
      priorityJustification: frap.priorityJustification,
      injuryLocation: frap.injuryLocation,
      receivingUnit: frap.receivingUnit,
      patientReception: frap.patientReception,
      insumos:
          frap.insumos
              .map(
                (insumo) => {
                  'cantidad': insumo.cantidad,
                  'articulo': insumo.articulo,
                },
              )
              .toList(),
    );
  }

  // MARCAR un registro como sincronizado
  Future<void> markAsSynced(String frapId) async {
    try {
      final box = await _getFrapBox;
      final existingIndex = box.values.toList().indexWhere(
        (frap) => frap.id == frapId,
      );

      if (existingIndex == -1) {
        throw Exception('Registro no encontrado');
      }

      final existingFrap = box.getAt(existingIndex)!;
      final updatedFrap = existingFrap.copyWith(isSynced: true);

      // Actualizar en Hive
      await box.putAt(existingIndex, updatedFrap);
    } catch (e) {
      throw Exception('Error al marcar como sincronizado: $e');
    }
  }

  // OBTENER registros no sincronizados
  Future<List<Frap>> getUnsyncedRecords() async {
    try {
      final box = await _getFrapBox;
      final records = box.values.toList();
      return records.where((frap) => !frap.isSynced).toList();
    } catch (e) {
      throw Exception('Error al obtener registros no sincronizados: $e');
    }
  }
}
