import 'package:bg_med/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bg_med/features/frap/presentation/providers/frap_unified_provider.dart';
import 'package:bg_med/features/frap/presentation/providers/frap_data_provider.dart';

class RegistryInfoFormDialog extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  final Map<String, dynamic>? initialData;

  const RegistryInfoFormDialog({
    super.key,
    required this.onSave,
    this.initialData,
  });

  @override
  ConsumerState<RegistryInfoFormDialog> createState() =>
      _RegistryInfoFormDialogState();
}

class _RegistryInfoFormDialogState
    extends ConsumerState<RegistryInfoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isGeneratingFolio = false;

  // Controladores de texto
  final _convenioController = TextEditingController();
  final _episodioController = TextEditingController();
  final _solicitadoPorController = TextEditingController();
  final _folioController = TextEditingController();

  // Variable para la fecha
  DateTime? _fechaSeleccionada;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.initialData != null) {
      final data = widget.initialData!;

      _convenioController.text = data['convenio'] ?? '';
      _episodioController.text = data['episodio'] ?? '';
      _solicitadoPorController.text = data['solicitadoPor'] ?? '';
      _folioController.text = data['folio'] ?? '';

      // Parsear fecha si existe
      if (data['fecha'] != null) {
        try {
          _fechaSeleccionada = DateTime.parse(data['fecha']);
        } catch (e) {
          _fechaSeleccionada = null;
        }
      }
    }
    // El folio se generará automáticamente usando el provider con iniciales del paciente
  }

  Future<void> _generateAutomaticFolio() async {
    setState(() {
      _isGeneratingFolio = true;
    });

    try {
      // Obtener nombre del paciente desde el provider de datos FRAP
      final frapData = ref.read(frapDataProvider);
      final patientName = _getPatientNameFromData(frapData);

      // Invalidar el provider para generar un nuevo folio
      ref.invalidate(patientFolioProvider(patientName));

      // Generar folio con iniciales del paciente
      final folio = await ref.read(patientFolioProvider(patientName).future);
      setState(() {
        _folioController.text = folio;
        _isGeneratingFolio = false;
      });
    } catch (e) {
      setState(() {
        _isGeneratingFolio = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generando folio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Obtener nombre del paciente desde los datos FRAP
  String _getPatientNameFromData(FrapData frapData) {
    try {
      final patientInfo = frapData.patientInfo;

      // Intentar obtener nombre completo
      final firstName = patientInfo['firstName']?.toString() ?? '';
      final paternalLastName =
          patientInfo['paternalLastName']?.toString() ?? '';
      final maternalLastName =
          patientInfo['maternalLastName']?.toString() ?? '';

      // Construir nombre completo
      final fullName =
          [
            firstName,
            paternalLastName,
            maternalLastName,
          ].where((part) => part.isNotEmpty).join(' ').trim();

      if (fullName.isNotEmpty) {
        return fullName;
      }

      // Si no hay nombre estructurado, buscar en otros campos
      final name = patientInfo['name']?.toString() ?? '';
      if (name.isNotEmpty) {
        return name;
      }

      // Si no hay nombre, usar valor por defecto
      return 'Sin Nombre';
    } catch (e) {
      // print('Error obteniendo nombre del paciente: $e');
      return 'Sin Nombre';
    }
  }

  @override
  void dispose() {
    _convenioController.dispose();
    _episodioController.dispose();
    _solicitadoPorController.dispose();
    _folioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.assignment, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'INFORMACIÓN DEL REGISTRO',
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
                      // Primera fila: Folio (automático)
                      _buildFolioField(),
                      const SizedBox(height: 20),

                      // Segunda fila: Convenio
                      _buildTextField(
                        controller: _convenioController,
                        label: 'Convenio',
                        isRequired: false,
                      ),
                      const SizedBox(height: 20),

                      // Tercera fila: Episodio y Fecha
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _episodioController,
                              label: 'Episodio',
                              isRequired: false,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: _buildDateField()),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Cuarta fila: Solicitado por
                      _buildTextField(
                        controller: _solicitadoPorController,
                        label: 'Solicitado por',
                        isRequired: true,
                      ),
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

  Widget _buildFolioField() {
    return Consumer(
      builder: (context, ref, child) {
        // Obtener nombre del paciente para generar folio
        final frapData = ref.watch(frapDataProvider);
        final patientName = _getPatientNameFromData(frapData);
        final folioAsync = ref.watch(patientFolioProvider(patientName));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Folio *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                if (_isGeneratingFolio)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                IconButton(
                  onPressed:
                      _isGeneratingFolio ? null : _generateAutomaticFolio,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Generar nuevo folio',
                ),
              ],
            ),
            const SizedBox(height: 8),
            folioAsync.when(
              data: (folio) {
                if (_folioController.text.isEmpty) {
                  _folioController.text = folio;
                }
                return TextFormField(
                  controller: _folioController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Folio automático',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    suffixIcon: const Icon(
                      Icons.auto_awesome,
                      color: Colors.blue,
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                );
              },
              loading:
                  () => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[50],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Generando folio...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
              error:
                  (error, stack) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.red[50],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red[600], size: 16),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Error generando folio',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'El folio se genera automáticamente con las iniciales del paciente. Puede regenerarlo si es necesario.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isRequired = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
      ),
      style: const TextStyle(fontSize: 14),
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return '$label es requerido';
        }
        return null;
      },
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fecha *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _fechaSeleccionada != null
                        ? '${_fechaSeleccionada!.day.toString().padLeft(2, '0')}/${_fechaSeleccionada!.month.toString().padLeft(2, '0')}/${_fechaSeleccionada!.year}'
                        : 'Seleccionar fecha',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          _fechaSeleccionada != null
                              ? Colors.black87
                              : Colors.grey[500],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null && picked != _fechaSeleccionada) {
      setState(() {
        _fechaSeleccionada = picked;
      });
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validar fecha requerida
    if (_fechaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha es requerida'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar folio requerido
    if (_folioController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El folio es requerido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final formData = {
        'convenio': _convenioController.text.trim(),
        'episodio': _episodioController.text.trim(),
        'fecha': _fechaSeleccionada!.toIso8601String(),
        'solicitadoPor': _solicitadoPorController.text.trim(),
        'folio': _folioController.text.trim(),
      };

      widget.onSave(formData);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Información del registro guardada'),
            backgroundColor: Colors.green,
          ),
        );
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
}
