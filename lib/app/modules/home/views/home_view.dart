import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_container.dart';
import '../../../core/widgets/web_shell.dart';
import '../../history/views/history_view.dart';
import '../controllers/home_controller.dart';
import '../../weekly/views/weekly_view.dart';
import '../../settings/views/settings_view.dart';
import '../../../data/models/note.dart';
import '../../../core/services/sync_service.dart';
import '../controllers/notes_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = controller;
    final webDesktop = isWebDesktop(context);

    // ── Tab content (shared between web and mobile) ───────────────────────
    final tabContent = Obx(() {
      final index = ctrl.currentTabIndex.value;
      if (index == 0) {
        return CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(child: _Header(ctrl: ctrl)),
            SliverToBoxAdapter(child: _TimerHero(ctrl: ctrl)),
            SliverToBoxAdapter(child: _StatsRow(ctrl: ctrl)),
            SliverToBoxAdapter(
              child: Obx(() => ctrl.isCheckedIn.value 
                  ? const _NotesSection() 
                  : const SizedBox.shrink()),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: webDesktop ? 100 : 150),
            ),
          ],
        );
      } else if (index == 1) {
        return const WeeklyView();
      } else if (index == 2) {
        return const HistoryView();
      } else if (index == 3) {
        return const SettingsView();
      }
      return const SizedBox.shrink();
    });

    // ── Note input bar ───────────────────────────────────────────────────
    final noteInputBar = Obx(() => ctrl.currentTabIndex.value == 0
        ? const _NoteInputBar()
        : const SizedBox.shrink());

    // ── Web desktop: WebShell handles layout ─────────────────────────────
    if (webDesktop) {
      return GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Obx(() => WebShell(
          navItems: [
            WebNavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              isActive: ctrl.currentTabIndex.value == 0,
              onTap: () => ctrl.changeTab(0),
            ),
            WebNavItem(
              icon: Icons.calendar_month_rounded,
              label: 'Weekly Target',
              isActive: ctrl.currentTabIndex.value == 1,
              onTap: () => ctrl.changeTab(1),
            ),
            WebNavItem(
              icon: Icons.format_list_bulleted_rounded,
              label: 'History',
              isActive: ctrl.currentTabIndex.value == 2,
              onTap: () => ctrl.changeTab(2),
            ),
            WebNavItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              isActive: ctrl.currentTabIndex.value == 3,
              onTap: () => ctrl.changeTab(3),
            ),
          ],
          bottomAccessory: noteInputBar,
          showBottomAccessory: ctrl.currentTabIndex.value == 0 && ctrl.isCheckedIn.value,
          child: tabContent,
        )),
      );
    }

    // ── Mobile: original layout unchanged ────────────────────────────────
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Stack(
            children: [
              // ── Scrollable content ──────────────────────────────────────
              Positioned.fill(child: tabContent),

              // ── Bottom UI pinned over the scroll area ────────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                   // Note Input Bar
                const _NoteInputBar(),
                    _BottomNav(ctrl: ctrl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final HomeController ctrl;
  const _Header({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.s24, AppSizes.s24, AppSizes.s24, AppSizes.s8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'TODAY',
                    style: TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFFC0C0C0),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Obx(() {
                    return Text(
                      "IN ${ctrl.checkInTimeDisplay}",
                      style: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.4,
                      ),
                    );
                  }),
                  _CloudIndicator(),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                ctrl.todayDisplay,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Obx(() => ctrl.isCheckedIn.value
              ? _LiveBadge(ctrl: ctrl)
              : const SizedBox.shrink()),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.15, end: 0, duration: 400.ms);
  }
}

