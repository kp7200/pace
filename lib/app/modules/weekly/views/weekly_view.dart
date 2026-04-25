import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_container.dart';
import '../../../core/widgets/common_container.dart';
import '../controllers/weekly_controller.dart';

class WeeklyView extends GetView<WeeklyController> {
  const WeeklyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Header (Learning #15: use solid container, not sliver) ───────────
        _WeeklyHeader(),
        // ─── Scrollable Body ─────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.s24, AppSizes.s16, AppSizes.s24, 120,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current week
                _CurrentWeekCard(),
                const SizedBox(height: AppSizes.s24),
                // Previous week
                _PreviousWeekCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _WeeklyHeader extends GetView<WeeklyController> {
  @override
  Widget build(BuildContext context) {
    return CommonContainer(
      padding: EdgeInsets.fromLTRB(
        AppSizes.s24,
        (MediaQuery.of(context).padding.top + AppSizes.s16),
        AppSizes.s24,
        AppSizes.s16,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PERFORMANCE',
                style: TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Weekly Target',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.15, end: 0, duration: 400.ms);
  }
}

// ─── Current Week Card ────────────────────────────────────────────────────────
class _CurrentWeekCard extends GetView<WeeklyController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final slots = controller.currentWeekSlots;
      final progress = controller.currentProgress.value;
      final worked = controller.currentWorkedDisplay.value;
      final remaining = controller.currentRemainingDisplay.value;
      final target = controller.currentTargetDisplay.value;
      final status = controller.weeklyStatus.value;
      final isOnTrack = controller.isOnTrack.value;
      final targetMet = progress >= 1.0;

      return AppContainer(
        padding: const EdgeInsets.all(AppSizes.s24),
        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.04),
        radius: AppSizes.containerRadius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Weekly Expectation Status (Subtle) ──────────────────────
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isOnTrack ? Colors.green : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  status,
                  style: TextStyle(
                    color: (isOnTrack ? Colors.green : Colors.orange).withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.s12),
            // ── Primary number & Remaining (Redesigned for Premium Look) ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        worked,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 64,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -3.5,
                          height: 0.9,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Target Badge
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppSizes.pillRadius),
                        ),
                        child: Text(
                          'of $target',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.s12),
                // Insights Row (Remaining & Needed)
                if (!targetMet)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InsightPill(
                        label: remaining,
                        suffix: 'remaining',
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                      ),
                      if (controller.requiredPerDayDisplay.value.isNotEmpty)
                        _InsightPill(
                          label: controller.requiredPerDayDisplay.value.replaceAll(' • ', ''),
                          color: isOnTrack ? Colors.green.withValues(alpha: 0.6) : Colors.orange.withValues(alpha: 0.8),
                          isCompact: false,
                        ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.s24),
            // ── Progress bar ───────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.pillRadius),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.s24),
            // ── Day chips row ──────────────────────────────────────────────
            if (slots.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: slots.expand((slot) => [
                    _DayChip(slot: slot),
                    if (slot != slots.last) const SizedBox(width: 8),
                  ]).toList(),
                ),
              ),
          ],
        ),
      );
    }).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.08, end: 0, duration: 400.ms);
  }
}

// ─── Previous Week Card ───────────────────────────────────────────────────────
class _PreviousWeekCard extends GetView<WeeklyController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final slots = controller.previousWeekSlots;
      final progress = controller.previousProgress.value;
      final worked = controller.previousWorkedDisplay.value;
      final target = controller.previousTargetDisplay.value;
      final rangeLabel = controller.previousWeekRangeLabel.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section label ──────────────────────────────────────────────
          Row(
            children: [
              const Text(
                'PREVIOUS WEEK',
                style: TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                rangeLabel,
                style: const TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s12),
          AppContainer(
            padding: const EdgeInsets.all(AppSizes.s24),
            backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.04),
            radius: AppSizes.containerRadius,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Compact summary row ──────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      worked,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Target Badge (Harmonized with Current Week)
                    Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppSizes.pillRadius),
                      ),
                      child: Text(
                        'of $target',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.55),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.s12),
                // ── Progress bar ────────────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.pillRadius),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.s16),
                // ── Mini day chips ──────────────────────────────────────
                if (slots.isNotEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: slots.expand((slot) => [
                        _DayChip(slot: slot, compact: true),
                        if (slot != slots.last) const SizedBox(width: 8),
                      ]).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.08, end: 0, duration: 400.ms);
  }
}

