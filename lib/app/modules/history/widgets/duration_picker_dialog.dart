import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// A modal dialog that lets the user pick a [Duration] via
/// hour + minute dropdowns. Returns null if the user cancels.
Future<Duration?> showDurationPicker({
  required BuildContext context,
  required Duration initial,
}) {
  return showDialog<Duration>(
    context: context,
    builder: (_) => _DurationPickerDialog(initial: initial),
  );
}

class _DurationPickerDialog extends StatefulWidget {
  final Duration initial;
  const _DurationPickerDialog({required this.initial});

  @override
  State<_DurationPickerDialog> createState() => _DurationPickerDialogState();
}

class _DurationPickerDialogState extends State<_DurationPickerDialog> {
  late int _hours;
  late int _minutes;

  @override
  void initState() {
    super.initState();
    _hours = widget.initial.inHours.clamp(0, 23);
    _minutes = widget.initial.inMinutes.remainder(60).abs();
    // Snap minutes to nearest 5
    _minutes = (_minutes / 5).round() * 5;
    if (_minutes == 60) {
      _minutes = 55;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).primaryColor;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.containerRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ──────────────────────────────────────────
            Text(
              'Break Duration',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: AppSizes.s24),

            // ── Pickers Row ────────────────────────────────────
            Row(
              children: [
                // Hours
                Expanded(
                  child: _SpinnerColumn(
                    label: 'Hours',
                    value: _hours,
                    values: List.generate(24, (i) => i),
                    onChanged: (v) => setState(() => _hours = v),
                    textColor: textColor,
                    bgColor: bgColor,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppSizes.s16,
                    left: AppSizes.s8,
                    right: AppSizes.s8,
                  ),
                  child: Text(
                    ':',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // Minutes (0, 5, 10 … 55)
                Expanded(
                  child: _SpinnerColumn(
                    label: 'Minutes',
                    value: _minutes,
                    values: List.generate(12, (i) => i * 5),
                    onChanged: (v) => setState(() => _minutes = v),
                    textColor: textColor,
                    bgColor: bgColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSizes.s24),

            // ── Actions ────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.s16),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.buttonRadius),
                        side: BorderSide(
                          color: textColor.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.s12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.inkBlack,
                      foregroundColor: AppColors.canvasCream,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.s16),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.buttonRadius),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(
                      Duration(hours: _hours, minutes: _minutes),
                    ),
                    child: const Text(
                      'Set',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A labeled dropdown column used inside the duration picker.
class _SpinnerColumn extends StatelessWidget {
  final String label;
  final int value;
  final List<int> values;
  final ValueChanged<int> onChanged;
  final Color textColor;
  final Color bgColor;

  const _SpinnerColumn({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
    required this.textColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textColor.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSizes.s8),
        Container(
          decoration: BoxDecoration(
            color: textColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.s12),
          child: DropdownButton<int>(
            value: value,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            dropdownColor: bgColor,
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
            icon: Icon(Icons.keyboard_arrow_down_rounded,
                color: textColor.withValues(alpha: 0.5), size: 18),
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            items: values
                .map(
                  (v) => DropdownMenuItem(
                    value: v,
                    child: Text(
                      v.toString().padLeft(2, '0'),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ],
    );
  }
}
