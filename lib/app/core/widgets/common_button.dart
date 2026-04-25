import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import 'common_text.dart';

class CommonButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isSecondary;

  const CommonButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary ? AppColors.transparent : AppColors.inkBlack,
          foregroundColor: isSecondary ? AppColors.inkBlack : AppColors.canvasCream,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
            side: isSecondary 
                ? const BorderSide(color: AppColors.inkBlack, width: 1.5)
                : BorderSide.none,
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isSecondary ? AppColors.inkBlack : AppColors.canvasCream,
                  ),
                ),
              )
            : CommonText(
                text,
                color: isSecondary ? AppColors.inkBlack : AppColors.canvasCream,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
      ),
    );
  }
}
