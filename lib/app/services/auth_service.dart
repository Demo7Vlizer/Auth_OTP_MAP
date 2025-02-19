import 'package:dio/dio.dart';
import '../models/api_response.dart';
import 'twilio_service.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';

class AuthService {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://67b57bf4a9acbdb38ed28a42.mockapi.io/api/v1/users';
  final TwilioService _twilioService = TwilioService.instance;

  Future<ApiResponse> sendOtp(String phoneNumber) async {
    try {
      // Check if phone number exists
      final existingUsers = await _dio.get(
        _baseUrl,
        queryParameters: {'phoneNumber': phoneNumber},
      );

      String otp = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
      print('Generated OTP: $otp');

      try {
        await _twilioService.sendSMS(
          phoneNumber,
          'Your OTP is: $otp',
        );
      } catch (smsError) {
        print('SMS Error (continuing anyway): $smsError');
        Get.snackbar(
          'Test OTP',
          'Use this OTP: $otp',
          duration: const Duration(seconds: 10),
        );
      }

      if ((existingUsers.data as List).isNotEmpty) {
        // Update existing user with new OTP
        final existingUser = (existingUsers.data as List).first;
        await _dio.put(
          '$_baseUrl/${existingUser['id']}',
          data: {
            ...existingUser,
            'otp': otp,
            'createdAt': DateTime.now().toIso8601String(),
          },
        );
      } else {
        // Create new user
        await _dio.post(
          _baseUrl,
          data: {
            'phoneNumber': phoneNumber,
            'otp': otp,
            'createdAt': DateTime.now().toIso8601String(),
          },
        );
      }

      return ApiResponse(success: true, message: 'OTP sent successfully');
    } catch (e) {
      print('Auth Service Error: $e');
      return ApiResponse(success: false, message: 'Error: ${e.toString()}');
    }
  }

  Future<ApiResponse> verifyOtp(String phoneNumber, String otp) async {
    try {
      final response = await _dio.get(
        _baseUrl,
        queryParameters: {'phoneNumber': phoneNumber},
      );

      if (response.data == null || (response.data as List).isEmpty) {
        return ApiResponse(success: false, message: 'No OTP found for this number');
      }

      final records = response.data as List;
      final latestRecord = records.last;
      
      if (latestRecord['otp'] == otp) {
        // Get current location
        Position position = await Geolocator.getCurrentPosition();
        
        await _dio.put(
          '$_baseUrl/${latestRecord['id']}',
          data: {
            ...latestRecord, 
            'verified': true,
            'location': {
              'latitude': position.latitude,
              'longitude': position.longitude,
            },
          },
        );
        return ApiResponse(success: true, message: 'OTP verified successfully');
      } else {
        return ApiResponse(success: false, message: 'Invalid OTP');
      }
    } catch (e) {
      print('Verify OTP Error: $e');
      return ApiResponse(success: false, message: 'Error: ${e.toString()}');
    }
  }
} 