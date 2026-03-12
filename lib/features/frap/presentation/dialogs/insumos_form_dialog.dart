import 'package:flutter/material.dart';
import 'package:bg_med/core/theme/app_theme.dart';

class InsumosFormDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  final Map<String, dynamic>? initialData;

  const InsumosFormDialog({super.key, required this.onSave, this.initialData});

  @override
  State<InsumosFormDialog> createState() => _InsumosFormDialogState();
}

class _InsumosFormDialogState extends State<InsumosFormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Lista de insumos
  List<InsumoRow> _insumos = [];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.initialData != null) {
      final data = widget.initialData!;

      // Si hay insumos guardados en formato de tabla
      if (data['insumosList'] != null) {
        try {
          final dynamic insumosListData = data['insumosList'];

          if (insumosListData is List) {
            _insumos =
                insumosListData.map((insumo) {
                  if (insumo is Map) {
                    return InsumoRow(
                      cantidad: _parseDoubleSafely(insumo['cantidad']),
                      articulo: insumo['articulo']?.toString() ?? '',
                    );
                  }
                  return InsumoRow();
                }).toList();
          } else if (insumosListData is String) {
            // Si viene como String, parsear
            _insumos = _parseTextToInsumos(insumosListData);
          }
        } catch (e) {
          print('Error al parsear insumosList: $e');
        }
      } else if (data['insumos'] != null &&
          data['insumos'].toString().isNotEmpty) {
        // Migrar de formato texto libre a tabla
        final String insumosText = data['insumos'].toString();
        _insumos = _parseTextToInsumos(insumosText);
      }
    }

    // Si no hay insumos, agregar una fila vacía
    if (_insumos.isEmpty) {
      _addInsumoRow();
    }
  }

  double _parseDoubleSafely(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  List<InsumoRow> _parseTextToInsumos(String text) {
    final List<InsumoRow> insumos = [];
    final lines = text.split('\n');

    for (final line in lines) {
      if (line.trim().isNotEmpty) {
        // Intentar parsear líneas con formato común
        final parts = line.split(' - ');
        if (parts.length >= 2) {
          final cantidad = double.tryParse(parts[0].trim()) ?? 0.0;
          insumos.add(InsumoRow(cantidad: cantidad, articulo: parts[1].trim()));
        } else {
          // Si no se puede parsear, agregar como artículo general
          insumos.add(InsumoRow(cantidad: 1.0, articulo: line.trim()));
        }
      }
    }

    return insumos;
  }

  void _addInsumoRow() {
    setState(() {
      _insumos.add(InsumoRow());
    });
  }

  void _removeInsumoRow(int index) {
    setState(() {
      _insumos.removeAt(index);
      // Asegurar que siempre haya al menos una fila
      if (_insumos.isEmpty) {
        _addInsumoRow();
      }
    });
  }

  void _updateInsumoRow(int index, InsumoRow insumo) {
    setState(() {
      _insumos[index] = insumo;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.85,
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
                  const Icon(Icons.inventory, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'INSUMOS',
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
                      // Título y descripción
                      const Text(
                        'Registro de Insumos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Registre todos los insumos utilizados durante la atención prehospitalaria.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tabla de insumos
                      _buildInsumosTable(),

                      const SizedBox(height: 16),

                      // Botón para agregar insumo
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _addInsumoRow,
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar Insumo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Guía de formato
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withAlpha(26),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryBlue.withAlpha(26),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppTheme.primaryBlue,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Información importante:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryBlue,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '• Complete todos los campos obligatorios\n'
                              '• La cantidad debe ser un número mayor a 0\n'
                              '• Especifique el artículo de manera clara y concisa\n'
                              '• Puede agregar o eliminar insumos según sea necesario',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.primaryBlue.withAlpha(204),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildInsumosTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de la tabla
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withAlpha(26),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            border: Border.all(color: AppTheme.primaryBlue.withAlpha(77)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Cantidad',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Artículo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 40), // Espacio para botón eliminar
            ],
          ),
        ),

        // Filas de insumos
        ...List.generate(_insumos.length, (index) {
          return _buildInsumoRow(index);
        }),
      ],
    );
  }

  Widget _buildInsumoRow(int index) {
    final insumo = _insumos[index];
    final isLastRow = index == _insumos.length - 1;

    return Container(
      margin: EdgeInsets.only(bottom: isLastRow ? 0 : 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Cantidad
            Expanded(
              child: TextFormField(
                initialValue:
                    insumo.cantidad > 0.0 ? insumo.cantidad.toString() : '',
                decoration: const InputDecoration(
                  hintText: '1',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                style: const TextStyle(fontSize: 14),
                keyboardType: TextInputType.numberWithOptions(
                  decimal: true,
                  signed: false,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Requerido';
                  }
                  final cantidad = double.tryParse(value);
                  if (cantidad == null || cantidad <= 0) {
                    return '> 0';
                  }
                  return null;
                },
                onChanged: (value) {
                  final cantidad = double.tryParse(value) ?? 0.0;
                  _updateInsumoRow(index, insumo.copyWith(cantidad: cantidad));
                },
              ),
            ),
            const SizedBox(width: 12),

            // Artículo
            Expanded(
              flex: 3,
              child: TextFormField(
                initialValue: insumo.articulo,
                decoration: const InputDecoration(
                  hintText: 'Ej: Gasas estériles',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                style: const TextStyle(fontSize: 14),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Requerido';
                  }
                  return null;
                },
                onChanged: (value) {
                  _updateInsumoRow(index, insumo.copyWith(articulo: value));
                },
              ),
            ),
            const SizedBox(width: 12),

            // Botón eliminar
            if (_insumos.length > 1)
              IconButton(
                onPressed: () => _removeInsumoRow(index),
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              )
            else
              const SizedBox(width: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validar que al menos un insumo tenga datos
    bool hasValidInsumo = false;
    for (final insumo in _insumos) {
      if (insumo.cantidad > 0 && insumo.articulo.isNotEmpty) {
        hasValidInsumo = true;
        break;
      }
    }

    if (!hasValidInsumo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe registrar al menos un insumo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Filtrar insumos con datos
      final validInsumos =
          _insumos
              .where(
                (insumo) => insumo.cantidad > 0.0 && insumo.articulo.isNotEmpty,
              )
              .toList();

      final insumosList =
          validInsumos
              .map(
                (insumo) => {
                  'cantidad': insumo.cantidad,
                  'articulo': insumo.articulo,
                },
              )
              .toList();

      final formData = {'insumosList': insumosList};

      print('=== GUARDANDO INSUMOS ===');
      print('Insumos válidos: ${validInsumos.length}');
      print('FormData: $formData');

      widget.onSave(formData);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${validInsumos.length} insumo(s) guardado(s) correctamente',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('=== ERROR AL GUARDAR INSUMOS ===');
      print('Error: $e');
      print('StackTrace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error al guardar: ${e.toString().substring(0, e.toString().length > 100 ? 100 : e.toString().length)}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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

// Clase para representar una fila de insumo
class InsumoRow {
  final double cantidad;
  final String articulo;

  const InsumoRow({this.cantidad = 0.0, this.articulo = ''});

  InsumoRow copyWith({double? cantidad, String? articulo}) {
    return InsumoRow(
      cantidad: cantidad ?? this.cantidad,
      articulo: articulo ?? this.articulo,
    );
  }
}
