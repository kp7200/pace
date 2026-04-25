import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/base_controller.dart';
import '../../../core/services/storage_service.dart';
import '../../../data/models/note.dart';
import '../../../data/models/work_session.dart';
import '../../../data/repositories/session_repository.dart';
import '../../weekly/controllers/weekly_controller.dart';
import '../../history/controllers/history_controller.dart';

class HomeController extends BaseController {
  // Initialized in onInit after all bindings are resolved
  late final SessionRepository _sessionRepository;
  final _uuid = const Uuid();

  // ─── Observable State ─────────────────────────────────────────────────────
  final Rx<WorkSession?> session = Rx<WorkSession?>(null);
  final RxList<Note> notes = <Note>[].obs;
  final RxBool isCheckedIn = false.obs;
  final RxInt targetHours = 8.obs;
  final TextEditingController noteInputController = TextEditingController();
  final FocusNode noteFocusNode = FocusNode();
  final GlobalKey notesSectionKey = GlobalKey();
  final RxBool isNoteFocused = false.obs;
  final RxBool isNoteNotEmpty = false.obs;
  final RxBool isOnBreak = false.obs;

  // ─── Navigation State ─────────────────────────────────────────────────────
  final RxInt currentTabIndex = 0.obs;

  void changeTab(int index) {
    if (currentTabIndex.value == index) return;
    currentTabIndex.value = index;
    
    // Trigger WeeklyController to refresh data when switching to index 1
    if (index == 1) {
      if (Get.isRegistered<WeeklyController>()) {
        Get.find<WeeklyController>().loadWeek();
      }
    }

    // Automatically intercept tab 2 switch to force a fresh data sync for History
    if (index == 2) {
      if (Get.isRegistered<HistoryController>()) {
        Get.find<HistoryController>().loadHistory();
      }
    }
  }

  // ─── Timer displays (recalculated from stored timestamps, never derived) ──
  final RxString elapsedDisplay = '--'.obs;
  final RxString breakDisplay = '--'.obs;
  final RxString remainingDisplay = '--'.obs;
  final RxString expectedLogoutDisplay = '--:--'.obs;
  final RxDouble progressValue = 0.0.obs;

  Timer? _ticker;

  // ─── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    // Safe to find here — all binding dependencies are resolved before onInit
    _sessionRepository = Get.find<SessionRepository>();
    targetHours.value = StorageService.to.getInt('target_hours') ?? 8;
    _restoreSession();

    noteFocusNode.addListener(() {
      isNoteFocused.value = noteFocusNode.hasFocus;
      if (noteFocusNode.hasFocus) {
        // Auto-scroll so the 'Daily Notes' header reaches the top of the screen.
        Future.delayed(const Duration(milliseconds: 300), () {
          if (notesSectionKey.currentContext != null) {
            Scrollable.ensureVisible(
              notesSectionKey.currentContext!,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
            );
          }
        });
      }
    });

