import 'package:bg_med/core/models/frap_firestore.dart';
import 'package:flutter/material.dart';

class SearchFilters {
  final DateTimeRange? dateRange;
  final String? patientName;
  final String? emergencyType;
  final String? receivingUnit;
  final bool? isSynced;
  final String? createdBy;
  final int? minAge;
  final int? maxAge;
  final String? gender;
  final String? traumaType; // Reemplaza allergies
  final String? agenteCausal;
  final String? vitalSigns;
  final bool? hasPathologicalHistory;
  final String? priorityLevel;

  SearchFilters({
    this.dateRange,
    this.patientName,
    this.emergencyType,
    this.receivingUnit,
    this.isSynced,
    this.createdBy,
    this.minAge,
    this.maxAge,
    this.gender,
    this.traumaType,
    this.agenteCausal,
    this.vitalSigns,
    this.hasPathologicalHistory,
    this.priorityLevel,
  });

  SearchFilters copyWith({
    DateTimeRange? dateRange,
    String? patientName,
    String? emergencyType,
    String? receivingUnit,
    bool? isSynced,
    String? createdBy,
    int? minAge,
    int? maxAge,
    String? gender,
    String? traumaType,
    String? agenteCausal,
    String? vitalSigns,
    bool? hasPathologicalHistory,
    String? priorityLevel,
  }) {
    return SearchFilters(
      dateRange: dateRange ?? this.dateRange,
      patientName: patientName ?? this.patientName,
      emergencyType: emergencyType ?? this.emergencyType,
      receivingUnit: receivingUnit ?? this.receivingUnit,
      isSynced: isSynced ?? this.isSynced,
      createdBy: createdBy ?? this.createdBy,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      gender: gender ?? this.gender,
      traumaType: traumaType ?? this.traumaType,
      agenteCausal: agenteCausal ?? this.agenteCausal,
      vitalSigns: vitalSigns ?? this.vitalSigns,
      hasPathologicalHistory:
          hasPathologicalHistory ?? this.hasPathologicalHistory,
      priorityLevel: priorityLevel ?? this.priorityLevel,
    );
  }

  bool get isEmpty {
    return dateRange == null &&
        patientName == null &&
        emergencyType == null &&
        receivingUnit == null &&
        isSynced == null &&
        createdBy == null &&
        minAge == null &&
        maxAge == null &&
        gender == null &&
        traumaType == null &&
        agenteCausal == null &&
        vitalSigns == null &&
        hasPathologicalHistory == null &&
        priorityLevel == null;
  }
}

class SearchResult {
  final FrapFirestore record;
  final double relevance;
  final List<String> matchedFields;

  SearchResult({
    required this.record,
    required this.relevance,
    required this.matchedFields,
  });
}

class SearchService {
  // Buscar registros por texto
  List<FrapFirestore> searchRecords(List<FrapFirestore> records, String query) {
    if (query.isEmpty) return records;

    final lowercaseQuery = query.toLowerCase();
    return records.where((record) {
      // Buscar en información del paciente
      if (record.patientInfo.isNotEmpty) {
        final patientName = record.patientInfo['firstName']?.toString() ?? '';
        final patientLastName =
            record.patientInfo['paternalLastName']?.toString() ?? '';
        final patientPhone = record.patientInfo['phone']?.toString() ?? '';

        if (patientName.toLowerCase().contains(lowercaseQuery) ||
            patientLastName.toLowerCase().contains(lowercaseQuery) ||
            patientPhone.toLowerCase().contains(lowercaseQuery)) {
          return true;
        }
      }

      // Buscar en información del servicio
      if (record.serviceInfo.isNotEmpty) {
        final lugarOcurrencia =
            record.serviceInfo['lugarOcurrencia']?.toString() ?? '';
        final tipoUrgencia =
            record.serviceInfo['tipoUrgencia']?.toString() ?? '';

        if (lugarOcurrencia.toLowerCase().contains(lowercaseQuery) ||
            tipoUrgencia.toLowerCase().contains(lowercaseQuery)) {
          return true;
        }
      }

      // Buscar en unidad receptora
      if (record.receivingUnit.isNotEmpty) {
        final lugarDestino =
            record.receivingUnit['lugarDestino']?.toString() ?? '';
        final lugarConsulta =
            record.receivingUnit['lugarConsulta']?.toString() ?? '';

        if (lugarDestino.toLowerCase().contains(lowercaseQuery) ||
            lugarConsulta.toLowerCase().contains(lowercaseQuery)) {
          return true;
        }
      }

      return false;
    }).toList();
  }

