import 'package:bg_med/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class PhysicalExamFormDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  final Map<String, dynamic>? initialData;

  const PhysicalExamFormDialog({
    super.key,
    required this.onSave,
    this.initialData,
  });

  @override
  State<PhysicalExamFormDialog> createState() => _PhysicalExamFormDialogState();
}

class _PhysicalExamFormDialogState extends State<PhysicalExamFormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Lista de signos vitales
  final List<String> _vitalSigns = [
    'EVA',
    'T/A',
    'FC',
    'FR',
    'Temp.',
    'Sat. O2',
    'LLC',
    'Glu',
    'Glasgow',
  ];

  // Lista de horas/columnas dinámicas
  List<String> _timeColumns = ['Hora 1', 'Hora 2', 'Hora 3'];

  // Mapa para almacenar los valores de cada signo vital por hora
  Map<String, Map<String, TextEditingController>> _controllers = {};

  // Controladores de texto adicionales
  final _llcController = TextEditingController();
  final _glucosaController = TextEditingController();
  final _taController = TextEditingController();
  final _sampleAlergiasController = TextEditingController();
  final _sampleMedicamentosController = TextEditingController();
  final _sampleEnfermedadesController = TextEditingController();
  final _sampleHoraAlimentoController = TextEditingController();
  final _sampleEventosPreviosController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeForm();
  }

  void _initializeControllers() {
    for (String vitalSign in _vitalSigns) {
      _controllers[vitalSign] = {};
      for (String timeColumn in _timeColumns) {
        _controllers[vitalSign]![timeColumn] = TextEditingController();
      }
    }
  }

  void _initializeForm() {
    if (widget.initialData != null) {
      final data = widget.initialData!;

      // Cargar columnas de tiempo si existen
      if (data['timeColumns'] != null) {
        _timeColumns = List<String>.from(data['timeColumns']);
        _initializeControllers(); // Re-inicializar controladores con las nuevas columnas
      }

      // Cargar valores de los signos vitales
      for (String vitalSign in _vitalSigns) {
        if (data[vitalSign] != null) {
          Map<String, dynamic> vitalData = data[vitalSign];
          for (String timeColumn in _timeColumns) {
            if (vitalData[timeColumn] != null) {
              _controllers[vitalSign]![timeColumn]?.text =
                  vitalData[timeColumn];
            }
          }
        }
      }

      // Campos existentes
      _llcController.text = data['llc'] ?? '';
      _glucosaController.text = data['glucosa'] ?? '';
      _taController.text = data['ta'] ?? '';
      _sampleAlergiasController.text = data['sampleAlergias'] ?? '';
      _sampleMedicamentosController.text = data['sampleMedicamentos'] ?? '';
      _sampleEnfermedadesController.text = data['sampleEnfermedades'] ?? '';
      _sampleHoraAlimentoController.text = data['sampleHoraAlimento'] ?? '';
      _sampleEventosPreviosController.text = data['sampleEventosPrevios'] ?? '';
    }
  }

  void _addTimeColumn() {
    setState(() {
      int newColumnNumber = _timeColumns.length + 1;
      String newColumn = 'Hora $newColumnNumber';
      _timeColumns.add(newColumn);

      // Agregar controladores para la nueva columna
      for (String vitalSign in _vitalSigns) {
        _controllers[vitalSign]![newColumn] = TextEditingController();
      }
    });
  }

  void _removeTimeColumn(String columnToRemove) {
    if (_timeColumns.length > 1) {
      setState(() {
        _timeColumns.remove(columnToRemove);

        // Remover controladores de la columna eliminada
        for (String vitalSign in _vitalSigns) {
          _controllers[vitalSign]![columnToRemove]?.dispose();
          _controllers[vitalSign]!.remove(columnToRemove);
        }

        // Renumerar las columnas para mantener la secuencia correcta
        _renumberTimeColumns();
      });
    }
  }

  void _renumberTimeColumns() {
    // Crear nueva lista con numeración correcta
    List<String> newTimeColumns = [];
    for (int i = 0; i < _timeColumns.length; i++) {
      newTimeColumns.add('Hora ${i + 1}');
    }

    // Si los nombres han cambiado, actualizar controladores
    if (!_areListsEqual(_timeColumns, newTimeColumns)) {
      Map<String, Map<String, TextEditingController>> newControllers = {};

      for (String vitalSign in _vitalSigns) {
        newControllers[vitalSign] = {};
        for (int i = 0; i < _timeColumns.length; i++) {
          String oldColumn = _timeColumns[i];
          String newColumn = newTimeColumns[i];

          // Transferir el controlador existente al nuevo nombre
          newControllers[vitalSign]![newColumn] =
              _controllers[vitalSign]![oldColumn]!;
        }
      }

      _controllers = newControllers;
      _timeColumns = newTimeColumns;
    }
  }

  bool _areListsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    // Dispose todos los controladores
    for (String vitalSign in _vitalSigns) {
      for (String timeColumn in _timeColumns) {
        _controllers[vitalSign]![timeColumn]?.dispose();
      }
    }
    _llcController.dispose();
    _glucosaController.dispose();
    _taController.dispose();
    _sampleAlergiasController.dispose();
    _sampleMedicamentosController.dispose();
    _sampleEnfermedadesController.dispose();
    _sampleHoraAlimentoController.dispose();
    _sampleEventosPreviosController.dispose();
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
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header mejorado
            _buildHeader(),

            // Form content
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sección 1: Evaluación del paciente
                      _buildSectionHeader(
                        'EVALUACIÓN DEL PACIENTE',
                        Icons.assessment,
                        'Complete los datos básicos de evaluación',
                      ),
                      const SizedBox(height: 24),

                      // LLC, Glucosa y TA
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField(
                              controller: _llcController,
                              label: 'LLC',
                              hint: 'Segundos',
                              suffix: 'seg',
                              icon: Icons.timer,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInputField(
                              controller: _glucosaController,
                              label: 'Glucosa',
                              hint: 'Nivel',
                              suffix: 'mg/dl',
                              icon: Icons.water_drop,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // TA
                      _buildInputField(
                        controller: _taController,
                        label: 'TA',
                        hint: 'Presión',
                        suffix: 'mm/Hg',
                        icon: Icons.favorite,
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: 32),

                      // Sección 2: SAMPLE
                      _buildSectionHeader(
                        'SAMPLE (Nemotecnia)',
                        Icons.medical_services,
                        'Complete la evaluación SAMPLE del paciente',
                      ),
                      const SizedBox(height: 16),

                      // Info card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[50]!, Colors.blue[100]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'SAMPLE - Evaluación Prehospitalaria',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'S: Signs & Symptoms (Signos y síntomas)\n'
                              'A: Allergies (Alergias)\n'
                              'M: Medications (Medicamentos)\n'
                              'P: Past medical history (Historia médica previa)\n'
                              'L: Last oral intake (Última ingesta oral)\n'
                              'E: Events leading to illness/injury (Eventos previos)',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue[800],
                                height: 1.4,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Campos SAMPLE
                      _buildInputField(
                        controller: _sampleAlergiasController,
                        label: 'A: Alergias',
                        hint: 'Ej: Penicilina, látex, etc.',
                        icon: Icons.warning,
                        maxLines: 2,
                      ),

                      const SizedBox(height: 16),

                      _buildInputField(
                        controller: _sampleMedicamentosController,
                        label: 'M: Medicamentos',
                        hint: 'Ej: Paracetamol, Ibuprofeno, etc.',
                        icon: Icons.medication,
                        maxLines: 2,
                      ),

                      const SizedBox(height: 16),

                      _buildInputField(
                        controller: _sampleEnfermedadesController,
                        label: 'P: Enfermedades patológicas',
                        hint: 'Ej: Diabetes, hipertensión, etc.',
                        icon: Icons.medical_information,
                        maxLines: 2,
                      ),

                      const SizedBox(height: 16),

                      _buildInputField(
                        controller: _sampleHoraAlimentoController,
                        label: 'L: Hora de último alimento',
                        hint: 'Ej: 14:30',
                        icon: Icons.access_time,
                      ),

                      const SizedBox(height: 16),

                      _buildInputField(
                        controller: _sampleEventosPreviosController,
                        label: 'E: Eventos previos',
                        hint: 'Ej: Caída, accidente, síntomas, etc.',
                        icon: Icons.event_note,
                        maxLines: 3,
                      ),

                      const SizedBox(height: 32),

                      // Sección 3: Signos Vitales
                      _buildSectionHeader(
                        'SIGNOS VITALES',
                        Icons.monitor_heart,
                        'Registre los signos vitales en diferentes momentos',
                      ),
                      const SizedBox(height: 16),

                      // Controls bar para la tabla
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.schedule,
                                color: AppTheme.primaryBlue,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Mediciones por hora',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Agregue más columnas según necesite',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _addTimeColumn,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Agregar Hora'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
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

                      const SizedBox(height: 16),

                      // Tabla de signos vitales
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: _buildVitalSignsTable(),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.health_and_safety,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EXPLORACIÓN FÍSICA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Evaluación completa del paciente',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? suffix,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixText: suffix,
          prefixIcon: Icon(icon, color: AppTheme.primaryBlue),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          labelStyle: TextStyle(color: Colors.grey[600]),
          hintStyle: TextStyle(color: Colors.grey[400]),
        ),
      ),
    );
  }

  Widget _buildVitalSignsTable() {
    const double columnWidth = 120.0;
    const double labelWidth = 100.0;

    return Container(
      child: Column(
        children: [
          // Header row mejorado
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue,
                  AppTheme.primaryBlue.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                // Empty cell for vital signs labels
                Container(
                  width: labelWidth,
                  height: 60,
                  alignment: Alignment.center,
                  child: const Text(
                    'Signos\nVitales',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                // Time column headers
                ..._timeColumns.map(
                  (timeColumn) =>
                      _buildTimeColumnHeader(timeColumn, columnWidth),
                ),
              ],
            ),
          ),

          // Data rows
          ..._vitalSigns.asMap().entries.map((entry) {
            int index = entry.key;
            String vitalSign = entry.value;
            return _buildVitalSignRow(
              vitalSign,
              index,
              labelWidth,
              columnWidth,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimeColumnHeader(String timeColumn, double width) {
    return Container(
      width: width,
      height: 60,
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.white.withOpacity(0.3))),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              timeColumn,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          if (_timeColumns.length > 1)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _removeTimeColumn(timeColumn),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVitalSignRow(
    String vitalSign,
    int index,
    double labelWidth,
    double columnWidth,
  ) {
    final isEvenRow = index % 2 == 0;
    final backgroundColor = isEvenRow ? Colors.white : Colors.grey[50];

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          // Vital sign label
          Container(
            width: labelWidth,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(right: BorderSide(color: Colors.grey[200]!)),
            ),
            alignment: Alignment.center,
            child: Text(
              vitalSign,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),

          // Input fields for each time column
          ..._timeColumns.map(
            (timeColumn) => _buildInputCell(vitalSign, timeColumn, columnWidth),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCell(String vitalSign, String timeColumn, double width) {
    return Container(
      width: width,
      height: 60,
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.grey[200]!)),
      ),
      padding: const EdgeInsets.all(8),
      child: TextFormField(
        controller: _controllers[vitalSign]![timeColumn],
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.cancel),
              label: const Text('Cancelar'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
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
              label: Text(_isLoading ? 'Guardando...' : 'Guardar Exploración'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveForm() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final formData = {
        'timeColumns': _timeColumns,
        'llc': _llcController.text.trim(),
        'glucosa': _glucosaController.text.trim(),
        'ta': _taController.text.trim(),
        'sampleAlergias': _sampleAlergiasController.text.trim(),
        'sampleMedicamentos': _sampleMedicamentosController.text.trim(),
        'sampleEnfermedades': _sampleEnfermedadesController.text.trim(),
        'sampleHoraAlimento': _sampleHoraAlimentoController.text.trim(),
        'sampleEventosPrevios': _sampleEventosPreviosController.text.trim(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Guardar datos de signos vitales
      for (String vitalSign in _vitalSigns) {
        Map<String, String> vitalData = {};
        for (String timeColumn in _timeColumns) {
          String value =
              _controllers[vitalSign]![timeColumn]?.text.trim() ?? '';
          if (value.isNotEmpty) {
            vitalData[timeColumn] = value;
          }
        }
        if (vitalData.isNotEmpty) {
          formData[vitalSign] = vitalData;
        }
      }

      widget.onSave(formData);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Exploración física guardada exitosamente'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Text('Error al guardar: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
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
