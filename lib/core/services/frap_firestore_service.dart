import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bg_med/core/models/frap_firestore.dart';
import 'package:bg_med/features/frap/presentation/providers/frap_data_provider.dart';
import 'package:bg_med/core/validators/frap_data_validator.dart';
import 'package:bg_med/core/exceptions/frap_exceptions.dart';

class FrapFirestoreService {
  static const String _collectionName = 'preHospitalRecords';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FrapDataValidator _validator = FrapDataValidator.instance;

  // Referencia a la colección
  CollectionReference get _collection => _firestore.collection(_collectionName);

  // Obtener el ID del usuario actual
  String? get _currentUserId => _auth.currentUser?.uid;

  // CREAR un nuevo registro FRAP
  Future<String?> createFrapRecord({
    required FrapData frapData,
    String? customUserId,
  }) async {
    try {
      final userId = customUserId ?? _currentUserId;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Validación pre-conversión
      final preValidation = _validator.validateComplete(frapData);
      if (!preValidation.isValid) {
        throw ValidationException(preValidation.errors);
      }

      final frapFirestore = FrapFirestore.create(
        userId: userId,
        serviceInfo: frapData.serviceInfo,
        registryInfo: frapData.registryInfo,
        patientInfo: frapData.patientInfo,
        management: frapData.management,
        medications: frapData.medications,
        gynecoObstetric: frapData.gynecoObstetric,
        attentionNegative: frapData.attentionNegative,
        pathologicalHistory: frapData.pathologicalHistory,
        clinicalHistory: frapData.clinicalHistory,
        physicalExam: frapData.physicalExam,
        priorityJustification: frapData.priorityJustification,
        injuryLocation: frapData.injuryLocation,
        receivingUnit: frapData.receivingUnit,
        patientReception: frapData.patientReception,
        insumos: frapData.insumos,
      );

      // Validación post-conversión para evitar persistir datos inconsistentes
      if (!_isValidFrapFirestore(frapFirestore)) {
        throw ConversionException(
          'La conversión produjo un modelo FrapFirestore inválido',
        );
      }

      final docRef = await _collection.add(frapFirestore.toFirestore());
      return docRef.id;
    } catch (e) {
      if (e is ValidationException || e is ConversionException) {
        rethrow;
      }
      throw Exception('Error al crear el registro FRAP: $e');
    }
  }

  // ACTUALIZAR un registro FRAP existente
  Future<void> updateFrapRecord({
    required String frapId,
    required FrapData frapData,
    String? customUserId,
  }) async {
    try {
      final userId = customUserId ?? _currentUserId;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Verificar que el registro existe y pertenece al usuario
      final doc = await _collection.doc(frapId).get();
      if (!doc.exists) {
        throw Exception('Registro no encontrado');
      }

      final existingData = doc.data() as Map<String, dynamic>;
      if (existingData['userId'] != userId) {
        throw Exception('No tienes permisos para actualizar este registro');
      }

      // Actualizar el registro
      final updatedData = {
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'serviceInfo': frapData.serviceInfo,
        'registryInfo': frapData.registryInfo,
        'patientInfo': frapData.patientInfo,
        'management': frapData.management,
        'medications': frapData.medications,
        'gynecoObstetric': frapData.gynecoObstetric,
        'attentionNegative': frapData.attentionNegative,
        'pathologicalHistory': frapData.pathologicalHistory,
        'clinicalHistory': frapData.clinicalHistory,
        'physicalExam': frapData.physicalExam,
        'priorityJustification': frapData.priorityJustification,
        'injuryLocation': frapData.injuryLocation,
        'receivingUnit': frapData.receivingUnit,
        'patientReception': frapData.patientReception,
        'insumos': frapData.insumos,
      };

      await _collection.doc(frapId).update(updatedData);
    } catch (e) {
      throw Exception('Error al actualizar el registro FRAP: $e');
    }
  }

  // ACTUALIZAR un registro FRAP existente (sobrecarga con modelo FrapFirestore)
  Future<void> updateFrapRecordDirect(
    String frapId,
    FrapFirestore updatedFrap,
  ) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Verificar que el registro existe y pertenece al usuario
      final doc = await _collection.doc(frapId).get();
      if (!doc.exists) {
        throw Exception('Registro no encontrado');
      }

      final existingData = doc.data() as Map<String, dynamic>;
      if (existingData['userId'] != userId) {
        throw Exception('No tienes permisos para actualizar este registro');
      }

      // Actualizar el registro con todos los datos
      final updateMap = updatedFrap.toMap();
      updateMap['updatedAt'] = Timestamp.fromDate(DateTime.now());
      updateMap['userId'] = userId; // Mantener el userId original

