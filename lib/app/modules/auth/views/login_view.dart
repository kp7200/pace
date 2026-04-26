import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/base/base_view.dart';
import '../../../core/widgets/common_button.dart';
import '../../../core/widgets/common_text_field.dart';
import '../controllers/auth_controller.dart';

class LoginView extends BaseView<AuthController> {
  const LoginView({super.key});

  @override
  Widget buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Text(
            'Welcome to Pace',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to sync your work sessions.',
            style: TextStyle(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Obx(() {
            if (controller.isOtpSent.value) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CommonTextField(
                    controller: controller.otpController,
                    hintText: '6-digit code',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  CommonButton(
                    text: 'Verify Code',
                    onPressed: controller.verifyOtp,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Didn\'t receive it? ',
                        style: TextStyle(color: Theme.of(context).primaryColor.withValues(alpha: 0.6)),
                      ),
                      GestureDetector(
                        onTap: controller.resendTimer.value == 0 ? controller.resendOtp : null,
                        child: Text(
                          controller.resendTimer.value == 0 
                            ? 'Resend Code' 
                            : 'Resend in ${controller.resendTimer.value}s',
                          style: TextStyle(
                            color: controller.resendTimer.value == 0 
                                ? Theme.of(context).primaryColor 
                                : Theme.of(context).primaryColor.withValues(alpha: 0.3),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      controller.isOtpSent.value = false;
                      controller.otpController.clear();
                    },
                    child: Text(
                      'Use a different email',
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CommonTextField(
                    controller: controller.emailController,
                    hintText: 'Email address',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  CommonButton(
                    text: 'Continue with Email',
                    onPressed: controller.loginWithEmail,
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('OR'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CommonButton(
                    text: 'Continue with Google',
                    onPressed: controller.loginWithGoogle,
                    isSecondary: true,
                    icon: const Icon(Icons.g_mobiledata, size: 32),
                  ),
                ],
              );
            }
          }),
          const Spacer(),
        ],
      ),
    );
  }
}
