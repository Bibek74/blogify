
import 'package:blogify/core/constants/hive_table_constants.dart';
import 'package:blogify/features/auth/data/models/auth_hive_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

class HiveService {
  Box<AuthHiveModel> get _authBox =>
    Hive.box<AuthHiveModel>(HiveTableConstants.authTable);

  Future<AuthHiveModel> registerUser(AuthHiveModel model) async {
    try {
      final key = model.authId;
      if (key == null) throw Exception('Auth id is null');
      await _authBox.put(key, model);
      return model;
    } catch (e, st) {
      // helpful debug information during development
      // ignore: avoid_print
      print('HiveService.registerUser error: $e\n$st');
      rethrow;
    }
  }

    //Login
  Future<AuthHiveModel?> loginUser(String email, String password) async {
    final users = _authBox.values.where(
      (user) => user.email == email && user.password == password,
    );
    if (users.isNotEmpty) {
      return users.first;
    } 
    return null;
  }  

  //logout
  Future<void> logoutUser() async {
    
  }

  //get current user
  AuthHiveModel? getCurrentUser(String authId) {
    return _authBox.get(authId);
  }

  //check email existence
  bool isEmailExists(String email) {
    final users = _authBox.values.where(
      (user) => user.email == email,
    );
    return users.isNotEmpty;
  }
}