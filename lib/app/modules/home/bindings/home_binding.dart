import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../../history/controllers/history_controller.dart';
import '../../settings/controllers/settings_controller.dart';
import '../../weekly/controllers/weekly_controller.dart';
import '../../../data/repositories/session_repository.dart';
import '../controllers/notes_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<HomeController>(HomeController());
    Get.lazyPut<HistoryController>(() => HistoryController());
    Get.lazyPut<SettingsController>(() => SettingsController());
    Get.lazyPut<WeeklyController>(() => WeeklyController());
    Get.lazyPut<NotesController>(() => NotesController());
  }
}
