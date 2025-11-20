import 'package:bg_med/core/models/frap.dart';
import 'package:bg_med/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class PatientSearchDialog extends StatefulWidget {
  const PatientSearchDialog({super.key});

  @override
  State<PatientSearchDialog> createState() => _PatientSearchDialogState();
}

class _PatientSearchDialogState extends State<PatientSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedGenderFilter = 'Todos';
  String _selectedAgeFilter = 'Todos';

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
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.search, color: AppTheme.primaryBlue, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Buscar Pacientes',
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

            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre...',
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
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
            const SizedBox(height: 16),

            // Filters
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedGenderFilter,
                    decoration: InputDecoration(
                      labelText: 'Género',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items:
                        ['Todos', 'Male', 'Female']
                            .map(
                              (String value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value == 'Male'
                                      ? 'Masculino'
                                      : value == 'Female'
                                      ? 'Femenino'
                                      : value,
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedGenderFilter = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedAgeFilter,
                    decoration: InputDecoration(
                      labelText: 'Edad',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items:
                        ['Todos', '0-18', '19-35', '36-60', '60+']
                            .map(
                              (String value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value == '0-18'
                                      ? 'Menor de edad'
                                      : value == '19-35'
                                      ? 'Joven adulto'
                                      : value == '36-60'
                                      ? 'Adulto'
                                      : value == '60+'
                                      ? 'Adulto mayor'
                                      : value,
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAgeFilter = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Results
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive.box<Frap>('fraps').listenable(),
                builder: (context, Box<Frap> box, _) {
                  if (box.values.isEmpty) {
                    return _buildEmptyState();
                  }

                  // Get unique patients
                  final Map<String, Frap> uniquePatients = {};
                  for (final frap in box.values) {
                    final key = '${frap.patient.name}_${frap.patient.age}';
                    if (!uniquePatients.containsKey(key) ||
                        frap.createdAt.isAfter(
                          uniquePatients[key]!.createdAt,
                        )) {
                      uniquePatients[key] = frap;
                    }
                  }

                  // Filter patients
                  var filteredPatients =
                      uniquePatients.values.where((frap) {
                        final matchesSearch =
                            _searchQuery.isEmpty ||
                            frap.patient.name.toLowerCase().contains(
                              _searchQuery,
                            );

                        final matchesGender =
                            _selectedGenderFilter == 'Todos' ||
                            frap.patient.sex == _selectedGenderFilter;

                        bool matchesAge = true;
                        if (_selectedAgeFilter != 'Todos') {
                          final age = frap.patient.age;
                          switch (_selectedAgeFilter) {
                            case '0-18':
                              matchesAge = age <= 18;
                              break;
                            case '19-35':
                              matchesAge = age >= 19 && age <= 35;
                              break;
                            case '36-60':
                              matchesAge = age >= 36 && age <= 60;
                              break;
                            case '60+':
                              matchesAge = age > 60;
                              break;
                          }
                        }

                        return matchesSearch && matchesGender && matchesAge;
                      }).toList();

                  // Sort by name
                  filteredPatients.sort(
                    (a, b) => a.patient.name.compareTo(b.patient.name),
                  );

                  if (filteredPatients.isEmpty) {
                    return _buildNoResultsState();
                  }

                  return ListView.builder(
                    itemCount: filteredPatients.length,
                    itemBuilder: (context, index) {
                      final frap = filteredPatients[index];
                      return _buildPatientSearchCard(frap);
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
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hay pacientes registrados',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los pacientes aparecerán aquí cuando\ncrées tu primer FRAP',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
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
            'No se encontraron pacientes',
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

  Widget _buildPatientSearchCard(Frap frap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: _getGenderColor(frap.patient.sex),
          child: Icon(
            frap.patient.sex == 'Male' ? Icons.male : Icons.female,
            color: Colors.white,
            size: 18,
          ),
        ),
        title: Text(
          frap.patient.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          '${frap.patient.age} años • ${_getGenderText(frap.patient.sex)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'view':
                _showPatientDetails(frap);
                break;
              case 'history':
                _showPatientHistory(frap);
                break;
            }
          },
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 16),
                      SizedBox(width: 8),
                      Text('Ver detalles'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'history',
                  child: Row(
                    children: [
                      Icon(Icons.history, size: 16),
                      SizedBox(width: 8),
                      Text('Ver historial'),
                    ],
                  ),
                ),
              ],
        ),
        onTap: () => _showPatientDetails(frap),
      ),
    );
  }

  Color _getGenderColor(String gender) {
    switch (gender) {
      case 'Male':
        return AppTheme.primaryBlue;
      case 'Female':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  String _getGenderText(String gender) {
    switch (gender) {
      case 'Male':
        return 'Masculino';
      case 'Female':
        return 'Femenino';
      default:
        return gender;
    }
  }

  void _showPatientDetails(Frap frap) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: _getGenderColor(frap.patient.sex),
                  child: Icon(
                    frap.patient.sex == 'Male' ? Icons.male : Icons.female,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    frap.patient.name,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Edad', '${frap.patient.age} años'),
                  _buildDetailRow(
                    'Género',
                    frap.patient.sex == 'Male' ? 'Masculino' : 'Femenino',
                  ),
                  if (frap.patient.address.isNotEmpty)
                    _buildDetailRow('Dirección', frap.patient.address),
                  _buildDetailRow(
                    'Último registro',
                    _formatFullDate(frap.createdAt),
                  ),

                  const SizedBox(height: 16),
                  Text(
                    'Información médica reciente:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (frap.clinicalHistory.traumaCraneo)
                    _buildDetailRow(
                      'Trauma Cráneo',
                      frap.clinicalHistory.traumaCraneoEspecifique.isEmpty
                          ? 'Sí'
                          : frap.clinicalHistory.traumaCraneoEspecifique,
                    ),
                  if (frap.clinicalHistory.traumaTorax)
                    _buildDetailRow(
                      'Trauma Tórax',
                      frap.clinicalHistory.traumaToraxEspecifique.isEmpty
                          ? 'Sí'
                          : frap.clinicalHistory.traumaToraxEspecifique,
                    ),
                  if (frap.clinicalHistory.traumaAbdomen)
                    _buildDetailRow(
                      'Trauma Abdomen',
                      frap.clinicalHistory.traumaAbdomenEspecifique.isEmpty
                          ? 'Sí'
                          : frap.clinicalHistory.traumaAbdomenEspecifique,
                    ),
                  if (frap.clinicalHistory.agenteCausal.isNotEmpty)
                    _buildDetailRow(
                      'Agente Causal',
                      frap.clinicalHistory.agenteCausal,
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
                  _showPatientHistory(frap);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                ),
                child: const Text('Ver historial'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showPatientHistory(Frap frap) {
    final box = Hive.box<Frap>('fraps');
    final patientRecords =
        box.values
            .where(
              (record) =>
                  record.patient.name == frap.patient.name &&
                  record.patient.age == frap.patient.age,
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('Historial de ${frap.patient.name}'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child:
                  patientRecords.isEmpty
                      ? Center(
                        child: Text(
                          'No hay registros disponibles',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                      : ListView.builder(
                        itemCount: patientRecords.length,
                        itemBuilder: (context, index) {
                          final record = patientRecords[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: AppTheme.primaryBlue
                                    .withOpacity(0.1),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: AppTheme.primaryBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              title: Text(
                                _formatFullDate(record.createdAt),
                                style: const TextStyle(fontSize: 14),
                              ),
                              subtitle: Text(
                                'FRAP #${record.id.substring(0, 8)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              onTap: () {
                                // TODO: Navigate to FRAP details
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Ver detalles del FRAP: ${record.id.substring(0, 8)}',
                                    ),
                                    backgroundColor: AppTheme.primaryBlue,
                                  ),
                                );
                              },
                            ),
                          );
                        },
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
  }
}
