// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'insumo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InsumoAdapter extends TypeAdapter<Insumo> {
  @override
  final int typeId = 21;

  @override
  Insumo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    final rawCantidad = fields[0];
    final double cantidad =
        rawCantidad == null
            ? 0.0
            : (rawCantidad is int
                ? rawCantidad.toDouble()
                : (rawCantidad as double));
    return Insumo(cantidad: cantidad, articulo: fields[1] as String);
  }

  @override
  void write(BinaryWriter writer, Insumo obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.cantidad)
      ..writeByte(1)
      ..write(obj.articulo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InsumoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
