import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/base_controller.dart';

class AuthController extends BaseController {
  final emailController = TextEditingController();
  final otpController = TextEditingController();
  
  final RxBool isOtpSent = false.obs;
  
  // Timer state for resending OTP
  final RxInt resendTimer = 0.obs;
  DateTime? _otpSentAt;
  Timer? _timer;

  @override
  void onClose() {
    emailController.dispose();
    otpController.dispose();
    _timer?.cancel();
    super.onClose();
  }

  void _startResendTimer() {
    _otpSentAt = DateTime.now();
    _timer?.cancel();
    _updateTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimer());
  }

  void _updateTimer() {
    if (_otpSentAt == null) {
      resendTimer.value = 0;
      _timer?.cancel();
      return;
    }
    
    final elapsed = DateTime.now().difference(_otpSentAt!).inSeconds;
    final remaining = 60 - elapsed;
    
    if (remaining > 0) {
      resendTimer.value = remaining;
    } else {
      resendTimer.value = 0;
      _timer?.cancel();
      _otpSentAt = null;
    }
  }

  Future<void> loginWithEmail() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      showError('Please enter your email');
      return;
    }

    await handleRequest(() async {
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'io.supabase.pace://login-callback',
      );
      isOtpSent.value = true;
      _startResendTimer();
      showSuccess('We sent a 6-digit code and a magic link to $email');
    });
  }

  Future<void> resendOtp() async {
    if (resendTimer.value > 0) return;
    
    final email = emailController.text.trim();
    if (email.isEmpty) return;

    await handleRequest(() async {
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'io.supabase.pace://login-callback',
      );
      _startResendTimer();
      showSuccess('A new code has been sent to $email');
    });
  }

  Future<void> verifyOtp() async {
    final email = emailController.text.trim();
    final otp = otpController.text.trim();
    
    if (otp.isEmpty || otp.length != 6) {
      showError('Please enter a valid 6-digit code');
      return;
    }

    await handleRequest(() async {
      await Supabase.instance.client.auth.verifyOTP(
        type: OtpType.email,
        email: email,
        token: otp,
      );
    });
  }

  Future<void> loginWithGoogle() async {
    await handleRequest(() async {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.pace://login-callback',
      );
    });
  }
}