  // Filtrar registros por criterios específicos
  List<FrapFirestore> filterRecords(
    List<FrapFirestore> records,
    Map<String, dynamic> filters,
  ) {
    return records.where((record) {
      // Filtro por fecha
      if (filters['dateFrom'] != null && filters['dateTo'] != null) {
        final recordDate = record.createdAt;
        final fromDate = DateTime.parse(filters['dateFrom']);
        final toDate = DateTime.parse(filters['dateTo']);

        if (recordDate.isBefore(fromDate) || recordDate.isAfter(toDate)) {
          return false;
        }
      }

      // Filtro por nombre del paciente
      if (filters['patientName'] != null && filters['patientName'].isNotEmpty) {
        if (record.patientInfo.isEmpty) return false;

        final firstName = record.patientInfo['firstName']?.toString() ?? '';
        final lastName =
            record.patientInfo['paternalLastName']?.toString() ?? '';
        final patientName = '$firstName $lastName'.toLowerCase();

        if (!patientName.contains(filters['patientName'].toLowerCase())) {
          return false;
        }
      }

      // Filtro por tipo de urgencia
      if (filters['type'] != null && filters['type'].isNotEmpty) {
        if (record.serviceInfo.isEmpty) return false;

        final tipoUrgencia =
            record.serviceInfo['tipoUrgencia']?.toString() ?? '';
        if (tipoUrgencia != filters['type']) {
          return false;
        }
      }

      // Filtro por estado de sincronización (todos los registros de Firestore están sincronizados)
      if (filters['status'] != null && filters['status'].isNotEmpty) {
        if (filters['status'] == 'Local') {
          return false; // Los registros de Firestore no son locales
        }
      }

      return true;
    }).toList();
  }

  // Obtener sugerencias de búsqueda
  List<String> getSearchSuggestions(List<dynamic> records, String query) {
    if (query.isEmpty) return [];

    final suggestions = <String>{};
    final lowercaseQuery = query.toLowerCase();

    for (final record in records) {
      if (record is FrapFirestore) {
        // Sugerencias de nombres de pacientes
        if (record.patientInfo.isNotEmpty) {
          final firstName = record.patientInfo['firstName']?.toString() ?? '';
          final lastName =
              record.patientInfo['paternalLastName']?.toString() ?? '';
          final fullName = '$firstName $lastName';
          if (fullName.toLowerCase().contains(lowercaseQuery)) {
            suggestions.add(fullName);
          }
        }

        // Sugerencias de tipos de urgencia
        if (record.serviceInfo.isNotEmpty) {
          final tipoUrgencia =
              record.serviceInfo['tipoUrgencia']?.toString() ?? '';
          if (tipoUrgencia.toLowerCase().contains(lowercaseQuery)) {
            suggestions.add(tipoUrgencia);
          }
        }

        // Sugerencias de lugares
        if (record.serviceInfo.isNotEmpty) {
          final lugarOcurrencia =
              record.serviceInfo['lugarOcurrencia']?.toString() ?? '';
          if (lugarOcurrencia.toLowerCase().contains(lowercaseQuery)) {
            suggestions.add(lugarOcurrencia);
          }
        }
      }
    }

    return suggestions.take(5).toList();
  }

  // Ordenar registros
  List<FrapFirestore> sortRecords(List<FrapFirestore> records, String sortBy) {
    final sortedRecords = List<FrapFirestore>.from(records);

    switch (sortBy) {
      case 'Más reciente':
        sortedRecords.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Más antiguo':
        sortedRecords.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'Nombre A-Z':
        sortedRecords.sort((a, b) {
          final aName = a.patientInfo['firstName']?.toString() ?? '';
          final bName = b.patientInfo['firstName']?.toString() ?? '';
          return aName.compareTo(bName);
        });
        break;
      case 'Nombre Z-A':
        sortedRecords.sort((a, b) {
          final aName = a.patientInfo['firstName']?.toString() ?? '';
          final bName = b.patientInfo['firstName']?.toString() ?? '';
          return bName.compareTo(aName);
        });
        break;
    }

    return sortedRecords;
  }

  // Buscar registros avanzada
  List<FrapFirestore> advancedSearch(
    List<FrapFirestore> records,
    Map<String, dynamic> criteria,
  ) {
    List<FrapFirestore> results = records;

    // Aplicar filtros uno por uno
    if (criteria['query'] != null && criteria['query'].isNotEmpty) {
      results = searchRecords(results, criteria['query']);
    }

    if (criteria['filters'] != null) {
      results = filterRecords(results, criteria['filters']);
    }

    if (criteria['sortBy'] != null) {
      results = sortRecords(results, criteria['sortBy']);
    }

    return results;
  }
}
