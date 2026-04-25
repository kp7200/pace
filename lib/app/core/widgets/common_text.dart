import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CommonText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;

  const CommonText(
    this.text, {
    super.key,
    this.fontSize,
    this.fontWeight,
    this.color = AppColors.inkBlack,
    this.textAlign,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        // Optional: you can define geometric sans font family here if applicable later
      ),
    );
  }
}
