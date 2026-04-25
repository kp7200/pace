import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.canvasCream,
      body: Center(
        child: _SplashAnimationBody(),
      ),
    );
  }
}

class _SplashAnimationBody extends StatefulWidget {
  const _SplashAnimationBody();

  @override
  State<_SplashAnimationBody> createState() => _SplashAnimationBodyState();
}

class _SplashAnimationBodyState extends State<_SplashAnimationBody>
    with TickerProviderStateMixin {

  // Phase 1: Dot appears (scale up)
  late AnimationController _dotController;
  late Animation<double> _dotScale;

  // Phase 2: Pill morphs (width expands)
  late AnimationController _pillController;
  late Animation<double> _pillWidth;

  // Phase 3: Text fades in
  late AnimationController _textController;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  // Phase 4: Exit (whole thing fades out)
  late AnimationController _exitController;
  late Animation<double> _exitOpacity;
  late Animation<double> _exitScale;

  static const double _dotSize = 64.0;
  static const double _expandedWidth = 280.0;

  @override
  void initState() {
    super.initState();

    // Phase 1: dot pops in with elastic bounce
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _dotScale = CurvedAnimation(parent: _dotController, curve: Curves.elasticOut);

    // Phase 2: pill stretches wide
    _pillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _pillWidth = CurvedAnimation(parent: _pillController, curve: Curves.easeInOutCubic);

    // Phase 3: text appears
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _textOpacity = CurvedAnimation(parent: _textController, curve: Curves.easeOut);
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic));

    // Phase 4: exit
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _exitOpacity = Tween<double>(begin: 1, end: 0)
        .animate(CurvedAnimation(parent: _exitController, curve: Curves.easeIn));
    _exitScale = Tween<double>(begin: 1, end: 8)
        .animate(CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic));

    _runSequence();
  }

  Future<void> _runSequence() async {
    // Phase 1: dot appears (0ms)
    await Future.delayed(const Duration(milliseconds: 150));
    _dotController.forward();

    // Phase 2: morph to pill (starts at 650ms, during dot elastic tail)
    await Future.delayed(const Duration(milliseconds: 650));
    _pillController.forward();

    // Phase 3: text slides in (starts as pill completes)
    await Future.delayed(const Duration(milliseconds: 400));
    _textController.forward();

    // Phase 4: exit animation (hold for reading, then exit)
    await Future.delayed(const Duration(milliseconds: 1200));
    _exitController.forward();
  }

  @override
  void dispose() {
    _dotController.dispose();
    _pillController.dispose();
    _textController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _dotController,
        _pillController,
        _textController,
        _exitController,
      ]),
      builder: (context, _) {
        final currentWidth = _dotSize + ((_expandedWidth - _dotSize) * _pillWidth.value);

        return Opacity(
          opacity: _exitOpacity.value,
          child: Transform.scale(
            scale: _exitScale.value,
            child: Transform.scale(
              scale: _dotScale.value,
              child: Container(
                width: currentWidth,
                height: _dotSize,
                decoration: BoxDecoration(
                  color: AppColors.inkBlack,
                  borderRadius: BorderRadius.circular(999),
                ),
                clipBehavior: Clip.hardEdge,
                child: Center(
                  child: ClipRect(
                    child: FadeTransition(
                      opacity: _textOpacity,
                      child: SlideTransition(
                        position: _textSlide,
                        child: const Text(
                          AppStrings.appName,
                          style: TextStyle(
                            color: AppColors.canvasCream,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
