import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/base_controller.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/sync_service.dart';
import '../../home/controllers/home_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/session_repository.dart';

class SettingsController extends BaseController {
  final StorageService _storage = StorageService.to;
  final ThemeService _themeService = ThemeService.to;
  final SessionRepository _sessionRepository = Get.find<SessionRepository>();

  // ─── Observable State ─────────────────────────────────────────────────────
  final RxInt targetHours = 8.obs;
  late final Rx<ThemeMode> themeMode;
  final RxBool hapticsEnabled = true.obs;
  late final RxBool isCloudSyncEnabled;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  void _loadSettings() {
    targetHours.value = _storage.getInt('target_hours') ?? 8;
    themeMode = _themeService.themeMode.obs;
    hapticsEnabled.value = _storage.getBool('haptics_enabled') ?? true;
    isCloudSyncEnabled = SyncService.to.isCloudSyncEnabled;
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

  void toggleCloudSync(bool value) {
    SyncService.to.toggleSync(value);
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

  // ─── Profile & Auth ───────────────────────────────────────────────────────

  Future<void> updateProfile(String fullName) async {
    await handleRequest(() async {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'full_name': fullName}),
      );
      // Update local state in auth service manually or let it refresh.
      AuthService.to.currentUser.value = Supabase.instance.client.auth.currentUser;
      showSuccess('Profile updated');
    });
  }

  Future<void> updateEmail(String email) async {
    await handleRequest(() async {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(email: email),
      );
      showSuccess('Verification sent to both new and old emails.');
    });
  }

  Future<void> logout() async {
    await handleRequest(() async {
      await Supabase.instance.client.auth.signOut();
    });
  }

  Future<void> deleteAccount() async {
    await handleRequest(() async {
      await Supabase.instance.client.rpc('delete_user');
      await Supabase.instance.client.auth.signOut();
    });
  }
}
