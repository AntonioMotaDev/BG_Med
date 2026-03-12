import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'insumo.g.dart';

@HiveType(typeId: 21)
class Insumo extends Equatable {
  @HiveField(0)
  final double cantidad;
  @HiveField(1)
  final String articulo;

  const Insumo({this.cantidad = 0.0, this.articulo = ''});

  Insumo copyWith({double? cantidad, String? articulo}) {
    return Insumo(
      cantidad: cantidad ?? this.cantidad,
      articulo: articulo ?? this.articulo,
    );
  }

  Map<String, dynamic> toJson() => {'cantidad': cantidad, 'articulo': articulo};

  @override
  List<Object?> get props => [cantidad, articulo];
}