    noteInputController.addListener(() {
      isNoteNotEmpty.value = noteInputController.text.trim().isNotEmpty;
    });
  }

  @override
  void onClose() {
    _ticker?.cancel();
    noteInputController.dispose();
    noteFocusNode.dispose();
    super.onClose();
  }

  // ─── Session Recovery (handles app kill/restart) ───────────────────────────
  void _restoreSession() {
    final today = DateTime.now();
    final saved = _sessionRepository.getSession(today);

    if (saved != null && saved.checkOutTime == null) {
      session.value = saved;
      notes.assignAll(saved.notes);
      isCheckedIn.value = true;
      _startTicker();
    } else if (saved != null) {
      session.value = saved;
      notes.assignAll(saved.notes);
      isCheckedIn.value = false;
      _recalculate();
    }
  }

  /// Public entry point used by [HistoryController] when today's session is
  /// edited externally. Re-reads the session from Hive so the live timer and
  /// all display values recalibrate without requiring a full app restart.
  void restoreSessionFromStorage() {
    _ticker?.cancel();
    resetSessionState();
    _restoreSession();
  }

  // ─── Check-In ─────────────────────────────────────────────────────────────
  Future<void> checkIn() async {
    if (isCheckedIn.value) return;
    final now = DateTime.now();
    
    // Check if a session already exists for today to support multiple check-ins
    final existingSession = _sessionRepository.getSession(now);
    
    if (existingSession != null) {
      // RESUME: Treat the gap between last checkout and now as an implicit break
      Duration additionalBreak = Duration.zero;
      if (existingSession.checkOutTime != null) {
        additionalBreak = now.difference(existingSession.checkOutTime!);
      }
      
      final updated = existingSession.copyWith(
        checkOutTime: null, // Clear checkout to make it active again
        clearCurrentBreakStartTime: true,
        totalBreakDuration: existingSession.totalBreakDuration + additionalBreak,
      );
      
      session.value = updated;
      notes.assignAll(updated.notes);
      isCheckedIn.value = true;
      await _sessionRepository.saveSession(updated);
      _startTicker();
    } else {
      // FRESH START
      final newSession = WorkSession(
        date: now,
        checkInTime: now,
        targetHours: targetHours.value,
      );
      session.value = newSession;
      notes.clear();
      isCheckedIn.value = true;
      await _sessionRepository.saveSession(newSession);
      _startTicker();
    }
  }

  // ─── Check-Out ────────────────────────────────────────────────────────────
  Future<void> checkOut() async {
    if (!isCheckedIn.value || session.value == null) return;
    _ticker?.cancel();
    final now = DateTime.now();
    final updated = session.value!.copyWith(
      checkOutTime: now,
      // If currently on break, cap the current break
      totalBreakDuration: session.value!.currentBreakStartTime != null 
          ? session.value!.totalBreakDuration + now.difference(session.value!.currentBreakStartTime!) 
          : session.value!.totalBreakDuration,
      clearCurrentBreakStartTime: true,
      totalWorkedDuration: now.difference(session.value!.checkInTime), // We will subtract breaks when displaying
      notes: notes.toList(),
    );
    session.value = updated;
    isCheckedIn.value = false;
    isOnBreak.value = false;
    await _sessionRepository.saveSession(updated);
    _recalculate();
  }

  // ─── Break ────────────────────────────────────────────────────────────────
  Future<void> toggleBreak() async {
    if (!isCheckedIn.value || session.value == null) return;
    final s = session.value!;
    final now = DateTime.now();

    if (s.currentBreakStartTime != null) {
      // Resume Work
      final thisBreakDuration = now.difference(s.currentBreakStartTime!);
      final updated = s.copyWith(
        totalBreakDuration: s.totalBreakDuration + thisBreakDuration,
        clearCurrentBreakStartTime: true,
      );
      session.value = updated;
      isOnBreak.value = false;
      await _sessionRepository.saveSession(updated);
    } else {
      // Take Break
      final updated = s.copyWith(
        currentBreakStartTime: now,
      );
      session.value = updated;
      isOnBreak.value = true;
      await _sessionRepository.saveSession(updated);
    }
    _recalculate();
  }

  // ─── Timer Engine (deterministic) ─────────────────────────────────────────
  void _startTicker() {
    _ticker?.cancel();
    _recalculate();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _recalculate());
  }

  void _recalculate() {
    final s = session.value;
    if (s == null) return;

    final endTime = s.checkOutTime ?? DateTime.now();
    
    // Break Context
    Duration currentActiveBreak = Duration.zero;
    if (s.currentBreakStartTime != null && s.checkOutTime == null) {
      isOnBreak.value = true;
      currentActiveBreak = endTime.difference(s.currentBreakStartTime!);
    } else if (s.currentBreakStartTime != null && s.checkOutTime != null) {
      // Checked out while on break edge case
      isOnBreak.value = false;
    } else {
      isOnBreak.value = false;
    }

    final totalBreaks = s.totalBreakDuration + currentActiveBreak;
    final totalDurationSinceCheckIn = endTime.difference(s.checkInTime);
    final elapsed = totalDurationSinceCheckIn - totalBreaks;

    final targetDuration = Duration(hours: targetHours.value);
    final remaining = targetDuration - elapsed;
    final expectedLogout = s.checkInTime.add(targetDuration).add(totalBreaks); // Add breaks because they push expected exit!

    elapsedDisplay.value = _fmt(elapsed);
    breakDisplay.value = totalBreaks.inMinutes > 0 ? _fmt(totalBreaks) : '--';
    remainingDisplay.value = remaining.isNegative
        ? '+${_fmt(remaining.abs())}'
        : _fmt(remaining);
    expectedLogoutDisplay.value = DateFormat('h:mm a').format(expectedLogout);
    progressValue.value = (elapsed.inSeconds / targetDuration.inSeconds).clamp(0.0, 1.0);
  }

  // ─── Notes ────────────────────────────────────────────────────────────────
  Future<void> addNote() async {
    final content = noteInputController.text.trim();
    if (content.isEmpty) return;

    final note = Note(id: _uuid.v4(), timestamp: DateTime.now(), content: content);
    notes.insert(0, note);
    noteInputController.clear();

    final updated = session.value?.copyWith(notes: notes.toList());
    if (updated != null) {
      session.value = updated;
      await _sessionRepository.saveSession(updated);
    }
  }

  Future<void> deleteNote(String id) async {
    notes.removeWhere((n) => n.id == id);
    final updated = session.value?.copyWith(notes: notes.toList());
    if (updated != null) {
      session.value = updated;
      await _sessionRepository.saveSession(updated);
    }
  }

  void updateTargetHours(int hours) {
    targetHours.value = hours;
    _recalculate();
  }

  void resetSessionState() {
    _ticker?.cancel();
    session.value = null;
    notes.clear();
    isCheckedIn.value = false;
    isOnBreak.value = false;
    elapsedDisplay.value = '--';
    breakDisplay.value = '--';
    remainingDisplay.value = '--';
    expectedLogoutDisplay.value = '--:--';
    progressValue.value = 0.0;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).abs();
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m}m';
  }

  String get checkInTimeDisplay {
    final s = session.value;
    if (s == null) return '--:--';
    return DateFormat('h:mm a').format(s.checkInTime);
  }

  String get todayDisplay => DateFormat('EEEE, MMM d').format(DateTime.now());
}
