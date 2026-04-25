import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/base_controller.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/app_container.dart';
import '../../../data/models/work_session.dart';
import '../../../data/repositories/session_repository.dart';

enum DayStatus { future, missed, active, complete }

class DaySlot {
  final DateTime date;
  final String dayLabel;
  final Duration worked;
  final DayStatus status;
  final bool targetMet;

  const DaySlot({
    required this.date,
    required this.dayLabel,
    required this.worked,
    required this.status,
    required this.targetMet,
  });
}

class WeeklyController extends BaseController {
  late final SessionRepository _repo;

  // ─── Observable State ─────────────────────────────────────────────────────
  final RxList<DaySlot> currentWeekSlots = <DaySlot>[].obs;
  final RxList<DaySlot> previousWeekSlots = <DaySlot>[].obs;

  final RxDouble currentProgress = 0.0.obs;
  final RxDouble previousProgress = 0.0.obs;

  final RxString currentWorkedDisplay = '--'.obs;
  final RxString currentRemainingDisplay = '--'.obs;
  final RxString currentTargetDisplay = '--'.obs;
  final RxString previousWorkedDisplay = '--'.obs;
  final RxString previousTargetDisplay = '--'.obs;

  final RxString currentWeekRangeLabel = ''.obs;
  final RxString previousWeekRangeLabel = ''.obs;

  final RxString weeklyStatus = ''.obs;
  final RxBool isOnTrack = true.obs;
  final RxString requiredPerDayDisplay = ''.obs;