class _CloudIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SyncService>()) return const SizedBox.shrink();
    
    return Obx(() {
      final isEnabled = SyncService.to.isCloudSyncEnabled.value;
      if (!isEnabled) return const SizedBox.shrink();

      final status = SyncService.to.status.value;
      IconData icon;
      Color color = const Color(0xFF888888);
      
      switch (status) {
        case SyncStatus.online:
          icon = Icons.cloud_done_rounded;
          color = const Color(0xFF4ADE80);
          break;
        case SyncStatus.syncing:
          icon = Icons.cloud_sync_rounded;
          color = const Color(0xFFF9A826);
          break;
        case SyncStatus.offline:
          icon = Icons.cloud_off_rounded;
          break;
        case SyncStatus.error:
          icon = Icons.error_outline_rounded;
          color = AppColors.signalOrange;
          break;
      }

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showSyncBottomSheet(context),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFFC0C0C0),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            if (status == SyncStatus.syncing)
              Icon(icon, color: color, size: 14)
                  .animate(onPlay: (c) => c.repeat())
                  .rotate(duration: const Duration(seconds: 2))
            else
              Icon(icon, color: color, size: 14),
          ],
        ),
      );
    });
  }

  void _showSyncBottomSheet(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final fgColor = Theme.of(context).primaryColor;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(AppSizes.s24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.containerRadius)),
        ),
        child: Obx(() {
          final status = SyncService.to.status.value;
          final lastSynced = SyncService.to.lastSyncedDisplay;
          
          String title = 'Cloud Sync';
          String desc = '';
          IconData headerIcon = Icons.cloud_done_rounded;
          Color headerColor = const Color(0xFF4ADE80);
          
          if (status == SyncStatus.syncing) {
            title = 'Syncing...';
            desc = 'Backing up your data to the cloud securely.';
            headerIcon = Icons.cloud_sync_rounded;
            headerColor = const Color(0xFFF9A826);
          } else if (status == SyncStatus.offline) {
            title = 'Offline Mode';
            desc = 'Changes are saved locally and will sync when online.';
            headerIcon = Icons.cloud_off_rounded;
            headerColor = const Color(0xFF888888);
          } else if (status == SyncStatus.error) {
            title = 'Sync Error';
            desc = 'Could not sync. We will try again later.';
            headerIcon = Icons.error_outline_rounded;
            headerColor = AppColors.signalOrange;
          } else {
            desc = 'Your data is securely backed up.';
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: fgColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Icon(headerIcon, color: headerColor, size: 48),
              const SizedBox(height: 16),
              Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: fgColor)),
              const SizedBox(height: 8),
              Text(desc, textAlign: TextAlign.center, style: TextStyle(color: fgColor.withValues(alpha: 0.5))),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: fgColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Last Synced', style: TextStyle(color: fgColor.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(lastSynced, style: TextStyle(color: fgColor, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: status == SyncStatus.syncing ? null : () {
                    Get.back();
                    SyncService.to.syncNow();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: fgColor,
                    foregroundColor: bgColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.buttonRadius)),
                  ),
                  child: Text(status == SyncStatus.syncing ? 'Syncing...' : 'Sync Now', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        }),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  final HomeController ctrl;
  const _LiveBadge({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isOnBreak = ctrl.isOnBreak.value;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.inkBlack,
          borderRadius: BorderRadius.circular(AppSizes.pillRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isOnBreak ? const Color(0xFFF9A826) : const Color(0xFF4ADE80),
                shape: BoxShape.circle,
              ),
            )
            .animate(key: ValueKey(isOnBreak), onPlay: (c) => c.repeat())
            .fade(begin: 1.0, end: 0.2, duration: isOnBreak ? 1500.ms : 800.ms),
            const SizedBox(width: 6),
            Text(
              isOnBreak ? 'ON BREAK' : 'LIVE',
              style: const TextStyle(
                color: AppColors.canvasCream,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ─── Timer Hero ───────────────────────────────────────────────────────────────
class _TimerHero extends StatelessWidget {
  final HomeController ctrl;
  const _TimerHero({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s24,
        vertical: AppSizes.s16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'REMAINING TIME',
            style: TextStyle(
              color: Color(0xFF888888),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: AppSizes.s8),

          // Remaining time or Paused state
          Obx(() {
            final fg = Theme.of(context).primaryColor;
            if (!ctrl.isCheckedIn.value) {
               return Text('--', style: TextStyle(
                color: fg,
                fontSize: 96,
                fontWeight: FontWeight.w800,
                letterSpacing: -4,
                height: 0.95,
              ));
            }
            if (ctrl.isOnBreak.value) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PAUSED', style: TextStyle(
                    color: fg,
                    fontSize: 72,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -3,
                    height: 0.95,
                  )),
                  const SizedBox(height: 4),
                  Text(ctrl.remainingDisplay.value, style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  )),
                ]
              );
            }
            return Text(
              ctrl.remainingDisplay.value,
              style: TextStyle(
                color: fg,
                fontSize: 96,
                fontWeight: FontWeight.w800,
                letterSpacing: -4,
                height: 0.95,
              ),
            );
          }),

          const SizedBox(height: AppSizes.s32),

          // Progress bar shown only while checked-in
          Obx(() => ctrl.isCheckedIn.value
              ? _ProgressBar(ctrl: ctrl)
              : const SizedBox.shrink()),

          Obx(() => ctrl.isCheckedIn.value
              ? const SizedBox(height: AppSizes.s32)
              : const SizedBox.shrink()),

          // Primary CTA
          _PrimaryCTA(ctrl: ctrl),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 500.ms).slideY(begin: 0.08, end: 0, duration: 500.ms);
  }
}

