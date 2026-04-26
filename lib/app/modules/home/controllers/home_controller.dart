import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/base_controller.dart';
import '../../../core/services/storage_service.dart';
import '../../../data/models/work_session.dart';
import '../../../data/repositories/session_repository.dart';
import '../../weekly/controllers/weekly_controller.dart';
import '../../history/controllers/history_controller.dart';
import 'notes_controller.dart';

class HomeController extends BaseController {
  // Initialized in onInit after all bindings are resolved
  late final SessionRepository _sessionRepository;
  final _uuid = const Uuid();

  // ─── Observable State ─────────────────────────────────────────────────────
  final Rx<WorkSession?> session = Rx<WorkSession?>(null);
  final RxBool isCheckedIn = false.obs;
  final RxInt targetHours = 8.obs;
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
  }

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
  }

  // ─── Session Recovery (handles app kill/restart) ───────────────────────────
  void _restoreSession() {
    final today = DateTime.now();

    // 1. Day Rollover Fix: Check for zombie sessions from previous days
    final allSessions = _sessionRepository.getAllSessions();
    if (allSessions.isNotEmpty) {
      final newest = allSessions.first;
      final isNotToday = newest.date.year != today.year || 
                         newest.date.month != today.month || 
                         newest.date.day != today.day;
                         
      if (isNotToday && newest.checkOutTime == null) {
        // Auto-checkout the old session to cap it.
        final targetDuration = Duration(hours: newest.targetHours);
        final autoCheckoutTime = newest.checkInTime.add(targetDuration);
        
        final updatedOldSession = newest.copyWith(
          checkOutTime: autoCheckoutTime,
          clearCurrentBreakStartTime: true,
          totalWorkedDuration: autoCheckoutTime.difference(newest.checkInTime),
        );
        _sessionRepository.saveSession(updatedOldSession);
      }
    }

    // 2. Load today's session
    final saved = _sessionRepository.getSession(today);

    if (saved != null && saved.checkOutTime == null) {
      session.value = saved;
      NotesController.to.setNotes(saved.notes);
      isCheckedIn.value = true;
      _startTicker();
    } else if (saved != null) {
      session.value = saved;
      NotesController.to.setNotes(saved.notes);
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
      final todaySession = _sessionRepository.getSession(now);

      if (todaySession != null) {
        // Resume existing session for the day (even if checked out, reopen it)
        final updated = todaySession.copyWith(
          clearCheckOutTime: true,
        );
        session.value = updated;
        NotesController.to.setNotes(updated.notes);
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
        NotesController.to.clearNotes();
        isCheckedIn.value = true;
        await _sessionRepository.saveSession(newSession);
        _startTicker();
      }
    }}

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
      notes: NotesController.to.notes.toList(),
    );
    session.value = updated;
    isCheckedIn.value = false;
    isOnBreak.value = false;
    await _sessionRepository.saveSession(updated);
    _recalculate();

    Get.snackbar(
      'Checked Out',
      'Your session has been saved.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(24),
      backgroundColor: const Color(0xFF141413).withValues(alpha: 0.9),
      colorText: const Color(0xFFF3F0EE),
      duration: const Duration(seconds: 5),
      mainButton: TextButton(
        onPressed: () {
          if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
          _undoCheckOut();
        },
        child: const Text(
          'UNDO',
          style: TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _undoCheckOut() async {
    if (session.value == null) return;
    final updated = session.value!.copyWith(
      clearCheckOutTime: true,
    );
    session.value = updated;
    isCheckedIn.value = true;
    await _sessionRepository.saveSession(updated);
    _startTicker();
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

    final newElapsedDisplay = _fmt(elapsed);
    final newBreakDisplay = totalBreaks.inMinutes > 0 ? _fmt(totalBreaks) : '--';
    final newRemainingDisplay = remaining.isNegative
        ? '+${_fmt(remaining.abs())}'
        : _fmt(remaining);
    final newExpectedLogoutDisplay = DateFormat('h:mm a').format(expectedLogout);
    final newProgressValue = (elapsed.inSeconds / targetDuration.inSeconds).clamp(0.0, 1.0);

    if (elapsedDisplay.value != newElapsedDisplay) elapsedDisplay.value = newElapsedDisplay;
    if (breakDisplay.value != newBreakDisplay) breakDisplay.value = newBreakDisplay;
    if (remainingDisplay.value != newRemainingDisplay) remainingDisplay.value = newRemainingDisplay;
    if (expectedLogoutDisplay.value != newExpectedLogoutDisplay) expectedLogoutDisplay.value = newExpectedLogoutDisplay;
    if (progressValue.value != newProgressValue) progressValue.value = newProgressValue;
  }

  void updateTargetHours(int hours) {
    targetHours.value = hours;
    _recalculate();
  }

  void resetSessionState() {
    _ticker?.cancel();
    session.value = null;
    NotesController.to.clearNotes();
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
