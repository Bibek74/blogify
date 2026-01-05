import 'package:blogify/app/routes/app.dart';
import 'package:blogify/core/constants/hive_table_constants.dart';
import 'package:blogify/features/auth/data/models/auth_hive_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters
  if (!Hive.isAdapterRegistered(HiveTableConstants.authTypeId)) {
    Hive.registerAdapter(AuthHiveModelAdapter());
  }

  // Open boxes
  await Hive.openBox<AuthHiveModel>(HiveTableConstants.authTable);

  runApp(const ProviderScope(child: App()));
}
