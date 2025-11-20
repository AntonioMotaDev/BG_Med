import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'package:bg_med/core/services/frap_unified_service.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// DTO Classes for unified data representation
class PatientDisplayData {
  final String fullName;
  final String address;
  final String age;
  final String sex;
  final String gender;
  final String phone;
  final String insurance;
  final String responsiblePerson;
  final String emergencyContact;
  final String addressDetails;
  final String tipoEntrega;
  final String currentCondition;

  PatientDisplayData({
    required this.fullName,
    required this.address,
    required this.age,
    required this.sex,
    required this.gender,
    required this.phone,
    required this.insurance,
    required this.responsiblePerson,
    required this.emergencyContact,
    required this.addressDetails,
    required this.tipoEntrega,
    required this.currentCondition,
  });
}

class ServiceDisplayData {
  final String ubicacion;
  final String tipoServicio;
  final String tipoServicioEspecifique;
  final String lugarOcurrencia;
  final String lugarOcurrenciaEspecifique;
  final String horaLlamada;
  final String horaArribo;
  final String horaLlegada;
  final String horaTermino;
  final String tiempoEsperaArribo;
  final String tiempoEsperaLlegada;
  final String tiempoTotal;
  final String currentCondition;

  ServiceDisplayData({
    required this.ubicacion,
    required this.tipoServicio,
    required this.tipoServicioEspecifique,
    required this.lugarOcurrencia,
    required this.lugarOcurrenciaEspecifique,
    required this.horaLlamada,
    required this.horaArribo,
    required this.horaLlegada,
    required this.horaTermino,
    required this.tiempoEsperaArribo,
    required this.tiempoEsperaLlegada,
    required this.tiempoTotal,
    required this.currentCondition,
  });
}

class VitalSignsDisplayData {
  final List<String> timeColumns;
  final Map<String, Map<String, String>> vitalSigns;
  final String eva;
  final String llc;
  final String glucosa;
  final String ta;

  VitalSignsDisplayData({
    required this.timeColumns,
    required this.vitalSigns,
    required this.eva,
    required this.llc,
    required this.glucosa,
    required this.ta,
  });
}

class SampleDisplayData {
  final String alergias;
  final String medicamentos;
  final String enfermedades;
  final String horaAlimento;
  final String eventosPrevios;

  SampleDisplayData({
    required this.alergias,
    required this.medicamentos,
    required this.enfermedades,
    required this.horaAlimento,
    required this.eventosPrevios,
  });
}

class ClinicalDisplayData {
  final String currentCondition;
  final bool traumaCraneo;
  final String traumaCraneoEspecifique;
  final bool traumaTorax;
  final String traumaToraxEspecifique;
  final bool traumaAbdomen;
  final String traumaAbdomenEspecifique;
  final bool traumaColumna;
  final String traumaColumnaEspecifique;
  final bool traumaExtremidades;
  final String traumaExtremidadesEspecifique;
  final bool traumaPelvis;
  final String traumaPelvisEspecifique;
  final bool traumaOtros;
  final String traumaOtrosEspecifique;
  final String agenteCausal;
  final String cinematica;
  final String medidaSeguridad;
  final String observaciones;

  ClinicalDisplayData({
    required this.currentCondition,
    this.traumaCraneo = false,
    this.traumaCraneoEspecifique = '',
    this.traumaTorax = false,
    this.traumaToraxEspecifique = '',
    this.traumaAbdomen = false,
    this.traumaAbdomenEspecifique = '',
    this.traumaColumna = false,
    this.traumaColumnaEspecifique = '',
    this.traumaExtremidades = false,
    this.traumaExtremidadesEspecifique = '',
    this.traumaPelvis = false,
    this.traumaPelvisEspecifique = '',
    this.traumaOtros = false,
    this.traumaOtrosEspecifique = '',
    this.agenteCausal = '',
    this.cinematica = '',
    this.medidaSeguridad = '',
    this.observaciones = '',
  });
}

class ManagementDisplayData {
  final Map<String, String> procedures;
  final String oxigenoLitros;
  final List<Map<String, dynamic>> insumos;
  final List<Map<String, dynamic>> personalMedico;
  final String medicamentos;

  ManagementDisplayData({
    required this.procedures,
    required this.oxigenoLitros,
    required this.insumos,
    required this.personalMedico,
    required this.medicamentos,
  });
}

class AmbulanceDisplayData {
  final String numeroAmbulancia;
  final String tipoAmbulancia;
  final String personalABordo;
  final String equipamiento;
  final String observaciones;

  AmbulanceDisplayData({
    required this.numeroAmbulancia,
    required this.tipoAmbulancia,
    required this.personalABordo,
    required this.equipamiento,
    required this.observaciones,
  });
}

class GynecoObstetricDisplayData {
  final String urgencia;
  final String fum;
  final String semanasGestacion;
  final String gesta;
  final String partos;
  final String cesareas;
  final String abortos;
  final String hora;
  final String metodosAnticonceptivos;
  final bool ruidosCardiacosFetales;
  final bool expulsionPlacenta;
  final Map<String, dynamic>? escalasObstetricas;

  GynecoObstetricDisplayData({
    required this.urgencia,
    required this.fum,
    required this.semanasGestacion,
    required this.gesta,
    required this.partos,
    required this.cesareas,
    required this.abortos,
    required this.hora,
    required this.metodosAnticonceptivos,
    required this.ruidosCardiacosFetales,
    required this.expulsionPlacenta,
    this.escalasObstetricas,
  });
}

class PriorityDisplayData {
  final String priority;
  final String pupils;
  final String skinColor;
  final String skin;
  final String temperature;
  final String influence;
  final String especifique;

  PriorityDisplayData({
    required this.priority,
    required this.pupils,
    required this.skinColor,
    required this.skin,
    required this.temperature,
    required this.influence,
    required this.especifique,
  });
}

class RegistryDisplayData {
  final String convenio;
  final String episodio;
  final String solicitadoPor;
  final String folio;
  final String fecha;

  RegistryDisplayData({
    required this.convenio,
    required this.episodio,
    required this.solicitadoPor,
    required this.folio,
    required this.fecha,
  });
}

class ReceptionDisplayData {
  final String receivingDoctor;
  final String? doctorSignature;
  final String originPlace;
  final String consultPlace;
  final String destinationPlace;

  ReceptionDisplayData({
    required this.receivingDoctor,
    this.doctorSignature,
    required this.originPlace,
    required this.consultPlace,
    required this.destinationPlace,
  });
}

class InsumosDisplayData {
  final List<Map<String, dynamic>> insumos;

  InsumosDisplayData({required this.insumos});
}

class FrapPdfDisplayData {
  final PatientDisplayData patient;
  final ServiceDisplayData service;
  final VitalSignsDisplayData vitalSigns;
  final SampleDisplayData sample;
  final ClinicalDisplayData clinical;
  final ManagementDisplayData management;
  final AmbulanceDisplayData ambulance;
  final GynecoObstetricDisplayData gynecoObstetric;
  final PriorityDisplayData priority;
  final RegistryDisplayData registry;
  final ReceptionDisplayData reception;
  final String? consentimientoServicio;
  final InsumosDisplayData insumos;

  FrapPdfDisplayData({
    required this.patient,
    required this.service,
    required this.vitalSigns,
    required this.sample,
    required this.clinical,
    required this.management,
    required this.ambulance,
    required this.gynecoObstetric,
    required this.priority,
    required this.registry,
    required this.reception,
    this.consentimientoServicio,
    required this.insumos,
  });
}

class PdfGeneratorService {
  static final PdfGeneratorService _instance = PdfGeneratorService._internal();
  factory PdfGeneratorService() => _instance;
  PdfGeneratorService._internal();

  // Cached fonts
  pw.Font? _robotoRegular;
  pw.Font? _robotoBold;
  pw.Font? _robotoItalic;
  pw.Font? _robotoBoldItalic;
  bool _fontsLoaded = false;

  // Cached styles - INICIALIZADAS DIRECTAMENTE
  late pw.TextStyle _sectionTitleStyle = pw.TextStyle(
    fontSize: 7,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.blueGrey800,
  );

  late pw.TextStyle _labelStyle = pw.TextStyle(
    fontSize: 5,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.grey800,
  );

  late pw.TextStyle _valueStyle = pw.TextStyle(
    fontSize: 5,
    color: PdfColors.black,
  );

  late pw.TextStyle _headerStyle = pw.TextStyle(
    fontSize: 10,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.blue800,
  );

  late pw.TextStyle _smallStyle = pw.TextStyle(
    fontSize: 4,
    color: PdfColors.black,
  );

  // Debug logging
  final bool _debugLogs = false;

  void _log(String message) {
    if (!_debugLogs) return;
    // ignore: avoid_print
    print('[PDF] $message');
  }

