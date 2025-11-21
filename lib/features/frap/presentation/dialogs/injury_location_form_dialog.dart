import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:bg_med/core/theme/app_theme.dart';

class InjuryLocationFormDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  final Map<String, dynamic>? initialData;

  const InjuryLocationFormDialog({
    super.key,
    required this.onSave,
    this.initialData,
  });

  @override
  State<InjuryLocationFormDialog> createState() => _InjuryLocationFormDialogState();
}

class _InjuryLocationFormDialogState extends State<InjuryLocationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Lista de puntos dibujados
  List<DrawnInjury> _drawnInjuries = [];
  
  // Tipo de lesión seleccionado
  InjuryType _selectedInjuryType = InjuryType.hemorragia;
  
  // Controlador para notas adicionales
  final _notesController = TextEditingController();
  
  // GlobalKey para el CustomPaint
  final GlobalKey _paintKey = GlobalKey();
  
  // Imagen de la silueta humana
  ui.Image? _humanSilhouetteImage;

  // Tamaño del canvas/imagen original donde se dibujaron las lesiones
  Size? _originalCanvasSize;

  // Rectángulo de la imagen dentro del canvas original
  Rect? _originalImageRect;

  @override
  void initState() {
    super.initState();
    _lockOrientation();
    _loadHumanSilhouetteImage();
    _initializeForm();
  }

  @override
  void dispose() {
    _unlockOrientation();
    _notesController.dispose();
    super.dispose();
  }

  // Bloquear rotación de pantalla
  void _lockOrientation() {
    // Permitir todas las orientaciones ya que tenemos tamaño fijo de imagen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  // Desbloquear rotación de pantalla
  void _unlockOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  // Cargar imagen de silueta humana
  Future<void> _loadHumanSilhouetteImage() async {
    try {
      final ByteData data = await rootBundle.load('assets/images/silueta_humana.jpeg');
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      setState(() {
        _humanSilhouetteImage = frameInfo.image;
      });
    } catch (e) {
      print('Error cargando imagen de silueta humana: $e');
    }
  }

  void _initializeForm() {
    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      final data = widget.initialData!;
      _notesController.text = data['notes'] ?? '';
      
      // Cargar lesiones dibujadas si existen
      if (data['drawnInjuries'] != null) {
        final List<dynamic> injuriesData = data['drawnInjuries'];
        _drawnInjuries = injuriesData.map((injury) => DrawnInjury.fromMap(injury)).toList();
      }
    }
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
                  const Icon(
                    Icons.my_location,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'LOCALIZACIÓN DE LESIONES',
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
                child: Row(
                  children: [
                    // Panel izquierdo - Tipos de lesiones
                    Container(
                      width: 250,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border(
                          right: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'TIPOS DE LESIONES',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              children: InjuryType.values.map((type) {
                                final isSelected = _selectedInjuryType == type;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: Material(
                                    color: isSelected ? type.color.withOpacity(0.2) : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () {
                                        setState(() {
                                          _selectedInjuryType = type;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: isSelected ? type.color : Colors.grey[300]!,
                                            width: isSelected ? 2 : 1,
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: type.color,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: 2),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.2),
                                                    blurRadius: 2,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '${type.number}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                type.label,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                  color: isSelected ? type.color : Colors.black87,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          // Herramientas
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                top: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'HERRAMIENTAS',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _clearAllInjuries,
                                        icon: const Icon(Icons.clear_all, size: 16),
                                        label: const Text('Limpiar Todo'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red[600],
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _undoLastInjury,
                                        icon: const Icon(Icons.undo, size: 16),
                                        label: const Text('Deshacer'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange[600],
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Panel central - Mapa de silueta humana
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: GestureDetector(
                                  onPanStart: _onPanStart,
                                  onPanUpdate: _onPanUpdate,
                                  onPanEnd: _onPanEnd,
                                  child: CustomPaint(
                                    key: _paintKey,
                                    painter: InjuryMapPainter(
                                      drawnInjuries: _drawnInjuries,
                                      humanSilhouetteImage: _humanSilhouetteImage,
                                    ),
                                    size: Size.infinite,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          // Campo de notas
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Notas adicionales',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _notesController,
                                  decoration: const InputDecoration(
                                    hintText: 'Describa detalles adicionales sobre las lesiones...',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.all(12),
                                  ),
                                  maxLines: 2,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isLoading ? 'Guardando...' : 'Guardar Localización'),
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

  void _onPanStart(DragStartDetails details) {
    final RenderBox renderBox = _paintKey.currentContext!.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    
    // Capturar el tamaño del canvas la primera vez que se dibuja
    if (_originalCanvasSize == null) {
      _originalCanvasSize = renderBox.size;
      
      // También calcular el rectángulo de la imagen original
      if (_humanSilhouetteImage != null) {
        _originalImageRect = _calculateImageRect(_originalCanvasSize!);
      }
    }
    
    // Crear nueva lesión
    final newInjury = DrawnInjury(
      points: [localPosition],
      injuryType: _selectedInjuryType,
    );
    
    setState(() {
      _drawnInjuries.add(newInjury);
    });
  }

  // Calcular el rectángulo donde se dibuja la imagen (igual que en el display widget)
  Rect _calculateImageRect(Size canvasSize) {
    if (_humanSilhouetteImage == null) {
      return Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height);
    }

    final imageWidth = _humanSilhouetteImage!.width.toDouble();
    final imageHeight = _humanSilhouetteImage!.height.toDouble();
    final imageAspectRatio = imageWidth / imageHeight;
    
    // Calcular dimensiones manteniendo aspect ratio (igual lógica que InjuryMapPainter)
    double targetWidth, targetHeight;
    
    if (canvasSize.width / canvasSize.height > imageAspectRatio) {
      // Ajustar por altura
      targetHeight = canvasSize.height * 0.9;
      targetWidth = targetHeight * imageAspectRatio;
    } else {
      // Ajustar por anchura
      targetWidth = canvasSize.width * 0.9;
      targetHeight = targetWidth / imageAspectRatio;
    }

    // Centrar la imagen
    final offsetX = (canvasSize.width - targetWidth) / 2;
    final offsetY = (canvasSize.height - targetHeight) / 2;

    return Rect.fromLTWH(offsetX, offsetY, targetWidth, targetHeight);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    /*final RenderBox renderBox = _paintKey.currentContext!.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    
    setState(() {
      if (_drawnInjuries.isNotEmpty) {
        _drawnInjuries.last.points.add(localPosition);
      }
    });*/
  }

  void _onPanEnd(DragEndDetails details) {
    // Finalizar el trazo actual
  }

  void _clearAllInjuries() {
    setState(() {
      _drawnInjuries.clear();
    });
  }

  void _undoLastInjury() {
    setState(() {
      if (_drawnInjuries.isNotEmpty) {
        _drawnInjuries.removeLast();
      }
    });
  }

  Future<void> _saveForm() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener el tamaño actual del canvas si no se ha guardado ya
      if (_originalCanvasSize == null && _paintKey.currentContext != null) {
        final RenderBox renderBox = _paintKey.currentContext!.findRenderObject() as RenderBox;
        _originalCanvasSize = renderBox.size;
        
        // También calcular el rectángulo de la imagen original
        if (_humanSilhouetteImage != null) {
          _originalImageRect = _calculateImageRect(_originalCanvasSize!);
        }
      }

      final formData = {
        'drawnInjuries': _drawnInjuries.map((injury) => injury.toMap()).toList(),
        'notes': _notesController.text.trim(),
        'timestamp': DateTime.now().toIso8601String(),
        'originalImageSize': _originalCanvasSize != null ? {
          'width': _originalCanvasSize!.width,
          'height': _originalCanvasSize!.height,
        } : null,
        'originalImageRect': _originalImageRect != null ? {
          'left': _originalImageRect!.left,
          'top': _originalImageRect!.top,
          'width': _originalImageRect!.width,
          'height': _originalImageRect!.height,
        } : null,
      };

      widget.onSave(formData);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Localización de lesiones guardada exitosamente'),
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

// Modelo para representar una lesión dibujada
class DrawnInjury {
  final List<Offset> points;
  final InjuryType injuryType;

  DrawnInjury({
    required this.points,
    required this.injuryType,
  });

  Map<String, dynamic> toMap() {
    return {
      'points': points.map((point) => {'dx': point.dx, 'dy': point.dy}).toList(),
      'injuryType': injuryType.index,
    };
  }

  factory DrawnInjury.fromMap(Map<String, dynamic> map) {
    final List<dynamic> pointsData = map['points'];
    final points = pointsData.map((point) => Offset(point['dx'], point['dy'])).toList();
    final injuryType = InjuryType.values[map['injuryType']];
    
    return DrawnInjury(
      points: points,
      injuryType: injuryType,
    );
  }
}

// Enum para tipos de lesiones
enum InjuryType {
  hemorragia(1, 'Hemorragia', Colors.red),
  herida(2, 'Herida', Colors.brown),
  contusion(3, 'Contusión', Colors.purple),
  fractura(4, 'Fractura', Colors.orange),
  luxacion(5, 'Luxación/Esguince', Colors.yellow),
  objetoExtrano(6, 'Objeto extraño', Colors.pink),
  quemadura(7, 'Quemadura', Colors.deepOrange),
  picadura(8, 'Picadura/Mordedura', Colors.green),
  edema(9, 'Edema/Hematoma', Colors.indigo),
  otro(10, 'Otro', Colors.grey);

  const InjuryType(this.number, this.label, this.color);
  
  final int number;
  final String label;
  final Color color;
}

// CustomPainter para dibujar la silueta humana y las lesiones
class InjuryMapPainter extends CustomPainter {
  final List<DrawnInjury> drawnInjuries;
  final ui.Image? humanSilhouetteImage;

  InjuryMapPainter({
    required this.drawnInjuries,
    required this.humanSilhouetteImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dibujar fondo blanco
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Dibujar silueta humana
    _drawHumanSilhouette(canvas, size);
    
    // Dibujar lesiones
    for (final injury in drawnInjuries) {
      _drawInjury(canvas, injury);
    }
  }

  void _drawHumanSilhouette(Canvas canvas, Size size) {
    // Intentar cargar y mostrar la imagen real
    if (humanSilhouetteImage != null) {
      _drawImageSilhouette(canvas, size);
    } else {
      _drawPlaceholderSilhouette(canvas, size);
    }
  }

  void _drawImageSilhouette(Canvas canvas, Size size) {
    if (humanSilhouetteImage == null) return;

    // Calcular dimensiones para mantener aspect ratio
    final imageWidth = humanSilhouetteImage!.width.toDouble();
    final imageHeight = humanSilhouetteImage!.height.toDouble();
    final imageAspectRatio = imageWidth / imageHeight;
    
    // Usar dimensiones fijas independientes de la orientación
    // Obtener tamaño óptimo basado en las dimensiones de la pantalla
    final double fixedHeight = _getOptimalFixedHeight(size);
    final double fixedWidth = fixedHeight * imageAspectRatio;
    
    // Verificar que la imagen fija quepa en el canvas disponible
    double targetWidth = fixedWidth;
    double targetHeight = fixedHeight;
    
    // Si las dimensiones fijas son muy grandes para el canvas, escalar proporcionalmente
    if (targetWidth > size.width * 0.9) {
      targetWidth = size.width * 0.9;
      targetHeight = targetWidth / imageAspectRatio;
    }
    
    if (targetHeight > size.height * 0.9) {
      targetHeight = size.height * 0.9;
      targetWidth = targetHeight * imageAspectRatio;
    }

    // Centrar la imagen
    final offsetX = (size.width - targetWidth) / 2;
    final offsetY = (size.height - targetHeight) / 2;

    // Crear el rectángulo de la imagen
    final currentImageRect = Rect.fromLTWH(offsetX, offsetY, targetWidth, targetHeight);

    // Dibujar la imagen con filtro de alta calidad
    canvas.drawImageRect(
      humanSilhouetteImage!,
      Rect.fromLTWH(0, 0, imageWidth, imageHeight),
      currentImageRect,
      Paint()
        ..filterQuality = FilterQuality.high
        ..isAntiAlias = true,
    );

    // Agregar texto de instrucción sobre la imagen real
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    textPainter.text = TextSpan(
      text: 'Seleccione un tipo de lesión y dibuje sobre la silueta',
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: 14,
        fontWeight: FontWeight.w500,
        shadows: [
          Shadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 2.0,
            offset: const Offset(1, 1),
          ),
        ],
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas, 
      Offset(
        (size.width - textPainter.width) / 2, 
        offsetY + targetHeight + 10,
      ),
    );
  }

  void _drawPlaceholderSilhouette(Canvas canvas, Size size) {
    // Mostrar indicador de carga
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Mensaje de carga
    textPainter.text = TextSpan(
      text: 'Cargando silueta humana...',
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas, 
      Offset(
        (size.width - textPainter.width) / 2, 
        (size.height - textPainter.height) / 2 - 20,
      ),
    );

    // Indicador visual de carga
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2 + 20),
      20,
      paint,
    );

    // Instrucciones
    textPainter.text = TextSpan(
      text: 'Por favor espere mientras se carga la imagen de la silueta humana',
      style: TextStyle(
        color: Colors.grey[500],
        fontSize: 14,
        fontStyle: FontStyle.italic,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas, 
      Offset(
        (size.width - textPainter.width) / 2, 
        size.height - 60,
      ),
    );
  }

  void _drawInjury(Canvas canvas, DrawnInjury injury) {
    if (injury.points.isEmpty) return;

    final paint = Paint()
      ..color = injury.injuryType.color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(injury.points.first.dx, injury.points.first.dy);

    for (int i = 1; i < injury.points.length; i++) {
      path.lineTo(injury.points[i].dx, injury.points[i].dy);
    }

    canvas.drawPath(path, paint);

    // Dibujar círculos en cada punto para hacer más visible la lesión
    final circlePaint = Paint()
      ..color = injury.injuryType.color
      ..style = PaintingStyle.fill;

    for (final point in injury.points) {
      canvas.drawCircle(point, 3.0, circlePaint);
    }

    // Dibujar el número de la lesión en el primer punto
    if (injury.points.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${injury.injuryType.number}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      
      // Dibujar círculo de fondo para el número
      canvas.drawCircle(
        injury.points.first, 
        10.0, 
        Paint()..color = injury.injuryType.color.withOpacity(0.8),
      );
      
      // Dibujar el texto centrado
      textPainter.paint(
        canvas, 
        Offset(
          injury.points.first.dx - textPainter.width / 2,
          injury.points.first.dy - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  // Obtener tamaño fijo óptimo basado en las dimensiones de la pantalla (método de instancia)
  double _getOptimalFixedHeight(Size screenSize) {
    // Determinar si estamos en orientación vertical u horizontal
    final bool isLandscape = screenSize.width > screenSize.height;
    
    if (isLandscape) {
      // En horizontal, usar altura fija de 350px para dejar espacio a los controles
      return 350.0;
    } else {
      // En vertical, usar altura fija de 400px
      return 400.0;
    }
  }
} 