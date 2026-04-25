import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'storage_service.dart';

class ThemeService extends GetxService {
  static ThemeService get to => Get.find();
  
  final _storage = StorageService.to;
  final _key = 'theme_mode';

  ThemeMode get themeMode {
    final storedValue = _storage.getString(_key);
    if (storedValue == null) return ThemeMode.system;
    
    return ThemeMode.values.firstWhere(
      (e) => e.toString() == storedValue,
      orElse: () => ThemeMode.system,
    );
  }

  void switchTheme(ThemeMode mode) {
    Get.changeThemeMode(mode);
    _storage.setString(_key, mode.toString());
  }

  /// Called on startup to ensure the stored theme is applied
  void initTheme() {
    Get.changeThemeMode(themeMode);
  }
}
