import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/base_controller.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/theme_service.dart';
import '../../home/controllers/home_controller.dart';
import '../../../data/repositories/session_repository.dart';

class SettingsController extends BaseController {
  final StorageService _storage = StorageService.to;
  final ThemeService _themeService = ThemeService.to;
  final SessionRepository _sessionRepository = Get.find<SessionRepository>();

  // ─── Observable State ─────────────────────────────────────────────────────
  final RxInt targetHours = 8.obs;
  late final Rx<ThemeMode> themeMode;
  final RxBool hapticsEnabled = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  void _loadSettings() {
    targetHours.value = _storage.getInt('target_hours') ?? 8;
    themeMode = _themeService.themeMode.obs;
    hapticsEnabled.value = _storage.getBool('haptics_enabled') ?? true;
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  void updateTargetHours(int hours) {
    targetHours.value = hours;
    _storage.setInt('target_hours', hours);
    
    // Sync with HomeController if it exists
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().updateTargetHours(hours);
    }
  }

  void updateThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    _themeService.switchTheme(mode);
  }

  void toggleHaptics(bool value) {
    hapticsEnabled.value = value;
    _storage.setBool('haptics_enabled', value);
  }

  Future<void> resetToday() async {
    // We'll use a confirmed action from the View, then:
    await _sessionRepository.clearSession(DateTime.now());
    
    // Reset HomeController state
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().resetSessionState();
    }
    
    showSuccess('Today\'s session has been reset.');
  }

  Future<void> clearAllHistory() async {
    await _sessionRepository.clearAllHistory();
    
    // Reset HomeController today as well since today IS history too
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().resetSessionState();
    }
    
    showSuccess('All history has been cleared.');
  }
}
