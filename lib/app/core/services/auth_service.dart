import 'dart:async';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../routes/app_pages.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find();

  final _supabase = Supabase.instance.client;
  final Rx<User?> currentUser = Rx<User?>(null);
  late final StreamSubscription<AuthState> _authStateSubscription;

  // We add this flag to prevent routing during app initialization (splash screen).
  // Splash screen handles the initial routing.
  bool _isReadyForRouting = false;

  Future<AuthService> init() async {
    currentUser.value = _supabase.auth.currentUser;

    _authStateSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      currentUser.value = session?.user;

      if (_isReadyForRouting) {
        if (event == AuthChangeEvent.signedOut) {
          Get.offAllNamed(Routes.auth);
        } else if (event == AuthChangeEvent.signedIn) {
          Get.offAllNamed(Routes.home);
        }
      }
    });

    return this;
  }

  @override
  void onClose() {
    _authStateSubscription.cancel();
    super.onClose();
  }

  void enableRouting() {
    _isReadyForRouting = true;
  }
}
