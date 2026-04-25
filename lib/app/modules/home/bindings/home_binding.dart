import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../../history/controllers/history_controller.dart';
import '../../settings/controllers/settings_controller.dart';
import '../../weekly/controllers/weekly_controller.dart';
import '../../../data/repositories/session_repository.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Use put (not lazyPut) so SessionRepository is fully available
    // before HomeController.onInit calls Get.find<SessionRepository>()
    final repo = SessionRepository();
    Get.put<SessionRepository>(repo);

    // Run one-time transparent migration from SharedPreferences → Hive.
    // migrateFromSharedPrefs() is idempotent — safe to call every launch.
    repo.migrateFromSharedPrefs();

    Get.put<HomeController>(HomeController());
    Get.lazyPut<HistoryController>(() => HistoryController());
    Get.lazyPut<SettingsController>(() => SettingsController());
    Get.lazyPut<WeeklyController>(() => WeeklyController());
  }
}


