import 'package:get/get.dart';

class CacheService extends GetxService {
  static const maxAge = Duration(minutes: 30);
  final _cache = <String, dynamic>{};
  final _timestamps = <String, DateTime>{};

  void set(String key, dynamic value) {
    _cache[key] = value;
    _timestamps[key] = DateTime.now();
  }

  T? get<T>(String key) {
    final timestamp = _timestamps[key];
    if (timestamp == null) return null;
    
    if (DateTime.now().difference(timestamp) > maxAge) {
      _cache.remove(key);
      _timestamps.remove(key);
      return null;
    }
    
    return _cache[key] as T?;
  }

  void clear() {
    _cache.clear();
    _timestamps.clear();
  }
} 