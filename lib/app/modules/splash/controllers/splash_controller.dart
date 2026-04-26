import 'package:get/get.dart';
import '../../../core/base_controller.dart';
import '../../../core/services/auth_service.dart';
import '../../../routes/app_pages.dart';

class SplashController extends BaseController {
  @override
  void onInit() {
    super.onInit();
    _startTransition();
  }

  void _startTransition() {
    // The total choreography takes ~3200ms. 
    // Triggering the fade-in of the Home route completes the visual sequence.
    Future.delayed(const Duration(milliseconds: 3200), () {
      final authService = AuthService.to;
      authService.enableRouting(); // allow auth service to route dynamically from now on
      
      if (authService.currentUser.value == null) {
        Get.offNamed(Routes.auth);
      } else {
        Get.offNamed(Routes.home);
      }
    });
  }
}
