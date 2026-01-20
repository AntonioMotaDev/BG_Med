import 'package:bg_med/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signature/signature.dart';
import 'dart:convert';

class ServiceInfoFormDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  final Map<String, dynamic>? initialData;

  const ServiceInfoFormDialog({
    super.key,
    required this.onSave,
    this.initialData,
  });

  @override
  State<ServiceInfoFormDialog> createState() => _ServiceInfoFormDialogState();
}

class _ServiceInfoFormDialogState extends State<ServiceInfoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controladores de texto para campos que no son de hora
  final _tiempoEsperaArriboController = TextEditingController();
  final _tiempoEsperaLlegadaController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _tipoServicioEspecifiqueController = TextEditingController();
  final _lugarOcurrenciaEspecifiqueController = TextEditingController();
  final _urgenciaEspecifiqueController = TextEditingController();

  // Variables para los horarios (usando TimeOfDay)
  TimeOfDay? _horaLlamada;
  TimeOfDay? _horaArribo;
  TimeOfDay? _horaLlegada;
  TimeOfDay? _horaTermino;

  // Variables para checkboxes y selecciones
  String _tipoServicioSeleccionado = '';
  String _lugarOcurrenciaSeleccionado = '';
  String _tipoUrgenciaSeleccionado = ''; // Nuevo: Clínico, Trauma, Otro

  // Controlador de firma para consentimiento
  late SignatureController _consentimientoSignatureController;
  String? _consentimientoSignatureData;

  final List<String> _tiposServicio = [
    'Traslado',
    'Urgencia',
    'Estudio',
    'Cuidados Intensivos',
    'Otro',
  ];

  final List<String> _lugaresOcurrencia = [
    'Hogar',
    'Escuela',
    'Trabajo',
    'Recreativo',
    'Vía pública',
    'Otro',
  ];

  final List<String> _tiposUrgencia = ['Clínico', 'Trauma', 'Otro'];

  @override
  void initState() {
    super.initState();
    _initializeSignatureController();
    _initializeForm();
  }

  void _initializeSignatureController() {
    _consentimientoSignatureController = SignatureController(
      penStrokeWidth: 2,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  void _initializeForm() {
    if (widget.initialData != null) {
      final data = widget.initialData!;

      // Campos de texto
      _tiempoEsperaArriboController.text = data['tiempoEsperaArribo'] ?? '';
      _tiempoEsperaLlegadaController.text = data['tiempoEsperaLlegada'] ?? '';
      _ubicacionController.text = data['ubicacion'] ?? '';
      _tipoServicioEspecifiqueController.text =
          data['tipoServicioEspecifique'] ?? '';
      _lugarOcurrenciaEspecifiqueController.text =
          data['lugarOcurrenciaEspecifique'] ?? '';
      _urgenciaEspecifiqueController.text = data['urgenciaEspecifique'] ?? '';

      // Selecciones
      _tipoServicioSeleccionado = data['tipoServicio'] ?? '';
      _lugarOcurrenciaSeleccionado = data['lugarOcurrencia'] ?? '';
      _tipoUrgenciaSeleccionado = data['tipoUrgencia'] ?? '';

      // Firma
      _consentimientoSignatureData = data['consentimientoSignature'];

      // Horarios - inicializar desde datos guardados
      _horaLlamada = _parseTimeFromString(data['horaLlamada']);
      _horaArribo = _parseTimeFromString(data['horaArribo']);
      _horaLlegada = _parseTimeFromString(data['horaLlegada']);
      _horaTermino = _parseTimeFromString(data['horaTermino']);
    }
  }

  // Método auxiliar para parsear tiempo desde string
  TimeOfDay? _parseTimeFromString(dynamic timeData) {
    if (timeData == null || timeData.toString().isEmpty) {
      return null;
    }

    try {
      final timeString = timeData.toString();
      if (timeString.contains(':')) {
        final parts = timeString.split(':');
        if (parts.length >= 2) {
          final hour = int.tryParse(parts[0]);
          final minute = int.tryParse(parts[1]);
          if (hour != null &&
              minute != null &&
              hour >= 0 &&
              hour <= 23 &&
              minute >= 0 &&
              minute <= 59) {
            return TimeOfDay(hour: hour, minute: minute);
          }
        }
      }
    } catch (e) {
      // Si hay error, retornar null
    }
    return null;
  }

  @override
  void dispose() {
    _tiempoEsperaArriboController.dispose();
    _tiempoEsperaLlegadaController.dispose();
    _ubicacionController.dispose();
    _tipoServicioEspecifiqueController.dispose();
    _lugarOcurrenciaEspecifiqueController.dispose();
    _urgenciaEspecifiqueController.dispose();
    _consentimientoSignatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'INFORMACIÓN DEL SERVICIO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Form content
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Horarios
                      _buildHorariosSection(),
                      const SizedBox(height: 24),

                      // Tipo de Servicio
                      _buildTipoServicioSection(),
                      const SizedBox(height: 24),

                      // Tipo de Urgencia (solo si se seleccionó "Urgencia")
                      if (_tipoServicioSeleccionado == 'Urgencia') ...[
                        _buildTipoUrgenciaSection(),
                        const SizedBox(height: 24),
                      ],

                      // Lugar de Ocurrencia
                      _buildLugarOcurrenciaSection(),
                      const SizedBox(height: 24),

                      // Ubicación
                      _buildUbicacionSection(),
                      const SizedBox(height: 24),

                      // Consentimiento de Servicio
                      _buildConsentimientoSection(),
                    ],
                  ),
                ),
              ),
            ),

            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveForm,
                    icon:
                        _isLoading
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Icon(Icons.save),
                    label: Text(
                      _isLoading ? 'Guardando...' : 'Guardar Sección',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorariosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Horarios',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // Primera fila
        Row(
          children: [
            Expanded(
              child: _buildTimeField(
                label: 'Hora de Llamada',
                value: _horaLlamada,
                onChanged: (time) => setState(() => _horaLlamada = time),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTimeField(
                label: 'Hora de Llegada al Lugar',
                value: _horaArribo,
                onChanged: (time) => setState(() => _horaArribo = time),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Segunda fila
        Row(
          children: [
            Expanded(
              child: _buildTimeField(
                label: 'Hora de Llegada al Hospital',
                value: _horaLlegada,
                onChanged: (time) => setState(() => _horaLlegada = time),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTimeField(
                label: 'Hora de Término',
                value: _horaTermino,
                onChanged: (time) => setState(() => _horaTermino = time),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Tiempos de espera
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _tiempoEsperaArriboController,
                decoration: const InputDecoration(
                  labelText: 'Tiempo de Espera Arribo',
                  border: OutlineInputBorder(),
                  suffixText: 'min',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _tiempoEsperaLlegadaController,
                decoration: const InputDecoration(
                  labelText: 'Tiempo de Espera Llegada',
                  border: OutlineInputBorder(),
                  suffixText: 'min',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTipoServicioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de Servicio',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _tiposServicio.map((tipo) {
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 80) / 3,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: CheckboxListTile(
                      title: Text(tipo, style: const TextStyle(fontSize: 12)),
                      value: _tipoServicioSeleccionado == tipo,
                      onChanged: (bool? value) {
                        setState(() {
                          _tipoServicioSeleccionado = value == true ? tipo : '';
                          // Limpiar tipo de urgencia si no es "Urgencia"
                          if (tipo != 'Urgencia') {
                            _tipoUrgenciaSeleccionado = '';
                          }
                        });
                      },
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      dense: true,
                    ),
                  ),
                );
              }).toList(),
        ),
        if (_tipoServicioSeleccionado == 'Otro') ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _tipoServicioEspecifiqueController,
            decoration: const InputDecoration(
              labelText: 'Especifique:',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (_tipoServicioSeleccionado == 'Otro' &&
                  (value == null || value.trim().isEmpty)) {
                return 'Especifique el tipo de servicio';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildTipoUrgenciaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tipo de Urgencia',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _tiposUrgencia.map((tipo) {
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 80) / 3,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue[300]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: CheckboxListTile(
                      title: Text(tipo, style: const TextStyle(fontSize: 12)),
                      value: _tipoUrgenciaSeleccionado == tipo,
                      onChanged: (bool? value) {
                        setState(() {
                          _tipoUrgenciaSeleccionado = value == true ? tipo : '';
                          if (tipo != 'Otro') {
                            _urgenciaEspecifiqueController.clear();
                          }
                        });
                      },
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      dense: true,
                    ),
                  ),
                );
              }).toList(),
        ),
        if (_tipoUrgenciaSeleccionado == 'Otro') ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _urgenciaEspecifiqueController,
            decoration: const InputDecoration(
              labelText: 'Especifique tipo de urgencia:',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (_tipoUrgenciaSeleccionado == 'Otro' &&
                  (value == null || value.trim().isEmpty)) {
                return 'Especifique el tipo de urgencia';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildLugarOcurrenciaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lugar de Ocurrencia',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _lugaresOcurrencia.map((lugar) {
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 80) / 3,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: CheckboxListTile(
                      title: Text(lugar, style: const TextStyle(fontSize: 12)),
                      value: _lugarOcurrenciaSeleccionado == lugar,
                      onChanged: (bool? value) {
                        setState(() {
                          _lugarOcurrenciaSeleccionado =
                              value == true ? lugar : '';
                          if (lugar != 'Otro') {
                            _lugarOcurrenciaEspecifiqueController.clear();
                          }
                        });
                      },
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      dense: true,
                    ),
                  ),
                );
              }).toList(),
        ),
        if (_lugarOcurrenciaSeleccionado == 'Otro') ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _lugarOcurrenciaEspecifiqueController,
            decoration: const InputDecoration(
              labelText: 'Especifique lugar:',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (_lugarOcurrenciaSeleccionado == 'Otro' &&
                  (value == null || value.trim().isEmpty)) {
                return 'Especifique el lugar de ocurrencia';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildUbicacionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ubicación',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _ubicacionController,
          decoration: const InputDecoration(
            labelText: 'Ubicación específica',
            border: OutlineInputBorder(),
            hintText: 'Ej: Calle Principal #123, Colonia Centro',
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildConsentimientoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.gavel, color: Colors.green[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Consentimiento de Servicio',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: const Text(
            'El paciente debe firmar para confirmar que acepta recibir el servicio médico prehospitalario proporcionado por el personal de BG Med.',
            style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
          ),
        ),
        const SizedBox(height: 16),
        _buildSignatureSection(
          title: 'Firma del Paciente o familiar',
          controller: _consentimientoSignatureController,
          base64Data: _consentimientoSignatureData,
          onClear: () {
            _consentimientoSignatureController.clear();
            setState(() {
              _consentimientoSignatureData = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildTimeField({
    required String label,
    required TimeOfDay? value,
    required Function(TimeOfDay?) onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: value ?? TimeOfDay.now(),
        );
        if (time != null) {
          onChanged(time);
          setState(() {}); // Forzar actualización de la UI
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value?.format(context) ?? 'Seleccionar hora',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: value != null ? Colors.black87 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignatureSection({
    required String title,
    required SignatureController controller,
    String? base64Data,
    required VoidCallback onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[400]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Stack(
            children: [
              // Si hay datos base64 guardados, mostrar la imagen
              if (base64Data != null)
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: MemoryImage(_getImageBytesFromBase64(base64Data)),
                      fit: BoxFit.contain,
                    ),
                  ),
                )
              else
                // Área de firma normal
                Signature(
                  controller: controller,
                  backgroundColor: Colors.white,
                ),

              // Texto de instrucción (solo visible cuando está vacía y no hay datos guardados)
              if (controller.isEmpty && base64Data == null)
                const Center(
                  child: Text(
                    'Firme aquí',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),

              // Botón de limpiar
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.clear, size: 16, color: Colors.red),
                    onPressed: () {
                      onClear();
                      // Si hay datos guardados, también los limpiamos
                      if (base64Data != null) {
                        setState(() {
                          _consentimientoSignatureData = null;
                        });
                      }
                    },
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 2, color: Colors.black),
        const SizedBox(height: 4),
        Center(
          child: Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
      ],
    );
  }

  Uint8List _getImageBytesFromBase64(String base64Data) {
    try {
      final base64String = base64Data.split(',').last;
      return base64Decode(base64String);
    } catch (e) {
      return Uint8List(0);
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validar que al menos un campo de tiempo esté completado
    if (_horaLlamada == null &&
        _horaArribo == null &&
        _horaLlegada == null &&
        _horaTermino == null) {
      _showErrorDialog(
        'Campos requeridos',
        'Por favor, complete al menos un campo de tiempo.',
      );
      return;
    }

    // Validar que la firma esté presente
    if (_consentimientoSignatureController.isEmpty &&
        _consentimientoSignatureData == null) {
      _showErrorDialog(
        'Firma requerida',
        'Por favor, complete la firma del consentimiento de servicio.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? signatureData = _consentimientoSignatureData;

      // Si no hay datos guardados pero hay una firma nueva, convertirla
      if (_consentimientoSignatureData == null &&
          _consentimientoSignatureController.isNotEmpty) {
        final signatureBytes =
            await _consentimientoSignatureController.toPngBytes();
        if (signatureBytes != null) {
          signatureData =
              'data:image/png;base64,${base64Encode(signatureBytes)}';
        }
      }

      if (signatureData != null) {
        // Convertir TimeOfDay a string para guardar
        final formData = {
          'horaLlamada': _horaLlamada?.format(context),
          'horaArribo': _horaArribo?.format(context),
          'horaLlegada': _horaLlegada?.format(context),
          'horaTermino': _horaTermino?.format(context),
          'tiempoEsperaArribo': _tiempoEsperaArriboController.text.trim(),
          'tiempoEsperaLlegada': _tiempoEsperaLlegadaController.text.trim(),
          'tipoServicio': _tipoServicioSeleccionado,
          'tipoServicioEspecifique':
              _tipoServicioEspecifiqueController.text.trim(),
          'tipoUrgencia': _tipoUrgenciaSeleccionado,
          'urgenciaEspecifique': _urgenciaEspecifiqueController.text.trim(),
          'lugarOcurrencia': _lugarOcurrenciaSeleccionado,
          'lugarOcurrenciaEspecifique':
              _lugarOcurrenciaEspecifiqueController.text.trim(),
          'ubicacion': _ubicacionController.text.trim(),
          'consentimientoSignature': signatureData,
          'timestamp': DateTime.now().toIso8601String(),
        };

        // Debug logging para ver qué datos se están guardando
        print('=== DEBUG: ServiceInfoFormDialog _saveForm ===');
        print('formData: $formData');
        print('horaLlamada: ${formData['horaLlamada']}');
        print('horaArribo: ${formData['horaArribo']}');
        print('horaLlegada: ${formData['horaLlegada']}');
        print('horaTermino: ${formData['horaTermino']}');
        print('================================');

        widget.onSave(formData);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Información del servicio guardada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Error al procesar la firma');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
