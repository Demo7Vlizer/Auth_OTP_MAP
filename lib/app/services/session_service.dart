import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';

class SessionService extends GetxService {
  static const String _boxName = 'sessionBox';
  static const String _deviceIdKey = 'device_id';
  static const String _sessionTokenKey = 'session_token';
  late Box<String> _box;

  Future<SessionService> init() async {
    _box = await Hive.openBox<String>(_boxName);
    return this;
  }

  Future<String?> getDeviceId() async {
    String? deviceId = _box.get(_deviceIdKey);
    
    if (deviceId == null) {
      deviceId = await _generateDeviceId();
      await _box.put(_deviceIdKey, deviceId);
    }
    
    return deviceId;
  }

  Future<String> _generateDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (GetPlatform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (GetPlatform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? DateTime.now().toIso8601String();
    }
    return DateTime.now().toIso8601String();
  }

  Future<void> saveSessionToken(String token) async {
    await _box.put(_sessionTokenKey, token);
  }

  String? getSessionToken() {
    return _box.get(_sessionTokenKey);
  }

  Future<void> clearSession() async {
    await _box.delete(_sessionTokenKey);
  }

  bool isValidSession() {
    return _box.get(_sessionTokenKey) != null;
  }

  @override
  void onClose() {
    _box.close();
    super.onClose();
  }
} 