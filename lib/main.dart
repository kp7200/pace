import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/core/theme/app_theme.dart';
import 'app/core/services/storage_service.dart';
import 'app/core/services/hive_service.dart';
import 'app/routes/app_pages.dart';
import 'app/core/constants/app_strings.dart';
import 'app/core/services/theme_service.dart';

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
  // 1. Hive (session storage) — must be first so repositories can access boxes
  await Get.putAsync(() => HiveService().init());
  // 2. SharedPreferences (settings: theme, targetHours, haptics)
  await Get.putAsync(() => StorageService().init());
  // 3. Theme (reads from SharedPreferences, so must come after)
  Get.put(ThemeService());
}

