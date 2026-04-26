import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/common_container.dart';
import '../controllers/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _Header(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.s24),
              children: [
                const SizedBox(height: AppSizes.s12),
                
                // ─── ACCOUNT ─────────────────────────────────────────────
                _SectionHeader(title: 'ACCOUNT'),
                _AccountSection(),
                const SizedBox(height: AppSizes.s32),

                // ─── APPEARANCE ──────────────────────────────────────────
                _SectionHeader(title: 'APPEARANCE'),
                _AppearanceSelector(),
                const SizedBox(height: AppSizes.s32),

                // ─── WORKDAY ─────────────────────────────────────────────
                _SectionHeader(title: 'WORKDAY'),
                _TargetSelector(),
                const SizedBox(height: AppSizes.s32),

                // ─── PREFERENCES ──────────────────────────────────────────
                _SectionHeader(title: 'PREFERENCES'),
                _HapticToggle(),
                const SizedBox(height: 12),
                _CloudSyncToggle(),
                const SizedBox(height: AppSizes.s32),

                // ─── DANGER ZONE ─────────────────────────────────────────
                _SectionHeader(title: 'DANGER ZONE', color: AppColors.signalOrange),
                _DangerZone(),
                const SizedBox(height: 64),

                // ─── VERSION ─────────────────────────────────────────────
                Center(
                  child: Text(
                    'v1.0.0 (Premium Build)',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
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
              Text(
                'PREFERENCES',
                style: TextStyle(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Settings',
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color? color;
  const _SectionHeader({required this.title, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.s12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: color ?? Theme.of(context).primaryColor.withValues(alpha: 0.4),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _AppearanceSelector extends GetView<SettingsController> {
  @override
  Widget build(BuildContext context) {
    return CommonContainer(
      padding: const EdgeInsets.all(AppSizes.s8),
      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.04),
      radius: AppSizes.pillRadius,
      child: Obx(() {
        return Row(
          children: [
            _buildOption(context, 'Light', ThemeMode.light),
            _buildOption(context, 'Dark', ThemeMode.dark),
            _buildOption(context, 'System', ThemeMode.system),
          ],
        );
      }),
    );
  }

  Widget _buildOption(BuildContext context, String label, ThemeMode mode) {
    // Called inside Obx, so .value access is correctly reactive
    final isSelected = controller.themeMode.value == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.updateThemeMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.pillRadius),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected
                  ? Theme.of(context).scaffoldBackgroundColor
                  : Theme.of(context).primaryColor.withValues(alpha: 0.6),
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _TargetSelector extends GetView<SettingsController> {
  @override
  Widget build(BuildContext context) {
    final targets = [4, 6, 8, 9, 10, 12];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: targets.map((h) => Obx(() {
        final isSelected = controller.targetHours.value == h;
        return GestureDetector(
          onTap: () => controller.updateTargetHours(h),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).primaryColor.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
              border: Border.all(
                color: isSelected ? Colors.transparent : Theme.of(context).primaryColor.withValues(alpha: 0.1),
              ),
            ),
            child: Text(
              '${h}h',
              style: TextStyle(
                color: isSelected 
                    ? Theme.of(context).scaffoldBackgroundColor 
                    : Theme.of(context).primaryColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      })).toList(),
    );
  }
}

class _HapticToggle extends GetView<SettingsController> {
  @override
  Widget build(BuildContext context) {
    return CommonContainer(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.04),
      radius: AppSizes.containerRadius,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.vibration_rounded, color: Theme.of(context).primaryColor, size: 20),
              const SizedBox(width: 12),
              Text(
                'Haptic Feedback',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Obx(() => Switch.adaptive(
            value: controller.hapticsEnabled.value,
            onChanged: (v) => controller.toggleHaptics(v),
            activeTrackColor: Theme.of(context).primaryColor,
          )),
        ],
      ),
    );
  }
}

class _CloudSyncToggle extends GetView<SettingsController> {
  @override
  Widget build(BuildContext context) {
    return CommonContainer(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.04),
      radius: AppSizes.containerRadius,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_sync_rounded, color: Theme.of(context).primaryColor, size: 20),
              const SizedBox(width: 12),
              Text(
                'Cloud Sync',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Obx(() => Switch.adaptive(
            value: controller.isCloudSyncEnabled.value,
            onChanged: (v) => controller.toggleCloudSync(v),
            activeTrackColor: Theme.of(context).primaryColor,
          )),
        ],
      ),
    );
  }
}

class _DangerZone extends GetView<SettingsController> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DangerButton(
          label: 'Reset Today\'s Session',
          onTap: () => _confirm(context, 'Reset Today?', 'This will wipe your current timer and notes.', controller.resetToday),
        ),
        const SizedBox(height: 12),
        _DangerButton(
          label: 'Clear All History',
          onTap: () => _confirm(context, 'Clear History?', 'This action cannot be undone. All logs will be deleted.', controller.clearAllHistory, requiresTyping: true),
        ),
        const SizedBox(height: 12),
        _DangerButton(
          label: 'Delete Account',
          onTap: () => _confirm(context, 'Delete Account?', 'This will permanently delete your account and all data.', controller.deleteAccount, requiresTyping: true),
        ),
      ],
    );
  }

  void _confirm(BuildContext context, String title, String msg, VoidCallback onConfirm, {bool requiresTyping = false}) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final fgColor = Theme.of(context).primaryColor;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) {
          bool canConfirm = !requiresTyping;
          return Container(
            padding: EdgeInsets.fromLTRB(AppSizes.s24, AppSizes.s24, AppSizes.s24, MediaQuery.of(context).viewInsets.bottom + AppSizes.s24),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.containerRadius)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: fgColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 24),
                Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: fgColor)),
                const SizedBox(height: 8),
                Text(msg, textAlign: TextAlign.center, style: TextStyle(color: fgColor.withValues(alpha: 0.5))),
                if (requiresTyping) ...[
                  const SizedBox(height: 20),
                  TextField(
                    autofocus: true,
                    onChanged: (val) {
                      setState(() {
                        canConfirm = val.trim().toUpperCase() == 'CONFIRM';
                      });
                    },
                    style: TextStyle(color: fgColor),
                    decoration: InputDecoration(
                      hintText: 'Type CONFIRM to proceed',
                      hintStyle: TextStyle(color: fgColor.withValues(alpha: 0.3)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: fgColor.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: fgColor.withValues(alpha: 0.3)),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        child: Text('Cancel', style: TextStyle(color: fgColor, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: canConfirm ? () {
                          Get.back();
                          onConfirm();
                        } : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.signalOrange,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.signalOrange.withValues(alpha: 0.3),
                          disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.buttonRadius)),
                        ),
                        child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        }
      ),
      isScrollControlled: true,
    );
  }
}

