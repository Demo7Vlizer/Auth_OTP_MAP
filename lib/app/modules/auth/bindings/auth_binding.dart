import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../services/otp_record_service.dart';
import '../../../services/twilio_service.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AuthController(), permanent: true);
    Get.lazyPut<TwilioService>(
      () => TwilioService.instance,
      fenix: true,
    );
    Get.lazyPut<OtpRecordService>(
      () => OtpRecordService(),
      fenix: true,
    );
  }
} 