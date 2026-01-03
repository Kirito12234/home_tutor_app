import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:home_tutor/app/app.dart';
import 'package:home_tutor/features/auth/data/datasources/local/auth_local_datasource.dart';
import 'package:home_tutor/features/auth/data/models/user_hive_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(UserHiveModelAdapter());
  await Hive.openBox<UserHiveModel>(AuthLocalDataSource.userBoxName);
  await Hive.openBox<String>(AuthLocalDataSource.sessionBoxName);
  runApp(const MyApp());
}

