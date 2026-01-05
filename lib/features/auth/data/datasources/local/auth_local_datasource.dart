
import 'package:blogify/core/services/hive/hive_service.dart';
import 'package:blogify/features/auth/data/datasources/auth_datasource.dart';
import 'package:blogify/features/auth/data/models/auth_hive_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authLocalDatasourceProvider = Provider<AuthLocalDatasource>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return AuthLocalDatasource(hiveService: hiveService);
});
class AuthLocalDatasource implements IAuthDatasource{

  final HiveService _hiveService;

  AuthLocalDatasource({required HiveService hiveService})
   : _hiveService = hiveService;
  @override
  Future<AuthHiveModel?> getCurrentUser() {
    throw UnimplementedError();
  }

  @override
  Future<bool> isEmailExists(String email) {
    try {
      final exists = _hiveService.isEmailExists(email);
      return Future.value(exists);
    } catch (e) {
      return Future.value(false);
    }
  }

  @override
  Future<AuthHiveModel?> login(String email, String password) async {
    try {
      final user = await _hiveService.loginUser(email, password);
      return user;
      } catch (e) {
      return null;
    } 
  }

  @override
  Future<bool> logout() async {
    try {
      await _hiveService.logoutUser();
      return Future.value(true);
    } catch (e) {
      return Future.value(false);
    }
  }

  @override
  Future<bool> register(AuthHiveModel model) async {
    try {
      // check if email already exists
      final exists = _hiveService.isEmailExists(model.email);
      if (exists) throw Exception('Email already exists');

      await _hiveService.registerUser(model);
      return Future.value(true);
    } catch (e) {
      // ignore: avoid_print
      print('AuthLocalDatasource.register error: $e');
      return Future.value(false);
    }
  }
}