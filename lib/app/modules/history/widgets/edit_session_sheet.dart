import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/work_session.dart';
import '../controllers/history_controller.dart';
import 'duration_picker_dialog.dart';

/// Shows the edit session bottom sheet for [session].
/// All state is local — nothing mutates until the user taps Save.
void showEditSessionSheet(BuildContext context, WorkSession session) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EditSessionSheet(session: session),
  );
}

class _EditSessionSheet extends StatefulWidget {
  final WorkSession session;
  const _EditSessionSheet({required this.session});

  @override
  State<_EditSessionSheet> createState() => _EditSessionSheetState();
}

class _EditSessionSheetState extends State<_EditSessionSheet> {
  late DateTime _checkIn;
  late DateTime? _checkOut;
  late Duration _breakDuration;

  bool _isSaving = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _checkIn = widget.session.checkInTime;
    _checkOut = widget.session.checkOutTime;
    _breakDuration = widget.session.totalBreakDuration;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _fmtTime(DateTime dt) => DateFormat('h:mm a').format(dt);

  String _fmtBreak(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    if (m > 0) return '${m}m';
    return 'None';
  }

  String? _validate() {
    if (_checkOut != null && !_checkOut!.isAfter(_checkIn)) {
      return 'Check-out must be after check-in.';
    }
    if (_checkOut != null) {
      final sessionLength = _checkOut!.difference(_checkIn);
      if (_breakDuration > sessionLength) {
        return 'Break cannot exceed the total session length.';
      }
    }
    final now = DateTime.now();
    if (_checkIn.isAfter(now)) {
      return 'Check-in cannot be in the future.';
    }
    if (_checkOut != null && _checkOut!.isAfter(now)) {
      return 'Check-out cannot be in the future.';
    }
    return null;
  }

  bool get _hasChanges =>
      _checkIn != widget.session.checkInTime ||
      _checkOut != widget.session.checkOutTime ||
      _breakDuration != widget.session.totalBreakDuration;

  // ── Time Picker helper — constrains to the session's date ─────────────────

  Future<TimeOfDay?> _pickTime(TimeOfDay initial) {
    return showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.inkBlack,
            onPrimary: AppColors.canvasCream,
            surface: AppColors.canvasCream,
            onSurface: AppColors.inkBlack,
            secondary: AppColors.inkBlack,
            onSecondary: AppColors.canvasCream,
            surfaceTint: Colors.transparent, // Disable Material 3 purple tint
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.inkBlack,
            ),
          ),
        ),
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        ),
      ),
    );
  }

  DateTime _applyTime(DateTime base, TimeOfDay time) {
    return DateTime(base.year, base.month, base.day, time.hour, time.minute);
  }

  // ── Tap handlers ──────────────────────────────────────────────────────────

  Future<void> _onTapCheckIn() async {
    final picked = await _pickTime(TimeOfDay.fromDateTime(_checkIn));
    if (picked == null) return;
    setState(() {
      _checkIn = _applyTime(widget.session.date, picked);
      _validationError = _validate();
    });
  }

  Future<void> _onTapCheckOut() async {
    final currentOut = _checkOut ?? widget.session.date;
    final picked = await _pickTime(TimeOfDay.fromDateTime(currentOut));
    if (picked == null) return;
    setState(() {
      _checkOut = _applyTime(widget.session.date, picked);
      _validationError = _validate();
    });
  }

  Future<void> _onTapBreak() async {
    final picked = await showDurationPicker(
      context: context,
      initial: _breakDuration,
    );
    if (picked == null) return;
    setState(() {
      _breakDuration = picked;
      _validationError = _validate();
    });
  }

  Future<void> _onSave() async {
    final error = _validate();
    if (error != null) {
      setState(() => _validationError = error);
      return;
    }
    setState(() => _isSaving = true);
    final ctrl = Get.find<HistoryController>();
    await ctrl.updateSessionTimes(
      date: widget.session.date,
      checkIn: _checkIn,
      checkOut: _checkOut,
      breakDuration: _breakDuration,
    );
    if (mounted) Navigator.of(context).pop();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).primaryColor;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final dateStr = DateFormat('EEEE, MMM d').format(widget.session.date);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSizes.containerRadius),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.s24,
              AppSizes.s16,
              AppSizes.s24,
              AppSizes.s24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Handle ────────────────────────────────────────
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: textColor.withValues(alpha: 0.15),
                      borderRadius:
                          BorderRadius.circular(AppSizes.pillRadius),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.s24),

                // ── Title ─────────────────────────────────────────
                Text(
                  'EDIT SESSION',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: AppSizes.s24),

                // ── Fields ────────────────────────────────────────
                _TimeField(
                  icon: Icons.login_rounded,
                  label: 'Check-In',
                  value: _fmtTime(_checkIn),
                  onTap: _onTapCheckIn,
                  textColor: textColor,
                ),
                const SizedBox(height: AppSizes.s12),
                _TimeField(
                  icon: Icons.coffee_rounded,
                  label: 'Break Duration',
                  value: _fmtBreak(_breakDuration),
                  onTap: _onTapBreak,
                  textColor: textColor,
                ),
                const SizedBox(height: AppSizes.s12),
                _TimeField(
                  icon: Icons.logout_rounded,
                  label: 'Check-Out',
                  value: _checkOut != null ? _fmtTime(_checkOut!) : 'Not recorded',
                  onTap: _onTapCheckOut,
                  textColor: textColor,
                  isOptional: _checkOut == null,
                ),

                // ── Validation error ──────────────────────────────
                if (_validationError != null) ...[
                  const SizedBox(height: AppSizes.s12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.s16,
                      vertical: AppSizes.s12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.signalOrange.withValues(alpha: 0.08),
                      borderRadius:
                          BorderRadius.circular(AppSizes.buttonRadius),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: AppColors.signalOrange, size: 16),
                        const SizedBox(width: AppSizes.s8),
                        Expanded(
                          child: Text(
                            _validationError!,
                            style: const TextStyle(
                              color: AppColors.signalOrange,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSizes.s24),

                // ── Action Buttons ────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSizes.s16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppSizes.buttonRadius),
                            side: BorderSide(
                              color: textColor.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.s12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasChanges && !_isSaving
                              ? AppColors.inkBlack
                              : AppColors.inkBlack.withValues(alpha: 0.35),
                          foregroundColor: AppColors.canvasCream,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSizes.s16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppSizes.buttonRadius),
                          ),
                        ),
                        onPressed: (_hasChanges && !_isSaving)
                            ? _onSave
                            : null,
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.canvasCream,
                                ),
                              )
                            : const Text(
                                'Save',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Reusable field tile ────────────────────────────────────────────────────

class _TimeField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final Color textColor;
  final bool isOptional;

  const _TimeField({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    required this.textColor,
    this.isOptional = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.s16,
            vertical: AppSizes.s16,
          ),
          decoration: BoxDecoration(
            color: textColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: textColor.withValues(alpha: 0.5)),
              const SizedBox(width: AppSizes.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        color: isOptional
                            ? textColor.withValues(alpha: 0.35)
                            : textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontStyle: isOptional
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: textColor.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
