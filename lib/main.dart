import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/core/theme/app_theme.dart';
import 'app/core/services/storage_service.dart';
import 'app/core/services/hive_service.dart';
import 'app/routes/app_pages.dart';
import 'app/core/constants/app_strings.dart';
import 'app/core/services/theme_service.dart';
import 'app/core/services/auth_service.dart';
import 'app/core/services/sync_service.dart';
import 'app/data/repositories/session_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Core Services
  await initServices();

  runApp(
    GetMaterialApp(
      title: AppStrings.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeService.to.themeMode,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.cupertino,
    ),
  );
}

Future<void> initServices() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://xpbxuqvbhnmheyuuvngy.supabase.co',
    anonKey: 'sb_publishable_VP5YMYdFA_Mf80xZG6VNiA_b6cLo29O',
  );

  // 1. Hive (session storage) — must be first so repositories can access boxes
  await Get.putAsync(() => HiveService().init());
  
  // 1.2 Session Repository
  final repo = SessionRepository();
  Get.put<SessionRepository>(repo);
  repo.migrateFromSharedPrefs();

  // 1.5 Supabase Auth Service
  await Get.putAsync(() => AuthService().init());
  // 2. SharedPreferences (settings: theme, targetHours, haptics)
  await Get.putAsync(() => StorageService().init());
  // 2.5 Sync Service
  await Get.putAsync(() => SyncService().init());
  // 3. Theme (reads from SharedPreferences, so must come after)
  Get.put(ThemeService());
}

