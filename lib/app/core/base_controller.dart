import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Base system for state management, loading, errors, and feedback.
/// All newly created controllers MUST extend this BaseController.
abstract class BaseController extends GetxController {
  // Centralized loading state flag
  final RxBool isLoading = false.obs;

  /// Shows the loader, intended to be observed by BaseView
  void showLoader() => isLoading.value = true;

  /// Hides the loader
  void hideLoader() => isLoading.value = false;

  /// Core async request handler for safe, predictable business logic execution.
  /// Automatically manages loading state and catches runtime failures to prevent crashes.
  /// 
  /// The [request] parameter is your async business logic.
  /// Returns [T] on success, or [null] if an error occurred.
  Future<T?> handleRequest<T>(
    Future<T> Function() request, {
    bool showLoading = true,
  }) async {
    try {
      if (showLoading) showLoader();
      final result = await request();
      return result;
    } catch (e, stackTrace) {
      debugPrint('[BaseController] Error: $e');
      debugPrint('[BaseController] StackTrace: $stackTrace');
      showError(_parseErrorMessage(e));
      return null;
    } finally {
      if (showLoading) hideLoader();
    }
  }

  /// Parses error type to provide user-friendly messages
  String _parseErrorMessage(dynamic e) {
    // Extended logic can be implemented here depending on the error type
    // (e.g., FirebaseException, SocketException, etc.)
    return e.toString();
  }

  /// Displays a Success message following the Design System
  void showSuccess(String message) {
    if (Get.isSnackbarOpen) Get.closeAllSnackbars();
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF141413), // Ink Black
      colorText: const Color(0xFFF3F0EE), // Canvas Cream
      margin: const EdgeInsets.all(16),
      borderRadius: 20, // Following Design System
      duration: const Duration(seconds: 3),
      isDismissible: true,
    );
  }

  /// Displays an Error message following the Design System
  void showError(String message) {
    if (Get.isSnackbarOpen) Get.closeAllSnackbars();
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFCF4500), // Signal Orange (for warnings/errors)
      colorText: const Color(0xFFF3F0EE), // Canvas Cream
      margin: const EdgeInsets.all(16),
      borderRadius: 20, // Following Design System
      duration: const Duration(seconds: 4),
      isDismissible: true,
    );
  }

  /// Displays an Informational message following the Design System
  void showInfo(String message) {
    if (Get.isSnackbarOpen) Get.closeAllSnackbars();
    Get.snackbar(
      'Info',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFF3F0EE), // Canvas Cream
      colorText: const Color(0xFF141413), // Ink Black
      margin: const EdgeInsets.all(16),
      borderRadius: 20, // Following Design System
      borderWidth: 1,
      borderColor: const Color(0xFF141413),
      duration: const Duration(seconds: 3),
      isDismissible: true,
    );
  }
}
