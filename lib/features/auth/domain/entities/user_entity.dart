import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String contactNumber;
  final int age;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
    required this.id,
    required this.fullName,
    required this.email,
    required this.contactNumber,
    required this.age,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  UserEntity copyWith({
    String? fullName,
    String? email,
    String? contactNumber,
    int? age,
    String? photoUrl,
    DateTime? updatedAt,
  }) {
    return UserEntity(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      contactNumber: contactNumber ?? this.contactNumber,
      age: age ?? this.age,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'contact_number': contactNumber,
      'age': age,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserEntity.fromMap(Map<String, dynamic> map) {
    return UserEntity(
      id: map['id'] ?? '',
      fullName: map['full_name'] ?? '',
      email: map['email'] ?? '',
      contactNumber: map['contact_number'] ?? '',
      age: map['age'] ?? 0,
      photoUrl: map['photo_url'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  @override
  List<Object?> get props => [id, fullName, email, contactNumber, age, photoUrl];
}