  // ─── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _repo = Get.find<SessionRepository>();
    loadWeek();
  }

  // ─── Core Logic ───────────────────────────────────────────────────────────

  void loadWeek() {
    final targetHours = StorageService.to.getInt('target_hours') ?? 8;
    final dailyTarget = Duration(hours: targetHours);
    final weeklyTarget = Duration(hours: targetHours * 5);
    final today = _today();

    final currentStart = _weekStart(today);
    final previousStart = currentStart.subtract(const Duration(days: 7));

    currentWeekRangeLabel.value = _weekRangeLabel(currentStart);
    previousWeekRangeLabel.value = _weekRangeLabel(previousStart);
    currentTargetDisplay.value = '${targetHours * 5}h';
    previousTargetDisplay.value = '${targetHours * 5}h';

    // Build slots
    final currentSlots = _buildSlots(currentStart, today, targetHours);
    final previousSlots = _buildSlots(previousStart, previousStart.subtract(const Duration(days: 1)), targetHours);

    currentWeekSlots.assignAll(currentSlots);
    previousWeekSlots.assignAll(previousSlots);

    // Aggregates — current week
    final currentWorked = currentSlots.fold(Duration.zero, (sum, s) => sum + s.worked);
    final currentRemaining = weeklyTarget - currentWorked;
    currentProgress.value = (currentWorked.inSeconds / weeklyTarget.inSeconds).clamp(0.0, 1.0);
    currentWorkedDisplay.value = _fmt(currentWorked);
    currentRemainingDisplay.value = currentRemaining.isNegative ? 'Done!' : _fmt(currentRemaining);

    // Weekly Expectation Status (On track / Behind)
    // Only calculate for the current Mon-Fri week.
    final weekdaysElapsed = (today.difference(currentStart).inDays + 1).clamp(0, 5);
    final expectedWorked = dailyTarget * weekdaysElapsed;
    
    isOnTrack.value = currentWorked >= expectedWorked;
    if (currentWorked >= weeklyTarget) {
      weeklyStatus.value = 'GOAL REACHED';
    } else {
      weeklyStatus.value = isOnTrack.value ? 'ON TRACK' : 'BEHIND';
    }

    // Required per day calculation
    // Remaining days = Mon-Fri that haven't passed (including today)
    final now = DateTime.now();
    final weekday = now.weekday; // 1=Mon, 7=Sun
    final remainingDays = (5 - weekday + 1).clamp(0, 5);
    
    if (remainingDays > 0 && !currentRemaining.isNegative && currentRemaining > Duration.zero) {
      // Remaining hours / remaining active days
      final reqSeconds = currentRemaining.inSeconds / remainingDays;
      final reqDur = Duration(seconds: reqSeconds.round());
      requiredPerDayDisplay.value = ' • ${_fmt(reqDur)}/day needed';
    } else {
      requiredPerDayDisplay.value = '';
    }

    // Aggregates — previous week
    final previousWorked = previousSlots.fold(Duration.zero, (sum, s) => sum + s.worked);
    previousProgress.value = (previousWorked.inSeconds / weeklyTarget.inSeconds).clamp(0.0, 1.0);
    previousWorkedDisplay.value = _fmt(previousWorked);
  }

  // ─── Navigation ─────────────────────────────────────────────────────────────

  void showDayDetails(DaySlot slot) {
    if (slot.status == DayStatus.future) return;

    final session = _repo.getSession(slot.date);
    final context = Get.context!;
    final primary = Theme.of(context).primaryColor;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    Get.bottomSheet(
      AppContainer(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.s24, vertical: AppSizes.s12),
        backgroundColor: bg,
        radius: AppSizes.containerRadius,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.pillRadius),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.s24),
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE').format(slot.date).toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, yyyy').format(slot.date),
                      style: TextStyle(
                        color: primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                _MetricSummary(worked: slot.worked, targetHours: session?.targetHours ?? 8),
              ],
            ),
            const SizedBox(height: AppSizes.s32),
            // Notes
            const Text(
              'DAY LOGS',
              style: TextStyle(
                color: Color(0xFF888888),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: AppSizes.s16),
            if (session == null || session.notes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.s32),
                child: Center(
                  child: Text(
                    'No notes recorded for this day',
                    style: TextStyle(
                      color: primary.withValues(alpha: 0.3),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: Get.height * 0.4),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: AppSizes.s24),
                  itemCount: session.notes.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSizes.s12),
                  itemBuilder: (context, index) {
                    final note = session.notes[index];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(note.timestamp),
                          style: TextStyle(
                            color: primary.withValues(alpha: 0.3),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            note.content,
                            style: TextStyle(
                              color: primary,
                              fontSize: 14,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            const SizedBox(height: AppSizes.s16),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  // ─── Slot Builder ─────────────────────────────────────────────────────────

  /// Builds 5 DaySlot objects (Mon–Fri) for the week starting [weekStart].
  /// [today] is used to determine whether a day is future/missed/active/complete.
  List<DaySlot> _buildSlots(DateTime weekStart, DateTime today, int targetHours) {
    final targetDuration = Duration(hours: targetHours);
    final slots = <DaySlot>[];
    const labels = ['MON', 'TUE', 'WED', 'THU', 'FRI'];

    for (int i = 0; i < 5; i++) {
      final day = weekStart.add(Duration(days: i));
      final dayOnly = _dateOnly(day);
      final todayOnly = _dateOnly(today);
      final label = labels[i];

      if (dayOnly.isAfter(todayOnly)) {
        // Future day
        slots.add(DaySlot(
          date: dayOnly,
          dayLabel: label,
          worked: Duration.zero,
          status: DayStatus.future,
          targetMet: false,
        ));
        continue;
      }

      final WorkSession? session = _repo.getSession(dayOnly);

      if (session == null) {
        // Past day with no session = missed
        slots.add(DaySlot(
          date: dayOnly,
          dayLabel: label,
          worked: Duration.zero,
          status: dayOnly.isAtSameMomentAs(todayOnly) ? DayStatus.future : DayStatus.missed,
          targetMet: false,
        ));
        continue;
      }

      // Compute worked duration
      Duration worked;
      if (session.checkOutTime != null) {
        // Completed session
        worked = session.actualWorkedDuration;
      } else {
        // Active session — compute live from stored timestamps
        final now = DateTime.now();
        final totalElapsed = now.difference(session.checkInTime);
        final activeBreak = session.currentBreakStartTime != null
            ? now.difference(session.currentBreakStartTime!)
            : Duration.zero;
        final totalBreaks = session.totalBreakDuration + activeBreak;
        worked = (totalElapsed - totalBreaks).isNegative ? Duration.zero : totalElapsed - totalBreaks;
      }

      final isActive = session.checkOutTime == null && dayOnly.isAtSameMomentAs(todayOnly);
      final targetMet = worked >= targetDuration;

      slots.add(DaySlot(
        date: dayOnly,
        dayLabel: label,
        worked: worked,
        status: isActive ? DayStatus.active : DayStatus.complete,
        targetMet: targetMet,
      ));
    }

    return slots;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Returns the Monday of the week containing [date].
  DateTime _weekStart(DateTime date) {
    final daysFromMonday = (date.weekday - 1) % 7; // Monday = 0
    return _dateOnly(date.subtract(Duration(days: daysFromMonday)));
  }

  DateTime _today() => _dateOnly(DateTime.now());

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  String _weekRangeLabel(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 4));
    final startStr = DateFormat('MMM d').format(weekStart);
    final endStr = DateFormat('MMM d').format(weekEnd);
    return '$startStr – $endStr';
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).abs();
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m}m';
  }
}

class _MetricSummary extends StatelessWidget {
  final Duration worked;
  final int targetHours;
  const _MetricSummary({required this.worked, required this.targetHours});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final targetMet = worked >= Duration(hours: targetHours);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${worked.inHours}h ${worked.inMinutes.remainder(60)}m',
          style: TextStyle(
            color: primary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          targetMet ? 'TARGET MET ✓' : 'of ${targetHours}h',
          style: TextStyle(
            color: (targetMet ? Colors.green : primary).withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