class _ProgressBar extends StatelessWidget {
  final HomeController ctrl;
  const _ProgressBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final progress = ctrl.progressValue.value;
      final target = ctrl.targetHours.value;
      final fg = Theme.of(context).primaryColor;
      return Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.pillRadius),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: fg.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toInt()}% complete',
                style: const TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'of ${target}h target',
                style: const TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      );
    });
  }
}

class _PrimaryCTA extends StatelessWidget {
  final HomeController ctrl;
  const _PrimaryCTA({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double W = constraints.maxWidth;
        const double H = 64.0;
        const double gap = AppSizes.s12;

        return Obx(() {
          final isIn = ctrl.isCheckedIn.value;
          final isOnBreak = ctrl.isOnBreak.value;
          
          final bool isSplit = isIn && !isOnBreak;

          // Break Button Bounds (Left Side)
          final double breakWidth = isSplit ? (W - gap) * 0.40 : 0.0;
          final double breakOpacity = isSplit ? 1.0 : 0.0;

          // Primary Button Bounds (Right Side, takes full when not split)
          final double primaryLeft = isSplit ? breakWidth + gap : 0.0;
          final double primaryWidth = isSplit ? (W - gap) * 0.60 : W;
          
          final String primaryLabel = !isIn ? 'Check-In' : (isOnBreak ? 'Resume' : 'Check-Out');
          final IconData primaryIcon = !isIn ? Icons.login_rounded : (isOnBreak ? Icons.play_arrow_rounded : Icons.logout_rounded);

          const dur = Duration(milliseconds: 650);
          const crv = Curves.fastLinearToSlowEaseIn;

          return SizedBox(
            width: W,
            height: H,
            child: Stack(
              children: [
                // ─── PRIMARY BUTTON (Check-in / Check-Out / Resume) ─── rendered first (bottom)
                AnimatedPositioned(
                  duration: dur,
                  curve: crv,
                  left: primaryLeft,
                  top: 0,
                  bottom: 0,
                  width: primaryWidth,
                  child: GestureDetector(
                    onTap: !isIn ? ctrl.checkIn : (isOnBreak ? ctrl.toggleBreak : ctrl.checkOut),
                    child: AnimatedContainer(
                      duration: dur,
                      curve: crv,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(AppSizes.pillRadius),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.0, 0.4),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: Row(
                              key: ValueKey(primaryLabel),
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(primaryIcon, color: Theme.of(context).scaffoldBackgroundColor, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  primaryLabel,
                                  style: TextStyle(color: Theme.of(context).scaffoldBackgroundColor, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ─── BREAK BUTTON (Reveals from left) ─── rendered last (on top) so it receives taps
                AnimatedPositioned(
                  duration: dur,
                  curve: crv,
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: breakWidth,
                  child: AnimatedOpacity(
                    duration: Duration(milliseconds: isSplit ? 400 : 200),
                    curve: Curves.easeInOut,
                    opacity: breakOpacity,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: isSplit ? ctrl.toggleBreak : null,
                      child: Container(
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(AppSizes.pillRadius),
                          border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.pause_rounded, color: Theme.of(context).primaryColor, size: 20),
                              const SizedBox(width: 8),
                              Text('Break', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final HomeController ctrl;
  const _StatsRow({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.s24, AppSizes.s8, AppSizes.s24, AppSizes.s8,
      ),
      child: AppContainer(
        padding: const EdgeInsets.all(AppSizes.s24),
        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.05),
        radius: AppSizes.containerRadius,
        child: Obx(() => Row(
          children: [
            _StatCell(label: 'TIME WORKED', value: ctrl.elapsedDisplay.value),
            _StatDivider(),
            _StatCell(label: 'BREAK TIME', value: ctrl.breakDisplay.value),
            _StatDivider(),
            _StatCell(label: 'EXPECTED OUT', value: ctrl.expectedLogoutDisplay.value),
          ],
        )),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  const _StatCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF888888),
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: const Color(0xFFE8E5E3));
  }
}

// ─── Notes Section ────────────────────────────────────────────────────────────
class _NotesSection extends StatelessWidget {
  const _NotesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = NotesController.to;
    return Padding(
      key: ctrl.notesSectionKey,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.s24, AppSizes.s16, AppSizes.s24, 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Notes',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              Obx(() => Text(
                '${ctrl.notes.length} notes',
                style: const TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              )),
            ],
          ),
          const SizedBox(height: AppSizes.s16),
          Obx(() {
            if (ctrl.notes.isEmpty) return const _EmptyNotesState();
            return Column(
              children: ctrl.notes
                  .asMap()
                  .entries
                  .map((e) => _NoteCard(note: e.value, index: e.key))
                  .toList(),
            );
          }),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }
}

class _EmptyNotesState extends StatelessWidget {
  const _EmptyNotesState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.s32),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppSizes.containerRadius),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.edit_note_rounded,
            size: 40,
            color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
          ),
          const SizedBox(height: AppSizes.s8),
          Text(
            'No notes yet.\nJot something down below.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.35),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final int index;
  const _NoteCard({super.key, required this.note, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.s12),
      child: AppContainer(
        padding: const EdgeInsets.all(AppSizes.s16),
        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.05),
        radius: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('h:mm a').format(note.timestamp),
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                GestureDetector(
                  onTap: () => NotesController.to.deleteNote(note.id),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.s8),
            Text(
              note.content,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    )
    .animate()
    .fadeIn(delay: Duration(milliseconds: 50 * index), duration: 300.ms)
    .slideX(begin: 0.05, end: 0,
        delay: Duration(milliseconds: 50 * index), duration: 300.ms);
  }
}

// ─── Note Input Bar ───────────────────────────────────────────────────────────
// Pinned inside the Column (not bottomSheet) — fixes the GetX reactive context issue
class _NoteInputBar extends StatelessWidget {
  const _NoteInputBar({super.key});

  @override
  Widget build(BuildContext context) {
    final homeCtrl = Get.find<HomeController>();
    return Obx(() {
      if (!homeCtrl.isCheckedIn.value) return const SizedBox.shrink();
      
      final ctrl = NotesController.to;
      final isFocused = ctrl.isNoteFocused.value;
      final hasText = ctrl.isNoteNotEmpty.value;

      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.s16, AppSizes.s12, AppSizes.s16, AppSizes.s8,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.pillRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isFocused ? 0.25 : 0.15),
                blurRadius: isFocused ? 24 : 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.pillRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.fromLTRB(AppSizes.s24, 6, 6, 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.pillRadius),
                  color: AppColors.inkBlack.withOpacity(isFocused ? 0.6 : 0.5),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.inkBlack.withOpacity(isFocused ? 0.85 : 0.8),
                      AppColors.inkBlack.withOpacity(isFocused ? 0.65 : 0.6),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(isFocused ? 0.3 : 0.1),
                    width: isFocused ? 1.2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(isFocused ? 0.15 : 0.08),
                      blurRadius: 10,
                      offset: const Offset(-2, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        focusNode: ctrl.noteFocusNode,
                        controller: ctrl.noteInputController,
                        minLines: 1,
                        maxLines: 4,
                        style: const TextStyle(
                          color: AppColors.canvasCream,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        cursorColor: AppColors.canvasCream,
                        decoration: InputDecoration.collapsed(
                          hintText: 'Jot down a quick note...',
                          hintStyle: TextStyle(
                            color: AppColors.canvasCream.withOpacity(isFocused ? 0.6 : 0.5),
                            fontSize: 15,
                          ),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => ctrl.addNote(),
                      ),
                    ),
                    const SizedBox(width: AppSizes.s12),
                    GestureDetector(
                      onTap: ctrl.addNote,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasText 
                              ? AppColors.canvasCream 
                              : isFocused
                                  ? AppColors.canvasCream.withOpacity(0.25)
                                  : AppColors.canvasCream.withOpacity(0.15),
                        ),
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          color: hasText 
                              ? AppColors.inkBlack 
                              : AppColors.canvasCream,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ─── Bottom Nav ───────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final HomeController ctrl;
  const _BottomNav({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            bg,
            bg.withValues(alpha: 0.9),
            bg.withValues(alpha: 0.0),
          ],
          stops: const [0.4, 0.75, 1.0],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.s24, AppSizes.s8, AppSizes.s24, AppSizes.s16,
      ),
      child: AppContainer(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.s16, vertical: 10),
        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.06),
        radius: AppSizes.pillRadius,
        showShadow: true,
        child: Obx(() => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavItem(
              icon: Icons.home_rounded, 
              label: 'Home', 
              isActive: ctrl.currentTabIndex.value == 0, 
              onTap: () => ctrl.changeTab(0),
            ),
            _NavItem(
              icon: Icons.calendar_month_rounded,
              label: 'Weekly Target',
              isActive: ctrl.currentTabIndex.value == 1, 
              onTap: () => ctrl.changeTab(1),
            ),
            _NavItem(
              icon: Icons.format_list_bulleted_rounded, 
              label: 'History', 
              isActive: ctrl.currentTabIndex.value == 2,
              onTap: () => ctrl.changeTab(2),
            ),
            _NavItem(
              icon: Icons.settings_outlined, 
              label: 'Settings', 
              isActive: ctrl.currentTabIndex.value == 3,
              onTap: () => ctrl.changeTab(3), // Or Get.toNamed('/settings') if Settings should overlay
            ),
          ],
        )),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? AppSizes.s16 : AppSizes.s8,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.pillRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? Theme.of(context).scaffoldBackgroundColor : Theme.of(context).primaryColor.withValues(alpha: 0.4),
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
