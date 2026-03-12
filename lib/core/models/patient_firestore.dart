import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class PatientFirestore extends Equatable {
  final String? id; // Firestore document ID
  final int age;
  final String city;
  final DateTime createdAt;
  final String exteriorNumber;
  final String firstName;
  final String insurance;
  final String? interiorNumber; // nullable
  final String maternalLastName;
  final String neighborhood;
  final String paternalLastName;
  final String phone;
  final String? responsiblePerson; // nullable
  final String? emergencyContact; // nullable
  final String sex;
  final String? gender;
  final String? addressDetails;
  final String street;
  final DateTime updatedAt;

  const PatientFirestore({
    this.id,
    required this.age,
    required this.city,
    required this.createdAt,
    required this.exteriorNumber,
    required this.firstName,
    required this.insurance,
    this.interiorNumber,
    required this.maternalLastName,
    required this.neighborhood,
    required this.paternalLastName,
    required this.phone,
    this.responsiblePerson,
    this.emergencyContact,
    required this.sex,
    this.gender,
    this.addressDetails,
    required this.street,
    required this.updatedAt,
  });

  // Getter para el nombre completo
  String get fullName =>
      '$firstName $paternalLastName $maternalLastName'.trim();

  // Getter para la dirección completa
  String get fullAddress {
    final interior =
        interiorNumber != null && interiorNumber!.isNotEmpty
            ? ', Int. $interiorNumber'
            : '';
    final details =
        addressDetails != null && addressDetails!.isNotEmpty
            ? ', $addressDetails'
            : '';
    return '$street $exteriorNumber$interior, $neighborhood, $city$details';
  }

  // Factory constructor desde Firestore
  factory PatientFirestore.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final defaultDate = DateTime.fromMillisecondsSinceEpoch(0);

    // Helper function para convertir timestamps de manera segura
    DateTime parseTimestamp(dynamic timestamp, {DateTime? fallback}) {
      final fallbackDate = fallback ?? defaultDate;
      if (timestamp == null) {
        return fallbackDate;
      }
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      }
      if (timestamp is String) {
        try {
          return DateTime.parse(timestamp);
        } catch (_) {
          return fallbackDate;
        }
      }
      return fallbackDate;
    }

    final updatedAt = parseTimestamp(data['updatedAt']);
    final createdAt = parseTimestamp(data['createdAt'], fallback: updatedAt);

    return PatientFirestore(
      id: doc.id,
      age: data['age'] ?? 0,
      city: data['city'] ?? '',
      createdAt: createdAt,
      exteriorNumber: data['exteriorNumber'] ?? '',
      firstName: data['firstName'] ?? '',
      insurance: data['insurance'] ?? '',
      interiorNumber: data['interiorNumber'],
      maternalLastName: data['maternalLastName'] ?? '',
      neighborhood: data['neighborhood'] ?? '',
      paternalLastName: data['paternalLastName'] ?? '',
      phone: data['phone'] ?? '',
      responsiblePerson: data['responsiblePerson'],
      emergencyContact: data['emergencyContact'],
      sex: data['sex'] ?? '',
      gender: data['gender'] ?? '',
      addressDetails: data['addressDetails'] ?? '',
      street: data['street'] ?? '',
      updatedAt: updatedAt,
    );
  }

  // Factory constructor desde Map
  factory PatientFirestore.fromMap(Map<String, dynamic> data, String id) {
    final defaultDate = DateTime.fromMillisecondsSinceEpoch(0);

    // Helper function para convertir timestamps de manera segura
    DateTime parseTimestamp(dynamic timestamp, {DateTime? fallback}) {
      final fallbackDate = fallback ?? defaultDate;
      if (timestamp == null) {
        return fallbackDate;
      }
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      }
      if (timestamp is String) {
        try {
          return DateTime.parse(timestamp);
        } catch (_) {
          return fallbackDate;
        }
      }
      return fallbackDate;
    }

    final updatedAt = parseTimestamp(data['updatedAt']);
    final createdAt = parseTimestamp(data['createdAt'], fallback: updatedAt);

    return PatientFirestore(
      id: id,
      age: data['age'] ?? 0,
      city: data['city'] ?? '',
      createdAt: createdAt,
      exteriorNumber: data['exteriorNumber'] ?? '',
      firstName: data['firstName'] ?? '',
      insurance: data['insurance'] ?? '',
      interiorNumber: data['interiorNumber'],
      maternalLastName: data['maternalLastName'] ?? '',
      neighborhood: data['neighborhood'] ?? '',
      paternalLastName: data['paternalLastName'] ?? '',
      phone: data['phone'] ?? '',
      responsiblePerson: data['responsiblePerson'],
      emergencyContact: data['emergencyContact'],
      sex: data['sex'] ?? '',
      gender: data['gender'] ?? '',
      street: data['street'] ?? '',
      addressDetails: data['addressDetails'] ?? '',
      updatedAt: updatedAt,
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'age': age,
      'city': city,
      'createdAt': Timestamp.fromDate(createdAt),
      'exteriorNumber': exteriorNumber,
      'firstName': firstName,
      'insurance': insurance,
      'interiorNumber': interiorNumber,
      'maternalLastName': maternalLastName,
      'neighborhood': neighborhood,
      'paternalLastName': paternalLastName,
      'phone': phone,
      'responsiblePerson': responsiblePerson,
      'emergencyContact': emergencyContact,
      'sex': sex,
      'gender': gender,
      'addressDetails': addressDetails,
      'street': street,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Convertir a Map sin timestamps (para casos especiales)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'age': age,
      'city': city,
      'createdAt': createdAt.toIso8601String(),
      'exteriorNumber': exteriorNumber,
      'firstName': firstName,
      'insurance': insurance,
      'interiorNumber': interiorNumber,
      'maternalLastName': maternalLastName,
      'neighborhood': neighborhood,
      'paternalLastName': paternalLastName,
      'phone': phone,
      'responsiblePerson': responsiblePerson,
      'emergencyContact': emergencyContact,
      'sex': sex,
      'gender': gender,
      'addressDetails': addressDetails,
      'street': street,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Método copyWith para crear copias con cambios
  PatientFirestore copyWith({
    String? id,
    int? age,
    String? city,
    DateTime? createdAt,
    String? exteriorNumber,
    String? firstName,
    String? insurance,
    String? interiorNumber,
    String? maternalLastName,
    String? neighborhood,
    String? paternalLastName,
    String? phone,
    String? responsiblePerson,
    String? emergencyContact,
    String? sex,
    String? gender,
    String? addressDetails,
    String? street,
    DateTime? updatedAt,
  }) {
    return PatientFirestore(
      id: id ?? this.id,
      age: age ?? this.age,
      city: city ?? this.city,
      createdAt: createdAt ?? this.createdAt,
      exteriorNumber: exteriorNumber ?? this.exteriorNumber,
      firstName: firstName ?? this.firstName,
      insurance: insurance ?? this.insurance,
      interiorNumber: interiorNumber ?? this.interiorNumber,
      maternalLastName: maternalLastName ?? this.maternalLastName,
      neighborhood: neighborhood ?? this.neighborhood,
      paternalLastName: paternalLastName ?? this.paternalLastName,
      phone: phone ?? this.phone,
      responsiblePerson: responsiblePerson ?? this.responsiblePerson,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      sex: sex ?? this.sex,
      gender: gender ?? this.gender,
      addressDetails: addressDetails ?? this.addressDetails,
      street: street ?? this.street,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Método para crear un nuevo paciente (sin ID, con timestamps actuales)
  factory PatientFirestore.create({
    required int age,
    required String city,
    required String exteriorNumber,
    required String firstName,
    required String insurance,
    String? interiorNumber,
    required String maternalLastName,
    required String neighborhood,
    required String paternalLastName,
    required String phone,
    String? responsiblePerson,
    required String sex,
    required String street,
    String? emergencyContact,
    String? gender,
    String? addressDetails,
  }) {
    final now = DateTime.now();
    return PatientFirestore(
      age: age,
      city: city,
      createdAt: now,
      exteriorNumber: exteriorNumber,
      firstName: firstName,
      insurance: insurance,
      interiorNumber: interiorNumber,
      maternalLastName: maternalLastName,
      neighborhood: neighborhood,
      paternalLastName: paternalLastName,
      phone: phone,
      responsiblePerson: responsiblePerson,
      emergencyContact: emergencyContact,
      sex: sex,
      gender: gender,
      addressDetails: addressDetails,
      street: street,
      updatedAt: now,
    );
  }

  @override
  List<Object?> get props => [
    id,
    age,
    city,
    createdAt,
    exteriorNumber,
    firstName,
    insurance,
    interiorNumber,
    maternalLastName,
    neighborhood,
    paternalLastName,
    phone,
    responsiblePerson,
    emergencyContact,
    sex,
    gender,
    addressDetails,
    street,
    updatedAt,
  ];

  @override
  String toString() {
    return 'PatientFirestore(id: $id, name: $fullName, age: $age, sex: $sex, gender: $gender, fullAddress: $fullAddress, emergencyContact: $emergencyContact)';
  }
}
