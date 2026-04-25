import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:suivi_quotidien/app/core/widgets/common_container.dart';
import '../../../core/base/base_view.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/work_session.dart';
import '../controllers/history_controller.dart';
import '../widgets/edit_session_sheet.dart';

class HistoryView extends BaseView<HistoryController> {
  const HistoryView({super.key});

  @override
  bool safeArea() => false; // We handle it manually like Home

  @override
  Widget buildBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Header(),
        Expanded(
          child: Obx(() {
            if (controller.sessions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 48,
                      color: const Color(0xFFC0C0C0),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No history yet',
                      style: TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.only(
                top: AppSizes.s12,
                bottom: 100,
                left: AppSizes.s24,
                right: AppSizes.s24,
              ),
              itemCount: controller.sessions.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSizes.s16),
              itemBuilder: (context, index) {
                final session = controller.sessions[index];
                return _HistoryCard(session: session, ctrl: controller)
                    .animate()
                    .fadeIn(delay: (index * 50).ms)
                    .slideY(begin: 0.1, end: 0, duration: 400.ms);
              },
            );
          }),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

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
                'YOUR LOGS',
                style: TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'History',
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
      )
          .animate()
          .fadeIn(duration: 400.ms)
          .slideY(begin: -0.15, end: 0, duration: 400.ms),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final WorkSession session;
  final HistoryController ctrl;

  const _HistoryCard({required this.session, required this.ctrl});

  String _formatH(Duration dur) {
    final h = dur.inHours;
    final m = dur.inMinutes.remainder(60);
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d, yyyy').format(session.date);
    final inStr = DateFormat('h:mm a').format(session.checkInTime);
    final outStr = session.checkOutTime != null
        ? DateFormat('h:mm a').format(session.checkOutTime!)
        : 'Active';
    final hasNotes = session.notes.isNotEmpty;

    return Obx(() {
      final isExpanded = ctrl.isExpanded(session.date);

      return GestureDetector(
        onTap: hasNotes ? () => ctrl.toggleExpansion(session.date) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.fastOutSlowIn,
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppSizes.containerRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.inkBlack.withValues(
                  alpha: isExpanded ? 0.04 : 0.01,
                ),
                blurRadius: isExpanded ? 20 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header: Date & Time ───
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateStr,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$inStr  →  $outStr',
                        style: const TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatH(session.actualWorkedDuration),
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(height: 2),
                          _TargetStatus(session: session),
                        ],
                      ),
                      const SizedBox(width: 4),
                      // ── Edit Button ──
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
                          onTap: () => showEditSessionSheet(context, session),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ─── Metrics Row ───
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Metric(
                    icon: Icons.pause_circle_outline,
                    label: 'Break',
                    value: _formatH(session.totalBreakDuration),
                  ),
                  _Metric(
                    icon: Icons.flag_outlined,
                    label: 'Target',
                    value: '${session.targetHours}h 0m',
                  ),
                  if (hasNotes)
                    Row(
                      children: [
                        Icon(
                          Icons.sticky_note_2_outlined,
                          size: 14,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${session.notes.length}',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                ],
              ),

              // ─── Expanded Notes ───
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.fastOutSlowIn,
                alignment: Alignment.topCenter,
                child: isExpanded && hasNotes
                    ? Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(color: Color(0xFFF0F0F0), height: 1),
                            const SizedBox(height: 16),
                            ...session.notes.map(
                              (n) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat('HH:mm').format(n.timestamp),
                                      style: const TextStyle(
                                        color: Color(0xFFB0B0B0),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        n.content,
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Metric({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF888888)),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Color(0xFF888888),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TargetStatus extends StatelessWidget {
  final WorkSession session;
  const _TargetStatus({required this.session});

  @override
  Widget build(BuildContext context) {
    final actual = session.actualWorkedDuration;
    final target = Duration(hours: session.targetHours);
    final isMet = actual >= target;

    if (isMet) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(AppSizes.pillRadius),
        ),
        child: Text(
          'TARGET MET',
          style: TextStyle(
            color: Theme.of(context).scaffoldBackgroundColor,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    final remaining = target - actual;
    final h = remaining.inHours;
    final m = remaining.inMinutes.remainder(60);

    return Text(
      'Remaining: ${h}h ${m}m',
      style: TextStyle(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