class _DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DangerButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.signalOrange.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.signalOrange,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _AccountSection extends GetView<SettingsController> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  _AccountSection() {
    // Initialize with current user's name if available
    final user = AuthService.to.currentUser.value;
    final fullName = user?.userMetadata?['full_name'] as String?;
    final email = user?.email;
    
    if (fullName != null) {
      _nameController.text = fullName;
    }
    if (email != null) {
      _emailController.text = email;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CommonContainer(
          padding: const EdgeInsets.all(AppSizes.s16),
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.04),
          radius: AppSizes.containerRadius,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Full Name',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSizes.s8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      style: TextStyle(color: Theme.of(context).primaryColor),
                      decoration: InputDecoration(
                        hintText: 'Enter your name',
                        hintStyle: TextStyle(color: Theme.of(context).primaryColor.withValues(alpha: 0.4)),
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.s12),
                  GestureDetector(
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      controller.updateProfile(_nameController.text.trim());
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
                      ),
                      child: Text(
                        'Save',
                        style: TextStyle(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.s16),
              Text(
                'Email Address',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSizes.s8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: Theme.of(context).primaryColor),
                      decoration: InputDecoration(
                        hintText: 'Enter new email',
                        hintStyle: TextStyle(color: Theme.of(context).primaryColor.withValues(alpha: 0.4)),
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.s12),
                  GestureDetector(
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      controller.updateEmail(_emailController.text.trim());
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
                      ),
                      child: Text(
                        'Update',
                        style: TextStyle(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => controller.logout(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
            ),
            child: Text(
              'Log Out',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
