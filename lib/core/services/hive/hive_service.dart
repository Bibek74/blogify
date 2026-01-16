import 'package:blogify/core/constants/hive_table_constants.dart';
import 'package:blogify/features/auth/data/models/auth_hive_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

final hiveServiceProvider = Provider<HiveService>((ref) {
  final service = HiveService();
  // trigger initialization (don't await here) so consumers can use the service
  service.init();
  service.openboxes();
  return service;
});

class HiveService {

  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/${HiveTableConstants.dbName}';
    Hive.init(path);
    _registerAdapter();
  }
  
  void _registerAdapter() {
    if (!Hive.isAdapterRegistered(HiveTableConstants.authTypeId)) {
      Hive.registerAdapter(AuthHiveModelAdapter());
    }
    
  }

  Future<void> openboxes() async {
    if (!Hive.isBoxOpen(HiveTableConstants.authTable)) {
      await Hive.openBox<AuthHiveModel>(HiveTableConstants.authTable);
    }
  }
  
  Future<void> close() async {
    await Hive.close();
  }

  Box<AuthHiveModel> get _authBox =>
    Hive.box<AuthHiveModel>(HiveTableConstants.authTable);

  Future<AuthHiveModel> register(AuthHiveModel model) async {
    try {
      if (!Hive.isBoxOpen(HiveTableConstants.authTable)) {
        await Hive.openBox<AuthHiveModel>(HiveTableConstants.authTable);
      }
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

    AuthHiveModel? getUserById(String authId) {
    return _authBox.get(authId);
  }

  //logout
  Future<void> logoutUser() async {
    
  }

  //get current user
  AuthHiveModel? getCurrentUser(String authId) {
    return _authBox.get(authId);
  }

  //check email existence
  AuthHiveModel? getUserByEmail(String email) {
    try {
      return _authBox.values.firstWhere((user) => user.email == email);
    } catch (e) {
      return null;
    }
  }
}