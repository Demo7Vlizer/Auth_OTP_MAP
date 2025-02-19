import 'package:dio/dio.dart';
import '../models/user_details.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UserService {
  final Dio _dio = Dio();
  late final String _baseUrl;

  UserService() {
    _baseUrl = dotenv.env['BASE_URL'] ?? 
        'https://679c68d087618946e65216b3.mockapi.io/otp/todolist';
  }

  Future<UserDetails> getUserDetails(String userId) async {
    try {
      final response = await _dio.get('$_baseUrl/user_details/$userId');
      return UserDetails.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch user details: $e');
    }
  }

  Future<UserDetails> updateUserDetails(String phoneNumber, UserDetails userDetails) async {
    try {
      // First check if user exists
      final response = await _dio.get('$_baseUrl?phoneNumber=$phoneNumber');
      final records = response.data as List;
      
      if (records.isEmpty) {
        // Create new user record
        final createResponse = await _dio.post(
          _baseUrl,
          data: {
            'phoneNumber': phoneNumber,
            'name': userDetails.name,
            'email': userDetails.email,
            'image': userDetails.image,
            'location': {
              'latitude': userDetails.location.latitude,
              'longitude': userDetails.location.longitude,
            },
          },
        );
        return UserDetails.fromJson(createResponse.data);
      } else {
        // Update existing user record
        final existingRecord = records.first;
        final updateResponse = await _dio.put(
          '$_baseUrl/${existingRecord['id']}',
          data: {
            'phoneNumber': phoneNumber,
            'name': userDetails.name,
            'email': userDetails.email,
            'image': userDetails.image,
            'location': {
              'latitude': userDetails.location.latitude,
              'longitude': userDetails.location.longitude,
            },
          },
        );
        return UserDetails.fromJson(updateResponse.data);
      }
    } catch (e) {
      print('Update user error: $e');
      throw Exception('Failed to update user details: $e');
    }
  }
} 