// ─── Day Chip ─────────────────────────────────────────────────────────────────
class _DayChip extends GetView<WeeklyController> {
  final DaySlot slot;
  final bool compact;
  const _DayChip({required this.slot, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    // Visual states — aligned with design system (no bright colors, depth via alpha)
    final Color chipBg;
    final Color textColor;
    final Color borderColor;
    final double borderWidth;
    final IconData? statusIcon;

    switch (slot.status) {
      case DayStatus.complete:
        if (slot.targetMet) {
          chipBg = primary.withValues(alpha: 0.12);
          textColor = primary;
          borderColor = primary.withValues(alpha: 0.4);
          borderWidth = 1.5;
          statusIcon = Icons.check_circle_rounded;
        } else {
          chipBg = primary.withValues(alpha: 0.05);
          textColor = primary.withValues(alpha: 0.6);
          borderColor = primary.withValues(alpha: 0.15);
          borderWidth = 1;
          statusIcon = Icons.remove_circle_outline_rounded;
        }
      case DayStatus.active:
        chipBg = primary;
        textColor = bg;
        borderColor = primary;
        borderWidth = 0;
        statusIcon = Icons.play_circle_filled_rounded;
      case DayStatus.missed:
        chipBg = Colors.transparent;
        textColor = primary.withValues(alpha: 0.25);
        borderColor = primary.withValues(alpha: 0.1);
        borderWidth = 1;
        statusIcon = Icons.cancel_outlined;
      case DayStatus.future:
        chipBg = Colors.transparent;
        textColor = primary.withValues(alpha: 0.15);
        borderColor = primary.withValues(alpha: 0.05);
        borderWidth = 1;
        statusIcon = null;
    }

    final double chipW = compact ? 52 : 62;
    final double chipH = compact ? 52 : 74;
    final double labelSize = compact ? 9 : 10;
    final double valueSize = compact ? 10 : 12;

    return GestureDetector(
      onTap: () => controller.showDayDetails(slot),
      child: Container(
        width: chipW,
        height: chipH,
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              slot.dayLabel,
              style: TextStyle(
                color: textColor,
                fontSize: labelSize,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _workedLabel(),
              style: TextStyle(
                color: textColor,
                fontSize: valueSize,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            if (!compact && statusIcon != null) ...[
              const SizedBox(height: 4),
              Icon(statusIcon, size: 12, color: textColor.withValues(alpha: 0.8)),
            ],
          ],
        ),
      ),
    );
  }

  String _workedLabel() {
    switch (slot.status) {
      case DayStatus.future:
        return '–';
      case DayStatus.missed:
        return '0h';
      case DayStatus.active:
      case DayStatus.complete:
        final h = slot.worked.inHours;
        final m = slot.worked.inMinutes.remainder(60);
        if (h > 0) return '${h}h${m > 0 ? ' ${m}m' : ''}';
        return '${m}m';
    }
  }
}

class _InsightPill extends StatelessWidget {
  final String label;
  final String? suffix;
  final Color color;
  final bool isCompact;

  const _InsightPill({
    required this.label,
    this.suffix,
    required this.color,
    this.isCompact = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.pillRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 1.0),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          if (suffix != null) ...[
            const SizedBox(width: 4),
            Text(
              suffix!,
              style: TextStyle(
                color: color.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

