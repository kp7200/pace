import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CommonLoader extends StatelessWidget {
  const CommonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.canvasCream.withOpacity(0.6),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.inkBlack),
          strokeWidth: 3.0,
        ),
      ),
    );
  }
}
