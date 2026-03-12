import 'package:bg_med/core/theme/app_theme.dart';
import 'package:bg_med/core/models/patient_firestore.dart';
import 'package:bg_med/features/patients/presentation/providers/patients_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PatientInfoFormDialog extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  final Map<String, dynamic>? initialData;

  const PatientInfoFormDialog({
    super.key,
    required this.onSave,
    this.initialData,
  });

  @override
  ConsumerState<PatientInfoFormDialog> createState() =>
      _PatientInfoFormDialogState();
}

class _PatientInfoFormDialogState extends ConsumerState<PatientInfoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  PatientFirestore? _selectedPatient;

  // Controladores de texto
  final _firstNameController = TextEditingController();
  final _paternalLastNameController = TextEditingController();
  final _maternalLastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _exteriorNumberController = TextEditingController();
  final _interiorNumberController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();
  final _insuranceController = TextEditingController();
  final _addressDetailsController = TextEditingController();
  final _searchController = TextEditingController();
  final _currentConditionController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _responsiblePersonController = TextEditingController();

  // Variables para dropdowns
  String _sexSelected = '';

  final List<String> _sexOptions = ['Masculino', 'Femenino'];

  // Variables para checkboxes y selecciones
  String _tipoEntregaSeleccionado = '';
  String _generoSeleccionado = '';

  // Controladores de texto adicionales
  final _tipoEntregaOtroController = TextEditingController();

  // final List<String> _tiposEntrega = [
  //   'Domicilio',
  //   'Hospital',
  //   'Clínica',
  //   'Centro de Salud',
  //   'Otro',
  // ];

  // final List<String> _generos = [
  //   'Masculino',
  //   'Femenino',
  //   'No binario',
  //   'Prefiero no decir',
  //   'Otro',
  // ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.initialData != null) {
      final data = widget.initialData!;
      _firstNameController.text = data['firstName'] ?? '';
      _paternalLastNameController.text = data['paternalLastName'] ?? '';
      _maternalLastNameController.text = data['maternalLastName'] ?? '';
      _ageController.text = data['age']?.toString() ?? '';
      _sexSelected = data['sex'] ?? ''; // Cambiado de gender a sex
      _phoneController.text = data['phone'] ?? '';
      _streetController.text = data['street'] ?? '';
      _exteriorNumberController.text = data['exteriorNumber'] ?? '';
      _interiorNumberController.text = data['interiorNumber'] ?? '';
      _neighborhoodController.text = data['neighborhood'] ?? '';
      _cityController.text = data['city'] ?? '';
      _addressDetailsController.text = data['addressDetails'] ?? '';
      _insuranceController.text = data['insurance'] ?? '';
      _currentConditionController.text = data['currentCondition'] ?? '';
      _emergencyContactController.text = data['emergencyContact'] ?? '';
      _responsiblePersonController.text = data['responsiblePerson'] ?? '';

      // Campos adicionales que estaban faltando
      _tipoEntregaSeleccionado = data['tipoEntrega'] ?? '';
      _tipoEntregaOtroController.text = data['tipoEntregaOtro'] ?? '';
      _generoSeleccionado = data['gender'] ?? '';

      // Si ya hay datos, probablemente es un paciente seleccionado
      if (data['patientId'] != null) {
        // Buscar el paciente en la lista para establecer _selectedPatient
        final patients = ref.read(patientsNotifierProvider).patients;
        try {
          _selectedPatient = patients.firstWhere(
            (p) => p.id == data['patientId'],
          );
        } catch (e) {
          // Si no se encuentra el paciente, _selectedPatient permanece null
          _selectedPatient = null;
        }
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _paternalLastNameController.dispose();
    _maternalLastNameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _exteriorNumberController.dispose();
    _interiorNumberController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _insuranceController.dispose();
    _addressDetailsController.dispose();
    _searchController.dispose();
    _currentConditionController.dispose();
    _emergencyContactController.dispose();
    _responsiblePersonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientsState = ref.watch(patientsNotifierProvider);

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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue,
                    AppTheme.primaryBlue.withAlpha(204),
                  ],
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
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_add_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INFORMACIÓN DEL PACIENTE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Complete los datos del paciente',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),

            // Form content
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selector de paciente existente mejorado
                      _buildPatientSelector(patientsState),
                      const SizedBox(height: 24),

                      // Divisor mejorado
                      if (_selectedPatient != null) ...[
                        _buildSectionDivider(
                          'DATOS DEL PACIENTE SELECCIONADO',
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ] else ...[
                        _buildSectionDivider(
                          'DATOS DEL NUEVO PACIENTE',
                          Icons.person_add,
                          AppTheme.primaryBlue,
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Formulario de datos del paciente
                      _buildPatientForm(),
                    ],
                  ),
                ),
              ),
            ),

            // Navigation buttons mejorados
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancelar'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (_selectedPatient != null) ...[
                    TextButton.icon(
                      onPressed: _clearSelection,
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Limpiar'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange[600],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveForm,
                    icon:
                        _isLoading
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Icon(Icons.save_rounded),
                    label: Text(_isLoading ? 'Guardando...' : 'Guardar Datos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
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

  Widget _buildPatientSelector(PatientsState patientsState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buscar paciente existente',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Seleccione un paciente de la base de datos',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _searchController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
              ),
              hintText: 'Buscar por nombre, apellido...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              setState(() {
                // Trigger rebuild to filter patients
              });
            },
          ),
          const SizedBox(height: 12),

          if (_searchController.text.isNotEmpty &&
              patientsState.patients.isNotEmpty) ...[
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue[300]!),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _getFilteredPatients(patientsState.patients).length,
                itemBuilder: (context, index) {
                  final patient =
                      _getFilteredPatients(patientsState.patients)[index];
                  final isSelected = _selectedPatient?.id == patient.id;
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? AppTheme.primaryBlue.withOpacity(0.1)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border:
                          isSelected
                              ? Border.all(
                                color: AppTheme.primaryBlue,
                                width: 2,
                              )
                              : null,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            isSelected
                                ? AppTheme.primaryBlue
                                : Colors.grey[300],
                        child: Text(
                          patient.firstName.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        '${patient.firstName} ${patient.paternalLastName} ${patient.maternalLastName}',
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color:
                              isSelected
                                  ? AppTheme.primaryBlue
                                  : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        'Edad: ${patient.age} • Teléfono: ${patient.phone}',
                        style: TextStyle(
                          color:
                              isSelected
                                  ? AppTheme.primaryBlue.withOpacity(0.8)
                                  : Colors.grey[600],
                        ),
                      ),
                      trailing:
                          isSelected
                              ? const Icon(
                                Icons.check_circle,
                                color: AppTheme.primaryBlue,
                              )
                              : null,
                      onTap: () => _selectPatient(patient),
                    ),
                  );
                },
              ),
            ),
          ],

          if (_selectedPatient != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[500],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Paciente seleccionado',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${_selectedPatient!.firstName} ${_selectedPatient!.paternalLastName}',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _clearSelection,
                    icon: Icon(Icons.close, color: Colors.green[600]),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.green[100],
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionDivider(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Divider(color: color.withOpacity(0.3))),
      ],
    );
  }

  Widget _buildPatientForm() {
    return Column(
      children: [
        // Sección: Información Personal
        _buildFormSection(
          'INFORMACIÓN PERSONAL',
          Icons.person_outline,
          Colors.blue,
          [
            // Nombre completo
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _firstNameController,
                    label: 'Nombre *',
                    icon: Icons.person,
                    enabled:
                        _selectedPatient == null ||
                        _firstNameController.text.trim().isEmpty,
                    validator: (value) {
                      if (_selectedPatient != null) return null;
                      if (value == null || value.trim().isEmpty) {
                        return 'El nombre es requerido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _paternalLastNameController,
                    label: 'Apellido Paterno *',
                    icon: Icons.person,
                    enabled:
                        _selectedPatient == null ||
                        _paternalLastNameController.text.trim().isEmpty,
                    validator: (value) {
                      if (_selectedPatient != null) return null;
                      if (value == null || value.trim().isEmpty) {
                        return 'El apellido paterno es requerido';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _maternalLastNameController,
                    label: 'Apellido Materno *',
                    icon: Icons.person,
                    enabled:
                        _selectedPatient == null ||
                        _maternalLastNameController.text.trim().isEmpty,
                    validator: (value) {
                      if (_selectedPatient != null) return null;
                      if (value == null || value.trim().isEmpty) {
                        return 'El apellido materno es requerido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _ageController,
                    label: 'Edad *',
                    icon: Icons.cake,
                    keyboardType: TextInputType.number,
                    enabled:
                        _selectedPatient == null ||
                        _ageController.text.trim().isEmpty,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La edad es requerida';
                      }
                      final age = int.tryParse(value);
                      if (age == null || age < 0 || age > 120) {
                        return 'Edad válida (0-120)';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sexo y teléfono
            Row(
              children: [
                Expanded(
                  child: _buildDropdownField(
                    value: _sexSelected.isEmpty ? null : _sexSelected,
                    label: 'Sexo *',
                    icon: Icons.wc,
                    items: _sexOptions,
                    enabled: (_selectedPatient == null || _sexSelected.isEmpty),
                    onChanged:
                        (_selectedPatient == null || _sexSelected.isEmpty)
                            ? (value) {
                              setState(() {
                                _sexSelected = value ?? '';
                              });
                            }
                            : null,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Seleccione el sexo';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _phoneController,
                    label: 'Teléfono *',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    enabled:
                        _selectedPatient == null ||
                        _phoneController.text.trim().isEmpty,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El teléfono es requerido';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Sección: Dirección
        _buildFormSection(
          'DIRECCIÓN',
          Icons.location_on_outlined,
          Colors.green,
          [
            // Calle y número exterior
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    controller: _streetController,
                    label: 'Calle *',
                    icon: Icons.streetview,
                    enabled:
                        _selectedPatient == null ||
                        _streetController.text.trim().isEmpty,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La calle es requerida';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _exteriorNumberController,
                    label: 'Núm. Ext. *',
                    icon: Icons.home,
                    enabled:
                        _selectedPatient == null ||
                        _exteriorNumberController.text.trim().isEmpty,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Número requerido';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Número interior y colonia
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _interiorNumberController,
                    label: 'Núm. Int.',
                    icon: Icons.home_work,
                    enabled:
                        _selectedPatient == null ||
                        _interiorNumberController.text.trim().isEmpty,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _neighborhoodController,
                    label: 'Colonia *',
                    icon: Icons.location_city,
                    enabled:
                        _selectedPatient == null ||
                        _neighborhoodController.text.trim().isEmpty,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La colonia es requerida';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Ciudad y seguro médico
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _cityController,
                    label: 'Ciudad *',
                    icon: Icons.location_city,
                    enabled:
                        _selectedPatient == null ||
                        _cityController.text.trim().isEmpty,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La ciudad es requerida';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _insuranceController,
                    label: 'Seguro Médico',
                    icon: Icons.medical_services,
                    enabled:
                        _selectedPatient == null ||
                        _insuranceController.text.trim().isEmpty,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Detalles de dirección
            _buildTextField(
              controller: _addressDetailsController,
              label: 'Detalles de dirección',
              icon: Icons.info_outline,
              hintText: 'Ej: Entre calles, referencias, etc.',
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Sección: Información Adicional
        // _buildFormSection(
        //   'INFORMACIÓN ADICIONAL',
        //   Icons.info_outline,
        //   Colors.orange,
        //   [
        //     // Tipo de entrega
        //     _buildSelectionGroup(
        //       'TIPO DE ENTREGA',
        //       Icons.delivery_dining,
        //       _tiposEntrega,
        //       _tipoEntregaSeleccionado,
        //       (value) {
        //         setState(() {
        //           _tipoEntregaSeleccionado = value;
        //           if (value != 'Otro') {
        //             _tipoEntregaOtroController.clear();
        //           }
        //         });
        //       },
        //     ),

        //     if (_tipoEntregaSeleccionado == 'Otro') ...[
        //       const SizedBox(height: 12),
        //       _buildTextField(
        //         controller: _tipoEntregaOtroController,
        //         label: 'Especifique tipo de entrega:',
        //         icon: Icons.edit,
        //         validator: (value) {
        //           if (_tipoEntregaSeleccionado == 'Otro' &&
        //               (value == null || value.trim().isEmpty)) {
        //             return 'Especifique el tipo de entrega';
        //           }
        //           return null;
        //         },
        //       ),
        //     ],

        //     const SizedBox(height: 16),

        //     // Género
        //     _buildSelectionGroup(
        //       'GÉNERO',
        //       Icons.person_outline,
        //       _generos,
        //       _generoSeleccionado,
        //       (value) {
        //         setState(() {
        //           _generoSeleccionado = value;
        //         });
        //       },
        //     ),

        //     const SizedBox(height: 16),
        //   ],
        // ),
        const SizedBox(height: 24),

        // Sección: Información Médica
        _buildFormSection(
          'INFORMACIÓN MÉDICA',
          Icons.medical_information,
          Colors.red,
          [
            // Padecimiento Actual
            _buildTextField(
              controller: _currentConditionController,
              label: 'Padecimiento Actual',
              icon: Icons.sick,
              maxLines: 3,
              hintText:
                  'Describe el padecimiento o síntomas actuales del paciente',
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Contacto de Emergencia
            _buildTextField(
              controller: _emergencyContactController,
              label: 'Contacto de Emergencia',
              icon: Icons.emergency,
              hintText: 'Nombre del contacto de emergencia',
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Persona Responsable
            _buildTextField(
              controller: _responsiblePersonController,
              label: 'Persona Responsable',
              icon: Icons.person_pin,
              hintText: 'Ej: Padre, Madre, Tutor',
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormSection(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    String? hintText,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(
          icon,
          color: enabled ? Colors.grey[600] : Colors.grey[400],
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[300]!),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        labelStyle: TextStyle(
          color: enabled ? Colors.grey[700] : Colors.grey[400],
        ),
      ),
      style: TextStyle(color: enabled ? Colors.black87 : Colors.grey[600]),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required bool enabled,
    required Function(String?)? onChanged,
    required String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: enabled ? Colors.grey[600] : Colors.grey[400],
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[300]!),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        labelStyle: TextStyle(
          color: enabled ? Colors.grey[700] : Colors.grey[400],
        ),
      ),
      items:
          items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
      onChanged: onChanged,
      validator: validator,
      style: TextStyle(color: enabled ? Colors.black87 : Colors.grey[600]),
    );
  }

  // Widget _buildSelectionGroup(
  //   String title,
  //   IconData icon,
  //   List<String> options,
  //   String selectedValue,
  //   Function(String) onChanged,
  // ) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Row(
  //         children: [
  //           Icon(icon, color: Colors.grey[600], size: 18),
  //           const SizedBox(width: 8),
  //           Text(
  //             title,
  //             style: TextStyle(
  //               fontSize: 14,
  //               fontWeight: FontWeight.w600,
  //               color: Colors.grey[700],
  //             ),
  //           ),
  //         ],
  //       ),
  //       const SizedBox(height: 8),
  //       Wrap(
  //         spacing: 8,
  //         runSpacing: 8,
  //         children:
  //             options.map((option) {
  //               final isSelected = selectedValue == option;
  //               return GestureDetector(
  //                 onTap: () => onChanged(isSelected ? '' : option),
  //                 child: Container(
  //                   padding: const EdgeInsets.symmetric(
  //                     horizontal: 12,
  //                     vertical: 8,
  //                   ),
  //                   decoration: BoxDecoration(
  //                     color: isSelected ? AppTheme.primaryBlue : Colors.white,
  //                     border: Border.all(
  //                       color:
  //                           isSelected
  //                               ? AppTheme.primaryBlue
  //                               : Colors.grey[300]!,
  //                       width: isSelected ? 2 : 1,
  //                     ),
  //                     borderRadius: BorderRadius.circular(20),
  //                   ),
  //                   child: Text(
  //                     option,
  //                     style: TextStyle(
  //                       fontSize: 12,
  //                       fontWeight:
  //                           isSelected ? FontWeight.w600 : FontWeight.normal,
  //                       color: isSelected ? Colors.white : Colors.grey[700],
  //                     ),
  //                   ),
  //                 ),
  //               );
  //             }).toList(),
  //       ),
  //     ],
  //   );
  // }

  List<PatientFirestore> _getFilteredPatients(List<PatientFirestore> patients) {
    if (_searchController.text.isEmpty) return [];

    final searchTerm = _searchController.text.toLowerCase();
    return patients.where((patient) {
      return patient.firstName.toLowerCase().contains(searchTerm) ||
          patient.paternalLastName.toLowerCase().contains(searchTerm) ||
          patient.maternalLastName.toLowerCase().contains(searchTerm);
    }).toList();
  }

  void _selectPatient(PatientFirestore patient) {
    setState(() {
      _selectedPatient = patient;

      // Llenar los campos con los datos del paciente seleccionado
      _firstNameController.text = patient.firstName;
      _paternalLastNameController.text = patient.paternalLastName;
      _maternalLastNameController.text = patient.maternalLastName;
      _ageController.text = patient.age.toString();
      _sexSelected = patient.sex;
      _phoneController.text = patient.phone;
      _streetController.text = patient.street;
      _exteriorNumberController.text = patient.exteriorNumber;
      _interiorNumberController.text = patient.interiorNumber ?? '';
      _neighborhoodController.text = patient.neighborhood;
      _cityController.text = patient.city;
      _addressDetailsController.text = patient.addressDetails ?? '';
      _insuranceController.text = patient.insurance;
      _responsiblePersonController.text = patient.responsiblePerson ?? '';
      _tipoEntregaSeleccionado = '';
      _tipoEntregaOtroController.text = '';
      _generoSeleccionado = '';

      // No llenamos currentCondition y emergencyContact porque son específicos de cada consulta FRAP

      // Limpiar búsqueda
      _searchController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _formKey.currentState?.reset();
      _formKey.currentState?.validate();
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedPatient = null;

      // Limpiar todos los campos
      _firstNameController.clear();
      _paternalLastNameController.clear();
      _maternalLastNameController.clear();
      _ageController.clear();
      _sexSelected = '';
      _phoneController.clear();
      _streetController.clear();
      _exteriorNumberController.clear();
      _interiorNumberController.clear();
      _neighborhoodController.clear();
      _cityController.clear();
      _addressDetailsController.clear();
      _insuranceController.clear();
      _searchController.clear();
      _currentConditionController.clear();
      _emergencyContactController.clear();
      _responsiblePersonController.clear();
      _tipoEntregaSeleccionado = '';
      _tipoEntregaOtroController.clear();
      _generoSeleccionado = '';
    });
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final formData = {
        'patientId': _selectedPatient?.id,
        'firstName': _firstNameController.text.trim(),
        'paternalLastName': _paternalLastNameController.text.trim(),
        'maternalLastName': _maternalLastNameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'sex': _sexSelected,
        'phone': _phoneController.text.trim(),
        'street': _streetController.text.trim(),
        'exteriorNumber': _exteriorNumberController.text.trim(),
        'interiorNumber': _interiorNumberController.text.trim(),
        'neighborhood': _neighborhoodController.text.trim(),
        'city': _cityController.text.trim(),
        'addressDetails': _addressDetailsController.text.trim(),
        'insurance': _insuranceController.text.trim(),
        'currentCondition': _currentConditionController.text.trim(),
        'emergencyContact': _emergencyContactController.text.trim(),
        'responsiblePerson': _responsiblePersonController.text.trim(),
        'tipoEntrega': _tipoEntregaSeleccionado,
        'tipoEntregaOtro': _tipoEntregaOtroController.text.trim(),
        'gender': _generoSeleccionado,
        'isNewPatient': _selectedPatient == null,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Si es un nuevo paciente, preguntar si quiere guardarlo
      if (_selectedPatient == null) {
        final shouldSavePatient = await _showSavePatientDialog();
        if (shouldSavePatient == true) {
          await _saveNewPatient();
        }
      }

      widget.onSave(formData);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Información del paciente guardada exitosamente'),
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

  Future<bool?> _showSavePatientDialog() async {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.save, color: AppTheme.primaryBlue),
                const SizedBox(width: 12),
                const Text('Guardar Nuevo Paciente'),
              ],
            ),
            content: const Text(
              '¿Deseas guardar este paciente en la base de datos para futuras consultas?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No guardar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Guardar paciente'),
              ),
            ],
          ),
    );
  }

  Future<void> _saveNewPatient() async {
    try {
      final newPatient = PatientFirestore.create(
        firstName: _firstNameController.text.trim(),
        paternalLastName: _paternalLastNameController.text.trim(),
        maternalLastName: _maternalLastNameController.text.trim(),
        age: int.tryParse(_ageController.text.trim()) ?? 0,
        sex: _sexSelected,
        gender: _generoSeleccionado,
        phone: _phoneController.text.trim(),
        street: _streetController.text.trim(),
        exteriorNumber: _exteriorNumberController.text.trim(),
        neighborhood: _neighborhoodController.text.trim(),
        city: _cityController.text.trim(),
        insurance: _insuranceController.text.trim(),
        interiorNumber:
            _interiorNumberController.text.trim().isEmpty
                ? null
                : _interiorNumberController.text.trim(),
        responsiblePerson:
            _responsiblePersonController.text.trim().isEmpty
                ? null
                : _responsiblePersonController.text.trim(),
        addressDetails: _addressDetailsController.text.trim(),
      );

      await ref
          .read(patientsNotifierProvider.notifier)
          .createPatient(newPatient);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Nuevo paciente guardado exitosamente'),
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
                Text('Error al guardar paciente: $e'),
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
    }
  }
}
