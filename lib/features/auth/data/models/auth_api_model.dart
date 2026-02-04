import 'package:blogify/features/auth/domain/entities/auth_entity.dart';

class AuthApiModel {
  final String? id;
  final String fullName;
  final String email;
  final String? username;
  final String? password;

  AuthApiModel({
    this.id,
    required this.fullName,
    required this.email,
    this.username,
    this.password,
  });

  // toJSON
  Map<String, dynamic> toJson() {
    return {
      'name': fullName,
      'email': email,
      'password': password,
    };
  }

  // fromJson
factory AuthApiModel.fromJson(Map<String, dynamic> json) {
  return AuthApiModel(
    id: json['_id']?.toString(),
    fullName: json['name'] ?? '',
    email: json['email'] ?? '',
    username: json['username'] ?? '',
    password: json['password'], // keep nullable
  );
}

  // toEntity
  AuthEntity toEntity() {
    return AuthEntity(
      authId: id,
      fullName: fullName,
      email: email,
      username: username,
      password: password,
    );
  }

  // fromEntity
  factory AuthApiModel.fromEntity(AuthEntity entity) {
    return AuthApiModel(
      id: entity.authId,
      fullName: entity.fullName,
      email: entity.email,
      username: entity.username ?? entity.email.split('@').first,
      password: entity.password,
    );
  }

  // toEntityList
  static List<AuthEntity> toEntityList(List<AuthApiModel> models) {
    return models.map((model) => model.toEntity()).toList();
  }
}