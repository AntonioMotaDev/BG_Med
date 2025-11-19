import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

class InjuryLocationDisplayWidget extends StatefulWidget {
  final List<DrawnInjuryDisplay> drawnInjuries;
  final Size? originalImageSize; // Tamaño original cuando se dibujaron las lesiones
  final Rect? originalImageRect; // Rectángulo original de la imagen
  final double? height; // Altura fija para renderizado en PDF

  const InjuryLocationDisplayWidget({
    super.key,
    required this.drawnInjuries,
    this.originalImageSize,
    this.originalImageRect,
    this.height,
  });

  @override
  State<InjuryLocationDisplayWidget> createState() => _InjuryLocationDisplayWidgetState();
}

class _InjuryLocationDisplayWidgetState extends State<InjuryLocationDisplayWidget> {
  ui.Image? _humanSilhouetteImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHumanSilhouetteImage();
  }

  Future<void> _loadHumanSilhouetteImage() async {
    try {
      final ByteData data = await rootBundle.load('assets/images/silueta_humana.jpeg');
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      
      if (mounted) {
        setState(() {
          _humanSilhouetteImage = frameInfo.image;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error cargando imagen de silueta humana: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              'Cargando mapa de lesiones...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_humanSilhouetteImage == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No se pudo cargar la imagen de la silueta',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Si se proporciona una altura, usar un SizedBox para forzar el tamaño.
    // Esto es ideal para la generación de PDF.
    if (widget.height != null) {
      // Calcular el aspect ratio de la imagen para darle un tamaño predecible al widget.
      // Esto es crucial para que el centrado en el PDF funcione correctamente.
      final imageWidth = _humanSilhouetteImage!.width.toDouble();
      final imageHeight = _humanSilhouetteImage!.height.toDouble();
      final imageAspectRatio = imageWidth / imageHeight;

      return SizedBox(
        height: widget.height,
        // Usar AspectRatio para que el widget tenga un ancho proporcional a su altura,
        // en lugar de `width: double.infinity`.
        child: AspectRatio(
          aspectRatio: imageAspectRatio,
          child: CustomPaint(
            painter: _createPainter(),
            // El painter usará el tamaño que le da el AspectRatio.
          ),
        ),
      );
    }

    // Comportamiento por defecto para la UI normal.
    return CustomPaint(
      painter: _createPainter(),
      size: Size.infinite, // Se adapta al contenedor padre
    );
  }

  InjuryLocationDisplayPainter _createPainter() {
    return InjuryLocationDisplayPainter(
      drawnInjuries: widget.drawnInjuries,
      humanSilhouetteImage: _humanSilhouetteImage!,
      originalImageSize: widget.originalImageSize,
      originalImageRect: widget.originalImageRect,
    );
  }
}

// Modelo para representar una lesión dibujada en modo de visualización
class DrawnInjuryDisplay {
  final List<Offset> points;
  final int injuryType;

  DrawnInjuryDisplay({
    required this.points,
    required this.injuryType,
  });
}

// CustomPainter para mostrar la silueta humana con las lesiones
class InjuryLocationDisplayPainter extends CustomPainter {
  final List<DrawnInjuryDisplay> drawnInjuries;
  final ui.Image humanSilhouetteImage;
  final Size? originalImageSize;
  final Rect? originalImageRect;

  InjuryLocationDisplayPainter({
    required this.drawnInjuries,
    required this.humanSilhouetteImage,
    this.originalImageSize,
    this.originalImageRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dibujar fondo blanco
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Calcular dimensiones y posición de la imagen actual
    final currentImageRect = _calculateImageRect(size);
    
    // Dibujar silueta humana
    _drawHumanSilhouette(canvas, size, currentImageRect);
    
    // Dibujar lesiones con coordenadas transformadas
    for (final injury in drawnInjuries) {
      _drawInjury(canvas, injury, currentImageRect);
    }

    // Si no hay lesiones, mostrar mensaje
    if (drawnInjuries.isEmpty) {
      _drawNoInjuriesMessage(canvas, size);
    }
  }

  // Calcular el rectángulo donde se dibuja la imagen actual
  Rect _calculateImageRect(Size canvasSize) {
    final imageWidth = humanSilhouetteImage.width.toDouble();
    final imageHeight = humanSilhouetteImage.height.toDouble();
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

  void _drawHumanSilhouette(Canvas canvas, Size size, Rect imageRect) {
    final imageWidth = humanSilhouetteImage.width.toDouble();
    final imageHeight = humanSilhouetteImage.height.toDouble();

    // Dibujar la imagen con filtro de alta calidad
    canvas.drawImageRect(
      humanSilhouetteImage,
      Rect.fromLTWH(0, 0, imageWidth, imageHeight),
      imageRect,
      Paint()
        ..filterQuality = FilterQuality.high
        ..isAntiAlias = true,
    );
  }

  void _drawInjury(Canvas canvas, DrawnInjuryDisplay injury, Rect currentImageRect) {
    if (injury.points.isEmpty) return;

    final color = _getInjuryTypeColor(injury.injuryType);
    
    // Transformar las coordenadas de las lesiones
    final transformedPoints = _transformInjuryPoints(injury.points, currentImageRect);
    
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    // Dibujar el path de la lesión con coordenadas transformadas
    if (transformedPoints.isNotEmpty) {
      final path = Path();
      path.moveTo(transformedPoints.first.dx, transformedPoints.first.dy);

      for (int i = 1; i < transformedPoints.length; i++) {
        path.lineTo(transformedPoints[i].dx, transformedPoints[i].dy);
      }

      canvas.drawPath(path, paint);

      // Dibujar círculos en cada punto para hacer más visible la lesión
      final circlePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      for (final point in transformedPoints) {
        canvas.drawCircle(point, 2.0, circlePaint);
      }

      // Dibujar el número de la lesión en el primer punto
      final number = injury.injuryType + 1; // Los números van de 1-10
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$number',
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
        transformedPoints.first, 
        12.0, 
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );

      // Dibujar borde blanco
      canvas.drawCircle(
        transformedPoints.first, 
        12.0, 
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
      
      // Dibujar el texto centrado
      textPainter.paint(
        canvas, 
        Offset(
          transformedPoints.first.dx - textPainter.width / 2,
          transformedPoints.first.dy - textPainter.height / 2,
        ),
      );
    }
  }

  // Transformar las coordenadas de las lesiones desde el espacio original al espacio actual
  List<Offset> _transformInjuryPoints(List<Offset> originalPoints, Rect currentImageRect) {
    // Si tenemos tanto el rectángulo original como el tamaño original, hacer transformación precisa
    if (originalImageRect != null && originalImageSize != null) {
      return originalPoints.map((point) {
        // Convertir coordenadas del canvas original a coordenadas relativas dentro de la imagen original (0.0 - 1.0)
        final relativeX = (point.dx - originalImageRect!.left) / originalImageRect!.width;
        final relativeY = (point.dy - originalImageRect!.top) / originalImageRect!.height;
        
        // Convertir coordenadas relativas al espacio actual de la imagen
        final transformedX = currentImageRect.left + (relativeX * currentImageRect.width);
        final transformedY = currentImageRect.top + (relativeY * currentImageRect.height);
        
        // Asegurar que están dentro de los límites de la imagen actual
        final clampedX = transformedX.clamp(currentImageRect.left, currentImageRect.right);
        final clampedY = transformedY.clamp(currentImageRect.top, currentImageRect.bottom);
        
        return Offset(clampedX, clampedY);
      }).toList();
    }
    
    // Si tenemos solo el tamaño original pero no el rectángulo, asumir que la imagen ocupaba todo el canvas
    if (originalImageSize != null) {
      return originalPoints.map((point) {
        // Convertir coordenadas del canvas original a coordenadas relativas (0.0 - 1.0)
        final relativeX = point.dx / originalImageSize!.width;
        final relativeY = point.dy / originalImageSize!.height;
        
        // Convertir coordenadas relativas al espacio actual de la imagen
        final transformedX = currentImageRect.left + (relativeX * currentImageRect.width);
        final transformedY = currentImageRect.top + (relativeY * currentImageRect.height);
        
        // Asegurar que están dentro de los límites de la imagen
        final clampedX = transformedX.clamp(currentImageRect.left, currentImageRect.right);
        final clampedY = transformedY.clamp(currentImageRect.top, currentImageRect.bottom);
        
        return Offset(clampedX, clampedY);
      }).toList();
    }

    // Si no tenemos información original, intentar escalar basado en coordenadas relativas
    // (fallback para registros antiguos)
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
      final normalizedX = originalWidth > 0 ? (point.dx - minX) / originalWidth : 0.5;
      final normalizedY = originalHeight > 0 ? (point.dy - minY) / originalHeight : 0.5;
      
      final transformedX = currentImageRect.left + (normalizedX * currentImageRect.width);
      final transformedY = currentImageRect.top + (normalizedY * currentImageRect.height);
      
      // Asegurar que están dentro de los límites de la imagen
      final clampedX = transformedX.clamp(currentImageRect.left, currentImageRect.right);
      final clampedY = transformedY.clamp(currentImageRect.top, currentImageRect.bottom);
      
      return Offset(clampedX, clampedY);
    }).toList();
  }

  void _drawNoInjuriesMessage(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'No se han marcado lesiones',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 16,
          fontStyle: FontStyle.italic,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    
    textPainter.paint(
      canvas, 
      Offset(
        (size.width - textPainter.width) / 2, 
        size.height - 40,
      ),
    );
  }

  Color _getInjuryTypeColor(int typeIndex) {
    const colors = [
      Colors.red,           // Hemorragia
      Color(0xFF8D6E63),   // Herida (brown)
      Colors.purple,        // Contusión
      Colors.orange,        // Fractura
      Colors.yellow,        // Luxación/Esguince
      Colors.pink,          // Objeto extraño
      Colors.deepOrange,    // Quemadura
      Colors.green,         // Picadura/Mordedura
      Colors.indigo,        // Edema/Hematoma
      Colors.grey,          // Otro
    ];
    
    if (typeIndex >= 0 && typeIndex < colors.length) {
      return colors[typeIndex];
    }
    return Colors.grey;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
} 