  // Initialize fonts and styles (singleton pattern)
  Future<void> _initializeFontsAndStyles() async {
    if (_fontsLoaded) return;

    try {
      _robotoRegular = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
      );
      _robotoBold = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
      );
      _robotoItalic = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Roboto-Italic.ttf'),
      );
      _robotoBoldItalic = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Roboto-BoldItalic.ttf'),
      );

      // Actualizar estilos con fuentes cargadas
      _sectionTitleStyle = _sectionTitleStyle.copyWith(font: _robotoBold);
      _labelStyle = _labelStyle.copyWith(font: _robotoBold);
      _valueStyle = _valueStyle.copyWith(font: _robotoRegular);
      _headerStyle = _headerStyle.copyWith(font: _robotoBold);
      _smallStyle = _smallStyle.copyWith(font: _robotoRegular);
    } catch (e) {
      _log('Error loading Roboto fonts: $e');
      // Usar fuentes por defecto si falla la carga
      try {
        _robotoRegular = pw.Font.times();
        _robotoBold = pw.Font.timesBold();
        _robotoItalic = pw.Font.timesItalic();
        _robotoBoldItalic = pw.Font.timesBoldItalic();

        // Actualizar estilos con fuentes por defecto
        _sectionTitleStyle = _sectionTitleStyle.copyWith(font: _robotoBold);
        _labelStyle = _labelStyle.copyWith(font: _robotoBold);
        _valueStyle = _valueStyle.copyWith(font: _robotoRegular);
        _headerStyle = _headerStyle.copyWith(font: _robotoBold);
        _smallStyle = _smallStyle.copyWith(font: _robotoRegular);
      } catch (_) {
        _log('Fallback fonts also failed');
        // Los estilos ya están inicializados, así que no hay problema
      }
    }

    _fontsLoaded = true;
    _log('Fonts and styles initialized successfully');
  }

  // Helper to safely decode base64 image data for PDF
  pw.MemoryImage? _getImageFromBase64(String? base64Data) {
    if (base64Data == null || base64Data.isEmpty) {
      return null;
    }
    try {
      final base64String = base64Data.split(',').last;
      final decodedBytes = base64Decode(base64String);
      return pw.MemoryImage(decodedBytes);
    } catch (e) {
      return null;
    }
  }

  /// Generates a PDF document for a given UnifiedFrapRecord.
  Future<Uint8List> generateFrapPdf(UnifiedFrapRecord record) async {
    // Initialize fonts and styles
    await _initializeFontsAndStyles();

    // Preload the human silhouette image
    pw.MemoryImage? silhouetteImage;
    try {
      final imageBytes = await rootBundle.load(
        'assets/images/silueta_humana.jpeg',
      );
      silhouetteImage = pw.MemoryImage(imageBytes.buffer.asUint8List());
    } catch (e) {
      _log('Error loading silhouette image: $e');
    }

    // Crear imagen combinada con silueta y lesiones
    pw.MemoryImage? combinedImage;
    final injuryLocation =
        record.getDetailedInfo()['injuryLocation'] as Map<String, dynamic>?;
    final drawnInjuries = injuryLocation?['drawnInjuries'] as List<dynamic>?;
    if (drawnInjuries != null && drawnInjuries.isNotEmpty) {
      try {
        combinedImage = await _createCombinedSilhouetteImage(
          'assets/images/silueta_humana.jpeg',
          drawnInjuries,
          injuryLocationMap: injuryLocation,
        );
      } catch (e) {
        _log('Error creating combined image: $e');
      }
    }

    // Build unified display data
    final displayData = _buildDisplayData(record);

    final pdf = pw.Document(
      title: 'Registro de Atención Prehospitalaria',
      author: 'BG Med',
    );

    // PAGINA ÚNICA CON TODOS LOS ELEMENTOS
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(10), // Márgenes reducidos
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // HEADER COMPACTO
              _buildCompactHeader(),
              pw.SizedBox(height: 4),

              // SECCIONES EN COLUMNAS
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Columna izquierda
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        _buildCompactTimeTracking(displayData.service),
                        pw.SizedBox(height: 4),
                        _buildCompactServiceInfo(displayData.service),
                        pw.SizedBox(height: 4),
                        _buildCompactPatientInfo(
                          displayData.patient,
                          displayData.service.currentCondition,
                        ),
                        pw.SizedBox(height: 4),
                        _buildCompactPathologicalHistory(displayData.clinical),
                        pw.SizedBox(height: 4),
                        _buildCompactClinicalHistory(displayData.clinical),
                        pw.SizedBox(height: 4),
                        _buildCompactVitalSignsTable(displayData.vitalSigns),
                        pw.SizedBox(height: 4),
                        _buildCompactInjuryLocationSection(
                          record,
                          combinedImage,
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 4),
                  // Columna derecha
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        _buildCompactAdminDetails(displayData.registry),
                        pw.SizedBox(height: 4),
                        _buildCompactManagementSection(displayData.management),
                        pw.SizedBox(height: 4),
                        _buildCompactMedicationsSection(displayData.management),
                        pw.SizedBox(height: 4),
                        // gineco obstetricia solo si es mujer
                        if (displayData.patient.sex.toLowerCase() ==
                            'femenino') ...[
                          _buildCompactGynecoObstetricSection(
                            displayData.gynecoObstetric,
                          ),
                        ],
                        _buildCompactPriorityJustification(
                          displayData.priority,
                        ),
                        pw.SizedBox(height: 4),
                        _buildCompactReceivingUnitSection(
                          displayData.reception,
                        ),
                        _buildCompactAmbulanceSection(displayData.ambulance),
                        pw.SizedBox(height: 4),
                        pw.SizedBox(height: 4),
                        _buildCompactSampleSection(displayData.sample),
                        pw.SizedBox(height: 4),
                        _buildCompactInsumosSection(displayData.insumos),
                        pw.SizedBox(height: 4),
                        _buildCompactPersonalMedicoSection(
                          displayData.management,
                        ),
                        pw.SizedBox(height: 4),
                        _buildCompactReceivingUnitSection(
                          displayData.reception,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // FIRMAS COMPACTAS
              _buildCompactAllSignaturesSection(displayData, record),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // ========== MÉTODOS COMPACTOS ==========

  pw.Widget _buildCompactHeader() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(4),
      child: pw.Center(
        child: pw.Text(
          'REGISTRO DE ATENCIÓN PREHOSPITALARIA',
          style: _headerStyle,
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  pw.Widget _buildCompactAdminDetails(RegistryDisplayData registry) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
      ),
      child: pw.Table(
        border: pw.TableBorder.all(width: 0.3),
        columnWidths: {
          0: const pw.FlexColumnWidth(1),
          1: const pw.FlexColumnWidth(1),
          2: const pw.FlexColumnWidth(1.5),
          3: const pw.FlexColumnWidth(1.5),
          4: const pw.FlexColumnWidth(1.5),
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfColors.grey100),
            children: [
              _buildCompactTableCell('Convenio', isHeader: true),
              _buildCompactTableCell('Episodio', isHeader: true),
              _buildCompactTableCell('Solicitado por', isHeader: true),
              _buildCompactTableCell('Folio', isHeader: true),
              _buildCompactTableCell('Fecha', isHeader: true),
            ],
          ),
          pw.TableRow(
            children: [
              _buildCompactTableCell(registry.convenio),
              _buildCompactTableCell(registry.episodio),
              _buildCompactTableCell(registry.solicitadoPor),
              _buildCompactTableCell(registry.folio),
              _buildCompactTableCell(registry.fecha),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCompactTimeTracking(ServiceDisplayData service) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
      ),
      child: pw.Column(
        children: [
          _buildCompactSectionHeader('INFORMACIÓN DEL SERVICIO'),
          pw.Table(
            border: pw.TableBorder.all(width: 0.3),
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(1),
              5: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _buildCompactTableCell('Hora llamada', isHeader: true),
                  _buildCompactTableCell('Hora arribo', isHeader: true),
                  _buildCompactTableCell('Tiempo espera', isHeader: true),
                  _buildCompactTableCell('Hora llegada', isHeader: true),
                  _buildCompactTableCell('Hora termino', isHeader: true),
                  _buildCompactTableCell('Tiempo espera', isHeader: true),
                ],
              ),
              pw.TableRow(
                children: [
                  _buildCompactTableCell(service.horaLlamada),
                  _buildCompactTableCell(service.horaArribo),
                  _buildCompactTableCell(service.tiempoEsperaArribo),
                  _buildCompactTableCell(service.horaLlegada),
                  _buildCompactTableCell(service.horaTermino),
                  _buildCompactTableCell(service.tiempoEsperaLlegada),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCompactPatientInfo(
    PatientDisplayData patient,
    String currentCondition,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
      ),
      child: pw.Column(
        children: [
          _buildCompactSectionHeader('INFORMACIÓN DEL PACIENTE'),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Table(
              border: null,
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  children: [
                    _buildCompactTableCell(
                      'Nombre: ${patient.fullName}',
                      alignLeft: true,
                    ),
                    _buildCompactTableCell(
                      'Edad: ${patient.age}',
                      alignLeft: true,
                    ),
                    _buildCompactTableCell(
                      'Sexo: ${patient.sex}',
                      alignLeft: true,
                    ),
                    _buildCompactTableCell(
                      'Seguro: ${patient.insurance}',
                      alignLeft: true,
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _buildCompactTableCell(
                      'Dirección: ${patient.address}',
                      alignLeft: true,
                      colSpan: 2,
                    ),
                    _buildCompactTableCell(
                      'Tel: ${patient.phone}',
                      alignLeft: true,
                    ),
                    _buildCompactTableCell(
                      'Responsable: ${patient.responsiblePerson}',
                      alignLeft: true,
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _buildCompactTableCell(
                      'Padecimiento: $currentCondition',
                      alignLeft: true,
                      colSpan: 4,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCompactServiceInfo(ServiceDisplayData service) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
      ),
      child: pw.Column(
        children: [
          _buildCompactSectionHeader('INFORMACIÓN DEL SERVICIO'),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Table(
              border: null,
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  children: [
                    _buildCompactTableCell('Lugar:', alignLeft: true),
                    _buildCompactTableCell(service.ubicacion, alignLeft: true),
                    _buildCompactTableCell('Tipo:', alignLeft: true),
                    _buildCompactTableCell(
                      service.tipoServicio,
                      alignLeft: true,
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _buildCompactTableCell('Ocurrencia:', alignLeft: true),
                    _buildCompactTableCell(
                      (service.lugarOcurrencia.isEmpty ||
                              service.lugarOcurrencia == 'Otro')
                          ? service.lugarOcurrenciaEspecifique
                          : service.lugarOcurrencia,
                      alignLeft: true,
                    ),
                    _buildCompactTableCell('Especifique:', alignLeft: true),
                    _buildCompactTableCell(
                      service.tipoServicioEspecifique,
                      alignLeft: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCompactInjuryLocationSection(
    UnifiedFrapRecord record,
    pw.MemoryImage? combinedImage,
  ) {
    final injuryLocation =
        record.getDetailedInfo()['injuryLocation'] as Map<String, dynamic>?;
    final drawnInjuries = injuryLocation?['drawnInjuries'] as List<dynamic>?;

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
      ),
      child: pw.Column(
        children: [
          _buildCompactSectionHeader('LOCALIZACIÓN DE LESIONES'),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Imagen de lesiones
                pw.Container(
                  width: 80,
                  height: 120,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                  ),
                  child:
                      combinedImage != null
                          ? pw.Image(combinedImage, fit: pw.BoxFit.contain)
                          : pw.Center(
                            child: pw.Text('No hay imagen', style: _smallStyle),
                          ),
                ),
                pw.SizedBox(width: 8),
                // Información de lesiones
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Lesiones registradas: ${drawnInjuries?.length ?? 0}',
                        style: _valueStyle,
                      ),
                      if (drawnInjuries != null &&
                          drawnInjuries.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Text('Tipos:', style: _labelStyle),
                        pw.Wrap(
                          spacing: 2,
                          runSpacing: 1,
                          children: _getInjuryTypesSummary(drawnInjuries),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<pw.Widget> _getInjuryTypesSummary(List<dynamic> drawnInjuries) {
    Map<int, int> injuriesByType = {};
    for (final injury in drawnInjuries) {
      final injuryType = injury['injuryType'] as int? ?? 0;
      injuriesByType[injuryType] = (injuriesByType[injuryType] ?? 0) + 1;
    }

    return injuriesByType.entries.map((entry) {
      final typeName = _getInjuryTypeName(entry.key);
      return pw.Container(
        margin: const pw.EdgeInsets.only(right: 4, bottom: 2),
        padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(2),
          border: pw.Border.all(color: PdfColors.grey400, width: 0.3),
        ),
        child: pw.Text(
          '${typeName.substring(0, 3)}: ${entry.value}',
          style: _smallStyle,
        ),
      );
    }).toList();
  }

  pw.Widget _buildCompactManagementSection(ManagementDisplayData management) {
    final selectedProcedures =
        management.procedures.entries
            .where((entry) => entry.value == 'Sí')
            .map((entry) => _getProcedureName(entry.key))
            .toList();

    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
      ),
      child: pw.Column(
        children: [
          _buildCompactSectionHeader('MANEJO'),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child:
                selectedProcedures.isNotEmpty
                    ? pw.Wrap(
                      spacing: 3,
                      runSpacing: 2,
                      children:
                          selectedProcedures
                              .map(
                                (procedure) => pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 3,
                                    vertical: 1,
                                  ),
                                  decoration: pw.BoxDecoration(
                                    color: PdfColors.grey100,
                                    borderRadius: pw.BorderRadius.circular(2),
                                    border: pw.Border.all(
                                      color: PdfColors.grey400,
                                      width: 0.3,
                                    ),
                                  ),
                                  child: pw.Text(procedure, style: _valueStyle),
                                ),
                              )
                              .toList(),
                    )
                    : pw.Text(
                      'No se seleccionaron procedimientos',
                      style: _valueStyle,
                    ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCompactMedicationsSection(ManagementDisplayData management) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
      ),
      child: pw.Column(
        children: [
          _buildCompactSectionHeader('MEDICAMENTOS'),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text(
              management.medicamentos.isNotEmpty
                  ? management.medicamentos
                  : 'No se registraron medicamentos',
              style: _valueStyle,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCompactPathologicalHistory(ClinicalDisplayData clinical) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
      ),
      child: pw.Column(
        children: [
          _buildCompactSectionHeader('ANTECEDENTES PATOLÓGICOS'),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (clinical.traumaCraneo)
                  _buildCompactDetailRow(
                    'Trauma Cráneo:',
                    clinical.traumaCraneoEspecifique.isEmpty
                        ? 'Sí'
                        : clinical.traumaCraneoEspecifique,
                  ),
                if (clinical.traumaTorax)
                  _buildCompactDetailRow(
                    'Trauma Tórax:',
                    clinical.traumaToraxEspecifique.isEmpty
                        ? 'Sí'
                        : clinical.traumaToraxEspecifique,
                  ),
                if (clinical.traumaAbdomen)
                  _buildCompactDetailRow(
                    'Trauma Abdomen:',
                    clinical.traumaAbdomenEspecifique.isEmpty
                        ? 'Sí'
                        : clinical.traumaAbdomenEspecifique,
                  ),
                if (clinical.agenteCausal.isNotEmpty)
                  _buildCompactDetailRow(
                    'Agente Causal:',
                    clinical.agenteCausal,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCompactClinicalHistory(ClinicalDisplayData clinical) {
    final traumasList = <String>[];
    if (clinical.traumaCraneo) traumasList.add('Cráneo');
    if (clinical.traumaTorax) traumasList.add('Tórax');
    if (clinical.traumaAbdomen) traumasList.add('Abdomen');
    if (clinical.traumaColumna) traumasList.add('Columna');
    if (clinical.traumaExtremidades) traumasList.add('Extremidades');
    if (clinical.traumaPelvis) traumasList.add('Pelvis');
    if (clinical.traumaOtros) traumasList.add('Otros');

    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
      ),
      child: pw.Column(
        children: [
          _buildCompactSectionHeader('HISTORIA CLÍNICA'),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (traumasList.isNotEmpty) ...[
                  pw.Text('Traumas:', style: _labelStyle),
                  pw.Wrap(
                    spacing: 2,
                    runSpacing: 1,
                    children:
                        traumasList
                            .map(
                              (trauma) => pw.Container(
                                padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 3,
                                  vertical: 1,
                                ),
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.grey100,
                                  borderRadius: pw.BorderRadius.circular(2),
                                  border: pw.Border.all(
                                    color: PdfColors.grey400,
                                    width: 0.3,
                                  ),
                                ),
                                child: pw.Text(trauma, style: _smallStyle),
                              ),
                            )
                            .toList(),
                  ),
                  pw.SizedBox(height: 4),
                ],
                _buildCompactDetailRow('Agente causal:', clinical.agenteCausal),
                _buildCompactDetailRow('Cinemática:', clinical.cinematica),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCompactSampleSection(SampleDisplayData sample) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
      ),
      child: pw.Column(
        children: [
          _buildCompactSectionHeader('EVALUACIÓN SAMPLE'),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildCompactDetailRow('Alergias (S):', sample.alergias),
                _buildCompactDetailRow(
                  'Medicamentos (M):',
                  sample.medicamentos,
                ),
                _buildCompactDetailRow(
                  'Antecedentes (A):',
                  sample.enfermedades,
                ),
                _buildCompactDetailRow(
                  'Última ingesta (L):',
                  sample.horaAlimento,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCompactVitalSignsTable(VitalSignsDisplayData vitalSigns) {
    final vitalSignsList = ['T/A', 'FC', 'FR', 'Temp.', 'Sat. O2', 'Glasgow'];

    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
      ),
      child: pw.Column(
        children: [
          _buildCompactSectionHeader('SIGNOS VITALES'),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Table(
              border: pw.TableBorder.all(width: 0.2),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.2),
                ...Map.fromIterable(
                  List.generate(
                    vitalSigns.timeColumns.length,
                    (index) => index + 1,
                  ),
                  key: (index) => index,
                  value: (index) => const pw.FlexColumnWidth(1.0),
                ),
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(2),
                      child: pw.Text(
                        'Signo',
                        style: _smallStyle.copyWith(
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    ...vitalSigns.timeColumns
                        .map(
                          (time) => pw.Padding(
                            padding: const pw.EdgeInsets.all(2),
                            child: pw.Text(
                              time,
                              style: _smallStyle.copyWith(
                                fontWeight: pw.FontWeight.bold,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                        )
                        .toList(),
                  ],
                ),
                // Data rows
                ...vitalSignsList.map((vitalSign) {
                  final vitalData = vitalSigns.vitalSigns[vitalSign] ?? {};
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text(vitalSign, style: _smallStyle),
                      ),
                      ...vitalSigns.timeColumns
                          .map(
                            (time) => pw.Padding(
                              padding: const pw.EdgeInsets.all(2),
                              child: pw.Text(
                                vitalData[time] ?? '-',
                                style: _smallStyle,
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                          )
                          .toList(),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
          // Valores adicionales compactos
          pw.Container(
            padding: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey400, width: 0.3),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildCompactVitalItem('EVA', '${vitalSigns.eva}/10'),
                _buildCompactVitalItem('LLC', '${vitalSigns.llc}s'),
                _buildCompactVitalItem('Glucosa', '${vitalSigns.glucosa}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCompactPriorityJustification(PriorityDisplayData priority) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
      ),
      child: pw.Column(
        children: [
          _buildCompactSectionHeader('JUSTIFICACIÓN DE PRIORIDAD'),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildPriorityOption('Rojo', priority.priority == 'Rojo'),
                _buildPriorityOption(
                  'Amarillo',
                  priority.priority == 'Amarillo',
                ),
                _buildPriorityOption('Verde', priority.priority == 'Verde'),
                _buildPriorityOption('Negro', priority.priority == 'Negro'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCompactGynecoObstetricSection(
    GynecoObstetricDisplayData gynecoObstetric,
  ) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
      ),
      child: pw.Column(
        children: [
          _buildCompactSectionHeader('URGENCIAS GINECO-OBSTÉTRICAS'),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Table(
              border: null,
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  children: [
                    _buildCompactTableCell(
                      'FUM: ${gynecoObstetric.fum}',
                      alignLeft: true,
                    ),
                    _buildCompactTableCell(
                      'Semanas: ${gynecoObstetric.semanasGestacion}',
                      alignLeft: true,
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _buildCompactTableCell(
                      'Gesta: ${gynecoObstetric.gesta}',
                      alignLeft: true,
                    ),
                    _buildCompactTableCell(
                      'Partos: ${gynecoObstetric.partos}',
                      alignLeft: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCompactInsumosSection(InsumosDisplayData insumos) {
    if (insumos.insumos.isEmpty) return pw.SizedBox();

    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
      ),
      child: pw.Column(
        children: [
          _buildCompactSectionHeader('INSUMOS UTILIZADOS'),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Wrap(
              spacing: 4,
              runSpacing: 2,
              children:
                  insumos.insumos
                      .map(
                        (insumo) => pw.Text(
                          '${insumo['cantidad']}x ${insumo['articulo']}',
                          style: _valueStyle,
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCompactPersonalMedicoSection(
    ManagementDisplayData management,
  ) {
    if (management.personalMedico.isEmpty) return pw.SizedBox();

    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
      ),
      child: pw.Column(
        children: [
          _buildCompactSectionHeader('PERSONAL MÉDICO'),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Column(
              children:
                  management.personalMedico
                      .map(
                        (personal) => pw.Text(
                          '${personal['nombre']} - ${personal['especialidad']}',
                          style: _valueStyle,
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCompactReceivingUnitSection(ReceptionDisplayData reception) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
      ),
      child: pw.Column(
        children: [
          _buildCompactSectionHeader('UNIDAD MÉDICA QUE RECIBE'),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text(
              'Lugar de origen: ${reception.originPlace}',
              style: _valueStyle,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCompactAmbulanceSection(AmbulanceDisplayData ambulance) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
      ),
      child: pw.Column(
        children: [
          _buildCompactSectionHeader('AMBULANCIA'),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text(
              '${ambulance.numeroAmbulancia} - ${ambulance.tipoAmbulancia}',
              style: _valueStyle,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCompactAllSignaturesSection(
    FrapPdfDisplayData displayData,
    UnifiedFrapRecord record,
  ) {
    final hasConsentimiento =
        displayData.consentimientoServicio != null &&
        displayData.consentimientoServicio!.isNotEmpty;
    final hasDoctorSignature =
        displayData.reception.doctorSignature != null &&
        displayData.reception.doctorSignature!.isNotEmpty;

    final attentionNegative =
        record.getDetailedInfo()['attentionNegative'] as Map<String, dynamic>?;
    final hasPatientSignature = attentionNegative?['patientSignature'] != null;
    final hasWitnessSignature = attentionNegative?['witnessSignature'] != null;

    if (!hasConsentimiento &&
        !hasDoctorSignature &&
        !hasPatientSignature &&
        !hasWitnessSignature) {
      return pw.SizedBox();
    }

    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
      ),
      child: pw.Column(
        children: [
          _buildCompactSectionHeader('FIRMAS Y CONSENTIMIENTOS'),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children:
                  [
                    if (hasConsentimiento)
                      _buildCompactSignature(
                        'Consentimiento',
                        displayData.consentimientoServicio!,
                      ),
                    if (hasPatientSignature)
                      _buildCompactSignature(
                        'Paciente',
                        attentionNegative!['patientSignature']!,
                      ),
                    if (hasWitnessSignature)
                      _buildCompactSignature(
                        'Testigo',
                        attentionNegative!['witnessSignature']!,
                      ),
                    if (hasDoctorSignature)
                      _buildCompactSignature(
                        'Médico',
                        displayData.reception.doctorSignature!,
                      ),
                  ].where((element) => element != null).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ========== MÉTODOS AUXILIARES COMPACTOS ==========

  pw.Widget _buildCompactSectionHeader(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey300,
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.black, width: 0.3),
        ),
      ),
      child: pw.Text(
        title,
        style: _sectionTitleStyle,
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildCompactTableCell(
    String text, {
    bool isHeader = false,
    bool alignLeft = false,
    int colSpan = 1,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(2),
      child: pw.Text(
        text,
        style: isHeader ? _labelStyle : _valueStyle,
        textAlign: alignLeft ? pw.TextAlign.left : pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildCompactDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 40, child: pw.Text(label, style: _labelStyle)),
          pw.Expanded(child: pw.Text(value, style: _valueStyle)),
        ],
      ),
    );
  }

  pw.Widget _buildCompactVitalItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: _smallStyle.copyWith(fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(value, style: _smallStyle),
      ],
    );
  }

  pw.Widget _buildPriorityOption(String label, bool isSelected) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 8,
          height: 8,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 0.5),
            color: isSelected ? PdfColors.black : PdfColors.white,
          ),
        ),
        pw.SizedBox(width: 2),
        pw.Text(label, style: _smallStyle),
      ],
    );
  }

  pw.Widget _buildCompactSignature(String label, String base64Data) {
    final signatureImage = _getImageFromBase64(base64Data);
    return pw.Column(
      children: [
        if (signatureImage != null)
          pw.Container(
            width: 40,
            height: 20,
            child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
          )
        else
          pw.Container(
            width: 40,
            height: 20,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
            ),
            child: pw.Center(child: pw.Text('N/A', style: _smallStyle)),
          ),
        pw.SizedBox(height: 2),
        pw.Text(label, style: _smallStyle),
      ],
    );
  }

  String _getProcedureName(String key) {
    final procedures = {
      'viaAerea': 'Vía aérea',
      'canalizacion': 'Canalización',
      'inmovilizacion': 'Inmovilización',
      'monitor': 'Monitor',
      'rcpBasica': 'RCP Básica',
      'oxigeno': 'Oxígeno',
    };
    return procedures[key] ?? key;
  }

  // ========== MÉTODOS ORIGINALES (se mantienen para funcionalidad) ==========
  Future<pw.MemoryImage> _createCombinedSilhouetteImage(
    String silhouettePath,
    List<dynamic> drawnInjuries, {
    Map<String, dynamic>? injuryLocationMap,
  }) async {
    // Cargar imagen de silueta
    final silhouetteBytes = await rootBundle.load(silhouettePath);
    final codec = await ui.instantiateImageCodec(
      silhouetteBytes.buffer.asUint8List(),
    );
    final frame = await codec.getNextFrame();
    final silhouetteImage = frame.image;

    // Tamaño fijo para el PDF (igual al que usa el widget en modo PDF)
    final pdfWidth = 300.0;
    final pdfHeight = 450.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Calcular el rectángulo donde se dibuja la imagen (igual que en el widget)
    final currentImageRect = _calculateImageRectForPDF(
      Size(pdfWidth, pdfHeight),
      silhouetteImage,
    );

    // Dibujar fondo blanco
    canvas.drawRect(
      Rect.fromLTWH(0, 0, pdfWidth, pdfHeight),
      Paint()..color = Colors.white,
    );

    // Dibujar silueta humana en el rectángulo calculado
    canvas.drawImageRect(
      silhouetteImage,
      Rect.fromLTWH(
        0,
        0,
        silhouetteImage.width.toDouble(),
        silhouetteImage.height.toDouble(),
      ),
      currentImageRect,
      Paint()
        ..filterQuality = FilterQuality.high
        ..isAntiAlias = true,
    );

    // Obtener información del tamaño original usado en la app
    final originalImageSize =
        injuryLocationMap?['originalImageSize'] != null
            ? Size(
              (injuryLocationMap!['originalImageSize']['width'] as num)
                  .toDouble(),
              (injuryLocationMap['originalImageSize']['height'] as num)
                  .toDouble(),
            )
            : null;

    final originalImageRect =
        injuryLocationMap?['originalImageRect'] != null
            ? Rect.fromLTWH(
              (injuryLocationMap!['originalImageRect']['left'] as num)
                  .toDouble(),
              (injuryLocationMap['originalImageRect']['top'] as num).toDouble(),
              (injuryLocationMap['originalImageRect']['width'] as num)
                  .toDouble(),
              (injuryLocationMap['originalImageRect']['height'] as num)
                  .toDouble(),
            )
            : null;

    // Dibujar lesiones transformadas (igual que en el widget)
    for (final injury in drawnInjuries) {
      _drawInjuryForPDF(
        canvas,
        injury,
        currentImageRect,
        originalImageSize,
        originalImageRect,
      );
    }

    final picture = recorder.endRecording();
    final combinedImage = await picture.toImage(
      pdfWidth.toInt(),
      pdfHeight.toInt(),
    );
    final byteData = await combinedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return pw.MemoryImage(byteData!.buffer.asUint8List());
  }

  // Método idéntico al del widget para calcular el rectángulo de la imagen
  Rect _calculateImageRectForPDF(Size canvasSize, ui.Image image) {
    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();
    final imageAspectRatio = imageWidth / imageHeight;

    // Calcular dimensiones manteniendo aspect ratio
    double targetWidth, targetHeight;

    if (canvasSize.width / canvasSize.height > imageAspectRatio) {
      // Ajustar por altura
      targetHeight = canvasSize.height;
      targetWidth = targetHeight * imageAspectRatio;
    } else {
      // Ajustar por anchura
      targetWidth = canvasSize.width;
      targetHeight = targetWidth / imageAspectRatio;
    }

    // Centrar la imagen
    final offsetX = (canvasSize.width - targetWidth) / 2;
    final offsetY = (canvasSize.height - targetHeight) / 2;

    return Rect.fromLTWH(offsetX, offsetY, targetWidth, targetHeight);
  }

  // Método para dibujar lesiones que replica exactamente la lógica del widget
  void _drawInjuryForPDF(
    Canvas canvas,
    dynamic injury,
    Rect currentImageRect,
    Size? originalImageSize,
    Rect? originalImageRect,
  ) {
    final points = injury['points'] as List<dynamic>? ?? [];
    if (points.isEmpty) return;

    final injuryType = injury['injuryType'] as int? ?? 0;
    final color = _getInjuryTypeFlutterColor(injuryType);

    // Transformar las coordenadas (igual que en el widget)
    final transformedPoints = _transformInjuryPointsForPDF(
      points,
      currentImageRect,
      originalImageSize,
      originalImageRect,
    );

    final paint =
        Paint()
          ..color = color
          ..strokeCap = StrokeCap.round
          ..strokeWidth =
              2.0 // Un poco más delgado para PDF
          ..style = PaintingStyle.stroke;

    // Dibujar el path de la lesión
    if (transformedPoints.isNotEmpty) {
      final path = Path();
      path.moveTo(transformedPoints.first.dx, transformedPoints.first.dy);

      for (int i = 1; i < transformedPoints.length; i++) {
        path.lineTo(transformedPoints[i].dx, transformedPoints[i].dy);
      }

      canvas.drawPath(path, paint);

      // Dibujar círculos en cada punto
      final circlePaint =
          Paint()
            ..color = color
            ..style = PaintingStyle.fill;

      for (final point in transformedPoints) {
        canvas.drawCircle(point, 1.5, circlePaint); // Más pequeños para PDF
      }

      // Dibujar el número de la lesión (opcional, para mantener consistencia)
      final number = injuryType + 1;

      final paragraphBuilder =
          ui.ParagraphBuilder(
              ui.ParagraphStyle(
                fontSize: 10, // Más pequeño para PDF
                fontFamily: 'Roboto',
              ),
            )
            ..pushStyle(ui.TextStyle(color: Colors.white))
            ..addText('$number');

      final paragraph = paragraphBuilder.build();
      paragraph.layout(ui.ParagraphConstraints(width: 20));

      // Dibujar círculo de fondo para el número
      canvas.drawCircle(
        transformedPoints.first,
        8.0, // Más pequeño para PDF
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );

      // Dibujar borde blanco
      canvas.drawCircle(
        transformedPoints.first,
        8.0,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );

      // Dibujar el texto centrado
      canvas.drawParagraph(
        paragraph,
        Offset(
          transformedPoints.first.dx - paragraph.minIntrinsicWidth / 2,
          transformedPoints.first.dy - paragraph.height / 2,
        ),
      );
    }
  }

  // Método idéntico al del widget para transformar puntos
  List<Offset> _transformInjuryPointsForPDF(
    List<dynamic> points,
    Rect currentImageRect,
    Size? originalImageSize,
    Rect? originalImageRect,
  ) {
    // Convertir puntos dinámicos a Offset
    final originalPoints =
        points.map((point) {
          return Offset(
            (point['dx'] as num).toDouble(),
            (point['dy'] as num).toDouble(),
          );
        }).toList();

    // Si tenemos tanto el rectángulo original como el tamaño original, hacer transformación precisa
    if (originalImageRect != null && originalImageSize != null) {
      return originalPoints.map((point) {
        // Convertir coordenadas del canvas original a coordenadas relativas dentro de la imagen original (0.0 - 1.0)
        final relativeX =
            (point.dx - originalImageRect.left) / originalImageRect.width;
        final relativeY =
            (point.dy - originalImageRect.top) / originalImageRect.height;

        // Convertir coordenadas relativas al espacio actual de la imagen
        final transformedX =
            currentImageRect.left + (relativeX * currentImageRect.width);
        final transformedY =
            currentImageRect.top + (relativeY * currentImageRect.height);

        // Asegurar que están dentro de los límites de la imagen actual
        final clampedX = transformedX.clamp(
          currentImageRect.left,
          currentImageRect.right,
        );
        final clampedY = transformedY.clamp(
          currentImageRect.top,
          currentImageRect.bottom,
        );

        return Offset(clampedX, clampedY);
      }).toList();
    }

    // Si tenemos solo el tamaño original pero no el rectángulo, asumir que la imagen ocupaba todo el canvas
    if (originalImageSize != null) {
      return originalPoints.map((point) {
        // Convertir coordenadas del canvas original a coordenadas relativas (0.0 - 1.0)
        final relativeX = point.dx / originalImageSize.width;
        final relativeY = point.dy / originalImageSize.height;

        // Convertir coordenadas relativas al espacio actual de la imagen
        final transformedX =
            currentImageRect.left + (relativeX * currentImageRect.width);
        final transformedY =
            currentImageRect.top + (relativeY * currentImageRect.height);

        // Asegurar que están dentro de los límites de la imagen
        final clampedX = transformedX.clamp(
          currentImageRect.left,
          currentImageRect.right,
        );
        final clampedY = transformedY.clamp(
          currentImageRect.top,
          currentImageRect.bottom,
        );

        return Offset(clampedX, clampedY);
      }).toList();
    }

    // Si no tenemos información original, usar el método de fallback (igual que en el widget)
    if (originalPoints.isEmpty) return originalPoints;

    // Encontrar los límites de los puntos originales
    double minX = originalPoints.first.dx;
    double maxX = originalPoints.first.dx;
    double minY = originalPoints.first.dy;
    double maxY = originalPoints.first.dy;

    for (final point in originalPoints) {
      minX = point.dx < minX ? point.dx : minX;
      maxX = point.dx > maxX ? point.dx : maxX;
      minY = point.dy < minY ? point.dy : minY;
      maxY = point.dy > maxY ? point.dy : maxY;
    }

    final originalWidth = maxX - minX;
    final originalHeight = maxY - minY;

    return originalPoints.map((point) {
      // Normalizar las coordenadas dentro del área de la imagen actual
      final normalizedX =
          originalWidth > 0 ? (point.dx - minX) / originalWidth : 0.5;
      final normalizedY =
          originalHeight > 0 ? (point.dy - minY) / originalHeight : 0.5;

      final transformedX =
          currentImageRect.left + (normalizedX * currentImageRect.width);
      final transformedY =
          currentImageRect.top + (normalizedY * currentImageRect.height);

      // Asegurar que están dentro de los límites de la imagen
      final clampedX = transformedX.clamp(
        currentImageRect.left,
        currentImageRect.right,
      );
      final clampedY = transformedY.clamp(
        currentImageRect.top,
        currentImageRect.bottom,
      );

      return Offset(clampedX, clampedY);
    }).toList();
  }

  Color _getInjuryTypeFlutterColor(int typeIndex) {
    const colors = [
      Colors.red, // Hemorragia
      Color(0xFF8D6E63), // Herida (brown)
      Colors.purple, // Contusión
      Colors.orange, // Fractura
      Colors.yellow, // Luxación/Esguince
      Colors.pink, // Objeto extraño
      Colors.deepOrange, // Quemadura
      Colors.green, // Picadura/Mordedura
      Colors.indigo, // Edema/Hematoma
      Colors.grey, // Otro
    ];

    if (typeIndex >= 0 && typeIndex < colors.length) {
      return colors[typeIndex];
    }
    return Colors.grey;
  }

  /*Future<pw.MemoryImage> _createCombinedSilhouetteImage(
  String silhouettePath,
  List<dynamic> drawnInjuries, {
  Map<String, dynamic>? injuryLocationMap,
}) async {
  // Obtener el tamaño ORIGINAL de la imagen de silueta
  final silhouetteBytes = await rootBundle.load(silhouettePath);
  final codec = await ui.instantiateImageCodec(silhouetteBytes.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  final silhouetteImage = frame.image;

  final originalWidth = silhouetteImage.width.toDouble();
  final originalHeight = silhouetteImage.height.toDouble();

  // Usar el tamaño ORIGINAL de la imagen, no valores fijos
  double width = originalWidth;
  double height = originalHeight;
  
  // Si tenemos información del tamaño original usado en la app, usarla
  if (injuryLocationMap != null && injuryLocationMap['originalImageSize'] != null) {
    final size = injuryLocationMap['originalImageSize'];
    final appWidth = (size['width']?.toDouble() ?? originalWidth);
    final appHeight = (size['height']?.toDouble() ?? originalHeight);
    
    // Si el tamaño usado en la app es diferente al de la imagen original,
    // necesitamos escalar las coordenadas
    if (appWidth != originalWidth || appHeight != originalHeight) {
      width = appWidth;
      height = appHeight;
    }
  }

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  // Dibujar la imagen de silueta escalada al tamaño usado en la app
  final dstRect = Rect.fromLTWH(0, 0, width, height);
  canvas.drawImageRect(
    silhouetteImage,
    Rect.fromLTWH(0, 0, originalWidth, originalHeight),
    dstRect,
    Paint(),
  );

  // Calcular factores de escala si las dimensiones son diferentes
  final scaleX = width / originalWidth;
  final scaleY = height / originalHeight;

  // Dibujar los puntos en las coordenadas CORRECTAS
  for (final injury in drawnInjuries) {
    final points = injury['points'] as List<dynamic>? ?? [];
    final injuryType = injury['injuryType'] as int? ?? 0;
    final color = _getInjuryTypeFlutterColor(injuryType);
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (final point in points) {
      final originalDx = (point['dx'] as num?)?.toDouble() ?? 0.0;
      final originalDy = (point['dy'] as num?)?.toDouble() ?? 0.0;
      
      // Las coordenadas ya están en el espacio de la imagen mostrada en la app
      // Solo necesitamos asegurarnos de que la imagen de fondo esté en el mismo espacio
      canvas.drawCircle(Offset(originalDx, originalDy), 8, paint); // Radio reducido para PDF
    }
  }

  final picture = recorder.endRecording();
  final combinedImage = await picture.toImage(width.toInt(), height.toInt());
  final byteData = await combinedImage.toByteData(format: ui.ImageByteFormat.png);

  return pw.MemoryImage(byteData!.buffer.asUint8List());
}

  Color _getInjuryTypeFlutterColor(int injuryType) {
    switch (injuryType) {
      case 0: return Colors.red;
      case 1: return Colors.orange;
      case 2: return Colors.purple;
      case 3: return Colors.brown;
      case 4: return Colors.blue;
      case 5: return Colors.yellow;
      case 6: return Colors.green;
      case 7: return Colors.pink;
      case 8: return Colors.cyan;
      case 9: return Colors.grey;
      default: return Colors.red;
    }
  }

  */
  String _getInjuryTypeName(int typeIndex) {
    const injuryTypes = [
      'Hemorragia',
      'Herida',
      'Contusión',
      'Fractura',
      'Luxación/Esguince',
      'Objeto extraño',
      'Quemadura',
      'Picadura/Mordedura',
      'Edema/Hematoma',
      'Otro',
    ];

    if (typeIndex >= 0 && typeIndex < injuryTypes.length) {
      return injuryTypes[typeIndex];
    }
    return 'Tipo desconocido';
  }

  String _getAccidentTypeName(String key) {
    final accidentTypes = {
      'atropellado': 'Atropellado',
      'lxPorCaida': 'Lx por caída',
      'intoxicacion': 'Intoxicación',
      'amputacion': 'Amputación',
      'choque': 'Choque',
      'agresion': 'Agresión',
      'hpab': 'HPAB',
      'hpaf': 'HPAF',
      'volcadura': 'Volcadura',
      'quemadura': 'Quemadura',
      'otroTipo': 'Otro tipo',
    };
    return accidentTypes[key] ?? key;
  }

  // ========== MÉTODOS DE CONSTRUCCIÓN DE DATOS ==========

  FrapPdfDisplayData _buildDisplayData(UnifiedFrapRecord record) {
    final detailedInfo = record.getDetailedInfo();

    return FrapPdfDisplayData(
      patient: _buildPatientDisplayData(record, detailedInfo),
      service: _buildServiceDisplayData(record, detailedInfo),
      vitalSigns: _buildVitalSignsDisplayData(record, detailedInfo),
      sample: _buildSampleDisplayData(record, detailedInfo),
      clinical: _buildClinicalDisplayData(record, detailedInfo),
      management: _buildManagementDisplayData(record, detailedInfo),
      ambulance: _buildAmbulanceDisplayData(record, detailedInfo),
      gynecoObstetric: _buildGynecoObstetricDisplayData(record, detailedInfo),
      priority: _buildPriorityDisplayData(record, detailedInfo),
      registry: _buildRegistryDisplayData(record, detailedInfo),
      reception: _buildReceptionDisplayData(record, detailedInfo),
      consentimientoServicio: _getConsentimientoServicio(record),
      insumos: _buildInsumosDisplayData(record),
    );
  }

  PatientDisplayData _buildPatientDisplayData(
    UnifiedFrapRecord record,
    Map<String, dynamic> detailedInfo,
  ) {
    _log('Building patient display data...');

    if (record.localRecord != null) {
      final patient = record.localRecord!.patient;
      _log('Using local patient data');
      return PatientDisplayData(
        fullName:
            '${patient.firstName} ${patient.paternalLastName} ${patient.maternalLastName}',
        address: patient.address,
        age: patient.age.toString(),
        sex: (patient.sex.isNotEmpty ? patient.sex : patient.gender),
        gender: patient.gender,
        phone: patient.phone,
        insurance: patient.insurance,
        responsiblePerson: patient.responsiblePerson ?? 'N/A',
        emergencyContact: 'N/A',
        addressDetails: patient.addressDetails,
        tipoEntrega: patient.tipoEntrega,
        currentCondition: patient.currentCondition ?? 'N/A',
      );
    } else {
      _log('Using cloud patient data');
      final patientInfo =
          detailedInfo['patientInfo'] as Map<String, dynamic>? ?? {};
      return PatientDisplayData(
        fullName: record.patientName,
        address: record.patientAddress,
        age: record.patientAge.toString(),
        sex: patientInfo['sex']?.toString() ?? record.patientGender,
        gender: patientInfo['gender']?.toString() ?? 'N/A',
        phone: patientInfo['phone']?.toString() ?? 'N/A',
        insurance: patientInfo['insurance']?.toString() ?? 'N/A',
        responsiblePerson:
            patientInfo['responsiblePerson']?.toString() ?? 'N/A',
        emergencyContact: patientInfo['emergencyContact']?.toString() ?? 'N/A',
        addressDetails: patientInfo['addressDetails']?.toString() ?? 'N/A',
        tipoEntrega: patientInfo['tipoEntrega']?.toString() ?? 'N/A',
        currentCondition: patientInfo['currentCondition']?.toString() ?? 'N/A',
      );
    }
  }

  ServiceDisplayData _buildServiceDisplayData(
    UnifiedFrapRecord record,
    Map<String, dynamic> detailedInfo,
  ) {
    final serviceInfo =
        detailedInfo['serviceInfo'] as Map<String, dynamic>? ?? {};
    return ServiceDisplayData(
      ubicacion: serviceInfo['ubicacion']?.toString() ?? 'N/A',
      tipoServicio: serviceInfo['tipoServicio']?.toString() ?? 'N/A',
      tipoServicioEspecifique:
          serviceInfo['tipoServicioEspecifique']?.toString() ?? 'N/A',
      lugarOcurrencia: serviceInfo['lugarOcurrencia']?.toString() ?? 'N/A',
      lugarOcurrenciaEspecifique:
          serviceInfo['lugarOcurrenciaEspecifique']?.toString() ?? 'N/A',
      horaLlamada: serviceInfo['horaLlamada']?.toString() ?? 'N/A',
      horaArribo: serviceInfo['horaArribo']?.toString() ?? 'N/A',
      horaLlegada: serviceInfo['horaLlegada']?.toString() ?? 'N/A',
      horaTermino: serviceInfo['horaTermino']?.toString() ?? 'N/A',
      tiempoEsperaArribo:
          serviceInfo['tiempoEsperaArribo']?.toString() ?? 'N/A',
      tiempoEsperaLlegada:
          serviceInfo['tiempoEsperaLlegada']?.toString() ?? 'N/A',
      tiempoTotal: _calculateTotalTime(serviceInfo),
      currentCondition: serviceInfo['currentCondition']?.toString() ?? 'N/A',
    );
  }

  VitalSignsDisplayData _buildVitalSignsDisplayData(
    UnifiedFrapRecord record,
    Map<String, dynamic> detailedInfo,
  ) {
    List<String> timeColumns = [];
    Map<String, Map<String, String>> vitalSigns = {};

    if (record.localRecord != null) {
      final physicalExam = record.localRecord!.physicalExam;
      timeColumns = physicalExam.timeColumns;
      vitalSigns = physicalExam.vitalSignsData.map(
        (key, value) => MapEntry(key, value.map((k, v) => MapEntry(k, v))),
      );

      return VitalSignsDisplayData(
        timeColumns: timeColumns,
        vitalSigns: vitalSigns,
        eva: physicalExam.eva,
        llc: physicalExam.llc,
        glucosa: physicalExam.glucosa,
        ta: physicalExam.ta,
      );
    } else {
      final physicalExam =
          detailedInfo['physicalExam'] as Map<String, dynamic>? ?? {};
      final tc = physicalExam['timeColumns'];
      if (tc is List) {
        timeColumns = tc.map((e) => e.toString()).toList();
      }

      const vitalSignKeys = [
        'T/A',
        'FC',
        'FR',
        'Temp.',
        'Sat. O2',
        'LLC',
        'Glu',
        'Glasgow',
      ];
      for (final key in vitalSignKeys) {
        final data = physicalExam[key];
        if (data is Map) {
          vitalSigns[key] = data.map(
            (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
          );
        }
      }

      return VitalSignsDisplayData(
        timeColumns: timeColumns,
        vitalSigns: vitalSigns,
        eva: physicalExam['eva']?.toString() ?? 'N/A',
        llc: physicalExam['llc']?.toString() ?? 'N/A',
        glucosa: physicalExam['glucosa']?.toString() ?? 'N/A',
        ta: physicalExam['ta']?.toString() ?? 'N/A',
      );
    }
  }

  SampleDisplayData _buildSampleDisplayData(
    UnifiedFrapRecord record,
    Map<String, dynamic> detailedInfo,
  ) {
    if (record.localRecord != null) {
      final physicalExam = record.localRecord!.physicalExam;
      return SampleDisplayData(
        alergias: physicalExam.sampleAlergias,
        medicamentos: physicalExam.sampleMedicamentos,
        enfermedades: physicalExam.sampleEnfermedades,
        horaAlimento: physicalExam.sampleHoraAlimento,
        eventosPrevios: physicalExam.sampleEventosPrevios,
      );
    } else {
      final physicalExam =
          detailedInfo['physicalExam'] as Map<String, dynamic>? ?? {};
      return SampleDisplayData(
        alergias: physicalExam['sampleAlergias']?.toString() ?? 'N/A',
        medicamentos: physicalExam['sampleMedicamentos']?.toString() ?? 'N/A',
        enfermedades: physicalExam['sampleEnfermedades']?.toString() ?? 'N/A',
        horaAlimento: physicalExam['sampleHoraAlimento']?.toString() ?? 'N/A',
        eventosPrevios:
            physicalExam['sampleEventosPrevios']?.toString() ?? 'N/A',
      );
    }
  }

  ClinicalDisplayData _buildClinicalDisplayData(
    UnifiedFrapRecord record,
    Map<String, dynamic> detailedInfo,
  ) {
    if (record.localRecord != null) {
      final clinicalHistory = record.localRecord!.clinicalHistory;
      return ClinicalDisplayData(
        currentCondition: '',
        traumaCraneo: clinicalHistory.traumaCraneo,
        traumaCraneoEspecifique: clinicalHistory.traumaCraneoEspecifique,
        traumaTorax: clinicalHistory.traumaTorax,
        traumaToraxEspecifique: clinicalHistory.traumaToraxEspecifique,
        traumaAbdomen: clinicalHistory.traumaAbdomen,
        traumaAbdomenEspecifique: clinicalHistory.traumaAbdomenEspecifique,
        traumaColumna: clinicalHistory.traumaColumna,
        traumaColumnaEspecifique: clinicalHistory.traumaColumnaEspecifique,
        traumaExtremidades: clinicalHistory.traumaExtremidades,
        traumaExtremidadesEspecifique:
            clinicalHistory.traumaExtremidadesEspecifique,
        traumaPelvis: clinicalHistory.traumaPelvis,
        traumaPelvisEspecifique: clinicalHistory.traumaPelvisEspecifique,
        traumaOtros: clinicalHistory.traumaOtros,
        traumaOtrosEspecifique: clinicalHistory.traumaOtrosEspecifique,
        agenteCausal: clinicalHistory.agenteCausal,
        cinematica: clinicalHistory.cinematica,
        medidaSeguridad: clinicalHistory.medidaSeguridad,
        observaciones: clinicalHistory.observaciones,
      );
    } else {
      return ClinicalDisplayData(
        currentCondition: '',
        traumaCraneo:
            _getFromClinicalHistory(detailedInfo, 'traumaCraneo') == 'true',
        traumaCraneoEspecifique: _getFromClinicalHistory(
          detailedInfo,
          'traumaCraneoEspecifique',
        ),
        traumaTorax:
            _getFromClinicalHistory(detailedInfo, 'traumaTorax') == 'true',
        traumaToraxEspecifique: _getFromClinicalHistory(
          detailedInfo,
          'traumaToraxEspecifique',
        ),
        traumaAbdomen:
            _getFromClinicalHistory(detailedInfo, 'traumaAbdomen') == 'true',
        traumaAbdomenEspecifique: _getFromClinicalHistory(
          detailedInfo,
          'traumaAbdomenEspecifique',
        ),
        traumaColumna:
            _getFromClinicalHistory(detailedInfo, 'traumaColumna') == 'true',
        traumaColumnaEspecifique: _getFromClinicalHistory(
          detailedInfo,
          'traumaColumnaEspecifique',
        ),
        traumaExtremidades:
            _getFromClinicalHistory(detailedInfo, 'traumaExtremidades') ==
            'true',
        traumaExtremidadesEspecifique: _getFromClinicalHistory(
          detailedInfo,
          'traumaExtremidadesEspecifique',
        ),
        traumaPelvis:
            _getFromClinicalHistory(detailedInfo, 'traumaPelvis') == 'true',
        traumaPelvisEspecifique: _getFromClinicalHistory(
          detailedInfo,
          'traumaPelvisEspecifique',
        ),
        traumaOtros:
            _getFromClinicalHistory(detailedInfo, 'traumaOtros') == 'true',
        traumaOtrosEspecifique: _getFromClinicalHistory(
          detailedInfo,
          'traumaOtrosEspecifique',
        ),
        agenteCausal: _getFromClinicalHistory(detailedInfo, 'agenteCausal'),
        cinematica: _getFromClinicalHistory(detailedInfo, 'cinematica'),
        medidaSeguridad: _getFromClinicalHistory(
          detailedInfo,
          'medidaSeguridad',
        ),
        observaciones: _getFromClinicalHistory(detailedInfo, 'observaciones'),
      );
    }
  }

  ManagementDisplayData _buildManagementDisplayData(
    UnifiedFrapRecord record,
    Map<String, dynamic> detailedInfo,
  ) {
    final management =
        detailedInfo['management'] as Map<String, dynamic>? ?? {};
    final insumos = _getInsumos(record);
    final personalMedico = _getPersonalMedico(record);

    return ManagementDisplayData(
      procedures: {
        'viaAerea': _boolToString(management['viaAerea']),
        'canalizacion': _boolToString(management['canalizacion']),
        'inmovilizacion': _boolToString(management['inmovilizacion']),
        'monitor': _boolToString(management['monitor']),
        'rcpBasica': _boolToString(management['rcpBasica']),
        'oxigeno': _boolToString(management['oxigeno']),
      },
      oxigenoLitros: management['ltMin']?.toString() ?? 'N/A',
      insumos: insumos,
      personalMedico: personalMedico,
      medicamentos:
          detailedInfo['medications']?['medications']?.toString() ?? 'N/A',
    );
  }

  AmbulanceDisplayData _buildAmbulanceDisplayData(
    UnifiedFrapRecord record,
    Map<String, dynamic> detailedInfo,
  ) {
    final ambulance = detailedInfo['ambulance'] as Map<String, dynamic>? ?? {};
    return AmbulanceDisplayData(
      numeroAmbulancia: ambulance['numero']?.toString() ?? 'N/A',
      tipoAmbulancia: ambulance['tipo']?.toString() ?? 'N/A',
      personalABordo: ambulance['personalABordo']?.toString() ?? 'N/A',
      equipamiento: ambulance['equipamiento']?.toString() ?? 'N/A',
      observaciones: ambulance['observaciones']?.toString() ?? 'N/A',
    );
  }

  GynecoObstetricDisplayData _buildGynecoObstetricDisplayData(
    UnifiedFrapRecord record,
    Map<String, dynamic> detailedInfo,
  ) {
    final gynecoObstetric =
        detailedInfo['gynecoObstetric'] as Map<String, dynamic>? ?? {};
    final escalas = _getEscalasObstetricas(record);

    return GynecoObstetricDisplayData(
      urgencia: gynecoObstetric['urgencia']?.toString() ?? 'N/A',
      fum: gynecoObstetric['fum']?.toString() ?? 'N/A',
      semanasGestacion:
          gynecoObstetric['semanasGestacion']?.toString() ?? 'N/A',
      gesta: gynecoObstetric['gesta']?.toString() ?? 'N/A',
      partos: gynecoObstetric['partos']?.toString() ?? 'N/A',
      cesareas: gynecoObstetric['cesareas']?.toString() ?? 'N/A',
      abortos: gynecoObstetric['abortos']?.toString() ?? 'N/A',
      hora: gynecoObstetric['hora']?.toString() ?? 'N/A',
      metodosAnticonceptivos:
          gynecoObstetric['metodosAnticonceptivos']?.toString() ?? 'N/A',
      ruidosCardiacosFetales: gynecoObstetric['ruidosCardiacosFetales'] == true,
      expulsionPlacenta: gynecoObstetric['expulsionPlacenta'] == true,
      escalasObstetricas: escalas,
    );
  }

  PriorityDisplayData _buildPriorityDisplayData(
    UnifiedFrapRecord record,
    Map<String, dynamic> detailedInfo,
  ) {
    final priority =
        detailedInfo['priorityJustification'] as Map<String, dynamic>? ?? {};
    return PriorityDisplayData(
      priority: priority['priority']?.toString() ?? 'N/A',
      pupils: priority['pupils']?.toString() ?? 'N/A',
      skinColor: priority['skinColor']?.toString() ?? 'N/A',
      skin: priority['skin']?.toString() ?? 'N/A',
      temperature: priority['temperature']?.toString() ?? 'N/A',
      influence: priority['influence']?.toString() ?? 'N/A',
      especifique: priority['especifique']?.toString() ?? 'N/A',
    );
  }

  RegistryDisplayData _buildRegistryDisplayData(
    UnifiedFrapRecord record,
    Map<String, dynamic> detailedInfo,
  ) {
    final registryInfo =
        detailedInfo['registryInfo'] as Map<String, dynamic>? ?? {};
    return RegistryDisplayData(
      convenio: registryInfo['convenio']?.toString() ?? 'N/A',
      episodio: registryInfo['episodio']?.toString() ?? 'N/A',
      solicitadoPor: registryInfo['solicitadoPor']?.toString() ?? 'N/A',
      folio: registryInfo['folio']?.toString() ?? 'N/A',
      fecha: (registryInfo['fecha']?.toString()?.split('T')?.first ?? 'N/A'),
    );
  }

  ReceptionDisplayData _buildReceptionDisplayData(
    UnifiedFrapRecord record,
    Map<String, dynamic> detailedInfo,
  ) {
    final reception =
        detailedInfo['patientReception'] as Map<String, dynamic>? ?? {};
    final receivingUnit =
        detailedInfo['receivingUnit'] as Map<String, dynamic>? ?? {};

    return ReceptionDisplayData(
      receivingDoctor: reception['receivingDoctor']?.toString() ?? 'N/A',
      doctorSignature: reception['doctorSignature']?.toString(),
      originPlace: receivingUnit['originPlace']?.toString() ?? 'N/A',
      consultPlace: receivingUnit['consultPlace']?.toString() ?? 'N/A',
      destinationPlace: receivingUnit['destinationPlace']?.toString() ?? 'N/A',
    );
  }

  InsumosDisplayData _buildInsumosDisplayData(UnifiedFrapRecord record) {
    if (record.localRecord != null) {
      return InsumosDisplayData(
        insumos:
            record.localRecord!.insumos
                .map(
                  (insumo) => {
                    'cantidad': insumo.cantidad,
                    'articulo': insumo.articulo,
                  },
                )
                .toList(),
      );
    }
    final insumosData =
        record.getDetailedInfo()['insumos'] as List<dynamic>? ?? [];
    return InsumosDisplayData(
      insumos: insumosData.map((item) => item as Map<String, dynamic>).toList(),
    );
  }

  // Helper methods
  String _calculateTotalTime(Map<String, dynamic> serviceInfo) {
    final inicio = serviceInfo['horaLlamada']?.toString();
    final fin = serviceInfo['horaTermino']?.toString();
    if (inicio != null && fin != null && inicio != 'N/A' && fin != 'N/A') {
      return 'Calculado';
    }
    return 'N/A';
  }

  Map<String, bool> _extractAccidentTypes(Map<String, dynamic> detailedInfo) {
    final clinicalHistory =
        detailedInfo['clinicalHistory'] as Map<String, dynamic>? ?? {};
    return {
      'atropellado':
          clinicalHistory['atropellado'] == true ||
          clinicalHistory['atropellado'] == 'Sí',
      'lxPorCaida':
          clinicalHistory['lxPorCaida'] == true ||
          clinicalHistory['lxPorCaida'] == 'Sí',
      'intoxicacion':
          clinicalHistory['intoxicacion'] == true ||
          clinicalHistory['intoxicacion'] == 'Sí',
      'amputacion':
          clinicalHistory['amputacion'] == true ||
          clinicalHistory['amputacion'] == 'Sí',
      'choque':
          clinicalHistory['choque'] == true ||
          clinicalHistory['choque'] == 'Sí',
      'agresion':
          clinicalHistory['agresion'] == true ||
          clinicalHistory['agresion'] == 'Sí',
      'hpab':
          clinicalHistory['hpab'] == true || clinicalHistory['hpab'] == 'Sí',
      'hpaf':
          clinicalHistory['hpaf'] == true || clinicalHistory['hpaf'] == 'Sí',
      'volcadura':
          clinicalHistory['volcadura'] == true ||
          clinicalHistory['volcadura'] == 'Sí',
      'quemadura':
          clinicalHistory['quemadura'] == true ||
          clinicalHistory['quemadura'] == 'Sí',
      'otroTipo':
          clinicalHistory['otroTipo'] == true ||
          clinicalHistory['otroTipo'] == 'Sí',
    };
  }

  String _getFromClinicalHistory(
    Map<String, dynamic> detailedInfo,
    String key,
  ) {
    final clinicalHistory =
        detailedInfo['clinicalHistory'] as Map<String, dynamic>? ?? {};
    final value = clinicalHistory[key];
    if (value == true) return 'Sí';
    if (value == false) return 'No';
    return value?.toString() ?? 'N/A';
  }

  String _boolToString(dynamic value) {
    if (value == true) return 'Sí';
    if (value == false) return 'No';
    return value?.toString() ?? 'N/A';
  }

  String _getConsentimientoServicio(UnifiedFrapRecord record) {
    if (record.localRecord != null) {
      return record.localRecord!.consentimientoServicio;
    }
    final serviceInfo =
        record.getDetailedInfo()['serviceInfo'] as Map<String, dynamic>?;
    final sig = serviceInfo?['consentimientoSignature']?.toString();
    if (sig != null && sig.trim().isNotEmpty) return sig;
    return serviceInfo?['consentimientoServicio']?.toString() ?? '';
  }

  List<Map<String, dynamic>> _getInsumos(UnifiedFrapRecord record) {
    if (record.localRecord != null) {
      return record.localRecord!.insumos
          .map(
            (insumo) => {
              'cantidad': insumo.cantidad,
              'articulo': insumo.articulo,
            },
          )
          .toList();
    }
    final details = record.getDetailedInfo();
    final management = details['management'] as Map<String, dynamic>?;
    final list =
        (management?['insumos'] as List?) ?? (details['insumos'] as List?);
    if (list is List) {
      return list
          .where((e) => e != null)
          .map(
            (e) =>
                e is Map
                    ? {
                      'cantidad': e['cantidad']?.toString() ?? '',
                      'articulo': e['articulo']?.toString() ?? '',
                    }
                    : {'cantidad': '', 'articulo': e.toString()},
          )
          .toList();
    }
    return [];
  }

  List<Map<String, dynamic>> _getPersonalMedico(UnifiedFrapRecord record) {
    if (record.localRecord != null) {
      return record.localRecord!.personalMedico
          .map(
            (p) => {
              'nombre': p.nombre,
              'especialidad': p.especialidad,
              'cedula': p.cedula,
            },
          )
          .toList();
    }
    final details = record.getDetailedInfo();
    final management = details['management'] as Map<String, dynamic>?;
    final list =
        (management?['personalMedico'] as List?) ??
        (details['personalMedico'] as List?);
    if (list is List) {
      return list
          .where((e) => e != null)
          .map(
            (e) =>
                e is Map
                    ? {
                      'nombre': e['nombre']?.toString() ?? '',
                      'especialidad': e['especialidad']?.toString() ?? '',
                      'cedula': e['cedula']?.toString() ?? '',
                    }
                    : {
                      'nombre': e.toString(),
                      'especialidad': '',
                      'cedula': '',
                    },
          )
          .toList();
    }
    return [];
  }

  Map<String, dynamic>? _getEscalasObstetricas(UnifiedFrapRecord record) {
    if (record.localRecord != null &&
        record.localRecord!.escalasObstetricas != null) {
      final e = record.localRecord!.escalasObstetricas!;
      return {
        'silvermanAnderson': e.silvermanAnderson,
        'apgar': e.apgar,
        'frecuenciaCardiacaFetal': e.frecuenciaCardiacaFetal,
        'contracciones': e.contracciones,
      };
    }
    final details = record.getDetailedInfo();
    final gyneco = details['gynecoObstetric'] as Map<String, dynamic>?;
    if (gyneco != null) {
      final silver = gyneco['silvermanAnderson'];
      final apgar = gyneco['apgar'];
      final fcf = gyneco['frecuenciaCardiacaFetal'];
      final cont = gyneco['contracciones'];
      if (silver != null || apgar != null || fcf != null || cont != null) {
        return {
          'silvermanAnderson': silver,
          'apgar': apgar,
          'frecuenciaCardiacaFetal': fcf,
          'contracciones': cont,
        };
      }
    }
    final esc = details['escalasObstetricas'] as Map<String, dynamic>?;
    return esc;
  }

  // ========== MÉTODOS DE ARCHIVO Y COMPARTIR ==========

  /// Saves the PDF to a file and returns the file path
  Future<String> savePdfToFile(UnifiedFrapRecord record) async {
    final pdfBytes = await generateFrapPdf(record);
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'FRAP_${record.patientName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  /// Shares the PDF file
  Future<void> sharePdf(UnifiedFrapRecord record) async {
    try {
      final filePath = await savePdfToFile(record);
      await Share.shareXFiles([
        XFile(filePath),
      ], text: 'Registro de Atención Prehospitalaria - ${record.patientName}');
    } catch (e) {
      throw Exception('Error al compartir el PDF: $e');
    }
  }

  /// Prints the PDF
  Future<void> printPdf(UnifiedFrapRecord record) async {
    try {
      final pdfBytes = await generateFrapPdf(record);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'Registro de Atención Prehospitalaria - ${record.patientName}',
      );
    } catch (e) {
      throw Exception('Error al imprimir el PDF: $e');
    }
  }
}
