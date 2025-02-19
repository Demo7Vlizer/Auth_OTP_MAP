import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/user_model.dart';
import '../services/session_service.dart';

class StorageService extends GetxService {
  late Box<UserModel> _userBox;
  late Box<String> _keyBox;
  static const String userBoxName = 'userBox';
  static const String keyBoxName = 'keyBox';
  static const String userKey = 'currentUser';

  Future<StorageService> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(UserModelAdapter());
    _userBox = await Hive.openBox<UserModel>(userBoxName);
    _keyBox = await Hive.openBox<String>(keyBoxName);
    return this;
  }

  // Save user data
  Future<void> saveUser(UserModel user) async {
    if (user.phoneNumber == null) return;
    
    // Save user with phone number as key
    final userKey = 'user_${user.phoneNumber}';
    await _userBox.put(userKey, user);
    
    // Update current user reference if user is logged in
    if (user.isLoggedIn) {
      await _keyBox.put('currentUser', userKey);
    }
  }

  // Get user by phone number
  UserModel? getUser([String? phoneNumber]) {
    if (phoneNumber != null) {
      return _userBox.get('user_$phoneNumber');
    }
    final currentUserKey = _keyBox.get('currentUser');
    return currentUserKey != null ? _userBox.get(currentUserKey) : null;
  }

  // Check if user exists
  bool isUserExists(String phoneNumber) {
    return _userBox.containsKey('user_$phoneNumber');
  }

  // Check if user is logged in
  bool isLoggedIn() {
    try {
      // First check current user
      final currentUserKey = _keyBox.get('currentUser');
      if (currentUserKey != null) {
        final currentUser = _userBox.get(currentUserKey);
        if (currentUser?.isLoggedIn == true) {
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Check login status error: $e');
      return false;
    }
  }

  // Logout user
  Future<void> logout(String phoneNumber) async {
    try {
      final userKey = 'user_$phoneNumber';
      final user = _userBox.get(userKey);
      if (user != null) {
        // Update login status
        await _userBox.put(userKey, user.copyWith(isLoggedIn: false));
        // Remove current user reference
        await _keyBox.delete('currentUser');
      }
    } catch (e) {
      print('Logout error: $e');
    }
  }

  // Check if profile is complete
  bool isProfileComplete(String phoneNumber) {
    final user = getUser(phoneNumber);
    return user != null && 
           user.name?.isNotEmpty == true && 
           user.email?.isNotEmpty == true;
  }

  // Clear all data
  Future<void> clearAll() async {
    await _userBox.clear();
    await _keyBox.clear();
  }

  // Clear auth state
  Future<void> clearAuthState() async {
    try {
      // Clear current user reference
      await _keyBox.delete('currentUser');
      
      // Set all users to logged out
      for (var key in _userBox.keys) {
        final user = _userBox.get(key);
        if (user != null) {
          await _userBox.put(key, user.copyWith(isLoggedIn: false));
        }
      }
    } catch (e) {
      print('Clear auth state error: $e');
    }
  }

  Future<void> initSession() async {
    final sessionService = Get.find<SessionService>();
    if (await sessionService.isValidSession()) {
      // Generate a simple session token
      final token = DateTime.now().millisecondsSinceEpoch.toString();
      await sessionService.saveSessionToken(token);
    }
  }

  // Get all stored users
  List<UserModel> getAllUsers() {
    try {
      return _userBox.values.toList();
    } catch (e) {
      print('Get all users error: $e');
      return [];
    }
  }

  // Get all logged in users
  List<UserModel> getLoggedInUsers() {
    try {
      return _userBox.values.where((user) => user.isLoggedIn).toList();
    } catch (e) {
      print('Get logged in users error: $e');
      return [];
    }
  }

  // Switch current user
  Future<bool> switchUser(String phoneNumber) async {
    try {
      final userKey = 'user_$phoneNumber';
      final user = _userBox.get(userKey);
      
      if (user != null) {
        // Set all other users as logged out
        for (var key in _userBox.keys) {
          if (key != userKey) {
            final otherUser = _userBox.get(key);
            if (otherUser != null) {
              await _userBox.put(key, otherUser.copyWith(isLoggedIn: false));
            }
          }
        }
        
        // Set selected user as logged in
        await _userBox.put(userKey, user.copyWith(isLoggedIn: true));
        await _keyBox.put('currentUser', userKey);
        return true;
      }
      return false;
    } catch (e) {
      print('Switch user error: $e');
      return false;
    }
  }

  // Delete user account
  Future<void> deleteUser(String phoneNumber) async {
    try {
      final userKey = 'user_$phoneNumber';
      await _userBox.delete(userKey);
      
      // If this was the current user, clear current user reference
      final currentUserKey = _keyBox.get('currentUser');
      if (currentUserKey == userKey) {
        await _keyBox.delete('currentUser');
      }
    } catch (e) {
      print('Delete user error: $e');
    }
  }
} 