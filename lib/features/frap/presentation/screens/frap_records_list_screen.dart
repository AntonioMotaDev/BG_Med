import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bg_med/core/services/frap_unified_service.dart';
import 'package:bg_med/features/frap/presentation/providers/frap_unified_provider.dart';
import 'package:bg_med/features/frap/presentation/screens/frap_record_details_screen.dart';
import 'package:bg_med/features/frap/presentation/screens/frap_screen.dart';
import 'package:bg_med/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class FrapRecordsListScreen extends ConsumerStatefulWidget {
  const FrapRecordsListScreen({super.key});

  @override
  ConsumerState<FrapRecordsListScreen> createState() =>
      _FrapRecordsListScreenState();
}

class _FrapRecordsListScreenState extends ConsumerState<FrapRecordsListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  // Estados de filtrado y paginación
  String _sortBy = 'date';
  bool _sortAscending = false;
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  String _filterType = 'all'; // all, local, cloud

  // Paginación
  int _currentPage = 1;
  final int _itemsPerPage = 25;
  final List<int> _itemsPerPageOptions = [10, 25, 50, 100];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _currentPage = 1;
    });
    _applyFilter();
  }

  Future<void> _applyFilter() async {
    final notifier = ref.read(unifiedFrapProvider.notifier);

    if (_searchQuery.isNotEmpty) {
      await notifier.searchRecords(_searchQuery);
    } else if (_startDate != null && _endDate != null) {
      await notifier.filterByDateRange(_startDate!, _endDate!);
    } else {
      await notifier.loadAllRecords();
    }

    setState(() {
      _currentPage = 1; // Reset pagination when filter changes
    });
  }

  List<UnifiedFrapRecord> _getFilteredAndSortedRecords(
    List<UnifiedFrapRecord> allRecords,
  ) {
    List<UnifiedFrapRecord> filtered = allRecords;

    // Filtrar por tipo (local/cloud)
    if (_filterType == 'local') {
      filtered = filtered.where((record) => record.isLocal).toList();
    } else if (_filterType == 'cloud') {
      filtered = filtered.where((record) => !record.isLocal).toList();
    }

    // Crear una copia de la lista antes de ordenar
    filtered = List<UnifiedFrapRecord>.from(filtered);

    // Ordenar
    filtered.sort((a, b) {
      int result;
      switch (_sortBy) {
        case 'date':
          result = a.createdAt.compareTo(b.createdAt);
          break;
        case 'patient':
          result = a.patientName.compareTo(b.patientName);
          break;
        case 'age':
          result = a.patientAge.compareTo(b.patientAge);
          break;
        case 'completion':
          result = a.completionPercentage.compareTo(b.completionPercentage);
          break;
        default:
          result = a.createdAt.compareTo(b.createdAt);
      }
      return _sortAscending ? result : -result;
    });

    return filtered;
  }

  List<UnifiedFrapRecord> _getPaginatedRecords(
    List<UnifiedFrapRecord> records,
  ) {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    if (startIndex >= records.length) return [];

    return records.sublist(
      startIndex,
      endIndex > records.length ? records.length : endIndex,
    );
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
    });
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange:
          _startDate != null && _endDate != null
              ? DateTimeRange(start: _startDate!, end: _endDate!)
              : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _currentPage = 1;
      });
      await _applyFilter();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _currentPage = 1;
    });
    _applyFilter();
  }

  Future<void> _refreshRecords() async {
    try {
      // Limpiar cualquier error previo
      ref.read(unifiedFrapProvider.notifier).clearError();

      // Forzar recarga completa
      await ref.read(unifiedFrapProvider.notifier).loadAllRecords();

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registros actualizados'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error actualizando registros: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showRecordDetails(UnifiedFrapRecord record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FrapRecordDetailsScreen(record: record),
      ),
    );
  }

  Widget _buildRecordCard(UnifiedFrapRecord record) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => _showRecordDetails(record),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              record.patientName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    record.isLocal
                                        ? AppTheme.primaryBlue
                                        : AppTheme.primaryGreen,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                record.isLocal ? 'LOCAL' : 'NUBE',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Edad: ${record.patientAge} años • ${record.patientGender}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        if (record.patientAddress.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            record.patientAddress,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'view':
                          _showRecordDetails(record);
                          break;
                        case 'edit':
                          _editRecord(record);
                          break;
                        case 'duplicate':
                          _duplicateRecord(record);
                          break;
                        case 'delete':
                          _deleteRecord(record);
                          break;
                      }
                    },
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: Text('Ver detalles'),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Editar'),
                          ),
                          const PopupMenuItem(
                            value: 'duplicate',
                            child: Text('Duplicar'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Eliminar'),
                          ),
                        ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(record.createdAt),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Row(
                    children: [
                      Text(
                        'Completitud: ${record.completionPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 60,
                        height: 4,
                        child: LinearProgressIndicator(
                          value: record.completionPercentage / 100,
                          backgroundColor: Colors.grey.withValues(alpha: 0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            record.completionPercentage >= 80
                                ? Colors.green
                                : record.completionPercentage >= 50
                                ? Colors.orange
                                : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsRow(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Primera fila: Estadísticas básicas
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  stats['total']?.toString() ?? '0',
                  Icons.assignment,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Locales',
                  stats['local']?.toString() ?? '0',
                  Icons.storage,
                  AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Nube',
                  stats['cloud']?.toString() ?? '0',
                  Icons.cloud,
                  AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Hoy',
                  stats['today']?.toString() ?? '0',
                  Icons.today,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Segunda fila: Información de sincronización y duplicados
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Sincronizados',
                  stats['syncedCount']?.toString() ?? '0',
                  Icons.sync,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Solo Local',
                  stats['localOnlyCount']?.toString() ?? '0',
                  Icons.storage_outlined,
                  Colors.blue[300]!,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Duplicados',
                  stats['duplicateCount']?.toString() ?? '0',
                  Icons.warning,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Completitud',
                  '${(stats['averageCompletion'] ?? 0.0).toStringAsFixed(1)}%',
                  Icons.assessment,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Barra de búsqueda
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre del paciente...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Filtro por tipo
              DropdownButton<String>(
                value: _filterType,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Todos')),
                  DropdownMenuItem(value: 'local', child: Text('Locales')),
                  DropdownMenuItem(value: 'cloud', child: Text('Nube')),
                ],
                onChanged: (value) {
                  setState(() {
                    _filterType = value ?? 'all';
                    _currentPage = 1;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Filtros de fecha y ordenamiento
          Row(
            children: [
              // Filtro de fechas
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    _startDate != null && _endDate != null
                        ? '${DateFormat('dd/MM/yy').format(_startDate!)} - ${DateFormat('dd/MM/yy').format(_endDate!)}'
                        : 'Filtrar por fecha',
                  ),
                  onPressed: _selectDateRange,
                ),
              ),

              if (_startDate != null && _endDate != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearDateFilter,
                ),
              ],

              const SizedBox(width: 8),

              // Orden ascendente/descendente
              IconButton(
                icon: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                ),
                onPressed: () {
                  setState(() {
                    _sortAscending = !_sortAscending;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationInfo(int totalRecords) {
    final startIndex = (_currentPage - 1) * _itemsPerPage + 1;
    final endIndex =
        (_currentPage * _itemsPerPage > totalRecords)
            ? totalRecords
            : _currentPage * _itemsPerPage;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Mostrando $startIndex-$endIndex de $totalRecords registros',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            'Página $_currentPage de ${(totalRecords / _itemsPerPage).ceil()}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _editRecord(UnifiedFrapRecord record) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Función de edición para ${record.patientName} próximamente disponible',
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _duplicateRecord(UnifiedFrapRecord record) async {
    final notifier = ref.read(unifiedFrapProvider.notifier);
    final messenger = ScaffoldMessenger.of(context); // Store messenger locally
    final newRecordId = await notifier.duplicateRecord(record);

    if (newRecordId != null && mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Registro duplicado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteRecord(UnifiedFrapRecord record) async {
    final context = this.context; // Store context locally
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: Text(
              '¿Está seguro de eliminar el registro de ${record.patientName}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final notifier = ref.read(unifiedFrapProvider.notifier);
      final messenger = ScaffoldMessenger.of(
        context,
      ); // Store messenger locally
      final result = await notifier.deleteRecord(record);

      if (mounted) {
        // Determinar el color y mensaje según el resultado
        Color snackBarColor;
        String message;

        if (result.success) {
          snackBarColor = Colors.green;
          message = result.message;
        } else if (result.deletedFromLocal && result.cloudError != null) {
          snackBarColor = Colors.orange;
          message = result.message;
        } else {
          snackBarColor = Colors.red;
          message = result.message;
        }

        messenger.showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: snackBarColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showSyncDialog() {
    final context = this.context; // Store context locally to avoid async gap
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sincronizar y Limpiar Registros'),
            content: const Text(
              'Esta acción realizará:\n\n'
              '1. Sincronizar registros locales con la nube\n'
              '2. Detectar registros duplicados\n'
              '3. Eliminar duplicados del almacenamiento local\n\n'
              '¿Desea continuar?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final navigator = Navigator.of(
                    context,
                  ); // Store navigator locally
                  final messenger = ScaffoldMessenger.of(
                    context,
                  ); // Store messenger locally
                  navigator.pop();

                  // Mostrar indicador de progreso
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Text('Sincronizando y limpiando registros...'),
                        ],
                      ),
                      duration: Duration(
                        seconds: 30,
                      ), // Duración larga para operación
                    ),
                  );

                  try {
                    print('Iniciando sincronización...');
                    final result =
                        await ref
                            .read(unifiedFrapProvider.notifier)
                            .syncAndCleanup();

                    if (mounted) {
                      // Cerrar el snackbar de progreso
                      messenger.hideCurrentSnackBar();

                      if (result['success'] == true) {
                        print('Sincronización exitosa: $result');

                        // Recargar registros después de la sincronización
                        await ref
                            .read(unifiedFrapProvider.notifier)
                            .loadAllRecords();

                        final cleanupResult =
                            result['cleanupResult'] as Map<String, dynamic>?;
                        final removedCount =
                            cleanupResult?['removedCount'] ?? 0;
                        final statistics =
                            cleanupResult?['statistics']
                                as Map<String, dynamic>?;
                        final spaceFreed =
                            statistics?['estimatedSpaceFreedMB'] ?? '0.00';

                        String message = 'Sincronización completada';
                        if (removedCount > 0) {
                          message +=
                              '\nSe eliminaron $removedCount registros duplicados';
                          message += '\nEspacio liberado: $spaceFreed MB';
                        } else {
                          message +=
                              '\nNo se encontraron duplicados para eliminar';
                        }

                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(message),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      } else {
                        print('Error en sincronización: $result');
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              result['message'] ??
                                  'Error durante la sincronización',
                            ),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    print('Excepción durante sincronización: $e');
                    if (mounted) {
                      // Cerrar el snackbar de progreso
                      messenger.hideCurrentSnackBar();

                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Sincronizar y Limpiar'),
              ),
            ],
          ),
    );
  }

  // Future<void> _debugDatabaseStatus() async {
  //   try {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Debug completado. Revisa la consola.'),
  //           backgroundColor: Colors.blue,
  //           duration: const Duration(seconds: 2),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Error en debug: $e'),
  //           backgroundColor: Colors.red,
  //           duration: const Duration(seconds: 3),
  //         ),
  //       );
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final unifiedState = ref.watch(unifiedFrapProvider);
    final statistics = ref.watch(unifiedFrapStatisticsProvider);

    final filteredRecords = _getFilteredAndSortedRecords(unifiedState.records);
    final paginatedRecords = _getPaginatedRecords(filteredRecords);
    final totalPages = (filteredRecords.length / _itemsPerPage).ceil();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registros FRAP'),
        actions: [
          // Indicador de duplicados si existen
          if (unifiedState.duplicateCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    '${unifiedState.localDuplicatesCount} duplicados',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshRecords,
          ),
          IconButton(
            icon: const Icon(Icons.cloud_sync),
            onPressed: _showSyncDialog,
            tooltip:
                unifiedState.localDuplicatesCount > 0
                    ? 'Sincronizar y limpiar duplicados'
                    : 'Sincronizar registros',
          ),
          // IconButton(
          //   icon: const Icon(Icons.bug_report),
          //   onPressed: _debugDatabaseStatus,
          //   tooltip: 'Ver estado de la base de datos',
          // ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _currentPage = 1;
              });
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'date',
                    child: Text('Ordenar por fecha'),
                  ),
                  const PopupMenuItem(
                    value: 'patient',
                    child: Text('Ordenar por paciente'),
                  ),
                  const PopupMenuItem(
                    value: 'age',
                    child: Text('Ordenar por edad'),
                  ),
                  const PopupMenuItem(
                    value: 'completion',
                    child: Text('Ordenar por completitud'),
                  ),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Estadísticas
          _buildStatisticsRow(statistics),

          // Filtros
          _buildFiltersSection(),

          // Lista de registros
          Expanded(
            child:
                unifiedState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : unifiedState.error != null
                    ? _buildErrorView(unifiedState.error!)
                    : filteredRecords.isEmpty
                    ? _buildEmptyView()
                    : Column(
                      children: [
                        // Información de paginación
                        _buildPaginationInfo(filteredRecords.length),

                        // Lista de registros
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: paginatedRecords.length,
                            itemBuilder: (context, index) {
                              final record = paginatedRecords[index];
                              return _buildRecordCard(record);
                            },
                          ),
                        ),

                        // Paginación
                        if (totalPages > 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed:
                                      _currentPage > 1
                                          ? () => setState(() => _currentPage--)
                                          : null,
                                  icon: const Icon(Icons.chevron_left),
                                ),
                                Text('Página $_currentPage de $totalPages'),
                                IconButton(
                                  onPressed:
                                      _currentPage < totalPages
                                          ? () => setState(() => _currentPage++)
                                          : null,
                                  icon: const Icon(Icons.chevron_right),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navegar a la pantalla de creación de FRAP
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FrapScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error al cargar los registros',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshRecords,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No hay registros FRAP',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea tu primer registro FRAP presionando el botón +',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
