import 'package:get/get.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:suivi_quotidien/hive_registrar.g.dart';
import '../../data/models/work_session.dart';

class HiveService extends GetxService {
  static HiveService get to => Get.find();

  static const String sessionsBox = 'sessions';

  late final Box<WorkSession> sessions;

  Future<HiveService> init() async {
    // hive_ce_flutter extends Hive with initFlutter() for correct Flutter paths
    await Hive.initFlutter();
    // Register all generated adapters via the auto-generated registrar extension
    Hive.registerAdapters();
    sessions = await Hive.openBox<WorkSession>(sessionsBox);
    return this;
  }
}
