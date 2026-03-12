// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clinical_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClinicalHistoryAdapter extends TypeAdapter<ClinicalHistory> {
  @override
  final int typeId = 1;

  @override
  ClinicalHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClinicalHistory(
      traumaCraneo: fields[0] as bool,
      traumaCraneoEspecifique: fields[1] as String,
      traumaTorax: fields[2] as bool,
      traumaToraxEspecifique: fields[3] as String,
      traumaAbdomen: fields[4] as bool,
      traumaAbdomenEspecifique: fields[5] as String,
      traumaColumna: fields[6] as bool,
      traumaColumnaEspecifique: fields[7] as String,
      traumaExtremidades: fields[8] as bool,
      traumaExtremidadesEspecifique: fields[9] as String,
      traumaPelvis: fields[10] as bool,
      traumaPelvisEspecifique: fields[11] as String,
      traumaOtros: fields[12] as bool,
      traumaOtrosEspecifique: fields[13] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ClinicalHistory obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.traumaCraneo)
      ..writeByte(1)
      ..write(obj.traumaCraneoEspecifique)
      ..writeByte(2)
      ..write(obj.traumaTorax)
      ..writeByte(3)
      ..write(obj.traumaToraxEspecifique)
      ..writeByte(4)
      ..write(obj.traumaAbdomen)
      ..writeByte(5)
      ..write(obj.traumaAbdomenEspecifique)
      ..writeByte(6)
      ..write(obj.traumaColumna)
      ..writeByte(7)
      ..write(obj.traumaColumnaEspecifique)
      ..writeByte(8)
      ..write(obj.traumaExtremidades)
      ..writeByte(9)
      ..write(obj.traumaExtremidadesEspecifique)
      ..writeByte(10)
      ..write(obj.traumaPelvis)
      ..writeByte(11)
      ..write(obj.traumaPelvisEspecifique)
      ..writeByte(12)
      ..write(obj.traumaOtros)
      ..writeByte(13)
      ..write(obj.traumaOtrosEspecifique);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClinicalHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
