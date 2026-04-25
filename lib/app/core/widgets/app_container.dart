import 'package:flutter/material.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class AppContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final bool showShadow;

  /// Important Formula Rule:
  /// Outer Radius = Inner Radius + Padding/Gap
  /// Make sure to configure inner children radii following this formula for perfect nested corners.
  const AppContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSizes.s24),
    this.margin,
    this.radius = AppSizes.containerRadius,
    this.backgroundColor = Colors.white,
    this.borderColor,
    this.borderWidth = 1.0,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: ShapeDecoration(
        color: backgroundColor,
        shadows: showShadow
            ? [
                BoxShadow(
                  color: AppColors.inkBlack.withValues(alpha: 0.04), // Corrected alpha implementation
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(radius),
          side: borderColor != null
              ? BorderSide(color: borderColor!, width: borderWidth)
              : BorderSide.none,
        ),
      ),
      child: child,
    );
  }
}
