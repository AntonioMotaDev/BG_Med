// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'frap.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FrapAdapter extends TypeAdapter<Frap> {
  @override
  final int typeId = 3;

  @override
  Frap read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Frap(
      id: fields[0] as String,
      patient: fields[1] as Patient,
      clinicalHistory: fields[2] as ClinicalHistory,
      physicalExam: fields[3] as PhysicalExam,
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime?,
      serviceInfo: (fields[6] as Map).cast<String, dynamic>(),
      registryInfo: (fields[7] as Map).cast<String, dynamic>(),
      management: (fields[8] as Map).cast<String, dynamic>(),
      medications: (fields[9] as Map).cast<String, dynamic>(),
      gynecoObstetric: (fields[10] as Map).cast<String, dynamic>(),
      attentionNegative: (fields[11] as Map).cast<String, dynamic>(),
      pathologicalHistory: (fields[12] as Map).cast<String, dynamic>(),
      priorityJustification: (fields[13] as Map).cast<String, dynamic>(),
      injuryLocation: (fields[14] as Map).cast<String, dynamic>(),
      receivingUnit: (fields[15] as Map).cast<String, dynamic>(),
      patientReception: (fields[16] as Map).cast<String, dynamic>(),
      insumos: (fields[18] as List).cast<Insumo>(),
      personalMedico: (fields[19] as List).cast<PersonalMedico>(),
      escalasObstetricas: fields[20] as EscalasObstetricas?,
      isSynced: fields[21] as bool,
      tipoUrgencia: fields[23] as String?,
      urgenciaEspecifique: fields[24] as String?,
      ubicacion: fields[25] as String?,
      tipoServicioEspecifique: fields[26] as String?,
      lugarOcurrenciaEspecifique: fields[27] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Frap obj) {
    writer
      ..writeByte(26)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.patient)
      ..writeByte(2)
      ..write(obj.clinicalHistory)
      ..writeByte(3)
      ..write(obj.physicalExam)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.serviceInfo)
      ..writeByte(7)
      ..write(obj.registryInfo)
      ..writeByte(8)
      ..write(obj.management)
      ..writeByte(9)
      ..write(obj.medications)
      ..writeByte(10)
      ..write(obj.gynecoObstetric)
      ..writeByte(11)
      ..write(obj.attentionNegative)
      ..writeByte(12)
      ..write(obj.pathologicalHistory)
      ..writeByte(13)
      ..write(obj.priorityJustification)
      ..writeByte(14)
      ..write(obj.injuryLocation)
      ..writeByte(15)
      ..write(obj.receivingUnit)
      ..writeByte(16)
      ..write(obj.patientReception)
      ..writeByte(18)
      ..write(obj.insumos)
      ..writeByte(19)
      ..write(obj.personalMedico)
      ..writeByte(20)
      ..write(obj.escalasObstetricas)
      ..writeByte(21)
      ..write(obj.isSynced)
      ..writeByte(23)
      ..write(obj.tipoUrgencia)
      ..writeByte(24)
      ..write(obj.urgenciaEspecifique)
      ..writeByte(25)
      ..write(obj.ubicacion)
      ..writeByte(26)
      ..write(obj.tipoServicioEspecifique)
      ..writeByte(27)
      ..write(obj.lugarOcurrenciaEspecifique);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FrapAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
