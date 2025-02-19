// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:new_auth/app/models/otp_record.dart';
import 'package:new_auth/app/services/auth_service.dart';
import 'package:new_auth/app/services/otp_record_service.dart';
import 'dart:async';
import '../../../routes/app_pages.dart';
import '../../../data/models/user_model.dart';
import '../../../services/storage_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import '../../../services/session_service.dart';

class AuthController extends GetxController {
  static AuthController get instance {
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController());
    }
    return Get.find<AuthController>();
  }

  final phoneController = TextEditingController().obs;
  final otpController = TextEditingController().obs;

  final AuthService _authService = AuthService();
  final OtpRecordService _otpRecordService = OtpRecordService();
  final isLoading = false.obs;
  final resendTimer = 30.obs;
  final canResendOtp = true.obs;
  Timer? _timer;
  final otpRecords = <OtpRecord>[].obs;
  final StorageService _storage = Get.find<StorageService>();
  final isAuthenticated = false.obs;
  final Dio _dio = Dio();
  final baseUrl = 'https://67b57bf4a9acbdb38ed28a42.mockapi.io/api/v1';
  final SessionService _sessionService = Get.find<SessionService>();

  @override
  void onInit() {
    super.onInit();
    phoneController.value = TextEditingController();
    otpController.value = TextEditingController();
    checkAuthStatus();
    fetchOtpRecords();
  }

  bool validatePhoneNumber(String phone) {
    // Remove any spaces, dashes, or other characters
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');

    // Check if it's exactly 10 digits
    if (cleanPhone.length != 10) {
      Get.snackbar(
        'Error',
        'Please enter a valid 10-digit phone number',
        backgroundColor: Colors.red.shade100,
      );
      return false;
    }
    return true;
  }

  void startResendTimer() {
    canResendOtp.value = false;
    resendTimer.value = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendTimer.value == 0) {
        timer.cancel();
        canResendOtp.value = true;
      } else {
        resendTimer.value--;
      }
    });
  }

  void sendOtp() async {
    if (!validatePhoneNumber(phoneController.value.text)) {
      return;
    }

    isLoading.value = true;
    try {
      // Check if number exists for new registration
      final isRegistration = Get.currentRoute == Routes.REGISTER;
      if (isRegistration) {
        final existingUser = await _dio.get(
          '$baseUrl/users',
          queryParameters: {'phoneNumber': phoneController.value.text},
        );

        if ((existingUser.data as List).isNotEmpty) {
          Get.snackbar(
            'Already Registered',
            'This number is already registered. Please use login instead.',
            backgroundColor: Colors.amber.shade100,
            duration: const Duration(seconds: 3),
            mainButton: TextButton(
              onPressed: () => Get.toNamed(Routes.LOGIN),
              child: const Text('Go to Login'),
            ),
          );
          return;
        }
      }

      // Proceed with OTP sending
      final response = await _authService.sendOtp(phoneController.value.text);
      if (response.success) {
        Get.toNamed(
          Routes.VERIFY_OTP,
          parameters: {
            'phone': phoneController.value.text,
            'isRegistration': isRegistration.toString(),
          },
        );
        startResendTimer();
      } else {
        Get.snackbar(
          'Error',
          response.message ?? 'Failed to send OTP',
          backgroundColor: Colors.red.shade100,
        );
      }
    } catch (e) {
      if (e is DioError && e.type == DioErrorType.connectionError) {
        Get.snackbar(
          'Network Error',
          'Please check your internet connection',
          backgroundColor: Colors.red.shade100,
        );
      } else {
        Get.snackbar(
          'Error',
          e.toString(),
          backgroundColor: Colors.red.shade100,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchOtpRecords() async {
    if (isLoading.value) return;

    isLoading.value = true;
    try {
      print('Fetching OTP records...'); // Debug print
      final records = await _otpRecordService.getOtpRecords();
      print('Fetched ${records.length} records'); // Debug print

      if (records.isNotEmpty) {
        otpRecords.assignAll(records);
      }
    } catch (e) {
      print('Failed to fetch OTP records: $e');
      Get.snackbar(
        'Error',
        'Failed to fetch records',
        backgroundColor: Colors.red.shade100,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshRecords() async {
    print('Refreshing records...'); // Debug print
    await fetchOtpRecords();
  }

  void checkAuthStatus() async {
    final isValidSession = await _sessionService.isValidSession();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isValidSession && _storage.isLoggedIn()) {
        Get.offAllNamed(Routes.VERIFICATION_HISTORY);
      } else {
        final currentRoute = Get.currentRoute;
        if (currentRoute != Routes.AUTH_CHOICE && 
            currentRoute != Routes.LOGIN && 
            currentRoute != Routes.REGISTER) {
          Get.offAllNamed(Routes.AUTH_CHOICE);
        }
      }
    });
  }

  void verifyOtp() async {
    if (otpController.value.text.length != 6) {
      Get.snackbar('Error', 'Please enter valid OTP');
      return;
    }

    isLoading.value = true;
    try {
      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        Get.snackbar('Error', 'Location permission is required');
        return;
      }

      final response = await _authService.verifyOtp(
        phoneController.value.text,
        otpController.value.text,
      );

      if (response.success) {
        final phoneNumber = phoneController.value.text;

        // Check if user exists and has complete profile
        if (_storage.isUserExists(phoneNumber)) {
          final existingUser = _storage.getUser(phoneNumber)!;
          await _storage.saveUser(existingUser.copyWith(isLoggedIn: true));

          if (_storage.isProfileComplete(phoneNumber)) {
            Get.offAllNamed(Routes.VERIFICATION_HISTORY);
          } else {
            Get.offAllNamed(
              Routes.PROFILE_UPDATE,
              parameters: {'phone': phoneNumber},
            );
          }
        } else {
          // Create new user
          final newUser = UserModel(
            phoneNumber: phoneNumber,
            name: '',
            email: '',
            profileImage: '',
            latitude: 0.0,
            longitude: 0.0,
            isLoggedIn: true,
          );
          await _storage.saveUser(newUser);

          // Send to profile update for new users
          Get.offAllNamed(
            Routes.PROFILE_UPDATE,
            parameters: {'phone': phoneNumber},
          );
        }

        // Generate and save session token
        final deviceId = await _sessionService.getDeviceId();
        final sessionToken = '$deviceId-${DateTime.now().millisecondsSinceEpoch}';
        await _sessionService.saveSessionToken(sessionToken);
      } else {
        Get.snackbar('Error', response.message ?? 'Invalid OTP');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      await _sessionService.clearSession();
      // Get current user from storage directly
      final currentUser = _storage.getUser();
      if (currentUser != null) {
        await _storage.logout(currentUser.phoneNumber ?? '');
        isAuthenticated.value = false;
        
        // Clear all data
        otpRecords.clear();
        phoneController.value.text = '';
        otpController.value.text = '';
        
        // Clear any stored auth state
        await _storage.clearAuthState();
        
        // Navigate to auth choice screen
        await Get.offAllNamed(Routes.AUTH_CHOICE);
      } else {
        await Get.offAllNamed(Routes.AUTH_CHOICE);
      }
    } catch (e) {
      print('Logout error: $e');
      Get.snackbar(
        'Error',
        'Failed to logout properly, please try again',
        backgroundColor: Colors.red.shade100,
      );
      // Still try to navigate to auth choice
      await Get.offAllNamed(Routes.AUTH_CHOICE);
    }
  }

  // Optimize location updates
  Future<void> updateUserLocation(double lat, double lng) async {
    try {
      final phoneNumber = Get.parameters['phone'];
      if (phoneNumber == null) return;

      final currentUser = _storage.getUser(phoneNumber);
      if (currentUser == null) return;

      // Only update if location changed significantly
      if (currentUser.latitude != null && currentUser.longitude != null) {
        if ((currentUser.latitude! - lat).abs() < 0.0001 &&
            (currentUser.longitude! - lng).abs() < 0.0001) {
          return;
        }
      }

      await _storage.saveUser(currentUser.copyWith(
        latitude: lat,
        longitude: lng,
      ));
    } catch (e) {
      print('Update location error: $e');
    }
  }

  Future<void> loginWithPhone() async {
    if (!validatePhoneNumber(phoneController.value.text)) return;

    isLoading.value = true;
    try {
      // Check if number exists
      final response = await _dio.get(
        '$baseUrl/users',
        queryParameters: {'phoneNumber': phoneController.value.text},
      );

      if ((response.data as List).isEmpty) {
        Get.snackbar(
          'Error',
          'Phone number not registered. Please register first.',
          backgroundColor: Colors.red.shade100,
        );
        return;
      }

      // Send OTP for login
      final otpResponse = await _authService.sendOtp(phoneController.value.text);
      if (otpResponse.success) {
        Get.toNamed(
          Routes.VERIFY_OTP,
          parameters: {'phone': phoneController.value.text, 'isLogin': 'true'},
        );
        startResendTimer();
      } else {
        Get.snackbar('Error', otpResponse.message ?? 'Failed to send OTP');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    phoneController.value.dispose();
    otpController.value.dispose();
    super.onClose();
  }
}
