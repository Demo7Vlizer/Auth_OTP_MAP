import 'package:get/get.dart';
import '../controllers/verification_history_controller.dart';
import '../../auth/controllers/auth_controller.dart';

class VerificationHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VerificationHistoryController>(
      () => VerificationHistoryController(),
    );
    Get.lazyPut<AuthController>(
      () => AuthController.instance,
    );
  }
} 