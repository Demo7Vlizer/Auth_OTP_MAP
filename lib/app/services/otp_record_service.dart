import 'package:dio/dio.dart';
import '../models/otp_record.dart';
import '../models/user_details.dart';
import 'package:get/get.dart';
import '../services/cache_service.dart';

class OtpRecordService {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://67b57bf4a9acbdb38ed28a42.mockapi.io/api/v1/users';
  final _cache = Get.find<CacheService>();
  static const _cacheKey = 'otp_records';

  OtpRecordService() {
    _dio.options.validateStatus = (status) => status! < 500;
  }

  Future<List<OtpRecord>> getOtpRecords() async {
    try {
      print('Fetching OTP records from: $_baseUrl');
      final response = await _dio.get(_baseUrl);
      
      print('API Response: ${response.data}'); // Debug print
      
      if (response.data == null) {
        print('No data received from API');
        return [];
      }

      final records = (response.data as List)
          .map((json) => OtpRecord.fromJson(json))
          .toList();

      print('Parsed Records Count: ${records.length}'); // Debug print

      // Sort by creation date, newest first
      records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Cache the records
      _cache.set(_cacheKey, records);
      
      return records;
    } catch (e) {
      print('Get OTP records error: $e');
      final cachedData = _cache.get<List<OtpRecord>>(_cacheKey);
      print('Returning cached data: ${cachedData?.length ?? 0} records');
      return cachedData ?? [];
    }
  }

  Future<OtpRecord> createOtpRecord(String phoneNumber,
      {UserDetails? userDetails}) async {
    try {
      final existingRecords =
          await _dio.get('$_baseUrl?phoneNumber=$phoneNumber');
      if ((existingRecords.data as List).isNotEmpty) {
        final existingRecord = (existingRecords.data as List).first;
        final data = {
          'phoneNumber': phoneNumber,
          'createdAt': DateTime.now().toIso8601String(),
          if (userDetails != null) 'userDetails': userDetails.toJson(),
        };

        final response =
            await _dio.put('$_baseUrl/${existingRecord['id']}', data: data);
        return OtpRecord.fromJson(response.data);
      }

      final data = {
        'phoneNumber': phoneNumber,
        'createdAt': DateTime.now().toIso8601String(),
        if (userDetails != null) 'userDetails': userDetails.toJson(),
      };

      final response = await _dio.post(_baseUrl, data: data);
      return OtpRecord.fromJson(response.data);
    } catch (e) {
      print('Error creating/updating OTP record: $e');
      throw Exception('Failed to create/update OTP record: $e');
    }
  }

  Future<OtpRecord> updateOtpRecord(String phoneNumber,
      {required UserDetails userDetails}) async {
    try {
      final existingRecords =
          await _dio.get('$_baseUrl?phoneNumber=$phoneNumber');
      if ((existingRecords.data as List).isEmpty) {
        throw Exception('Record not found');
      }

      final existingRecord = (existingRecords.data as List).first;
      final response = await _dio.put(
        '$_baseUrl/${existingRecord['id']}',
        data: {
          'phoneNumber': phoneNumber,
          'userDetails': userDetails.toJson(),
        },
      );
      return OtpRecord.fromJson(response.data);
    } catch (e) {
      print('Error updating OTP record: $e');
      throw Exception('Failed to update OTP record: $e');
    }
  }
}
