
import 'package:blogify/features/auth/domain/entities/auth_entity.dart';

class AuthApiModel {
  final String? id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? password;

  AuthApiModel({
    this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.password,
  });

  // toJSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'password': password,
    };
  }

  // fromJson
  factory AuthApiModel.fromJson(Map<String, dynamic> json) {
    return AuthApiModel(
      id: json['id'] as String? ?? json['_id'] as String?,
      fullName: json['name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      password: json['password'] as String?
    );
  }

  // toEntity
  AuthEntity toEntity() {
    return AuthEntity(
      authId: id,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      password: password
    );
  }

  // fromEntity
  factory AuthApiModel.fromEntity(AuthEntity entity) {
    return AuthApiModel(
      fullName: entity.fullName,
      email: entity.email,
      phoneNumber: entity.phoneNumber,
      password: entity.password
    );
  }
  
}