import 'package:equatable/equatable.dart';

class AuthEntity extends Equatable{
  final String? authId;
  final String fullName;
  final String username;
  final String email;
  final String? password;
  

  const AuthEntity({
    this.authId,
    required this.fullName,
    required this.email,
    required this. username,
    this.password,
  });

  @override
  List<Object?> get props =>[
    authId,
    fullName,
    email,
    username,
    password,
    ];
  }