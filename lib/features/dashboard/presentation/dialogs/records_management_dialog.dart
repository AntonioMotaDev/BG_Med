import 'package:bg_med/core/models/frap.dart';
import 'package:bg_med/core/theme/app_theme.dart';
import 'package:bg_med/features/frap/presentation/screens/frap_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class RecordsManagementDialog extends StatefulWidget {
  const RecordsManagementDialog({super.key});

  @override
  State<RecordsManagementDialog> createState() =>
      _RecordsManagementDialogState();
}

class _RecordsManagementDialogState extends State<RecordsManagementDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSortBy = 'Más reciente';
  DateTimeRange? _selectedDateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.list_alt, color: AppTheme.primaryBlue, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Administrar Registros',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _createNewRecord(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo FRAP'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showBulkActions(context),
                    icon: const Icon(Icons.checklist),
                    label: const Text('Acciones masivas'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      side: BorderSide(color: AppTheme.primaryBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search and Filters
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por paciente...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon:
                          _searchQuery.isNotEmpty
                              ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                              : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSortBy,
                    decoration: InputDecoration(
                      labelText: 'Ordenar',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items:
                        [
                              'Más reciente',
                              'Más antiguo',
                              'Nombre A-Z',
                              'Nombre Z-A',
                            ]
                            .map(
                              (String value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSortBy = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showDateRangeFilter(context),
                  icon: Icon(
                    Icons.date_range,
                    color:
                        _selectedDateRange != null
                            ? AppTheme.primaryBlue
                            : Colors.grey[600],
                  ),
                  tooltip: 'Filtrar por fecha',
                ),
              ],
            ),

            if (_selectedDateRange != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.date_range,
                      size: 16,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}',
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDateRange = null;
                        });
                      },
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Records List
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive.box<Frap>('fraps').listenable(),
                builder: (context, Box<Frap> box, _) {
                  if (box.values.isEmpty) {
                    return _buildEmptyState();
                  }

                  // Filter and sort records
                  var filteredRecords =
                      box.values.where((frap) {
                        final matchesSearch =
                            _searchQuery.isEmpty ||
                            frap.patient.name.toLowerCase().contains(
                              _searchQuery,
                            );

                        final matchesDateRange =
                            _selectedDateRange == null ||
                            (frap.createdAt.isAfter(
                                  _selectedDateRange!.start,
                                ) &&
                                frap.createdAt.isBefore(
                                  _selectedDateRange!.end.add(
                                    const Duration(days: 1),
                                  ),
                                ));

                        return matchesSearch && matchesDateRange;
                      }).toList();

                  // Sort records
                  switch (_selectedSortBy) {
                    case 'Más reciente':
                      filteredRecords.sort(
                        (a, b) => b.createdAt.compareTo(a.createdAt),
                      );
                      break;
                    case 'Más antiguo':
                      filteredRecords.sort(
                        (a, b) => a.createdAt.compareTo(b.createdAt),
                      );
                      break;
                    case 'Nombre A-Z':
                      filteredRecords.sort(
                        (a, b) => a.patient.name.compareTo(b.patient.name),
                      );
                      break;
                    case 'Nombre Z-A':
                      filteredRecords.sort(
                        (a, b) => b.patient.name.compareTo(a.patient.name),
                      );
                      break;
                  }

                  if (filteredRecords.isEmpty) {
                    return _buildNoResultsState();
                  }

                  return ListView.builder(
                    itemCount: filteredRecords.length,
                    itemBuilder: (context, index) {
                      final frap = filteredRecords[index];
                      return _buildRecordCard(frap, index);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hay registros FRAP',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primer registro para comenzar',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _createNewRecord(context),
            icon: const Icon(Icons.add),
            label: const Text('Crear Registro'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No se encontraron registros',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta ajustar los filtros de búsqueda',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(Frap frap, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        title: Text(
          frap.patient.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(frap.createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(Icons.person, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${frap.patient.age} años • ${_getGenderText(frap.patient.sex)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleRecordAction(value, frap),
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Ver detalles'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'duplicate',
                  child: Row(
                    children: [
                      Icon(Icons.copy, size: 16, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Duplicar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.share, size: 16, color: Colors.purple),
                      SizedBox(width: 8),
                      Text('Exportar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Eliminar'),
                    ],
                  ),
                ),
              ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailSection('Información del Paciente', [
                  'Nombre: ${frap.patient.name}',
                  'Edad: ${frap.patient.age} años',
                  'Género: ${_getGenderText(frap.patient.sex)}',
                  if (frap.patient.address.isNotEmpty)
                    'Dirección: ${frap.patient.address}',
                ]),
                const SizedBox(height: 12),
                _buildDetailSection('Historia Clínica', [
                  if (frap.clinicalHistory.traumaCraneo)
                    'Trauma Cráneo: ${frap.clinicalHistory.traumaCraneoEspecifique.isEmpty ? "Sí" : frap.clinicalHistory.traumaCraneoEspecifique}',
                  if (frap.clinicalHistory.traumaTorax)
                    'Trauma Tórax: ${frap.clinicalHistory.traumaToraxEspecifique.isEmpty ? "Sí" : frap.clinicalHistory.traumaToraxEspecifique}',
                  if (frap.clinicalHistory.traumaAbdomen)
                    'Trauma Abdomen: ${frap.clinicalHistory.traumaAbdomenEspecifique.isEmpty ? "Sí" : frap.clinicalHistory.traumaAbdomenEspecifique}',
                  if (frap.clinicalHistory.agenteCausal.isNotEmpty)
                    'Agente Causal: ${frap.clinicalHistory.agenteCausal}',
                  if (frap.clinicalHistory.observaciones.isNotEmpty)
                    'Observaciones: ${frap.clinicalHistory.observaciones}',
                ]),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      'Ver completo',
                      Icons.visibility,
                      Colors.blue,
                      () => _viewFullRecord(frap),
                    ),
                    _buildActionButton(
                      'Editar',
                      Icons.edit,
                      Colors.orange,
                      () => _editRecord(frap),
                    ),
                    _buildActionButton(
                      'Exportar',
                      Icons.share,
                      Colors.purple,
                      () => _exportRecord(frap),
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

  Widget _buildDetailSection(String title, List<String> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBlue,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        ...details.map(
          (detail) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(detail, style: const TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getGenderText(String sex) {
    switch (sex) {
      case 'Male':
        return 'Masculino';
      case 'Female':
        return 'Femenino';
      default:
        return sex;
    }
  }

  // CRUD Operations
  void _createNewRecord(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FrapScreen()),
    );
  }

  void _handleRecordAction(String action, Frap frap) {
    switch (action) {
      case 'view':
        _viewFullRecord(frap);
        break;
      case 'edit':
        _editRecord(frap);
        break;
      case 'duplicate':
        _duplicateRecord(frap);
        break;
      case 'export':
        _exportRecord(frap);
        break;
      case 'delete':
        _deleteRecord(frap);
        break;
    }
  }

  void _viewFullRecord(Frap frap) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('FRAP - ${frap.patient.name}'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailSection('Paciente', [
                    'Nombre: ${frap.patient.name}',
                    'Edad: ${frap.patient.age} años',
                    'Género: ${_getGenderText(frap.patient.sex)}',
                    if (frap.patient.address.isNotEmpty)
                      'Dirección: ${frap.patient.address}',
                  ]),
                  const SizedBox(height: 16),
                  _buildDetailSection('Historia Clínica', [
                    if (frap.clinicalHistory.traumaCraneo)
                      'Trauma Cráneo: ${frap.clinicalHistory.traumaCraneoEspecifique.isEmpty ? "Sí" : frap.clinicalHistory.traumaCraneoEspecifique}',
                    if (frap.clinicalHistory.traumaTorax)
                      'Trauma Tórax: ${frap.clinicalHistory.traumaToraxEspecifique.isEmpty ? "Sí" : frap.clinicalHistory.traumaToraxEspecifique}',
                    if (frap.clinicalHistory.traumaAbdomen)
                      'Trauma Abdomen: ${frap.clinicalHistory.traumaAbdomenEspecifique.isEmpty ? "Sí" : frap.clinicalHistory.traumaAbdomenEspecifique}',
                    if (frap.clinicalHistory.agenteCausal.isNotEmpty)
                      'Agente Causal: ${frap.clinicalHistory.agenteCausal}',
                    if (frap.clinicalHistory.observaciones.isNotEmpty)
                      'Observaciones: ${frap.clinicalHistory.observaciones}',
                  ]),
                  const SizedBox(height: 16),
                  _buildDetailSection('Examen Físico', [
                    'Signos vitales: ${(frap.physicalExam['vitalSigns']?.toString() ?? '').isEmpty ? "No registrado" : frap.physicalExam['vitalSigns']}',
                    'Cabeza: ${(frap.physicalExam['head']?.toString() ?? '').isEmpty ? "Normal" : frap.physicalExam['head']}',
                    'Cuello: ${(frap.physicalExam['neck']?.toString() ?? '').isEmpty ? "Normal" : frap.physicalExam['neck']}',
                    'Tórax: ${(frap.physicalExam['thorax']?.toString() ?? '').isEmpty ? "Normal" : frap.physicalExam['thorax']}',
                    'Abdomen: ${(frap.physicalExam['abdomen']?.toString() ?? '').isEmpty ? "Normal" : frap.physicalExam['abdomen']}',
                    'Extremidades: ${(frap.physicalExam['extremities']?.toString() ?? '').isEmpty ? "Normal" : frap.physicalExam['extremities']}',
                  ]),
                  const SizedBox(height: 16),
                  Text(
                    'Fecha de registro: ${_formatDateTime(frap.createdAt)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Text(
                    'ID: ${frap.id}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _editRecord(frap);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                ),
                child: const Text('Editar'),
              ),
            ],
          ),
    );
  }

  void _editRecord(Frap frap) {
    // TODO: Navigate to edit screen with pre-filled data
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editar registro de ${frap.patient.name}'),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
          label: 'Próximamente',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _duplicateRecord(Frap frap) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Duplicar Registro'),
            content: Text(
              '¿Deseas crear una copia del registro de ${frap.patient.name}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    final newFrap = Frap(
                      id: const Uuid().v4(),
                      patient: frap.patient,
                      clinicalHistory: frap.clinicalHistory,
                      physicalExam: frap.physicalExam,
                      createdAt: DateTime.now(),
                    );

                    final frapBox = Hive.box<Frap>('fraps');
                    await frapBox.add(newFrap);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Registro duplicado exitosamente'),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al duplicar registro: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                ),
                child: const Text('Duplicar'),
              ),
            ],
          ),
    );
  }

  void _exportRecord(Frap frap) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Exportar Registro'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Selecciona el formato de exportación para el registro de ${frap.patient.name}:',
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _exportToPDF(frap);
                      },
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _exportToText(frap);
                      },
                      icon: const Icon(Icons.text_snippet),
                      label: const Text('Texto'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
    );
  }

  void _exportToPDF(Frap frap) {
    // TODO: Implement PDF export
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exportando ${frap.patient.name} a PDF...'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Próximamente',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _exportToText(Frap frap) {
    final textData = '''
REGISTRO FRAP - ${frap.patient.name}
=====================================

INFORMACIÓN DEL PACIENTE:
- Nombre: ${frap.patient.name}
- Edad: ${frap.patient.age} años
- Género: ${_getGenderText(frap.patient.sex)}
- Dirección: ${frap.patient.address.isEmpty ? "No especificada" : frap.patient.address}

HISTORIA CLÍNICA:
${frap.clinicalHistory.traumaCraneo ? '- Trauma Cráneo: ${frap.clinicalHistory.traumaCraneoEspecifique.isEmpty ? "Sí" : frap.clinicalHistory.traumaCraneoEspecifique}\n' : ''}${frap.clinicalHistory.traumaTorax ? '- Trauma Tórax: ${frap.clinicalHistory.traumaToraxEspecifique.isEmpty ? "Sí" : frap.clinicalHistory.traumaToraxEspecifique}\n' : ''}${frap.clinicalHistory.traumaAbdomen ? '- Trauma Abdomen: ${frap.clinicalHistory.traumaAbdomenEspecifique.isEmpty ? "Sí" : frap.clinicalHistory.traumaAbdomenEspecifique}\n' : ''}${frap.clinicalHistory.agenteCausal.isNotEmpty ? '- Agente Causal: ${frap.clinicalHistory.agenteCausal}\n' : ''}${frap.clinicalHistory.cinematica.isNotEmpty ? '- Cinemática: ${frap.clinicalHistory.cinematica}\n' : ''}${frap.clinicalHistory.observaciones.isNotEmpty ? '- Observaciones: ${frap.clinicalHistory.observaciones}\n' : ''}${!frap.clinicalHistory.traumaCraneo && !frap.clinicalHistory.traumaTorax && !frap.clinicalHistory.traumaAbdomen && frap.clinicalHistory.agenteCausal.isEmpty ? '- Sin información de trauma registrada\n' : ''}
EXAMEN FÍSICO:
- Signos vitales: ${(frap.physicalExam['vitalSigns']?.toString() ?? '').isEmpty ? "No registrado" : frap.physicalExam['vitalSigns']}
- Cabeza: ${(frap.physicalExam['head']?.toString() ?? '').isEmpty ? "Normal" : frap.physicalExam['head']}
- Cuello: ${(frap.physicalExam['neck']?.toString() ?? '').isEmpty ? "Normal" : frap.physicalExam['neck']}
- Tórax: ${(frap.physicalExam['thorax']?.toString() ?? '').isEmpty ? "Normal" : frap.physicalExam['thorax']}
- Abdomen: ${(frap.physicalExam['abdomen']?.toString() ?? '').isEmpty ? "Normal" : frap.physicalExam['abdomen']}
- Extremidades: ${(frap.physicalExam['extremities']?.toString() ?? '').isEmpty ? "Normal" : frap.physicalExam['extremities']}

REGISTRO:
- Fecha: ${_formatDateTime(frap.createdAt)}
- ID: ${frap.id}
    ''';

    // TODO: Save to file or share
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Datos de ${frap.patient.name} copiados'),
        backgroundColor: Colors.blue,
        action: SnackBarAction(
          label: 'Ver',
          textColor: Colors.white,
          onPressed: () {
            showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: Text('Datos de ${frap.patient.name}'),
                    content: SingleChildScrollView(
                      child: Text(
                        textData,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
            );
          },
        ),
      ),
    );
  }

  void _deleteRecord(Frap frap) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 8),
                Text('Eliminar Registro'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Estás seguro de que deseas eliminar el registro de ${frap.patient.name}?',
                ),
                const SizedBox(height: 8),
                const Text(
                  'Esta acción no se puede deshacer.',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Registro a eliminar:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text('• Paciente: ${frap.patient.name}'),
                      Text('• Fecha: ${_formatDateTime(frap.createdAt)}'),
                      Text('• ID: ${frap.id.substring(0, 8)}...'),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    final frapBox = Hive.box<Frap>('fraps');
                    final key = frapBox.values.toList().indexWhere(
                      (f) => f.id == frap.id,
                    );

                    if (key != -1) {
                      await frapBox.deleteAt(key);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Registro de ${frap.patient.name} eliminado',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al eliminar registro: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
  }

  void _showDateRangeFilter(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppTheme.primaryBlue),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _showBulkActions(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Acciones Masivas'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.file_download, color: Colors.green),
                  title: const Text('Exportar todos'),
                  subtitle: const Text('Exportar todos los registros'),
                  onTap: () {
                    Navigator.pop(context);
                    _exportAllRecords();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.backup, color: Colors.blue),
                  title: const Text('Crear respaldo'),
                  subtitle: const Text('Respaldar base de datos'),
                  onTap: () {
                    Navigator.pop(context);
                    _createBackup();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_sweep, color: Colors.red),
                  title: const Text('Limpiar antiguos'),
                  subtitle: const Text('Eliminar registros antiguos'),
                  onTap: () {
                    Navigator.pop(context);
                    _showCleanupDialog();
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  void _exportAllRecords() {
    // TODO: Implement bulk export
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Exportando todos los registros...'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Próximamente',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _createBackup() {
    // TODO: Implement backup functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Creando respaldo...'),
        backgroundColor: Colors.blue,
        action: SnackBarAction(
          label: 'Próximamente',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showCleanupDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Limpiar Registros Antiguos'),
            content: const Text('Selecciona qué registros deseas eliminar:'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Implement cleanup older than 30 days
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Funcionalidad próximamente'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                child: const Text('Más de 30 días'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Implement cleanup older than 90 days
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Funcionalidad próximamente'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                child: const Text('Más de 90 días'),
              ),
            ],
          ),
    );
  }
}
