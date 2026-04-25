import 'package:get/get.dart';
import '../../../core/base_controller.dart';
import '../../../data/models/work_session.dart';
import '../../../data/repositories/session_repository.dart';
import '../../home/controllers/home_controller.dart';

class HistoryController extends BaseController {
  final SessionRepository _repository = Get.find<SessionRepository>();

  final RxList<WorkSession> sessions = <WorkSession>[].obs;
  final RxSet<String> expandedDates = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  Future<void> loadHistory() async {
    await handleRequest(() async {
      // Temporarily inject mock data if this is effectively a fresh install
      await _repository.injectMockDataIfNeeded();

      // Fetch and assign all stored sessions
      final loadedSessions = _repository.getAllSessions();
      sessions.assignAll(loadedSessions);
    });
  }

  void toggleExpansion(DateTime date) {
    final key = date.toIso8601String();
    if (expandedDates.contains(key)) {
      expandedDates.remove(key);
    } else {
      expandedDates.add(key);
    }
  }

  bool isExpanded(DateTime date) {
    return expandedDates.contains(date.toIso8601String());
  }

  /// Updates check-in, break duration, and check-out for a given session date.
  /// Recomputes [totalWorkedDuration] deterministically from stored timestamps.
  /// After saving, refreshes the session list and notifies [HomeController]
  /// if the edited day is today (so the live timer recalibrates from Hive).
  Future<void> updateSessionTimes({
    required DateTime date,
    required DateTime checkIn,
    required DateTime? checkOut,
    required Duration breakDuration,
  }) async {
    await handleRequest(() async {
      final existing = _repository.getSession(date);
      if (existing == null) {
        showError('Session not found for the selected date.');
        return;
      }

      // Validation at the business logic layer
      if (checkOut != null) {
        if (!checkOut.isAfter(checkIn)) {
          showError('Check-out must be after check-in.');
          return;
        }
        final sessionLength = checkOut.difference(checkIn);
        if (breakDuration > sessionLength) {
          showError('Break cannot exceed the total session length.');
          return;
        }
      }

      final now = DateTime.now();
      if (checkIn.isAfter(now)) {
        showError('Check-in cannot be in the future.');
        return;
      }
      if (checkOut != null && checkOut.isAfter(now)) {
        showError('Check-out cannot be in the future.');
        return;
      }

      // Recompute totalWorkedDuration from wall-clock difference.
      // actualWorkedDuration (the getter on WorkSession) will subtract breaks.
      final rawDuration =
          checkOut != null ? checkOut.difference(checkIn) : Duration.zero;

      final updated = existing.copyWith(
        checkInTime: checkIn,
        checkOutTime: checkOut,
        totalBreakDuration: breakDuration,
        totalWorkedDuration: rawDuration,
        // Only clear active break state if the session is finalized (checked out).
        clearCurrentBreakStartTime: checkOut != null,
      );

      await _repository.saveSession(updated);

      // Refresh the list displayed in HistoryView.
      final refreshed = _repository.getAllSessions();
      sessions.assignAll(refreshed);

      // If today's session was edited, tell HomeController to re-read from Hive
      // so the live timer and displays recalibrate without a full restart.
      final today = DateTime.now();
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;

      if (isToday && Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().restoreSessionFromStorage();
      }

      showSuccess('Session updated successfully.');
    });
  }
}