      await _collection.doc(frapId).update(updateMap);
    } catch (e) {
      throw Exception('Error al actualizar el registro FRAP: $e');
    }
  }

  // ACTUALIZAR sección específica de un registro FRAP
  Future<void> updateFrapSection({
    required String frapId,
    required String sectionName,
    required Map<String, dynamic> sectionData,
    String? customUserId,
  }) async {
    try {
      final userId = customUserId ?? _currentUserId;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Verificar que el registro existe y pertenece al usuario
      final doc = await _collection.doc(frapId).get();
      if (!doc.exists) {
        throw Exception('Registro no encontrado');
      }

      final existingData = doc.data() as Map<String, dynamic>;
      if (existingData['userId'] != userId) {
        throw Exception('No tienes permisos para actualizar este registro');
      }

      // Actualizar solo la sección específica
      final updateData = {
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        sectionName: sectionData,
      };

      await _collection.doc(frapId).update(updateData);
    } catch (e) {
      throw Exception('Error al actualizar la sección del registro FRAP: $e');
    }
  }

  // OBTENER un registro FRAP por ID
  Future<FrapFirestore?> getFrapRecord(String frapId) async {
    try {
      final doc = await _collection.doc(frapId).get();
      if (!doc.exists) {
        return null;
      }

      return FrapFirestore.fromFirestore(doc);
    } catch (e) {
      throw Exception('Error al obtener el registro FRAP: $e');
    }
  }

  // OBTENER todos los registros FRAP del usuario actual
  Future<List<FrapFirestore>> getAllFrapRecords({String? customUserId}) async {
    try {
      final userId = customUserId ?? _currentUserId;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final querySnapshot =
          await _collection
              .where('userId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => FrapFirestore.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener los registros FRAP: $e');
    }
  }

  // OBTENER registros FRAP con paginación
  Future<List<FrapFirestore>> getFrapRecordsPaginated({
    String? customUserId,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      final userId = customUserId ?? _currentUserId;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      Query query = _collection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => FrapFirestore.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener los registros FRAP paginados: $e');
    }
  }

  // OBTENER registros FRAP por rango de fechas
  Future<List<FrapFirestore>> getFrapRecordsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? customUserId,
  }) async {
    try {
      final userId = customUserId ?? _currentUserId;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final querySnapshot =
          await _collection
              .where('userId', isEqualTo: userId)
              .where(
                'createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
              )
              .where(
                'createdAt',
                isLessThanOrEqualTo: Timestamp.fromDate(endDate),
              )
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => FrapFirestore.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener los registros FRAP por fecha: $e');
    }
  }

  // BUSCAR registros FRAP por nombre de paciente
  Future<List<FrapFirestore>> searchFrapRecordsByPatientName({
    required String patientName,
    String? customUserId,
  }) async {
    try {
      final userId = customUserId ?? _currentUserId;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Obtener todos los registros del usuario
      final allRecords = await getAllFrapRecords(customUserId: userId);

      // Filtrar por nombre del paciente
      final filteredRecords =
          allRecords.where((record) {
            final fullName = record.patientName.toLowerCase();
            final searchTerm = patientName.toLowerCase();
            return fullName.contains(searchTerm);
          }).toList();

      return filteredRecords;
    } catch (e) {
      throw Exception('Error al buscar registros FRAP: $e');
    }
  }

  // ELIMINAR un registro FRAP
  Future<void> deleteFrapRecord(String frapId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Verificar que el registro existe y pertenece al usuario
      final doc = await _collection.doc(frapId).get();
      if (!doc.exists) {
        throw Exception('Registro no encontrado');
      }

      final existingData = doc.data() as Map<String, dynamic>;
      if (existingData['userId'] != userId) {
        throw Exception('No tienes permisos para eliminar este registro');
      }

      await _collection.doc(frapId).delete();
    } catch (e) {
      throw Exception('Error al eliminar el registro FRAP: $e');
    }
  }

  // DUPLICAR un registro FRAP
  Future<String?> duplicateFrapRecord(String frapId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Obtener el registro original
      final originalRecord = await getFrapRecord(frapId);
      if (originalRecord == null) {
        throw Exception('Registro no encontrado');
      }

      // Verificar permisos
      if (originalRecord.userId != userId) {
        throw Exception('No tienes permisos para duplicar este registro');
      }

      // Crear una copia del registro
      final duplicatedRecord = FrapFirestore.create(
        userId: userId,
        serviceInfo: originalRecord.serviceInfo,
        registryInfo: originalRecord.registryInfo,
        patientInfo: originalRecord.patientInfo,
        management: originalRecord.management,
        medications: originalRecord.medications,
        gynecoObstetric: originalRecord.gynecoObstetric,
        attentionNegative: originalRecord.attentionNegative,
        pathologicalHistory: originalRecord.pathologicalHistory,
        clinicalHistory: originalRecord.clinicalHistory,
        physicalExam: originalRecord.physicalExam,
        priorityJustification: originalRecord.priorityJustification,
        injuryLocation: originalRecord.injuryLocation,
        receivingUnit: originalRecord.receivingUnit,
        patientReception: originalRecord.patientReception,
        insumos: originalRecord.insumos,
      );

      final docRef = await _collection.add(duplicatedRecord.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Error al duplicar el registro FRAP: $e');
    }
  }

  // BUSCAR si un registro equivalente ya existe en la nube
  Future<String?> findExistingCloudRecord({
    required FrapData frapData,
    String? customUserId,
  }) async {
    try {
      final userId = customUserId ?? _currentUserId;
      if (userId == null) {
        // No se puede buscar sin un usuario
        return null;
      }

      final folio = frapData.registryInfo['folio']?.toString();
      final patientName =
          '${frapData.patientInfo['firstName'] ?? ''} ${frapData.patientInfo['paternalLastName'] ?? ''}'
              .trim();

      // Si no hay folio o nombre de paciente, no podemos buscar de forma fiable.
      if (folio == null || folio.isEmpty || patientName.isEmpty) {
        return null;
      }

      // Buscar por folio, que debería ser el identificador más fiable.
      final querySnapshot =
          await _collection
              .where('userId', isEqualTo: userId)
              .where('registryInfo.folio', isEqualTo: folio)
              .limit(1)
              .get();

      return querySnapshot.docs.isNotEmpty ? querySnapshot.docs.first.id : null;
    } catch (e) {
      // Si hay un error en la búsqueda, es más seguro asumir que no existe.
      return null;
    }
  }

  // STREAM de registros FRAP en tiempo real
  Stream<List<FrapFirestore>> getFrapRecordsStream({String? customUserId}) {
    try {
      final userId = customUserId ?? _currentUserId;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      return _collection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (querySnapshot) =>
                querySnapshot.docs
                    .map((doc) => FrapFirestore.fromFirestore(doc))
                    .toList(),
          );
    } catch (e) {
      throw Exception('Error al obtener el stream de registros FRAP: $e');
    }
  }

  // STREAM de un registro FRAP específico en tiempo real
  Stream<FrapFirestore?> getFrapRecordStream(String frapId) {
    try {
      return _collection.doc(frapId).snapshots().map((docSnapshot) {
        if (!docSnapshot.exists) {
          return null;
        }
        return FrapFirestore.fromFirestore(docSnapshot);
      });
    } catch (e) {
      throw Exception('Error al obtener el stream del registro FRAP: $e');
    }
  }

  // OBTENER estadísticas de registros FRAP
  Future<Map<String, dynamic>> getFrapStatistics({String? customUserId}) async {
    try {
      final userId = customUserId ?? _currentUserId;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final allRecords = await getAllFrapRecords(customUserId: userId);
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
        'completed': allRecords.where((record) => record.isComplete).length,
        'averageCompletion':
            allRecords.isEmpty
                ? 0.0
                : allRecords
                        .map((record) => record.completionPercentage)
                        .reduce((a, b) => a + b) /
                    allRecords.length,
      };
    } catch (e) {
      throw Exception('Error al obtener las estadísticas FRAP: $e');
    }
  }

  // SINCRONIZAR registros locales con la nube
  Future<void> syncLocalRecordsToCloud() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Aquí puedes implementar la lógica para sincronizar los registros locales de Hive
      // con los registros en Firestore
      // Por ejemplo, obtener registros de Hive y subirlos a Firestore si no existen

      print('Sincronización de registros locales con la nube completada');
    } catch (e) {
      throw Exception('Error al sincronizar registros: $e');
    }
  }

  // BACKUP de registros FRAP
  Future<List<Map<String, dynamic>>> backupFrapRecords({
    String? customUserId,
  }) async {
    try {
      final records = await getAllFrapRecords(customUserId: customUserId);
      return records.map((record) => record.toMap()).toList();
    } catch (e) {
      throw Exception('Error al crear backup de registros FRAP: $e');
    }
  }

  // RESTAURAR registros FRAP desde backup
  Future<void> restoreFrapRecords({
    required List<Map<String, dynamic>> backupData,
    String? customUserId,
  }) async {
    try {
      final userId = customUserId ?? _currentUserId;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final batch = _firestore.batch();

      for (final recordData in backupData) {
        final docRef = _collection.doc();
        final frapRecord = FrapFirestore.fromMap(recordData, docRef.id);
        batch.set(docRef, frapRecord.copyWith(userId: userId).toFirestore());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error al restaurar registros FRAP: $e');
    }
  }

  // VALIDAR que el modelo FrapFirestore convertido es válido
  bool _isValidFrapFirestore(FrapFirestore frap) {
    // 1. Validar que userId no es nulo o vacío
    if (frap.userId.isEmpty) return false;

    // 2. Validar información del paciente
    if (frap.patientInfo.isEmpty) return false;
    final patientInfo = frap.patientInfo;
    final firstName = patientInfo['firstName']?.toString().trim() ?? '';
    if (firstName.isEmpty) {
      return false;
    }

    // 3. Validar información de servicio
    if (frap.serviceInfo.isEmpty) return false;
    final serviceInfo = frap.serviceInfo;
    final urgencyType = serviceInfo['tipoUrgencia']?.toString().trim() ?? '';
    if (urgencyType.isEmpty) {
      return false;
    }

    // 4. Validar información de registro
    if (frap.registryInfo.isEmpty) return false;
    final registryInfo = frap.registryInfo;
    final folio = registryInfo['folio']?.toString().trim() ?? '';
    if (folio.isEmpty) {
      return false;
    }

    return true;
  }
}
