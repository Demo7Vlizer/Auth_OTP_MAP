import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/auth_view.dart';
import '../modules/auth/views/verify_otp_view.dart';
import '../modules/verification_history/views/verification_history_view.dart';
import '../modules/profile/views/profile_update_view.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/auth/controllers/auth_controller.dart';
import '../modules/auth/views/auth_choice_view.dart';
import '../modules/auth/views/login_view.dart';
import '../modules/verification_history/bindings/verification_history_binding.dart';
import '../services/storage_service.dart';
import '../modules/gallery/views/gallery_view.dart';
import '../modules/gallery/bindings/gallery_binding.dart';

part 'app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final storage = Get.find<StorageService>();

    // If user is already logged in, redirect to verification history
    if (storage.isLoggedIn()) {
      return const RouteSettings(name: Routes.VERIFICATION_HISTORY);
    }

    return null;
  }

  @override
  GetPageBuilder? onPageBuildStart(GetPageBuilder? page) {
    // Ensure controller exists
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController.instance, permanent: true);
    }
    return page;
  }
}

class AppPages {
  static const INITIAL = Routes.AUTH_CHOICE;

  static final routes = [
    GetPage(
      name: Routes.AUTH_CHOICE,
      page: () => const AuthChoiceView(),
      binding: AuthBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.LOGIN,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.REGISTER,
      page: () => const AuthView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.VERIFY_OTP,
      page: () => const VerifyOtpView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.VERIFICATION_HISTORY,
      page: () => const VerificationHistoryView(),
      binding: VerificationHistoryBinding(),
    ),
    GetPage(
      name: Routes.PROFILE_UPDATE,
      page: () => const ProfileUpdateView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: Routes.GALLERY,
      page: () => const GalleryView(),
      binding: GalleryBinding(),
    ),
  ];
}
