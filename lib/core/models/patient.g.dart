// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PatientAdapter extends TypeAdapter<Patient> {
  @override
  final int typeId = 0;

  @override
  Patient read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Patient(
      name: fields[0] as String,
      age: fields[1] as int,
      sex: fields[2] as String,
      gender: fields[16] as String,
      address: fields[3] as String,
      addressDetails: fields[4] as String,
      firstName: fields[5] as String,
      paternalLastName: fields[6] as String,
      maternalLastName: fields[7] as String,
      phone: fields[8] as String,
      street: fields[9] as String,
      exteriorNumber: fields[10] as String,
      interiorNumber: fields[11] as String?,
      neighborhood: fields[12] as String,
      city: fields[13] as String,
      insurance: fields[14] as String,
      responsiblePerson: fields[15] as String?,
      tipoEntrega: fields[17] as String,
      emergencyContact: fields[18] as String?,
      currentCondition: fields[19] as String?,
      tipoEntregaOtro: fields[20] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Patient obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.age)
      ..writeByte(2)
      ..write(obj.sex)
      ..writeByte(3)
      ..write(obj.address)
      ..writeByte(4)
      ..write(obj.addressDetails)
      ..writeByte(5)
      ..write(obj.firstName)
      ..writeByte(6)
      ..write(obj.paternalLastName)
      ..writeByte(7)
      ..write(obj.maternalLastName)
      ..writeByte(8)
      ..write(obj.phone)
      ..writeByte(9)
      ..write(obj.street)
      ..writeByte(10)
      ..write(obj.exteriorNumber)
      ..writeByte(11)
      ..write(obj.interiorNumber)
      ..writeByte(12)
      ..write(obj.neighborhood)
      ..writeByte(13)
      ..write(obj.city)
      ..writeByte(14)
      ..write(obj.insurance)
      ..writeByte(15)
      ..write(obj.responsiblePerson)
      ..writeByte(16)
      ..write(obj.gender)
      ..writeByte(17)
      ..write(obj.tipoEntrega)
      ..writeByte(18)
      ..write(obj.emergencyContact)
      ..writeByte(19)
      ..write(obj.currentCondition)
      ..writeByte(20)
      ..write(obj.tipoEntregaOtro);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatientAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
